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
--  ORBIS32 instruction set.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package orbis32 is

    -- OP1 (instruction (31 downto 26))
    subtype op1_type is std_logic_vector(5 downto 0);

    constant J      : op1_type := "000000";
    constant JAL    : op1_type := "000001";
    constant BNF    : op1_type := "000011";
    constant BF     : op1_type := "000100";
    constant NOP    : op1_type := "000101";
    constant MOVHI  : op1_type := "000110";
    constant OTHER  : op1_type := "001000";
    constant RFE    : op1_type := "001001";
    constant JR     : op1_type := "010001";
    constant JALR   : op1_type := "010010";

    constant MFSPR  : op1_type := "101101";
    constant MTSPR  : op1_type := "110000";

    constant LWZ    : op1_type := "100001";
    constant LWS    : op1_type := "100010";
    constant LBZ    : op1_type := "100011";
    constant LBS    : op1_type := "100100";
    constant LHZ    : op1_type := "100101";
    constant LHS    : op1_type := "100110";

    constant SW     : op1_type := "110101";
    constant SB     : op1_type := "110110";
    constant SH     : op1_type := "110111";

    constant ADDI   : op1_type := "100111";
    constant ADDIC  : op1_type := "101000";
    constant ANDI   : op1_type := "101001";
    constant ORI    : op1_type := "101010";
    constant XORI   : op1_type := "101011";
    constant MULI   : op1_type := "101100";
    constant SRLI   : op1_type := "101110";
    constant SETFI  : op1_type := "101111";
    constant ALU    : op1_type := "111000";
    constant SETF   : op1_type := "111001";

    constant CUST1  : op1_type := "011100";
    constant CUST2  : op1_type := "011101";
    constant CUST3  : op1_type := "011110";
    constant CUST4  : op1_type := "011111";
    constant CUST5  : op1_type := "111100";
    constant CUST6  : op1_type := "111101";
    constant CUST7  : op1_type := "111110";
    constant CUST8  : op1_type := "111111";

    -- OP2 (instruction (25 downto 21))
    subtype op2_type is std_logic_vector(4 downto 0);

    constant SYS    : op2_type := "00000";
    constant TRAP   : op2_type := "01000";

    constant MSYNC  : op2_type := "10000";
    constant PSYNC  : op2_type := "10100";
    constant CSYNC  : op2_type := "11000";

    constant SFEQ   : op2_type := "00000";
    constant SFNE   : op2_type := "00001";
    constant SFGTU  : op2_type := "00010";
    constant SFGEU  : op2_type := "00011";
    constant SFLTU  : op2_type := "00100";
    constant SFLEU  : op2_type := "00101";
    constant SFGTS  : op2_type := "01010";
    constant SFGES  : op2_type := "01011";
    constant SFLTS  : op2_type := "01100";
    constant SFLES  : op2_type := "01101";

    -- OP3 (instruction (3 downto 0))
    subtype op3_type is std_logic_vector(3 downto 0);

    constant ADDR    : op3_type := "0000";
    constant ADDCR   : op3_type := "0001";
    constant SUBR    : op3_type := "0010";
    constant ANDR    : op3_type := "0011";
    constant ORR     : op3_type := "0100";
    constant XORR    : op3_type := "0101";
    constant MUL     : op3_type := "0110";
    constant SHIFT   : op3_type := "1000";
    constant DIV     : op3_type := "1001";
    constant DIVU    : op3_type := "1010";
    constant MULU    : op3_type := "1011";
    constant EXT     : op3_type := "1100";
    constant CMOV    : op3_type := "1110";

    -- OP4 (instruction (7 downto 6))
    subtype op4_type is std_logic_vector(1 downto 0);

    constant SHLL   : op4_type := "00";
    constant SHRL   : op4_type := "01";
    constant SHRA   : op4_type := "10";
    constant SROR   : op4_type := "11";

    -- OP5 (instruction (9 downto 8))
    subtype op5_type is std_logic_vector(1 downto 0);

    constant ALUR   : op5_type := "00";
    constant MULX   : op5_type := "11";

end package;
