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
--  Component and type declarations for the counter module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package counter_pkg is

    component wb_counter is
        generic (N_COUNTER : integer range 1 to 16 := 1);
        port (
                 -- Ports (WISHBONE slave)
                 wb_clk     : in std_logic;
                 wb_rst     : in std_logic;
                 wb_ack_o   : out std_logic;                    -- normal termination
                 wb_err_o   : out std_logic;                    -- termination w/ error
                 wb_rty_o   : out std_logic;                    -- termination w/ retry
                 wb_dat_i   : in std_logic_vector(31 downto 0); -- input data bus
                 wb_cyc_i   : in std_logic;                     -- cycle valid input
                 wb_stb_i   : in std_logic;                     -- strobe input
                 wb_we_i    : in std_logic;                     -- indicates write transfer
                 wb_sel_i   : in std_logic_vector(3 downto 0);  -- byte select input
                 wb_adr_i   : in std_logic_vector(31 downto 0); -- address bus input
                 wb_dat_o   : out std_logic_vector(31 downto 0) -- data bus output
             );
    end component;

    component counter_top is
        port (
                 clk: in std_logic;
                 reset : in std_logic;
                 enable : in std_logic;
                 cnt_div : in std_logic_vector(31 downto 0);
                 cnt_out : out std_logic_vector(31 downto 0)
             );
    end component;

end package;
