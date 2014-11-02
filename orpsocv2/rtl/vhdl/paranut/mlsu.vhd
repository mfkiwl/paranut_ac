--------------------------------------------------------------------------------
-- This file is part of the ParaNut project.
-- 
-- Copyright (C) 2013  Michael Seider, Hochschule Augsburg
-- michael.seider@hs-augsburg.de
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Description:
--  Load/store unit with store buffer
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.paranut_config.all;
use paranut.lsu.all;
use paranut.types.all;
use paranut.memu_lib.all;
use paranut.paranut_lib.all;

entity mlsu is
    generic (
                LSU_WBUF_SIZE_LD : integer range 2 to 4 := 2
            );
    port (
             clk            : in std_logic;
             reset          : in std_logic;
             -- to EXU...
             lsui           : in lsu_in_type;
             lsuo           : out lsu_out_type;
             -- to MEMU/read port...
             rpi            : out readport_in_type;
             rpo            : in readport_out_type;
             -- to MEMU/write port...
             wpi            : out writeport_in_type;
             wpo            : in writeport_out_type;
             -- from CePU
             dcache_enable  : in std_logic
         );
end mlsu;

architecture rtl of mlsu is

    constant MAX_WBUF_SIZE_LD : integer := LSU_WBUF_SIZE_LD;
    constant MAX_WBUF_SIZE    : integer := 2**MAX_WBUF_SIZE_LD;

    -- Registers
    type registers is record
        wbuf_adr: TWord_Vec(0 to MAX_WBUF_SIZE-1);
        wbuf_data: TWord_Vec(0 to MAX_WBUF_SIZE-1);
        wbuf_valid: TWBufValid_Vec(0 to MAX_WBUF_SIZE-1);
        wbuf_dirty0 : std_logic;
        buf_fill_hist : TWord_Vec(0 to MAX_WBUF_SIZE+1);
    end record;

    -- returns, if there is a hit with the MSB, and the index of the entry with the remaining bits
    function FindWbufHit (
        adr : in TWord; 
        wbuf_adr : in TWord_Vec;
        wbuf_valid : in TWBufValid_Vec)
    return std_logic_vector is
        variable i : std_logic_vector(MAX_WBUF_SIZE_LD downto 0);
    begin
        i := (others => '0');
        for n in MAX_WBUF_SIZE-1 downto 0 loop
            if (wbuf_adr(n)(31 downto 2) = adr(31 downto 2) and wbuf_valid(n) /= "0000") then
                i := '1' & conv_std_logic_vector(n, MAX_WBUF_SIZE_LD);
                exit;
            end if;
        end loop;
        return(i);
    end;

    -- returns, if there is an empty entry with the MSB, and the index of the entry with the remaining bits
    function FindEmptyWbufEntry (wbuf_valid : in TWBufValid_Vec)
    return std_logic_vector is
        variable i : std_logic_vector(MAX_WBUF_SIZE_LD downto 0);
    begin
        i := (others => '0');
        for n in 0 to MAX_WBUF_SIZE-1 loop
            if (wbuf_valid(n) = "0000") then
                i := '1' & conv_std_logic_vector(n, MAX_WBUF_SIZE_LD);
                exit;
            end if;
        end loop;
        return(i);
    end;

    function IsFlushed (wbuf_valid : in TWBufValid_Vec)
    return boolean is
        variable b : boolean;
    begin
        b := true;
        for n in 0 to MAX_WBUF_SIZE-1 loop
            if (wbuf_valid(n) /= "0000") then
                b := false;
                exit;
            end if;
        end loop;
        return(b);
    end;

    signal r, rin : registers;

