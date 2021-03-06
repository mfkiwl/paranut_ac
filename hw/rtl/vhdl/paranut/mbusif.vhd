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
--  Bus interface to the Wishbone BUS
--  (Bus interface operations defined in memu_lib.vhd)
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library paranut;
use paranut.paranut_config.all;
use paranut.types.all;
use paranut.memu_lib.all;
use paranut.paranut_lib.all;

use paranut.histogram.all;

entity mbusif is
    port (
             clk    : in  std_logic;
             reset  : in  std_logic;
             -- Bus interface (Wishbone)...
             bifwbi : in busif_wishbone_in_type;
             bifwbo : out busif_wishbone_out_type;
             -- Memory/Control (cache, rp, wp)...
             bifi  : in busif_in_type;
             bifo  : out busif_out_type;
             -- Request & grant lines...
             bifai  : in busif_arbiter_in_type;
             bifao  : out busif_arbiter_out_type;
             -- Histogram...
             hist_cache_line_fill : out hist_ctrl_type;
             hist_cache_line_wb : out hist_ctrl_type
         );
end mbusif;

architecture rtl of mbusif is

    type state_type is (S_BIF_IDLE, S_BIF_DIRECT_READ_1, S_BIF_DIRECT_READ_2,
    S_BIF_DIRECT_WRITE, S_BIF_CACHE_REQUEST_LL_WAIT,
    S_BIF_CACHE_REQUEST_RT_WAIT, S_BIF_CACHE_READ_TAG,
    S_BIF_CACHE_REPLACE_READ_IDATA, S_BIF_CACHE_READ_DIRTY_BANKS,
    S_BIF_CACHE_REPLACE_INVALIDATE_TAG, S_BIF_CACHE_REPLACE_WRITE_BANKS,
    S_BIF_CACHE_WRITE_TAG, S_BIF_CACHE_WRITE_BACK_VICTIM, S_BIF_CACHE_ACK);

    type registers is record
        state : state_type;
        op : BUS_IF_OP;
        linelock : std_logic;
        bsel : TByteSel;
        adr : TWord;
        adr_ofs : std_logic_vector(CFG_MEMU_CACHE_BANKS_LD-1 downto 0);
        idata : TWord_Vec(0 to CFG_MEMU_CACHE_BANKS-1);
        odata : TWord_Vec(0 to CFG_MEMU_CACHE_BANKS-1);
        banks_left : std_logic_vector(0 to CFG_MEMU_CACHE_BANKS-1);
        banks_left_last : std_logic_vector(0 to CFG_MEMU_CACHE_BANKS-1);
        write_victim : std_logic;
        idata_valid : std_logic_vector(0 to CFG_MEMU_CACHE_BANKS-1);
        cnt : unsigned(CFG_MEMU_CACHE_BANKS_LD-1 downto 0);
        tag : cache_tag_type;
    end record;

    signal r, rin : registers;

