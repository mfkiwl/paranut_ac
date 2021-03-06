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
--  Simple Load/store unit without store buffer
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

entity mlsu_simple is
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
end mlsu_simple;

architecture rtl of mlsu_simple is

begin

    comb : process(reset, lsui, rpo, wpo)

        variable vrpi : readport_in_type;
        variable vwpi : writeport_in_type;
        variable vlsuo : lsu_out_type;

        variable bsel : TByteSel;
        variable wbdata : TWord;

    begin

        vlsuo.ack := '0';
        vlsuo.align_err := '0';

        vrpi.port_rd := '0';
        --vrpi.port_adr := lsui.adr(31 downto 2) & "00";
        vrpi.port_adr := lsui.adr;

        vwpi.port_rlink_wcond := '0';
        vwpi.port_writeback := '0';
        vwpi.port_invalidate := '0';

        bsel := "0000";
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

        -- Read request: generate 'rdata', 'rp_bsel'...
        vlsuo.rdata := rpo.port_data;
        vrpi.port_bsel := bsel;

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

        vrpi.port_rd := lsui.rd;
        if (lsui.rd = '1') then
            vlsuo.ack := rpo.port_ack;
        elsif (lsui.wr = '1') then
            vlsuo.ack := wpo.port_ack;
        end if;

        -- Generate MEMU write port signals...
        vwpi.port_adr := lsui.adr;
        vwpi.port_data := wbdata;
        vwpi.port_bsel := bsel;
        vwpi.port_wr := lsui.wr;
        vwpi.port_writeback := lsui.cache_writeback;
        vwpi.port_invalidate := lsui.cache_invalidate;

        -- only assert 'align_err' if there's access
        if (lsui.rd = '0' and lsui.wr = '0') then
            vlsuo.align_err := '0';
        elsif (vlsuo.align_err = '1') then
            vrpi.port_rd := '0';
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

    end process;

end rtl;
