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
--  LSU testbench.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.types.all;
use work.memu_lib.all;
use work.lsu.all;

entity mlsu_tb is
    end mlsu_tb;

architecture tb of mlsu_tb is

             signal clk    : std_logic;
             signal reset  : std_logic;

             signal lsui   : lsu_in_type;
             signal lsuo   : lsu_out_type;

             signal rpi    : readport_in_type;
             signal rpo    : readport_out_type;

             signal wpi    : writeport_in_type;
             signal wpo    : writeport_out_type;
             signal dcache_enable : std_logic;

    constant clk_period : time := 10 ns;

    signal halt: boolean := false;

begin

    uut: mlsu
    port map (clk, reset, lsui, lsuo, rpi, rpo, wpi, wpo, dcache_enable);

    clock: process
    begin
        while (not halt) loop
            clk <= '1'; wait for clk_period/2;
            clk <= '0'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    tb: process

        procedure write(adr, data : TWord; width : std_logic_vector(1 downto 0)) is
        begin
            lsui.wr <= '1';
            lsui.adr <= adr;
            lsui.wdata <= data;
            lsui.width <= width;
            wait for clk_period;
            lsui.wr <= '0';
        end procedure;

    begin

        reset <= '1';
        lsui.rd <= '0';
        lsui.wr <= '0';
        lsui.cache_invalidate <= '0';
        lsui.cache_writeback <= '0';
        lsui.rlink_wcond <= '0';
        lsui.flush <= '0';
        lsui.exts <= '0';
        dcache_enable <= '0';
        --wait for clk_period/8;
        wait for 5*clk_period;

        reset <= '0';
        wait for clk_period;

        write(X"00003100", X"01234567", "00");
        write(X"00007200", X"89abcdef", "00");
        write(X"00027200", X"091b2d3f", "00");
        write(X"00000000", X"11111111", "00");
        write(X"00000001", X"22222222", "01");
        write(X"00000002", X"33333333", "10");
        write(X"00000004", X"44444444", "00");

        wpo.port_ack <= '1';
        write(X"00000004", X"44444444", "00");
        wait for 4*clk_period;
        wpo.port_ack <= '0';

        write(X"90000000", X"00000000", "00");
        write(X"90000002", X"11111111", "10");
        wait for 2*clk_period;
        write(X"90000000", X"22222222", "10");
        write(X"90000000", X"22222222", "10");
        wpo.port_ack <= '1';
        write(X"90000000", X"22222222", "10");
        wpo.port_ack <= '0';
        write(X"90000000", X"22222222", "10");
        write(X"90000000", X"22222222", "10");
        write(X"90000000", X"22222222", "10");
        wait for 2*clk_period;
        wpo.port_ack <= '1';
        wait for clk_period;
        wpo.port_ack <= '1';
        wait for clk_period;

        halt <= true;
        report "Simulation halted";
        wait;

    end process;

end tb;
