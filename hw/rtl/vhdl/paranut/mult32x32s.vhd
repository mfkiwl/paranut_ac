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
--  Multiplier interface module. Includes the multiplier core module.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library paranut;
use paranut.exu.all;
use paranut.mul_tech.all;
use paranut.paranut_lib.all;

entity mult32x32s is
    generic (
                MUL_PIPE_STAGES : integer range 1 to 5 := 2;
                IN_REG : integer range 0 to 1 := 0
            );
    port (
             clk    : in std_logic;
             reset  : in std_logic;
             muli   : in mul_in_type;
             mulo   : out mul_out_type
         );
end mult32x32s;

architecture rtl of mult32x32s is

    type mul_state is (S_MUL_INIT, S_MUL_CNT);

    type registers is record
        state   : mul_state;
        mul_cnt : unsigned(log2x(MUL_PIPE_STAGES+IN_REG+1)-1 downto 0);
    end record;

    signal r, rin : registers;

    signal pout : std_logic_vector(63 downto 0);

begin

    comb : process (reset, r, muli)
        variable v : registers;
        variable rdy : std_logic;
    begin

        v := r;
        rdy := '0';

        case r.state is
            when S_MUL_INIT =>
                if (muli.start = '1') then
                    v.mul_cnt := r.mul_cnt + 1;
                    v.state := S_MUL_CNT;
                end if;
            when S_MUL_CNT =>
                if (r.mul_cnt = MUL_PIPE_STAGES+IN_REG) then
                    rdy := '1';
                    v.mul_cnt := (others => '0');
                    v.state := S_MUL_INIT;
                else
                    v.mul_cnt := r.mul_cnt + 1;
                end if;
            when others =>
        end case;

        if (reset = '1') then
            v.state := S_MUL_INIT;
            v.mul_cnt := (others => '0');
            rdy := '0';
        end if;

        mulo.rdy <= rdy;
        rin <= v;
    end process;

    process (clk)
    begin
        if (clk'event and clk = '1') then
            r <= rin;
        end if;
    end process;

    mulo.p <= pout(31 downto 0);

    mul : gen_mul_inferred
    generic map (AWIDTH => 32, BWIDTH => 32, PIPE_STAGES => MUL_PIPE_STAGES)
    port map (clk => clk, a => muli.a, b => muli.b, p => pout, sign => muli.signed);

end rtl;
