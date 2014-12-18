--------------------------------------------------------------------------------
-- This file is part of the ParaNut project.
-- 
-- Copyright (C) 2014  Michael Seider, Hochschule Augsburg
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
--  ParaNut testbench. Executes the program found in prog_mem.vhd that is found in
--  this folder.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.paranut_pkg.all;
use paranut.paranut_config.all;
use paranut.types.all;
use paranut.peripherals.all;
use paranut.prog_mem.all;
use paranut.tb_monitor.all;

entity mparanut_tb is
    end mparanut_tb;

architecture tb of mparanut_tb is

    constant MEM_WB_SLV_ADDR : natural := 16#00#;
    constant UART_WB_SLV_ADDR : natural := 16#90#;
    constant COUNTER_WB_SLV_ADDR : natural := 16#F0#;

    signal clk : std_logic;
    signal reset : std_logic;
    signal wb_ack : std_logic;
    signal wb_err : std_logic;
    signal wb_rty : std_logic;
    signal wb_cyc : std_logic;
    signal wb_stb : std_logic;
    signal wb_we : std_logic;
    signal wb_sel : TByteSel;
    signal wb_adr : TWord;
    signal wb_dat_r : TWord;
    signal wb_dat_w : TWord;
    signal wb_cti : std_logic_vector(2 downto 0);
    signal wb_bte : std_logic_vector(1 downto 0);

    constant clk_period : time := 10 ns;

begin

    nut : mparanut
    --generic map (1, 1)
    port map (clk, reset, wb_ack, wb_err, wb_rty, wb_dat_r, wb_cyc, wb_stb, wb_we, wb_sel, wb_adr,
    wb_dat_w, wb_cti, wb_bte, '0');

    memory : wb_memory
    generic map (WB_SLV_ADDR => MEM_WB_SLV_ADDR, PROG_DATA => prog_data)
    port map (clk, reset, wb_stb, wb_cyc, wb_we, wb_sel, wb_ack, wb_err, wb_rty,
    wb_adr, wb_dat_w, wb_dat_r, wb_cti, wb_bte);

    uart : wb_uart
    generic map (WB_SLV_ADDR => UART_WB_SLV_ADDR)
    port map (clk, reset, wb_stb, wb_cyc, wb_we, wb_sel, wb_ack, wb_err, wb_rty,
    wb_adr, wb_dat_w, wb_dat_r);

    counter : wb_counter_wrapper
    generic map (WB_SLV_ADDR => COUNTER_WB_SLV_ADDR, N_COUNTER => 1)
    port map (clk, reset, wb_stb, wb_cyc, wb_we, wb_sel, wb_ack, wb_err, wb_rty,
    wb_adr, wb_dat_w, wb_dat_r);

    clk_gen : process
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

        for i in 0 to CFG_NUT_CPU_CORES-1 loop
            if not monitor(i).halted then
                wait until monitor(i).halted;
            end if;
        end loop;

        wait for 60*clk_period;

        sim_halt <= true;
        assert false report "Simulation finished" severity note;
        wait;

    end process;


end tb;