begin

    comb : process (r, reset, bifwbi, bifi, bifai)
        variable v : registers;
        -- Output variables...
        variable vbifwbo : busif_wishbone_out_type;
        variable vbifo : busif_out_type;
        variable vbifao : busif_arbiter_out_type;
    begin

        v := r;

        hist_cache_line_fill.start <= '0';
        hist_cache_line_fill.stop <= '0';
        hist_cache_line_wb.start <= '0';
        hist_cache_line_wb.stop <= '0';

        -- Defaults for outputs...
        vbifwbo.cyc_o := '0';
        vbifwbo.stb_o := '0';
        vbifwbo.we_o := '0';
        -- don't cares...
        -- Note: The mbusif was not functional after synthesis with don't
        -- cares, so all Wishbone signals are assigned a default value other
        -- than '-' and the values are changed in the corresponding states.
        --vbifwbo.sel_o := X"F";
        vbifwbo.sel_o := r.bsel;
        --vbifwbo.adr_o := (others => '-');
        --vbifwbo.dat_o := (others => '-');
        vbifwbo.adr_o := r.adr;
        vbifwbo.dat_o := r.odata(conv_integer(r.adr(BANK_OF_ADDR_RANGE)));
        vbifwbo.cti_o := "000";
        -- registered feedback bus cycle only for 4-16 banks
        if (CFG_MEMU_CACHE_BANKS = 4) then
            vbifwbo.bte_o := "01";
        elsif (CFG_MEMU_CACHE_BANKS = 8) then
            vbifwbo.bte_o := "10";
        elsif (CFG_MEMU_CACHE_BANKS = 16) then
            vbifwbo.bte_o := "11";
        else
            vbifwbo.bte_o := "00";
        end if;

        vbifo.tag_rd := '0';
        vbifo.tag_wr := '0';
        vbifo.bank_rd := (others => '0');
        vbifo.bank_wr := (others => '0');
        vbifo.busif_busy := '1';
        -- don't cares...
        vbifo.tag_out := r.tag; -- needed to put the 'way' to the outputs
        --vbifo.tag_out := (
        --valid => '0',
        --dirty => '0',
        --taddr => (others => '-'),
        --way => (others => '-'));

        vbifao.req_tagr := '0';
        vbifao.req_tagw := '0';
        vbifao.req_linelock := r.linelock;
        vbifao.req_bank := (others => '0');

        v.banks_left_last := r.banks_left;
        --if (unsigned(r.banks_left) = 0) then
        --    v.banks_left := (others => '1');
        --end if;

        case r.state is
            when S_BIF_IDLE =>
                -- Latch all inputs since the BUSIF requester may release the request after one clock cycle...
                vbifo.busif_busy := '0';
                v.op := bifi.busif_op;
                v.bsel := bifi.busif_bsel;
                v.adr := bifi.adr_in;
                v.adr_ofs := bifi.adr_in(BANK_OF_ADDR_RANGE);
                v.odata := bifi.data_in;
                v.cnt := (others => '0');
                -- Helper registers...
                v.write_victim := '0';
                v.banks_left := (others => '1');

                case bifi.busif_op is
                    when BIO_DIRECT_READ =>
                        v.state := S_BIF_DIRECT_READ_1;
                    when BIO_DIRECT_WRITE =>
                        v.state := S_BIF_DIRECT_WRITE;
                    when BIO_WRITEBACK | BIO_INVALIDATE | BIO_FLUSH | BIO_REPLACE =>
                        -- All cache-related operations...
                        v.linelock := not bifi.busif_nolinelock;
                        v.adr(1 downto 0) := "00";
                        if (bifi.busif_nolinelock = '1') then
                            v.state := S_BIF_CACHE_REQUEST_RT_WAIT;
                        else
                            v.state := S_BIF_CACHE_REQUEST_LL_WAIT;
                        end if;
                    when others => -- incl. BIO_NOTHING
                end case;
            -- Perform WB read cycle...
            when S_BIF_DIRECT_READ_1 =>
                -- dat_o, adr_o, sel_o taken care of by default assignment
                --vbifwbo.adr_o := r.adr;
                --vbifwbo.sel_o := r.bsel;
                vbifwbo.cyc_o := '1';
                vbifwbo.stb_o := '1';
                if (bifwbi.ack_i = '1') then
                    v.idata(conv_integer(r.adr(BANK_OF_ADDR_RANGE))) := bifwbi.dat_i;
                    v.idata_valid(conv_integer(r.adr(BANK_OF_ADDR_RANGE))) := '1';
                    v.state := S_BIF_DIRECT_READ_2;
                end if;
            when S_BIF_DIRECT_READ_2 =>
                -- Reset valid signal to avoid wrong BusIF hits
                v.idata_valid(conv_integer(r.adr(BANK_OF_ADDR_RANGE))) := '0';
                -- Note: 'r.idata' must still be valid in the first cycle of
                --'idata_valid_out = 0' due to pipelining in the read ports
                v.state := S_BIF_IDLE;
            -- Perform WB write cycle...
            when S_BIF_DIRECT_WRITE =>
                -- dat_o, adr_o, sel_o taken care of by default assignment
                --vbifwbo.adr_o := r.adr;
                --vbifwbo.dat_o := r.odata(conv_integer(r.adr(BANK_OF_ADDR_RANGE)));
                --vbifwbo.sel_o := r.bsel;
                vbifwbo.we_o := '1';
                vbifwbo.cyc_o := '1';
                vbifwbo.stb_o := '1';
                if (bifwbi.ack_i = '1') then
                    v.state := S_BIF_IDLE;
                end if;
            -- All cache-related operations...
            when S_BIF_CACHE_REQUEST_LL_WAIT =>
                if (bifai.gnt_linelock = '1') then
                    v.state := S_BIF_CACHE_REQUEST_RT_WAIT;
                end if;
            when S_BIF_CACHE_REQUEST_RT_WAIT =>
                vbifao.req_tagr := '1';
                if (bifai.gnt_tagr = '1') then
                    vbifo.tag_rd := '1';
                    v.state := S_BIF_CACHE_READ_TAG;
                end if;
            when S_BIF_CACHE_READ_TAG =>
                -- Read tag...
                v.tag := bifi.tag_in;
                case r.op is
                    when BIO_REPLACE =>
                        hist_cache_line_fill.start <= '1';
                        v.state := S_BIF_CACHE_REPLACE_READ_IDATA;
                    when BIO_WRITEBACK | BIO_FLUSH =>
                        if (bifi.tag_in.dirty = '1') then
                            v.state := S_BIF_CACHE_READ_DIRTY_BANKS;
                        else
                            v.state := S_BIF_CACHE_WRITE_TAG;
                        end if;
                    when others =>
                        v.state := S_BIF_CACHE_WRITE_TAG;
                end case;
            when S_BIF_CACHE_REPLACE_READ_IDATA =>
                -- Read (new) bus data into 'idata' register...
                -- ... allowing to serve a read request as early as possible
                vbifwbo.sel_o := X"F";
                vbifwbo.cyc_o := '1';
                vbifwbo.stb_o := '1';
                if (CFG_MEMU_CACHE_BANKS >= 4 and CFG_MEMU_CACHE_BANKS <= 16) then
                    -- registered feedback bus cycle only for 4-16 banks
                    if (r.cnt = CFG_MEMU_CACHE_BANKS-1) then
                        vbifwbo.cti_o := "111";
                    else
                        vbifwbo.cti_o := "010";
                    end if;
                end if;
                vbifwbo.adr_o := r.adr(31 downto CFG_MEMU_CACHE_BANKS_LD+2) & r.adr_ofs & "00";
                if (bifwbi.ack_i = '1') then
                    v.idata(conv_integer(r.adr_ofs)) := bifwbi.dat_i;
                    v.idata_valid(conv_integer(r.adr_ofs)) := '1';
                    v.adr(BANK_OF_ADDR_RANGE) := r.adr_ofs;
                    if (r.cnt /= CFG_MEMU_CACHE_BANKS-1) then
                        v.adr_ofs := std_logic_vector(unsigned(r.adr_ofs) + 1);
                        v.cnt := r.cnt + 1;
                    else
                        hist_cache_line_fill.stop <= '1';
                        v.cnt := (others => '0');
                        if (r.tag.dirty = '1') then
                            v.state := S_BIF_CACHE_READ_DIRTY_BANKS;
                        else
                            v.state := S_BIF_CACHE_REPLACE_INVALIDATE_TAG;
                        end if;
                    end if;
                end if;
            when S_BIF_CACHE_READ_DIRTY_BANKS =>
                v.write_victim := '1';
                -- Read (old) cache bank into 'odata' register (with maximum parallelism)
                -- 'bank_rd' also selects the 'data_in' mux input for banks in
                -- the memu so it has to be kept up in the cycle after
                -- 'gnt_bank' when data is finally arriving
                vbifao.req_bank := r.banks_left;
                vbifo.bank_rd := r.banks_left_last;
                --v.banks_left := r.banks_left and not bifai.gnt_bank;
                for n in 0 to CFG_MEMU_CACHE_BANKS-1 loop
                    if (r.banks_left(n) = '0' and r.banks_left_last(n) = '1') then
                        v.odata(n) := bifi.data_in(n);
                    end if;
                    if (bifai.gnt_bank(n) = '1') then
                        -- bank data will arrive in the next cycle!
                        v.banks_left(n) := '0';
                    end if;
                end loop;
                if (unsigned(r.banks_left) = 0) then
                    v.banks_left := (others => '1');
                    if (r.op = BIO_REPLACE) then
                        v.state := S_BIF_CACHE_REPLACE_INVALIDATE_TAG;
                    else
                        v.state := S_BIF_CACHE_WRITE_TAG;
                    end if;
                end if;
            when S_BIF_CACHE_REPLACE_INVALIDATE_TAG =>
                -- Write invalid tag (to make sure that concurrent readers do not receive invalid data)
                vbifao.req_tagw := '1';
                vbifo.tag_out.valid := '0';
                if (bifai.gnt_tagw = '1') then
                    v.cnt := r.cnt + 1;
                    vbifo.tag_wr := '1';
                    if (r.cnt(0) = '1') then
                        v.cnt := (others => '0');
                        v.state := S_BIF_CACHE_REPLACE_WRITE_BANKS;
                    end if;
                end if;
            when S_BIF_CACHE_REPLACE_WRITE_BANKS =>
                -- Write data to cache banks; operate in parallel as much as possible
                vbifao.req_bank := r.banks_left;
                vbifo.bank_wr := r.banks_left;
                --v.banks_left := r.banks_left and not bifai.gnt_bank;
                for n in 0 to CFG_MEMU_CACHE_BANKS-1 loop
                    if (bifai.gnt_bank(n) = '1') then
                        v.banks_left(n) := '0';
                    end if;
                end loop;
                if (unsigned(r.banks_left) = 0) then
                    v.banks_left := (others => '1');
                    v.state := S_BIF_CACHE_WRITE_TAG;
                end if;
            when S_BIF_CACHE_WRITE_TAG =>
                -- Write new tag...
                vbifao.req_tagw := '1';
                vbifo.tag_out.taddr := r.adr(TAG_OF_ADDR_RANGE);
                if (r.op = BIO_REPLACE) then
                    vbifo.tag_out.valid := '1';
                elsif (r.op = BIO_FLUSH or r.op = BIO_INVALIDATE) then
                    vbifo.tag_out.valid := '0';
                end if;
                vbifo.tag_out.dirty := '0';
                if (bifai.gnt_tagw = '1') then
                    v.cnt := r.cnt + 1;
                    vbifo.tag_wr := '1';
                    if (r.cnt(0) = '1') then
                        v.cnt := (others => '0');
                        if (r.write_victim = '1') then
                            hist_cache_line_wb.start <= '1';
                            v.state := S_BIF_CACHE_WRITE_BACK_VICTIM;
                        else
                            -- Reset valid signal to avoid wrong BusIF hits
                            v.idata_valid := (others => '0');
                            v.state := S_BIF_CACHE_ACK;
                        end if;
                    end if;
                end if;
            when S_BIF_CACHE_WRITE_BACK_VICTIM =>
                -- Write back victim data to bus...
                vbifwbo.sel_o := X"F";
                vbifwbo.cyc_o := '1';
                vbifwbo.we_o := '1';
                vbifwbo.stb_o := '1';
                vbifwbo.adr_o := r.tag.taddr & r.adr(INDEX_OF_ADDR_RANGE) & std_logic_vector(r.cnt) & "00";
                vbifwbo.dat_o := r.odata(conv_integer(r.cnt));
                if (CFG_MEMU_CACHE_BANKS >= 4 and CFG_MEMU_CACHE_BANKS <= 16) then
                    -- registered feedback bus cycle only for 4-16 banks
                    if (r.cnt = CFG_MEMU_CACHE_BANKS-1) then
                        vbifwbo.cti_o := "111";
                    else
                        vbifwbo.cti_o := "010";
                    end if;
                end if;
                if (bifwbi.ack_i = '1') then
                    if (r.cnt = CFG_MEMU_CACHE_BANKS-1) then
                        hist_cache_line_wb.stop <= '1';
                        -- Reset valid signal to avoid wrong BusIF hits
                        v.idata_valid := (others => '0');
                        v.state := S_BIF_CACHE_ACK;
                    else
                        v.cnt := r.cnt + 1;
                    end if;
                end if;
            when S_BIF_CACHE_ACK =>
                vbifo.busif_busy := '0';
                v.linelock := '0';
                v.state := S_BIF_IDLE;
            when others =>
                v.state := S_BIF_IDLE;
        end case;

        if (reset = '1') then
            v.idata_valid := (others => '0');
            v.state := S_BIF_IDLE;
            v.op := BIO_NOTHING;
            v.linelock := '0';
            --v.banks_left := (others => '0');
            vbifo.busif_busy := '0';
        end if;

        vbifo.adr_out := r.adr;
        vbifo.data_out := r.idata;
        vbifo.data_out_valid := r.idata_valid;

        bifwbo <= vbifwbo;
        bifo <= vbifo;
        bifao <= vbifao;

        rin <= v;

    end process;

    regs : process (clk)
    begin
        if (clk'event and clk = '1') then
            r <= rin;
        end if;
    end process;

end rtl;

