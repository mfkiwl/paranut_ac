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
--  IFU testbench.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.types.all;
use work.memu_lib.all;
use work.ifu.all;

entity mifu_tb is
    end mifu_tb;

architecture tb of mifu_tb is

    signal clk    : std_logic;
    signal reset  : std_logic;
    signal ifui   : ifu_in_type;
    signal ifuo   : ifu_out_type;
    signal rpi    : readport_in_type;
    signal rpo    : readport_out_type;
    signal icache_enable : std_logic;

    constant clk_period : time := 10 ns;

    signal halt: boolean := false;

begin

    uut: mifu
    port map (clk, reset, ifui, ifuo, rpi, rpo, icache_enable);

    clock: process
    begin
        while (not halt) loop
            clk <= '1'; wait for clk_period/2;
            clk <= '0'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    tb: process
    begin

        reset <= '1';
        icache_enable <= '0';
        ifui.nexti <= '0';
        ifui.jump <= '0';
        wait for 5*clk_period;

        reset <= '0';
        ifui.jump <= '1';
        ifui.jump_adr <= X"00001000";
        wait for clk_period;

        ifui.jump <= '0';
        rpo.port_ack <= '1';
        wait for clk_period;
        rpo.port_data <= X"99234567";
        rpo.port_ack <= '0';
        wait for 3*clk_period;

        rpo.port_ack <= '1';
        wait for clk_period;
        rpo.port_data <= X"99456789";
        rpo.port_ack <= '0';
        wait for clk_period;

        ifui.nexti <= '1';
        wait for clk_period;
        ifui.nexti <= '0';
        wait for clk_period;

        ifui.nexti <= '1';
        wait for clk_period;
        ifui.nexti <= '0';
        wait for clk_period;

        wait for 10*clk_period;

        rpo.port_ack <= '1';
        wait for clk_period;
        rpo.port_data <= X"996789ab";
        wait for clk_period;
        rpo.port_data <= X"9989abcd";
        rpo.port_ack <= '0';
        wait for clk_period;
        rpo.port_ack <= '1';
        wait for clk_period;
        rpo.port_data <= X"99abcdef";
        rpo.port_ack <= '0';
        wait for 3*clk_period;
        ifui.nexti <= '1';
        wait for 1*clk_period;
        ifui.nexti <= '0';
        wait for clk_period;

        ifui.jump <= '1';
        ifui.jump_adr <= X"11111100";
        wait for clk_period;

        ifui.nexti <= '1';
        ifui.jump <= '0';
        wait for 1*clk_period;
        ifui.nexti <= '1';
        wait for 1*clk_period;
        ifui.nexti <= '1';
        wait for 1*clk_period;
        ifui.nexti <= '1';
        wait for 1*clk_period;

        ifui.nexti <= '0';
        wait for 5*clk_period;

        halt <= true;
        report "Simulation halted";
        wait;

    end process;


end tb;
