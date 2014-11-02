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
--  Global type definitions for the ParaNut project.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package types is

    subtype THalfWord is std_logic_vector(15 downto 0);
    type THalfWord_Vec is array (natural range <>) of THalfWord;

    subtype TWord is std_logic_vector(31 downto 0);
    type TWord_Vec is array (natural range <>) of TWord;

    subtype TLSUWidth is std_logic_vector(1 downto 0); -- "00" = word, "01" = byte, "10" = half word
    type TLSUWidth_Vec is array (natural range <>) of TLSUWidth;

    subtype TWBufValid is std_logic_vector(3 downto 0);
    type TWBufValid_Vec is array (natural range <>) of TWBufValid;
    subtype TByteSel is std_logic_vector(3 downto 0);
    type TByteSel_Vec is array (natural range <>) of TByteSel;

    type integer_vector is array (natural range <>) of integer;

    type mem_type is array (natural range <>) of std_logic_vector(31 downto 0);

    constant zero64 : std_logic_vector(63 downto 0) := (others => '0');
    constant ones64 : std_logic_vector(63 downto 0) := (others => '1');

end package;
