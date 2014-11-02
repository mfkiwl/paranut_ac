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
--  EXU testbench. Executes the program found in prog_mem.vhd that is found in
--  this folder.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.types.all;
use paranut.exu.all;
use paranut.lsu.all;
use paranut.ifu.all;
use paranut.memu_lib.all;
use paranut.tb_monitor.all;

entity mexu_tb is
    generic (MIFU_BS_IMPL : boolean := false);
end mexu_tb;

architecture tb of mexu_tb is

    signal clk           : std_logic;
    signal reset         : std_logic;
    signal ifui          : ifu_in_type;
    signal ifuo          : ifu_out_type;
    signal lsui          : lsu_in_type;
    signal lsuo          : lsu_out_type;
    signal icache_enable : std_logic;
    signal dcache_enable : std_logic;
    signal emhci : exu_memu_hist_ctrl_in_type;

    signal ifurpi : readport_in_type;
    signal ifurpo : readport_out_type;

    signal lsurpi : readport_in_type;
    signal lsurpo : readport_out_type;
    signal lsuwpi : writeport_in_type;
    signal lsuwpo : writeport_out_type;

    constant clk_period : time := 10 ns;

    component rwports_sim is
        port (
                 clk    : in std_logic;
                 reset  : in std_logic;
                 ifurpi : in readport_in_type;
                 ifurpo : out readport_out_type;
                 lsurpi : in readport_in_type;
                 lsurpo : out readport_out_type;
                 lsuwpi : in writeport_in_type;
                 lsuwpo : out writeport_out_type
             );
    end component;

begin

    uut : mexu
    port map (clk, reset, ifui, ifuo, lsui, lsuo, icache_enable, dcache_enable, '0', emhci);

    gen_mifu_bs : if MIFU_BS_IMPL generate
        ifu : mifu_bs
        port map (clk, reset, ifui, ifuo, ifurpi, ifurpo, icache_enable);
    end generate;
    gen_mifu : if not MIFU_BS_IMPL generate
        ifu : mifu
        port map (clk, reset, ifui, ifuo, ifurpi, ifurpo, icache_enable);
    end generate;


    lsu : mlsu
    port map (clk, reset, lsui, lsuo, lsurpi, lsurpo, lsuwpi, lsuwpo, dcache_enable);

    rwps : rwports_sim
    port map (clk, reset, ifurpi, ifurpo, lsurpi, lsurpo, lsuwpi, lsuwpo);

    clock: process
    begin
        while (not sim_halt) loop
            clk <= '1'; wait for clk_period/2;
            clk <= '0'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    tb: process

    begin

        reset <= '1';
        wait for 5*clk_period;

        reset <= '0';
        wait until monitor(0).halted;

        wait for 60*clk_period;

        sim_halt <= true;
        report "Simulation finished";
        wait;

    end process;

end tb;
