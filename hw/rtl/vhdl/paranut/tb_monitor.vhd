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
--  Testbench monitor. Useful for simulation only. Provides global
--  synchronisation mechanisms used to control simulation from various parts of
--  the model.
--  Component and type declarations for simulation helpers.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;

library paranut;
use paranut.paranut_config.all;
use paranut.types.all;

package tb_monitor is

    type monitor_type is record
        halted : boolean;
        insn_issued : boolean;
        regfile : TWord_Vec(0 to 31);
        sr : TWord;
    end record;
    type monitor_vector is array (0 to CFG_NUT_CPU_CORES-1) of monitor_type;
    signal monitor : monitor_vector;

    signal sim_halt : boolean;

    shared variable tty : line;

    component orbis32_disas is
        generic (
                    CPU_ID : integer := 0
                );
        port (
                 clk : in std_logic;
                 insn : in TWord;
                 pc : in TWord
             );
    end component;

    component or1ksim_putchar is
        generic (
                    CPU_ID : integer := 0
                );
        port (
                 clk : in std_logic;
                 insn : in TWord
             );
    end component;

    component uart_putchar is
        port (
                 clk : in std_logic;
                 ifinished : in std_logic;
                 data : in std_logic_vector(7 downto 0)
             );
    end component;

end package;
