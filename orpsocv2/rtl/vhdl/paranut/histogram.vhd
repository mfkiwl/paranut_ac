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
--  Component and type declarations for the mhistogram module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.types.all;

package histogram is

    type hist_ctrl_type is record
        start : std_logic;
        stop  : std_logic;
        abort : std_logic;
    end record;
    type hist_ctrl_vector is array (natural range <>) of hist_ctrl_type;

    type hist_in_type is record
        enable : std_logic;
        ctrl   : hist_ctrl_type;
        addr   : TWord;
    end record;
    type hist_in_vector is array (natural range <>) of hist_in_type;

    type hist_out_type is record
        data : TWord;
    end record;
    type hist_out_vector is array (natural range <>) of hist_out_type;

    component mhistogram is
        generic (
                    HIST_BINS_LD : integer := 6;
                    ADDR_WIDTH : integer := 6
                );
        port (
                 clk : in std_logic;
                 reset : in std_logic;
                 hi : in hist_in_type;
                 ho : out hist_out_type
             );
    end component;

end package;
