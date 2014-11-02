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
--  ORBIS32 disassembly (for debugging purposes only (simulation))
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library paranut;
use paranut.types.all;
use paranut.text_io.all;
use paranut.tb_monitor.all;
use paranut.orbis32.all;

entity orbis32_disas is
    generic (
                CPU_ID : integer := 0
            );
    port (
             clk : in std_logic;
             insn : in TWord;
             pc : in TWord
         );
end orbis32_disas;

architecture tb of orbis32_disas is

    function regs_to_str (r1, r2 : std_logic_vector(4 downto 0)) return string
    is
    begin
        return "r" & to_ud_string(r1) & ", r" & to_ud_string(r2);
    end;

    function regs_to_str (r1, r2, r3 : std_logic_vector(4 downto 0)) return string
    is
    begin
        return "r" & to_ud_string(r1) & ", r" & to_ud_string(r2) & ", r" & to_ud_string(r3);
    end;

    function alui_to_str (op : string; d, a : op2_type; imm : TWord) return string is
    begin
        return op & regs_to_str(d, a) & ", 0x" & to_h_string(imm);
    end;

    function setfi_to_str (op : string; a : op2_type; imm : TWord) return string is
    begin
        return op & " r" & to_ud_string(a) & ", 0x" & to_h_string(imm);
    end;

    function shfti_to_str (op : string; d, a, imm : op2_type) return string is
    begin
        return op & regs_to_str(d, a) & ", " & to_ud_string("000" & imm);
    end;

    function load_to_str (op : string; d : op2_type; imm : TWord; a : op2_type) return string is
    begin
        return op & "r" & to_ud_string(d) & ", 0x" & to_h_string(imm) & "(r" & to_ud_string(a) & ")";
    end;

    function store_to_str (op : string; imm : TWord; a, b : op2_type) return string is
    begin
        return op & "0x" & to_h_string(imm) & "(r" & to_ud_string(a) & "), r" & to_ud_string(b);
    end;

    function pnext_to_str (op : string; imm : TWord; a : op2_type) return string is
    begin
        return op & "0x" & to_h_string(imm) & "(r" & to_ud_string(a) & ")";
    end;

    function insn_disas (insn : std_logic_vector(31 downto 0)) return string
    is
        variable opcode : op1_type;
        variable op2 : op2_type;
        variable bits_10_5 : std_logic_vector(5 downto 0);
        variable bits_9_8 : op5_type;
        variable bits_4_0 : std_logic_vector(4 downto 0);
        variable bits_3_0 : op3_type;
        variable bits_7_6 : op4_type;
        variable a, d, b : std_logic_vector(4 downto 0);
        variable i16z, i16s, i162z, i162s, i26z, i26s : TWord;
    begin
        opcode := insn(31 downto 26);
        op2 := insn(25 downto 21);
        bits_10_5 := insn(10 downto 5);
        bits_9_8 := insn(9 downto 8);
        bits_7_6 := insn(7 downto 6);
        bits_4_0 := insn(4 downto 0);
        bits_3_0 := insn(3 downto 0);

        d := op2;
        a := insn(20 downto 16);
        b := insn(15 downto 11);


        i16z := X"0000" & insn(15 downto 0);
        if (insn(15) = '1') then
            i16s := X"FFFF" & i16z(15 downto 0);
        else
            i16s := i16z;
        end if;
        i162z := X"0000" & insn(25 downto 21) & insn(10 downto 0);
        if (insn(25) = '1') then
            i162s := X"FFFF" & i162z(15 downto 0);
        else
            i162s := i162z;
        end if;
        i26z := X"0" & insn(25 downto 0) & "00";
        if (insn(25) = '1') then
            i26s := X"F" & i26z(27 downto 0);
        else
            i26s := i26z;
        end if;

        case opcode is
            when ALU =>
                case bits_9_8 is
                    when ALUR =>

                        case bits_3_0 is
                            when ADDR =>
                                return "l.add " & regs_to_str(d, a, b);
                            when ADDCR =>
                                return "l.addc " & regs_to_str(d, a, b);
                            when SUBR =>
                                return "l.sub " & regs_to_str(d, a, b);
                            when ANDR =>
                                return "l.and " & regs_to_str(d, a, b);
                            when ORR =>
                                return "l.or " & regs_to_str(d, a, b);
                            when XORR =>
                                return "l.xor " & regs_to_str(d, a, b);
                            when SHIFT =>

                                case bits_7_6 is
                                    when SHLL =>
                                        return "l.sll " & regs_to_str(d, a, b);
                                    when SHRL =>
                                        return "l.srl " & regs_to_str(d, a, b);
                                    when SHRA =>
                                        return "l.sra " & regs_to_str(d, a, b);
                                    when SROR =>
                                        return "l.ror " & regs_to_str(d, a, b);
                                    when others =>
                                end case;

                            when EXT =>

                                case bits_7_6 is
                                    when SHLL =>
                                        return "l.exths_ " & regs_to_str(d, a);
                                    when SHRL =>
                                        return "l.extbs_ " & regs_to_str(d, a);
                                    when SHRA =>
                                        return "l.exthz_ " & regs_to_str(d, a);
                                    when SROR =>
                                        return "l.extbz_ " & regs_to_str(d, a);
                                    when others =>
                                end case;

                            when CMOV =>
                                return "l.cmov " & regs_to_str(d, a, b);
                            when others =>
                        end case;

                    when MULX =>

                        case bits_3_0 is
                            when MUL =>
                                return "l.mul " & regs_to_str(d, a, b);
                            when DIV =>
                                return "l.div_ " & regs_to_str(d, a, b);
                            when DIVU =>
                                return "l.divu_ " & regs_to_str(d, a, b);
                            when MULU =>
                                return "l.mulu " & regs_to_str(d, a, b);
                            when others =>
                        end case;

                    when others =>
                end case;

                case bits_7_6 is
                    --TODO
                    when others =>
                end case;

            when SETF =>
                case op2 is
                    when SFEQ =>
                        return "l.sfeq " & regs_to_str(a, b);
                    when SFNE =>
                        return "l.sfne " & regs_to_str(a, b);
                    when SFGTU =>
                        return "l.sfgtu " & regs_to_str(a, b);
                    when SFGEU =>
                        return "l.sfgeu " & regs_to_str(a, b);
                    when SFLTU =>
                        return "l.sfltu " & regs_to_str(a, b);
                    when SFLEU =>
                        return "l.sfleu " & regs_to_str(a, b);
                    when SFGTS =>
                        return "l.sfgts " & regs_to_str(a, b);
                    when SFGES =>
                        return "l.sfges " & regs_to_str(a, b);
                    when SFLTS =>
                        return "l.sflts " & regs_to_str(a, b);
                    when SFLES =>
                        return "l.sfles " & regs_to_str(a, b);
                    when others =>
                end case;

            when ADDI =>
                return alui_to_str("l.addi ", d, a, i16s);
            when ADDIC =>
                return alui_to_str("l.addic ", d, a, i16s);
            when ANDI =>
                return alui_to_str("l.andi ", d, a, i16z);
            when ORI =>
                return alui_to_str("l.ori ", d, a, i16z);
            when XORI =>
                return alui_to_str("l.xori ", d, a, i16s);
            when MULI =>
                return alui_to_str("l.muli ", d, a, i16s);
            when SETFI =>
                case op2 is
                    when SFEQ =>
                        return setfi_to_str("l.sfeqi ", a, i16s);
                    when SFNE =>
                        return setfi_to_str("l.sfnei ", a, i16s);
                    when SFGTU =>
                        return setfi_to_str("l.sfgtu ", a, i16z);
                    when SFGEU =>
                        return setfi_to_str("l.sfgeu ", a, i16z);
                    when SFLTU =>
                        return setfi_to_str("l.sfltu ", a, i16z);
                    when SFLEU =>
                        return setfi_to_str("l.sfleu ", a, i16z);
                    when SFGTS =>
                        return setfi_to_str("l.sfgts ", a, i16s);
                    when SFGES =>
                        return setfi_to_str("l.sfges ", a, i16s);
                    when SFLTS =>
                        return setfi_to_str("l.sflts ", a, i16s);
                    when SFLES =>
                        return setfi_to_str("l.sfles ", a, i16s);
                    when others =>
                end case;

            when SRLI =>
                case bits_7_6 is
                    when SHLL =>
                        return shfti_to_str("l.slli ", d, a, bits_4_0);
                    when SHRL =>
                        return shfti_to_str("l.srli ", d, a, bits_4_0);
                    when SHRA =>
                        return shfti_to_str("l.srai ", d, a, bits_4_0);
                    when SROR =>
                        return shfti_to_str("l.rori ", d, a, bits_4_0);
                    when others =>
                end case;

            when MOVHI =>
                return "l.movhi r" & to_ud_string(d) & ", 0x" & to_h_string(i16z);

            -- L/S
            when LWZ =>
                return load_to_str("l.lwz ", d, i16s, a);
            when LWS =>
                return load_to_str("l.lws ", d, i16s, a);
            when LBZ =>
                return load_to_str("l.lbz ", d, i16s, a);
            when LBS =>
                return load_to_str("l.lbs ", d, i16s, a);
            when LHZ =>
                return load_to_str("l.lhz ", d, i16s, a);
            when LHS =>
                return load_to_str("l.lhs ", d, i16s, a);

            when SW =>
                return store_to_str("l.sw ", i162s, a, b);
            when SB =>
                return store_to_str("l.sb ", i162s, a, b);
            when SH =>
                return store_to_str("l.sh ", i162s, a, b);

            -- Jumps
            when J =>
                return "l.j " & to_sd_string(i26s);
            when JAL =>
                return "l.jal " & to_sd_string(i26s);
            when BNF =>
                return "l.bnf " & to_sd_string(i26s);
            when BF =>
                return "l.bf " & to_sd_string(i26s);
            when NOP =>
                case op2 is
                    when TRAP =>
                        return "l.nop " & to_h_string(i16z);
                    when others =>
                end case;
            when JR =>
                return "l.jr r" & to_ud_string(b);
            when JALR =>
                return "l.jalr r" & to_ud_string(b);
            when RFE =>
                return "l.rfe";

            -- Other
            when MFSPR =>
                return "l.mfspr " & regs_to_str(d, a) & ", " & to_h_string(i16z);
            when MTSPR =>
                return "l.mtspr " & regs_to_str(a, b) & ", " & to_h_string(i162z);
            when OTHER =>
                case op2 is
                    when SYS =>
                        return "l.sys";
                    when TRAP =>
                        return "l.trap_";
                    when MSYNC =>
                        return "l.msync_";
                    when PSYNC =>
                        return "l.psync_";
                    when CSYNC =>
                        return "l.csync_";
                    when others =>
                end case;
            -- ParaNut extensions...
            when CUST7 =>
                case b is
                    when "00001" =>
                        return pnext_to_str("pn.cwriteback ", i162s, a);
                    when "00010" =>
                        return pnext_to_str("pn.cinvalidate ", i162s, a);
                    when "00011" =>
                        return pnext_to_str("pn.cflush ", i162s, a);
                    when others =>
                end case;
            when CUST1 =>
                return "l.cust1 0x" & to_h_string(i26z);
            when CUST2 =>
                return "l.cust2 0x" & to_h_string(i26z);
            when CUST3 =>
                return "l.cust3 0x" & to_h_string(i26z);
            when CUST4 =>
                return "l.cust4 0x" & to_h_string(i26z);
            when CUST5 =>
                return "l.cust5 " & to_ud_string(d) & ", " & to_ud_string(a)
                & ", " & to_ud_string(b) & ", " & to_ud_string(bits_10_5) & ", " &
                to_ud_string(bits_4_0);
            when CUST6 =>
                return "l.cust6 0x" & to_h_string(i26z);
            when CUST8 =>
                return "l.cust8 0x" & to_h_string(i26z);

            when others =>
                return "? " & to_h_string(insn);
        end case;
        return "";

    end;

    function flags_to_str(sr : std_logic_vector(31 downto 0)) return string is
    begin
        return "F=" & to_b_string(sr(9 downto 9)) &
        " C=" & to_b_string(sr(10 downto 10)) &
        " O=" & to_b_string(sr(11 downto 11));
    end;

    procedure print_regfile (a, b : integer range 0 to 31) is
        variable l : line;
    begin
        for i in a to b loop
            if (i mod 8 = 0) then
                write(l, now);
                write(l, string'(": EXU("));
                write(l, CPU_ID);
                write(l, string'(") "));
            end if;
            if (i = 0) then
                write(l, flags_to_str(monitor(CPU_ID).sr), right, 13);
            else
                write(l, string'(" R" & integer'image(i) & "="), right, 5);
                write(l, to_h_string(monitor(CPU_ID).regfile(i)));
            end if;
            if (i mod 8 = 7) then
                writeline(OUTPUT, l);
            end if;
        end loop;
    end procedure;

    procedure print_insn (pc, insn : std_logic_vector(31 downto 0)) is
        variable l : line;
    begin
        writeline(OUTPUT, l);
        write(l, now);
        write(l, string'(": EXU("));
        write(l, CPU_ID);
        write(l, string'(") "));
        --write(l, flags_to_str(monitor(CPU_ID).sr), right, 13);
        --write(l, string'(" PC=" & to_h_string(pc)), right, 13);
        --write(l, string'(" IR=" & to_h_string(insn)), right, 13);
        --write(l, string'(", " & insn_disas(insn)));
        write(l, string'(to_h_string(pc)), right, 22);
        write(l, string'(": " & to_h_string(insn)));
        write(l, string'(", " & insn_disas(insn)));
        writeline(OUTPUT, l);
    end procedure;

begin

    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (monitor(CPU_ID).insn_issued) then
                print_regfile(0, monitor(CPU_ID).regfile'length-1);
                print_insn(pc, insn);
            end if;
        end if;
    end process;

end tb;

--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library paranut;
use paranut.types.all;
use paranut.text_io.all;
use paranut.tb_monitor.all;
use paranut.orbis32.all;
use paranut.paranut_lib.all;

entity or1ksim_putchar is
    generic (
                CPU_ID : integer := 0
            );
    port (
             clk : in std_logic;
             insn : in TWord
         );
end or1ksim_putchar;

architecture tb of or1ksim_putchar is
begin
    process
        variable do_print : boolean := false;
    begin
        while not sim_halt loop
            wait until clk = '1';
            if (do_print) then
                put_char(tty, slv2ascii(monitor(CPU_ID).regfile(3)));
                do_print := false;
            end if;
            if (insn(31 downto 26) = NOP and insn(15 downto 0) = X"0004" and monitor(CPU_ID).insn_issued) then
                do_print := true;
            end if;
        end loop;
        wait;
    end process;
end tb;

--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library paranut;
use paranut.types.all;
use paranut.text_io.all;
use paranut.tb_monitor.all;
use paranut.orbis32.all;
use paranut.paranut_lib.all;

entity uart_putchar is
    port (
             clk : in std_logic;
             ifinished : in std_logic;
             data : in std_logic_vector(7 downto 0)
         );
end uart_putchar;

architecture tb of uart_putchar is
begin
    process
    begin
        while not sim_halt loop
            wait until clk = '1';
            if (ifinished = '1') then
                put_char(tty, slv2ascii(data));
            end if;
        end loop;
        wait;
    end process;
end tb;

