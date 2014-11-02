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
--  Inferred multiplier module with configurable number of pipeline stages.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_mul_inferred is
    generic (
                AWIDTH      : natural := 32;
                BWIDTH      : natural := 32;
                PIPE_STAGES : natural range 1 to 5 := 3;
                IN_REG      : natural range 0 to 1 := 0
            );
    port (
             clk    : in std_logic;
             a      : in std_logic_vector(AWIDTH-1 downto 0);
             b      : in std_logic_vector(BWIDTH-1 downto 0);
             p      : out std_logic_vector(AWIDTH+BWIDTH-1 downto 0);
             sign   : in std_logic
         );
end gen_mul_inferred;

architecture rtl of gen_mul_inferred is

    type pipe_reg_type is array (0 to PIPE_STAGES-1) of std_logic_vector(AWIDTH+BWIDTH-1 downto 0);
    signal pipe_regs : pipe_reg_type;
    signal mult_res : std_logic_vector(AWIDTH+BWIDTH-1 downto 0);
    signal a_in : std_logic_vector(AWIDTH-1 downto 0);
    signal b_in : std_logic_vector(BWIDTH-1 downto 0);
begin

    in_regs : if (IN_REG = 1) generate
        process (clk)
        begin
            if (clk'event and clk = '1') then
                a_in <= a;
                b_in <= b;
            end if;
        end process;
    end generate;

    no_in_regs : if (IN_REG = 0) generate
        a_in <= a;
        b_in <= b;
    end generate;

    mult_res <= std_logic_vector(unsigned(a_in) * unsigned(b_in)) when (sign = '0') else
                std_logic_vector(signed(a_in) * signed(b_in));

    process (clk)
    begin
        if (clk'event and clk = '1') then
            -- Sadly, the next line does not work with ghdl!
            --pipe_regs <= mult_res & pipe_regs(0 to PIPE_STAGES-2);
            pipe_regs(0) <= mult_res;
        end if;
    end process;

    gen_mul_pipe_stages : for n in 1 to PIPE_STAGES-1 generate
        process (clk)
        begin
            if (clk'event and clk = '1') then
                pipe_regs(n) <= pipe_regs(n-1);
            end if;
        end process;
    end generate;

    p <= pipe_regs(PIPE_STAGES-1);

end rtl;

