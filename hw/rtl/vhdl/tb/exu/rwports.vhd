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
--  This file simulates the behaviour of read and write ports, so there is no
--  need to the MEMU and a peripheral bus with memory system.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.paranut_config.all;
use work.types.all;
use work.memu_lib.all;
use work.paranut_lib.all;
use work.prog_mem.all;

entity rwports_sim is
    port (
             clk : in std_logic;
             reset : in std_logic;
             ifurpi    : in readport_in_type;
             ifurpo    : out readport_out_type;
             lsurpi    : in readport_in_type;
             lsurpo    : out readport_out_type;
             lsuwpi    : in writeport_in_type;
             lsuwpo    : out writeport_out_type
         );
end rwports_sim;

architecture rtl of rwports_sim is

    constant ifurcntdelay : unsigned (4 downto 0) := "00001";
    constant lsurcntdelay : unsigned (4 downto 0) := "10000";
    constant lsuwcntdelay : unsigned (4 downto 0) := "10000";
    signal ifurcnt : unsigned(4 downto 0) := "00000";
    signal lsurcnt : unsigned(4 downto 0) := "00000";
    signal lsuwcnt : unsigned(4 downto 0) := "00000";

    shared variable mem : mem_type(0 to CFG_NUT_MEM_SIZE/4-1) := (others => X"00000000");

begin


    process
    begin
        mem(0 to PROG_DATA'high) := PROG_DATA;
        wait;
    end process;

    comb : process (ifurcnt, lsurcnt, lsuwcnt)
    begin
        ifurpo.port_ack <= '0';
        lsurpo.port_ack <= '0';
        lsuwpo.port_ack <= '0';
        if (ifurcnt = ifurcntdelay) then
            ifurpo.port_ack <= '1';
        end if;
        if (lsurcnt = lsurcntdelay) then
            lsurpo.port_ack <= '1';
        end if;
        if (lsuwcnt = lsuwcntdelay) then
            lsuwpo.port_ack <= '1';
        end if;
    end process;

    process (clk)
    begin
        if (clk'event and clk='1') then
            if (ifurpi.port_rd = '1') then
                ifurcnt <= ifurcnt + "00001";
            end if;
            if (ifurcnt = ifurcntdelay) then
                ifurpo.port_data <= (others => '0');
                for i in 0 to 3 loop
                    if (ifurpi.port_bsel(i) = '1') then
                        ifurpo.port_data(31-8*i downto 24-8*i) <=
                        mem(conv_integer(ifurpi.port_adr)/4)(31-8*i downto 24-8*i);
                    end if;
                end loop;
                ifurcnt <= (others => '0');
            end if;

            if (lsurpi.port_rd = '1') then
                lsurcnt <= lsurcnt + "00001";
            end if;
            if (lsurcnt = lsurcntdelay) then
                lsurpo.port_data <= (others => '0');
                for i in 0 to 3 loop
                    if (lsurpi.port_bsel(i) = '1') then
                        lsurpo.port_data(31-8*i downto 24-8*i) <=
                        mem(conv_integer(lsurpi.port_adr)/4)(31-8*i downto 24-8*i);
                    end if;
                end loop;
                lsurcnt <= (others => '0');
            end if;

            if (lsuwpi.port_wr = '1') then
                lsuwcnt <= lsuwcnt + "00001";
            end if;
            if (lsuwcnt = lsuwcntdelay) then
                for i in 0 to 3 loop
                    if (lsuwpi.port_bsel(i) = '1') then
                        mem(conv_integer(lsuwpi.port_adr)/4)(31-8*i downto 24-8*i) := lsuwpi.port_data(31-8*i downto 24-8*i);
                    end if;
                end loop;
                lsuwcnt <= (others => '0');
            end if;
        end if;
    end process;

end rtl;
