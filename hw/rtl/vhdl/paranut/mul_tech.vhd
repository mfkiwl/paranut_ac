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
--  Component and type declarations for the mul_inferred module.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package mul_tech is
    component gen_mul_inferred is
        generic (
                    AWIDTH : integer := 32;
                    BWIDTH : integer := 32;
                    PIPE_STAGES : integer := 3;
                    IN_REG : integer range 0 to 1 := 0
                );
        port (
                 clk    : in std_logic;
                 a      : in std_logic_vector(AWIDTH-1 downto 0);
                 b      : in std_logic_vector(BWIDTH-1 downto 0);
                 p      : out std_logic_vector(AWIDTH+BWIDTH-1 downto 0);
                 sign   : in std_logic
             );
    end component;

end package;