begin

    comb : process(reset, r, lsui, rpo, wpo)

        variable v : registers;

        variable vrpi : readport_in_type;
        variable vwpi : writeport_in_type;
        variable vlsuo : lsu_out_type;

        variable bsel : TByteSel;
        variable valid : TWBufValid;
        variable data : TWord;
        variable wbdata : TWord;

        variable wbuf_hit, wbuf_new : std_logic_vector(MAX_WBUF_SIZE_LD downto 0);
        -- buffer hit?
        variable wbuf_hit_b, wbuf_new_b, wbuf_entry_b, wbuf_full : boolean;
        -- entry indices (used to index a wbuf entry)
        variable wbuf_hit_i, wbuf_new_i, wbuf_entry_i : integer range 0 to MAX_WBUF_SIZE-1;
        variable wbuf_dont_change : std_logic;

    begin

        v := r;

        vlsuo.ack := '0';
        vlsuo.align_err := '0';
        if (CFG_NUT_HISTOGRAM) then
            vlsuo.buf_fill_hist := r.buf_fill_hist;
        end if;

        vrpi.port_rd := '0';
        --vrpi.port_adr := lsui.adr(31 downto 2) & "00";
        vrpi.port_adr := lsui.adr;

        vwpi.port_rlink_wcond := '0';
        vwpi.port_writeback := '0';
        vwpi.port_invalidate := '0';

        bsel := "0000";
        data := (others => '-');
        wbdata := (others => '-');

        -- Generate 'wbdata', 'bsel', general alignment check...
        case lsui.width is
            when "00" =>
                if (lsui.adr(1 downto 0) /= "00") then
                    vlsuo.align_err := '1';
                else
                    bsel := X"f";
                    wbdata := lsui.wdata;
                end if;
            when "01" =>
                bsel(conv_integer(lsui.adr(1 downto 0))) := '1';
                for n in 0 to 3 loop
                    wbdata(31-8*n downto 24-8*n) := lsui.wdata(7 downto 0);
                end loop;
            when "10" =>
                if (lsui.adr(0) /= '0') then
                    vlsuo.align_err := '1';
                else
                    bsel(1+conv_integer(lsui.adr(1 downto 0)) downto 0+conv_integer(lsui.adr(1 downto 0))) := "11";
                    for n in 0 to 1 loop
                        wbdata(31-16*n downto 16-16*n) := lsui.wdata(15 downto 0);
                    end loop;
                end if;
            when others =>
                null;
        end case;

        if (lsui.cache_writeback = '1' or lsui.cache_invalidate = '1') then bsel := "0000"; end if;

        -- Examine wbuf...
        wbuf_hit := FindWbufHit(lsui.adr, r.wbuf_adr, r.wbuf_valid);
        wbuf_hit_b := wbuf_hit(MAX_WBUF_SIZE_LD) = '1';
        wbuf_hit_i := conv_integer(wbuf_hit(MAX_WBUF_SIZE_LD-1 downto 0));
        wbuf_new := FindEmptyWbufEntry(r.wbuf_valid);
        wbuf_new_i := conv_integer(wbuf_new(MAX_WBUF_SIZE_LD-1 downto 0));
        wbuf_new_b := wbuf_new(MAX_WBUF_SIZE_LD) = '1';

        -- Read request: generate 'rdata', 'rp_bsel'...
        vlsuo.rdata := rpo.port_data;
        vrpi.port_bsel := bsel;
        if (wbuf_hit_b) then
            -- we can only serve partially, but MUST forward modified bytes from the write buffer
            for n in 0 to 3 loop
                if (r.wbuf_valid(wbuf_hit_i)(n) = '1') then
                    vlsuo.rdata(31-8*n downto 24-8*n) := r.wbuf_data(wbuf_hit_i)(31-8*n downto 24-8*n);
                end if;
            end loop;
        end if;

        -- Format data word & generate 'rdata'...
        case lsui.width is
            when "01" =>
                vlsuo.rdata(7 downto 0) := vlsuo.rdata(31-8*conv_integer(lsui.adr(1 downto 0)) downto 24-8*conv_integer(lsui.adr(1 downto 0)));
                if (lsui.exts = '1' and vlsuo.rdata(7) = '1') then
                    vlsuo.rdata(31 downto 8) := (others => '1');
                else
                    vlsuo.rdata(31 downto 8) := (others => '0');
                end if;
            when "10" =>
                vlsuo.rdata(15 downto 0) := vlsuo.rdata(31-16*conv_integer(lsui.adr(1 downto 1)) downto 16-16*conv_integer(lsui.adr(1 downto 1)));
                if (lsui.exts = '1' and vlsuo.rdata(15) = '1') then
                    vlsuo.rdata(31 downto 16) := (others => '1');
                else
                    vlsuo.rdata(31 downto 16) := (others => '0');
                end if;
            when others =>
                null;
        end case;

        -- Read request: generate 'rp_rd, 'ack'...
        if (lsui.rd = '1') then
            if (wbuf_hit_b and (bsel and not r.wbuf_valid(wbuf_hit_i)) = "0000") then
                -- we can serve all bytes from the write buffer
                vrpi.port_rd := '0'; -- no request to memory
                vlsuo.ack := '1';
                if (CFG_NUT_HISTOGRAM) then
                    if (lsui.hist_enable = '1') then
                        v.buf_fill_hist(MAX_WBUF_SIZE) := r.buf_fill_hist(MAX_WBUF_SIZE) + 1;
                    end if;
                end if;
            else
                -- we either have a write buffer miss or cannot serve all bytes
                -- pass through ack from MEMU...
                vrpi.port_rd := '1';
                vlsuo.ack := rpo.port_ack;
                if (CFG_NUT_HISTOGRAM) then
                    if (lsui.hist_enable = '1' and rpo.port_ack = '1' and wbuf_hit_b) then
                        v.buf_fill_hist(MAX_WBUF_SIZE+1) := r.buf_fill_hist(MAX_WBUF_SIZE+1) + 1;
                    end if;
                end if;
            end if;
        end if;

        -- Handle flush mode (generate 'ack')...
        if (lsui.flush = '1' and IsFlushed(r.wbuf_valid)) then vlsuo.ack := '1'; end if;

        -- Generate MEMU write port signals...
        vwpi.port_adr := r.wbuf_adr(0);
        vwpi.port_data := r.wbuf_data(0);
        vwpi.port_bsel := r.wbuf_valid(0);
        if (IsFlushed(r.wbuf_valid) and (lsui.cache_writeback = '1' or lsui.cache_invalidate = '1')) then
            vwpi.port_wr := '0'; -- cannot write now
            vwpi.port_writeback := lsui.cache_writeback;
            vwpi.port_invalidate := lsui.cache_invalidate;
            vlsuo.ack := wpo.port_ack;
        else
            vwpi.port_wr := r.wbuf_dirty0;
            vwpi.port_writeback := lsui.cache_writeback;
            vwpi.port_invalidate := lsui.cache_invalidate;
        end if;

        -- only assert 'align_err' if there's access
        if (lsui.rd = '0' and lsui.wr = '0') then
            vlsuo.align_err := '0';
        elsif (vlsuo.align_err = '1') then
            vrpi.port_rd := '0';
        end if;

        -- Generate all register contents...

        -- Determine place for (eventual) new wbuf entry...
        if (lsui.wr = '1') then
            wbuf_entry_i := wbuf_hit_i;
            wbuf_entry_b := wbuf_hit_b;
            wbuf_full := false;
            if (not wbuf_entry_b or adr_is_special(lsui.adr)) then
                wbuf_entry_i := wbuf_new_i;
                wbuf_entry_b := wbuf_new_b;
            end if;
            if (not wbuf_entry_b) then
                wbuf_entry_i := MAX_WBUF_SIZE-1;
                wbuf_entry_b := true;
                wbuf_full := true;
            end if;
        else
            wbuf_entry_i := MAX_WBUF_SIZE-1; -- Set to /= 0 to allow wbuf removes
            wbuf_entry_b := false;
            wbuf_full := false;
        end if;

        -- Handle cache control operations...
        if (lsui.cache_writeback = '1' or lsui.cache_invalidate = '1') then
            -- pragma translate_off
            assert (lsui.wr = '0' and lsui.rd = '0') report "lsui.wr and lsui.rd /= '0'";
            -- pragma translate_on
            if (IsFlushed(r.wbuf_valid)) then
                wbuf_entry_i := 0;
                wbuf_entry_b := true;
                wbuf_full := false;
            else
                wbuf_entry_b := false;
            end if;
        end if;

        -- Read old data if applicable...
        if (wbuf_entry_b and not wbuf_full) then
            data := r.wbuf_data(wbuf_entry_i);
            valid := r.wbuf_valid(wbuf_entry_i);
        else
            valid := "0000";
        end if;

        wbuf_dont_change := '0';
        -- this prevents changes of the wbuf in 2 situations:
        -- - For a read hit in wbuf slot #0:
        --      make sure the wbuf is not changed in this clock cycle so that the forwarded data is still present in the next cycle
        -- - For a write hit in wbuf slot #0:
        --      don't write into slot 0 if it is already writing
        if (r.wbuf_dirty0 = '1' and
            ((lsui.rd = '1' and wbuf_hit_b and wbuf_hit_i = 0) or
            (lsui.wr = '1' and wbuf_entry_b and wbuf_entry_i = 0))) then
            wbuf_dont_change := '1';
        end if;

        -- Remove oldest entry if MEMU write / cache_writeback / cache_invalidate was completed...
        if (wpo.port_ack = '1') then
            v.wbuf_dirty0 := '0';
        end if;
        if (wbuf_dont_change = '0' and (r.wbuf_dirty0 = '0' or wpo.port_ack = '1') and wbuf_entry_i /= 0) then
            -- we can safely remove the data...
            v.wbuf_adr(0 to MAX_WBUF_SIZE-2) := r.wbuf_adr(1 to MAX_WBUF_SIZE-1);
            v.wbuf_data(0 to MAX_WBUF_SIZE-2) := r.wbuf_data(1 to MAX_WBUF_SIZE-1);
            v.wbuf_valid(0 to MAX_WBUF_SIZE-2) := r.wbuf_valid(1 to MAX_WBUF_SIZE-1);
            v.wbuf_valid(MAX_WBUF_SIZE-1) := "0000";
            -- pragma translate_off
            if (wbuf_entry_i > 0) then
            -- pragma translate_on
            if (wbuf_full) then
                -- buffer already points to the last entry MAX_WBUF_SIZE-1 if buffer was previously full
                -- comment out to help improve timing and area consumption
                wbuf_full := false;
            else
                 --adjust new entry index
                wbuf_entry_i := wbuf_entry_i - 1;
            end if;
            -- pragma translate_off
            end if;
            -- pragma translate_on
            v.wbuf_dirty0 := conv_std_logic(r.wbuf_valid(1) /= "0000");
        end if;

        -- Store new entry if applicable...
        if (wbuf_entry_b and not wbuf_full
                and (not (adr_is_special(lsui.adr) and wbuf_entry_i /= 0))
                and wbuf_dont_change = '0') then
            --v.wbuf_adr(wbuf_entry_i) := lsui.adr(31 downto 2) & "00";
            v.wbuf_adr(wbuf_entry_i) := lsui.adr;
            for n in 0 to 3 loop
                if (bsel(n) = '1') then
                    data(31-n*8 downto 24-n*8) := wbdata(31-n*8 downto 24-n*8);
                end if;
            end loop;
            v.wbuf_data(wbuf_entry_i) := data;
            v.wbuf_valid(wbuf_entry_i) := valid or bsel;
            if (wbuf_entry_i = 0) then
                v.wbuf_dirty0 := '1';
            end if;
            vlsuo.ack := '1';
            if (CFG_NUT_HISTOGRAM) then
                if (lsui.hist_enable = '1') then
                    v.buf_fill_hist(wbuf_entry_i) := r.buf_fill_hist(wbuf_entry_i) + 1;
                end if;
            end if;
        end if;

        -- 'direct' lines for read/write ports...
        if ((dcache_enable = '0') or (not adr_is_cached(vrpi.port_adr))) then
            vrpi.port_direct := '1';
        else
            vrpi.port_direct := '0';
        end if;
        if ((dcache_enable = '0') or (not adr_is_cached(vwpi.port_adr))) then
            vwpi.port_direct := '1';
        else
            vwpi.port_direct := '0';
        end if;

        -- Output...
        lsuo <= vlsuo;
        rpi <= vrpi;
        wpi <= vwpi;

        -- Reset...
        if (reset = '1') then
            v.wbuf_valid := (others => "0000");
            v.wbuf_dirty0 := '0';
            if (CFG_NUT_HISTOGRAM) then
                v.buf_fill_hist := (others => (others => '0'));
            end if;
        end if;

        rin <= v;

    end process;

    regs : process(clk)
    begin
        if (clk'event and clk = '1') then
            r <= rin;
        end if;
    end process;

end rtl;
