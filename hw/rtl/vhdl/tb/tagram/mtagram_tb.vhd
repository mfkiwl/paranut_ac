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
--  TagRAM testbench.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.paranut_config.all;
use paranut.memu_lib.all;
use paranut.paranut_lib.all;
use paranut.text_io.all;

entity mtagram_tb is
    end mtagram_tb;

architecture tb of mtagram_tb is

             signal clk    : std_logic;
             signal reset  : std_logic;

             signal tri   : tagram_in_type;
             signal tro   : tagram_out_type;

    constant clk_period : time := 10 ns;

    signal halt: boolean := false;

begin

    uut : mtagram
    port map (clk, reset, tri, tro);

    clock : process
    begin
        while (not halt) loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    tb : process

        procedure read_tag (prt : in natural; addr : in std_logic_vector(31 downto 0)) is
        begin
            tri.rd(prt) <= '1';
            tri.addr(prt) <= addr;
            wait for clk_period;
            tri.rd(prt) <= '0';
        end procedure;

        procedure write_tag (prt : in natural; addr : in std_logic_vector(31
        downto 0); way : in std_logic_vector(1 downto 0); valid, dirty : in
        std_logic) is
        begin
            tri.wr(prt) <= '1';
            tri.addr(prt) <= addr;
            tri.tag_in(prt).valid <= valid;
            tri.tag_in(prt).dirty <= dirty;
            --report "tag: " & to_h_string(addr(TAG_OF_ADDR_RANGE));
            tri.tag_in(prt).taddr <= addr(TAG_OF_ADDR_RANGE);
            tri.tag_in(prt).way <= way(tri.tag_in(prt).way'range);
            wait for clk_period;
            tri.wr(prt) <= '0';
        end procedure;
    begin

        reset <= '1';
        for i in 0 to CFG_NUT_CPU_CORES-1 loop
            tri.addr(i) <= (others => '1');
        end loop;
        wait for clk_period/2;
        wait for clk_period/8;

        reset <= '0';
        wait for clk_period;

        write_tag(0, X"ffff0000", "00", '1', '0');
        write_tag(0, X"ffff2000", "01", '1', '0');
        write_tag(0, X"ffff4000", "11", '1', '0');
        write_tag(0, X"ffff8000", "10", '1', '0');
        --write_tag(1, X"ffffe000", "10");

        read_tag(0, X"ffff0000");

        write_tag(0, X"ffff0000", "00", '1', '1');

        read_tag(0, X"ffff0000");
        read_tag(0, X"ffff0000");
        read_tag(0, X"ffff0000");
        read_tag(0, X"ffff0000");

        write_tag(0, X"ffff0000", "00", '0', '0');
        write_tag(0, X"ffff0000", "00", '0', '1');
        write_tag(0, X"ffff0000", "00", '1', '0');
        write_tag(0, X"ffff0000", "00", '1', '1');

        read_tag(0, X"ffff0000");
        read_tag(0, X"ffff2000");
        read_tag(0, X"ffff4000");
        read_tag(0, X"ffff8000");

        read_tag(0, X"fff00000");
        read_tag(0, X"fff02000");
        read_tag(0, X"ffff4000");
        read_tag(0, X"fff08000");

        --tri.rd(0) <= '0';
        --tri.addr(0) <= X"000043e0";
        --wait for clk_period;

        --tri.rd(0) <= '1';
        --wait for 2*clk_period;

        --tri.rd(0) <= '0';
        --wait for 1*clk_period;
        --tri.rd(0) <= '0';

        wait for 7*clk_period;

        halt <= true;
        report "Simulation halted";
        wait;

    end process;

end tb;
