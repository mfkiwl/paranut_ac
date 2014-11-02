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
--  Instruction fetch buffer module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library paranut;
use paranut.paranut_config.all;
use paranut.ifu.all;
use paranut.types.all;
use paranut.memu_lib.all;
use paranut.paranut_lib.all;
use paranut.orbis32.all;

entity mifu is
    generic (
                IFU_BUF_SIZE_MIN : integer range 4 to 16 := 4
            );
    port (
             clk            : in std_logic;
             reset          : in std_logic;
             -- to EXU...
             ifui           : in ifu_in_type;
             ifuo           : out ifu_out_type;
             -- to MEMU (read port)...
             rpi            : out readport_in_type;
             rpo            : in readport_out_type;
             -- from CePU...
             icache_enable  : in std_logic
         );
end mifu;

architecture rtl of mifu is

    constant IFU_BUF_SIZE_LD : integer := log2x(IFU_BUF_SIZE_MIN);
    constant IFU_BUF_SIZE : integer := 2**IFU_BUF_SIZE_LD;

    constant RESET_ADDRESS : integer := 16#100#;

    type registers is record
        insn_buf      : TWord_Vec(0 to IFU_BUF_SIZE-1);
        adr_buf       : TWord_Vec(0 to IFU_BUF_SIZE-1);
        insn_top      : unsigned(IFU_BUF_SIZE_LD downto 0); -- 'insn_top': first buffer place with not-yet-known contents (insn)
        adr_top       : unsigned(IFU_BUF_SIZE_LD downto 0); -- 'adr_top': first buffer place with not-yet-known adress
        last_rp_ack   : std_logic;
        rp_rd         : std_logic;
        rp_adr        : TWord;
        buf_fill_hist : TWord_Vec(0 to IFU_BUF_SIZE+1);
    end record;

    function is_jump (insn : TWord)
    return boolean is
        variable opcode : std_logic_vector(5 downto 0);
    begin
        opcode := insn(31 downto 26);
        case opcode is
            when J | JAL | BNF | BF | JR | JALR | OTHER | RFE =>
                return true;
            when others =>
                return false;
        end case;
    end;

    signal r, rin: registers;

