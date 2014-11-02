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
--  Counter implementation
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_top is
    port (
             clk: in std_logic;
             reset : in std_logic;
             enable : in std_logic;
             cnt_div : in std_logic_vector(31 downto 0);
             cnt_out : out std_logic_vector(31 downto 0)
         );
end counter_top;

architecture rtl of counter_top is
    type registers is record
        count   : unsigned(31 downto 0);
        div     : unsigned(31 downto 0);
    end record;
    signal r, rin : registers;
begin
    comb : process (r, reset, enable, cnt_div)
        variable v : registers;
    begin
        v := r;
        if (reset = '1') then
            v.count := (others => '0');
            v.div := (others => '0');
        elsif enable = '1' then
            if (r.div <= 1) then
                v.count := r.count + 1;
                v.div := unsigned(cnt_div);
            else
                v.div := r.div - 1;
            end if;
        end if;
        cnt_out <= std_logic_vector(r.count);
        rin <= v;
    end process;

    process (clk)
    begin
        if (clk'event and clk = '1') then
            r <= rin;
        end if;
    end process;

end architecture rtl;

