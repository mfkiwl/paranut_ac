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
--  Shift implementation. Currently, there are 3 different implementations.
--   - serial shifter (needs 1 clock cycle per 1 shift distance!)
--   - generic shifter (1 clock cycle shift for all shifts)
--   - barrell shifter (1 clock cycle shift for all shifts)
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library paranut;
use paranut.exu.all;
use paranut.paranut_lib.all;

entity shift32 is
    generic (
                SHIFT_IMPL : integer range 0 to 2 := 0 -- 0 : serial shifter, 1 : generic implementation, 2 : barrell shifter
            );
    port (
             clk    : in std_logic;
             reset  : in std_logic;
             shfti  : in shift_in_type;
             shfto  : out shift_out_type
         );
end shift32;

architecture rtl of shift32 is

    -- generic shift implementation with 1 shift per clock
    function shift_generic(shiftin : std_logic_vector(31 downto 0); shift_cnt : std_logic_vector(4 downto 0); mode : std_logic_vector(1 downto 0))
    return std_logic_vector is
        variable n : natural;
        variable result : std_logic_vector(31 downto 0);
    begin
        n := conv_integer(shift_cnt);
        case mode is
            when "00" => -- sll
                result := std_logic_vector(SHIFT_LEFT(unsigned(shiftin), n));
            when "01" => -- srl
                result := std_logic_vector(SHIFT_RIGHT(unsigned(shiftin), n));
            when "10" => -- sra
                result := std_logic_vector(SHIFT_RIGHT(signed(shiftin), n));
            when "11" => -- ror
                result := std_logic_vector(SHIFT_RIGHT(unsigned(shiftin), n));
                result(31 downto 32-n) := shiftin(n-1 downto 0);
            when others => null;
        end case;
        return (result);
    end;

    -- barrell shifter
    function shift_barrell(shiftin : std_logic_vector(31 downto 0); shift_cnt : std_logic_vector(4 downto 0); mode : std_logic_vector(1 downto 0))
    return std_logic_vector is
        variable sign : std_logic;
        variable cnt : std_logic_vector(4 downto 0);
        variable upper : std_logic_vector(31 downto 0);
        variable lower : std_logic_vector(31 downto 0);
        variable result : std_logic_vector(63 downto 0);
    begin
        sign := mode(1) and shiftin(31);
        cnt := shift_cnt;
        upper := (others => sign); 
        lower := shiftin;
        if (mode = "00") then -- sll
            upper := '0' & shiftin(31 downto 1);
            lower := (31 => shiftin(0), others => '0');
            cnt := not shift_cnt;
        elsif (mode = "11") then -- ror
            upper := shiftin;
        end if;
        result := upper & lower;
        if (cnt(4) = '1') then result(47 downto 0) := result(63 downto 16); end if;
        if (cnt(3) = '1') then result(39 downto 0) := result(47 downto 8); end if;
        if (cnt(2) = '1') then result(35 downto 0) := result(39 downto 4); end if;
        if (cnt(1) = '1') then result(33 downto 0) := result(35 downto 2); end if;
        if (cnt(0) = '1') then result(31 downto 0) := result(32 downto 1); end if;
        return result(31 downto 0);
    end;

    type shft_state is (S_SHIFT_INIT, S_SHIFT_CNT);

    type registers is record
        state   : shft_state;
        shft_cnt : unsigned(4 downto 0);
        shft_val : std_logic_vector(31 downto 0);
    end record;

    signal r, rin : registers;

begin

    comb : process (reset, r, shfti)
        variable v : registers;
        variable rdy : std_logic;
        variable sout : std_logic_vector(31 downto 0);

    begin

        if (SHIFT_IMPL = 0) then
            v := r;
            rdy := '0';
            case r.state is
                when S_SHIFT_INIT =>
                    if (shfti.start = '1') then
                        v.shft_val := shfti.value;
                        v.state := S_SHIFT_CNT;
                    end if;
                when S_SHIFT_CNT =>
                    if (r.shft_cnt = unsigned(shfti.cnt)) then
                        rdy := '1';
                        v.shft_cnt := (others => '0');
                        v.state := S_SHIFT_INIT;
                    else
                        v.shft_val := shift_generic(r.shft_val, "00001", shfti.mode);
                        v.shft_cnt := r.shft_cnt + 1;
                    end if;
                when others =>
            end case;

            if (reset = '1') then
                v.state := S_SHIFT_INIT;
                v.shft_cnt := (others => '0');
                rdy := '0';
            end if;
        else
            rdy := '1';
        end if;

        if (SHIFT_IMPL = 0) then
            sout := r.shft_val;
            rin <= v;
        elsif (SHIFT_IMPL = 1) then
            sout := shift_generic(shfti.value, shfti.cnt, shfti.mode);
        else
            sout := shift_barrell(shfti.value, shfti.cnt, shfti.mode);
        end if;

        shfto.rdy <= rdy;
        shfto.dout <= sout;

    end process;

    clk_proc_gen : if (SHIFT_IMPL = 0) generate
        clk_prc : process (clk)
        begin
            if (clk'event and clk = '1') then
                r <= rin;
            end if;
        end process;
    end generate;

end rtl;