begin

    comb : process(reset, r, rpo, ifui)

        variable v : registers;
        variable vrpi : readport_in_type;
        variable add : integer range 0 to 1;
        variable next_insn_top : unsigned(IFU_BUF_SIZE_LD downto 0);
        variable next_insn_top_ofs : unsigned(IFU_BUF_SIZE_LD downto 0);
        variable next_insn_top_ofs_jmp : unsigned(IFU_BUF_SIZE_LD downto 0);

    begin

        v := r;

        if (CFG_NUT_HISTOGRAM) then
            ifuo.buf_fill_hist <= r.buf_fill_hist;
        end if;
        ifuo.hist_ctrl.start <= '0';
        ifuo.hist_ctrl.stop <= '0';
        ifuo.hist_ctrl.abort <= '0';

        -- Shift buffer if 'next' is asserted...
        if (ifui.nexti = '1') then
            v.insn_buf(0 to IFU_BUF_SIZE-2) := r.insn_buf(1 to IFU_BUF_SIZE-1);
            v.adr_buf(0 to IFU_BUF_SIZE-2) := r.adr_buf(1 to IFU_BUF_SIZE-1);
            if (r.insn_top > 0) then v.insn_top := r.insn_top - 1; end if;
            if (r.adr_top > 0) then v.adr_top := r.adr_top - 1; end if;
        end if;

        -- Generate new address...
        if (v.adr_top(IFU_BUF_SIZE_LD) = '0') then
            add := conv_integer(not ifui.nexti);
            v.adr_buf(conv_integer(v.adr_top(IFU_BUF_SIZE_LD-1 downto 0))) :=
            r.adr_buf(conv_integer(v.adr_top(IFU_BUF_SIZE_LD-1 downto 0)) - add) + 4;
            v.adr_top := v.adr_top + 1;
        end if;

        -- Handle jump...
        if (ifui.jump = '1') then
            -- pragma translate_off
            assert (ifui.jump_adr(1 downto 0) = "00") report "jump_adr % 4 != 0";
            -- pragma translate_on
            if (v.insn_top > 2) then v.insn_top := to_unsigned(2, IFU_BUF_SIZE_LD+1); end if;
            v.adr_buf(2) := ifui.jump_adr;
            v.adr_top := to_unsigned(3, IFU_BUF_SIZE_LD+1);
        end if;

        -- Store new memory data if available...
        v.last_rp_ack := rpo.port_ack;
        if (r.last_rp_ack = '1') then
            -- pragma translate_off
            assert (v.insn_top(IFU_BUF_SIZE_LD) = '0') report "insn_top >= IFU_BUF_SIZE";
            -- pragma translate_on
            v.insn_buf(conv_integer(v.insn_top(IFU_BUF_SIZE_LD-1 downto 0))) := rpo.port_data;
            if (CFG_NUT_HISTOGRAM) then
                if (ifui.hist_enable = '1') then
                    v.buf_fill_hist(conv_integer(v.insn_top(IFU_BUF_SIZE_LD-1 downto 0))) :=
                    r.buf_fill_hist(conv_integer(v.insn_top(IFU_BUF_SIZE_LD-1 downto 0))) + 1;
                end if;
            end if;
            v.insn_top := v.insn_top + 1;
        end if;

        -- Issue new memory read request if appropriate...
        v.rp_rd := '0'; -- default
        next_insn_top := v.insn_top + conv_integer(rpo.port_ack);
        next_insn_top_ofs := next_insn_top + conv_integer(ifui.nexti);
        next_insn_top_ofs_jmp := next_insn_top_ofs - 2;
        if (v.adr_top > next_insn_top and next_insn_top_ofs(IFU_BUF_SIZE_LD) = '0'
            and not (next_insn_top >= 2 and
            (is_jump(r.insn_buf(conv_integer(next_insn_top_ofs_jmp(IFU_BUF_SIZE_LD-1 downto 0))))
            or (r.last_rp_ack = '1' and next_insn_top_ofs_jmp = r.insn_top)))) then
            v.rp_rd := '1';
            v.rp_adr := r.adr_buf(conv_integer(next_insn_top_ofs(IFU_BUF_SIZE_LD-1 downto 0)));
        end if;

        if (reset = '1') then
            v.insn_top := to_unsigned(1, IFU_BUF_SIZE_LD+1);
            v.adr_top := to_unsigned(1, IFU_BUF_SIZE_LD+1);
            v.adr_buf(0) := conv_std_logic_vector(RESET_ADDRESS - 4, TWord'length);
            v.last_rp_ack := '0';
            v.rp_rd := '0';
            if (CFG_NUT_HISTOGRAM) then
                v.buf_fill_hist := (others => (others => '0'));
            end if;
        end if;

        -- outputs

        ifuo.ir <= r.insn_buf(1);
        ifuo.ppc <= r.adr_buf(0);
        ifuo.pc <= r.adr_buf(1);
        ifuo.npc <= r.adr_buf(2);
        ifuo.ir_valid <= conv_std_logic(r.insn_top > 1);
        ifuo.npc_valid <= conv_std_logic(r.adr_top > 2);

        vrpi.port_rd := r.rp_rd;
        vrpi.port_adr := r.rp_adr;
        vrpi.port_bsel := X"f";
        -- 'direct' lines for read ports...
        if ((icache_enable = '0') or (not adr_is_cached(vrpi.port_adr))) then
            vrpi.port_direct := '1';
        else
            vrpi.port_direct := '0';
        end if;

        if (CFG_NUT_HISTOGRAM) then
            ifuo.hist_ctrl.start <= r.rp_rd and not (not r.last_rp_ack and rpo.port_ack);
            ifuo.hist_ctrl.stop <= rpo.port_ack;
        end if;

        rin <= v;
        rpi <= vrpi;

    end process;

    regs : process(clk)
    begin
        if (clk'event and clk = '1') then
            r <= rin;
        end if;
    end process;

end rtl;
