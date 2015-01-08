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
--  Execution unit (EXU) integer pipeline implementing the ORBIS32 instruction
--  set.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library paranut;
use paranut.paranut_config.all;
use paranut.exu.all;
use paranut.types.all;
use paranut.paranut_lib.all;
use paranut.ifu.all;
use paranut.lsu.all;
use paranut.orbis32.all;
use paranut.memu_lib.all;
-- pragma translate_off
use paranut.text_io.all;
use paranut.txt_util.all;
use paranut.tb_monitor.all;
-- pragma translate_on

use paranut.histogram.all;

entity mexu is
    generic (
                CEPU_FLAG       : boolean := true;
                CAPABILITY_FLAG : integer := 3;
                CPU_ID          : integer := 0
            );
    port (
             clk            : in std_logic;
             reset          : in std_logic;
             -- to IFU
             ifui           : out ifu_in_type;
             ifuo           : in ifu_out_type;
             -- to Load/Store Unit (LSU)
             lsui           : out lsu_in_type;
             lsuo           : in lsu_out_type;
             -- controller outputs
             icache_enable  : out std_logic;
             dcache_enable  : out std_logic;
             -- Debug unit
             du_stall       : in std_logic;
             -- Histogram
             emhci          : in exu_memu_hist_ctrl_in_type
             -- TBD: timer, interrupt controller ...
         );
end mexu;

architecture rtl of mexu is

    -- pragma translate_off
    constant CFG_DBG_INSN_TRACE_CPU_MASK_SLV : std_logic_vector(CFG_NUT_CPU_CORES-1 downto 0) := conv_std_logic_vector(CFG_DBG_INSN_TRACE_CPU_MASK, CFG_NUT_CPU_CORES);
    -- pragma translate_on

    constant GPRS : integer := 32;
    constant GPRS_LD : integer := log2x(GPRS);
    constant LINK_REGISTER : integer := 9; -- R9 is the link register according to the OR1k manual

    -- SPR addresses...
    -- Group 0...
    constant SPR_VR       : natural := 0; -- VR           - Version register
    constant SPR_UPR      : natural := 1; -- UPR          - Unit Present register
    constant SPR_CPUCFGR  : natural := 2; -- CPUCFGR      - CPU Configuration register
    constant SPR_DMMUCFGR : natural := 3; -- DMMUCFGR     - Data MMU Configuration register
    constant SPR_IMMUCFGR : natural := 4; -- IMMUCFGR     - Instruction MMU Configuration register
    constant SPR_DCCFGR   : natural := 5; -- DCCFGR       - Data Cache Configuration register
    constant SPR_ICCFGR   : natural := 6; -- ICCFGR       - Instruction Cache Configuration register
    constant SPR_DCFGR    : natural := 7; -- DCFGR        - Debug Configuration register
    constant SPR_PCCFGR   : natural := 8; -- PCCFGR       - Performance Counters Configuration register
    constant SPR_VR2      : natural := 9; -- VR2          - Version register 2
    constant SPR_AVR      : natural := 10; -- AVR          - Architecture Version register
    constant SPR_NPC      : natural := 16; -- NPC          - PC mapped to SPR space (NOTE: NPC according to OR1k, PC according to OR1200!)
    constant SPR_SR       : natural := 17; -- SR           - Supervision register
    constant SPR_PPC      : natural := 18; -- PPC          - PC mapped to SPR space (previous PC)
    constant SPR_FPCSR    : natural := 19; -- FPCSR        - FP Control/Status register
    constant SPR_EPCR0    : natural := 32; -- EPCR0-EPCR15 - Exception PC registers
    constant SPR_EEAR0    : natural := 48; -- EEAR0-EEAR15 - Exception EA registers
    constant SPR_ESR0     : natural := 64; -- ESR0-ESR15   - Exception SR registers
    constant SPR_GPR0     : natural := 1024; -- GPR0-GPR511  - GPRs mapped to SPR space

    -- Group 1 (Data MMU)... (group 2 / IMMU decoded into group 1)
    -- Group 3 (Data Cache)... (group 4 / ICache decoded into group 3)
    -- Group 6 (Debug)...
    -- Group 7 (Performance Counters)...
    -- Group 9 (Programmable Interrupt Controler)...
    -- Group 10 (Tick Timer)...

    -- Group 24 (ParaNut)...
    constant SPR_PNCPUS  : integer := 0;
    constant SPR_PNM2CAP : integer := 1;
    constant SPR_PNCPUID : integer := 2;
    constant SPR_PNCE    : integer := 4;
    constant SPR_PNLM    : integer := 5;
    constant SPR_PNX     : integer := 8;
    constant SPR_PNXID0  : integer := 32;

    -- CPU registers
    type special_purpose_registers is record
        -- GRP #0
        EPCR   : TWord;
        EEAR   : TWord;
        ESR    : TWord;
        SR     : TWord;
        -- GRP #24 (TBD)
        --PNCE   : TWord;
        --PNLM   : TWord;
        --PNX    : TWord;
        --PNXID  : TWord_Vec(0 to CFG_NUT_CPU_CORES-1);
        -- GRP #25 (HISTOGRAMS)
        HIST_CTRL : TWord;
    end record;

    -- Supervision register (SR) bits
    subtype CID is natural range 31 downto 28;
    subtype RES is natural range 27 downto 17;
    constant SUMRA : integer := 16;
    constant FO    : integer := 15;
    constant EPH   : integer := 14;
    constant DSX   : integer := 13;
    constant OVE   : integer := 12;
    constant OV    : integer := 11;
    constant CY    : integer := 10;
    constant F     : integer := 9;
    constant CE    : integer := 8;
    constant LEE   : integer := 7;
    constant IME   : integer := 6;
    constant DME   : integer := 5;
    constant ICE   : integer := 4;
    constant DCE   : integer := 3;
    constant IEE   : integer := 2;
    constant TEE   : integer := 1;
    constant SM    : integer := 0;

    -- ALU functions
    subtype EAluFunc is std_logic_vector(4 downto 0);

    constant AF_ADD  : EAluFunc := "00000";
    constant AF_ADC  : EAluFunc := "00001";
    constant AF_SUB  : EAluFunc := "00010";
    constant AF_AND  : EAluFunc := "00011";
    constant AF_OR   : EAluFunc := "00100";
    constant AF_XOR  : EAluFunc := "00101";
    --constant AF_MUL  : EAluFunc := "00110";
    --constant AF_SXX  : EAluFunc := "01000";
    --constant AF_DIV  : EAluFunc := "01001";
    --constant AF_DIVU : EAluFunc := "01010";
    --constant AF_MULU : EAluFunc := "01011";
    constant AF_EXT  : EAluFunc := "01100";
    constant AF_CMOV : EAluFunc := "01110";
    --constant AF_FX1  : EAluFunc := "01111";
    constant AF_MOVHI: EAluFunc := "10000";
    --constant AF_NOP  : EAluFunc := "11111";

    -- EXU OPs
    constant EX_OP_NOP     : std_logic_vector(2 downto 0) := "000";
    constant EX_OP_MUL     : std_logic_vector(2 downto 0) := "001";
    constant EX_OP_SHIFT   : std_logic_vector(2 downto 0) := "010";
    constant EX_OP_ALU     : std_logic_vector(2 downto 0) := "011";
    constant EX_OP_LS      : std_logic_vector(2 downto 0) := "100";
    constant EX_OP_JUMP    : std_logic_vector(2 downto 0) := "101";
    constant EX_OP_SETSPR  : std_logic_vector(2 downto 0) := "110";
    constant EX_OP_RFE     : std_logic_vector(2 downto 0) := "111";

    -- EXU result select
    constant EX_RES_ALU    : std_logic_vector(1 downto 0) := "00";
    constant EX_RES_MUL    : std_logic_vector(1 downto 0) := "01";
    constant EX_RES_SHIFT  : std_logic_vector(1 downto 0) := "10";
    constant EX_RES_REG    : std_logic_vector(1 downto 0) := "11";

    -- Regfile write data select
    constant RF_WRD_EX_RES  : std_logic_vector(1 downto 0) := "00";
    constant RF_WRD_LOAD    : std_logic_vector(1 downto 0) := "01";
    constant RF_WRD_NPC     : std_logic_vector(1 downto 0) := "10";
    constant RF_WRD_SPR     : std_logic_vector(1 downto 0) := "11";

    -- ALU sources
    subtype AA_SRC is std_logic;
    constant AA_REG  : AA_SRC := '1';
    constant AA_PC   : AA_SRC := '0';

    subtype AB_SRC is std_logic_vector(3 downto 0);
    constant AB_REG     : AB_SRC := "1000";
    constant AB_IMM16S  : AB_SRC := "0000";
    constant AB_IMM16Z  : AB_SRC := "0001";
    constant AB_IMM16HI : AB_SRC := "0010";
    constant AB_IMM162  : AB_SRC := "0011";
    constant AB_IMM26S  : AB_SRC := "0100";

    -- ALU compare modes
    constant COMP_EQU : std_logic_vector(2 downto 0) := "000";
    constant COMP_NEQ : std_logic_vector(2 downto 0) := "001";
    constant COMP_GTH : std_logic_vector(2 downto 0) := "010";
    constant COMP_GEQ : std_logic_vector(2 downto 0) := "011";
    constant COMP_LTH : std_logic_vector(2 downto 0) := "100";
    constant COMP_LEQ : std_logic_vector(2 downto 0) := "101";

    -- Exception stages
    constant STAGE_IF : std_logic_vector(1 downto 0) := "00";
    constant STAGE_ID : std_logic_vector(1 downto 0) := "01";
    constant STAGE_EX : std_logic_vector(1 downto 0) := "10";
    constant STAGE_XC : std_logic_vector(1 downto 0) := "11";

    -- Exception types
    subtype exceptions_type is std_logic_vector(14 downto 0);
    constant T_XC_RESET      : integer := 14;
    constant T_XC_ITLB_MISS  : integer := 13;
    constant T_XC_IPF        : integer := 12;
    constant T_XC_IBUS_ERR   : integer := 11;
    constant T_XC_ILL_OP     : integer := 10;
    constant T_XC_ALIGN      : integer := 9;
    constant T_XC_DTLB_MISS  : integer := 8;
    constant T_XC_SYS_CALL   : integer := 7;
    constant T_XC_TRAP       : integer := 6;
    constant T_XC_DPF        : integer := 5;
    constant T_XC_DBUS_ERR   : integer := 4;
    constant T_XC_RANGE      : integer := 3;
    constant T_XC_FP         : integer := 2;
    constant T_XC_EXT_INT    : integer := 1;
    constant T_XC_TT         : integer := 0;

    -- Histograms size
    constant MAX_HIST_BINS_LD : integer := 0;

    -- Pipeline registers...

    type exception_state_type is (S_XC_INIT, S_XC_FLUSH_PIPL, S_XC_JUMP);

    type exception_reg_type is record
        state : exception_state_type;
        pc : TWord;
        id : std_logic_vector(3 downto 0);
        pc_stage_id : std_logic_vector(1 downto 0);
        in_delay_slot : std_logic;
        save_eear : std_logic;
    end record;

    type memory_reg_type is record
        mem_data : TWord;
        --wb_result : TWord;
        --wb_jump_linked : std_logic;
        --wb_set_reg_d : std_logic;
        --wb_rsel_d : std_logic_vector(4 downto 0);
        --wb_wdata_sel : std_logic_vector(1 downto 0);
        --in_delay_slot : std_logic;
    end record;

    type execution_state_type is (S_EX_INIT, S_EX_ALU_WB, S_EX_LS_MEM_STALL,
    S_EX_LOAD_MEM, S_EX_LS_WB, S_EX_CACHE_INVALIDATE_1,
    S_EX_CACHE_INVALIDATE_2, S_EX_JUMP, S_EX_SHIFT_STALL, S_EX_MUL_STALL,
    S_EX_MUL_WB, S_EX_SHIFT_WB, S_EX_SPR_WB1, S_EX_SPR_WB2, S_EX_RFE);

    type execute_reg_type is record
        state : execution_state_type;
        wb_result : TWord;
        --b : TWord;
        --mem_lsu_width : std_logic_vector(1 downto 0);
        --mem_lsu_exts : std_logic;
        --wb_jump_linked : std_logic;
        --wb_set_reg_d : std_logic;
        --wb_rsel_d : std_logic_vector(4 downto 0);
        --wb_wdata_sel : std_logic_vector(1 downto 0);
        --in_delay_slot : std_logic;
    end record;

    type decode_reg_type is record
        alu_func : EAluFunc;
        alu_in_1, alu_in_2 : TWord;
        --alu_src_a : AA_SRC;
        --alu_src_b : AB_SRC;
        --imm : TWord;
        --a : TWord;
        b : TWord;
        pc : TWord;
        ill_op : std_logic;
        sys : std_logic;
        trap : std_logic;
        ex_op : std_logic_vector(2 downto 0);
        ex_shift_mode : std_logic_vector(1 downto 0);
        ex_bhw_exts : std_logic;
        ex_bhw_sel : std_logic;
        ex_signed : std_logic;
        ex_comp_mode : std_logic_vector(2 downto 0);
        ex_set_cy_ov : std_logic;
        ex_set_f : std_logic;
        ex_res_sel : std_logic_vector(1 downto 0);
        mem_lsu_width : std_logic_vector(1 downto 0);
        mem_lsu_exts : std_logic;
        mem_lsu_load : std_logic;
        mem_lsu_store : std_logic;
        mem_lsu_flush : std_logic;
        mem_lsu_cache_invalidate : std_logic;
        mem_lsu_cache_writeback : std_logic;
        wb_jump_linked : std_logic;
        wb_set_reg_d : std_logic;
        wb_rsel_d : std_logic_vector(4 downto 0);
        wb_wdata_sel : std_logic_vector(1 downto 0);
        in_delay_slot : std_logic;
        halt : std_logic;
        insn_valid : std_logic; -- only used for histograms...
    end record;

    type fetch_reg_type is record
        in_delay_slot : std_logic;
    end record;

    type registers is record
        x : exception_reg_type;
        m : memory_reg_type;
        e : execute_reg_type;
        d : decode_reg_type;
        f : fetch_reg_type;
        mode : unsigned(1 downto 0);
    end record;

    signal alu_hist_ctrl : hist_ctrl_type;
    signal shift_hist_ctrl : hist_ctrl_type;
    signal mul_hist_ctrl : hist_ctrl_type;
    signal load_hist_ctrl : hist_ctrl_type;
    signal store_hist_ctrl : hist_ctrl_type;
    signal jump_hist_ctrl : hist_ctrl_type;
    signal other_hist_ctrl : hist_ctrl_type;

    signal alu_hi : hist_in_type;
    signal alu_ho : hist_out_type;
    signal shift_hi : hist_in_type;
    signal shift_ho : hist_out_type;
    signal mul_hi : hist_in_type;
    signal mul_ho : hist_out_type;
    signal load_hi : hist_in_type;
    signal load_ho : hist_out_type;
    signal store_hi : hist_in_type;
    signal store_ho : hist_out_type;
    signal jump_hi : hist_in_type;
    signal jump_ho : hist_out_type;
    signal other_hi : hist_in_type;
    signal other_ho : hist_out_type;
    signal ifu_hi : hist_in_type;
    signal ifu_ho : hist_out_type;
    signal clf_hi : hist_in_type;
    signal clf_ho : hist_out_type;
    signal clwb_hi : hist_in_type;
    signal clwb_ho : hist_out_type;
    signal crhi_hi : hist_in_type;
    signal crhi_ho : hist_out_type;
    signal crmi_hi : hist_in_type;
    signal crmi_ho : hist_out_type;
    signal crhl_hi : hist_in_type;
    signal crhl_ho : hist_out_type;
    signal crml_hi : hist_in_type;
    signal crml_ho : hist_out_type;
    signal cwhl_hi : hist_in_type;
    signal cwhl_ho : hist_out_type;
    signal cwml_hi : hist_in_type;
    signal cwml_ho : hist_out_type;

    function get_dccfgr return TWord is
        variable ret : TWord;
    begin
        ret := (others => '0');
        ret(8) := '1';
        if (CFG_MEMU_CACHE_BANKS <= 4) then
            ret(7) := '0';
        else
            ret(7) := '1';
        end if;
        ret(6 downto 3) := conv_std_logic_vector(CFG_MEMU_CACHE_SETS_LD, 4);
        ret(2 downto 0) := conv_std_logic_vector(CFG_MEMU_CACHE_WAYS_LD, 3);
        return (ret);
    end function;

    impure function get_spr(reg_addr : std_logic_vector(15 downto 0); r : registers; spr : special_purpose_registers; ifuo : ifu_out_type)
    return TWord is
        variable outd : TWord;
        variable grp_nr : unsigned(4 downto 0);
        variable reg_nr : unsigned(10 downto 0);
        -- pragma translate_off
        variable spr_present : boolean := true;
        -- pragma translate_on
    begin

        outd := (others => '0'); -- default value for unimplemented registers
        grp_nr := unsigned(reg_addr(15 downto 11));
        reg_nr := unsigned(reg_addr(10 downto 0));

        case to_integer(grp_nr) is
            when 0 =>
                if (reg_nr >= SPR_EPCR0 and reg_nr <= SPR_EPCR0+15) then outd := spr.EPCR;
                elsif (reg_nr >= SPR_EEAR0 and reg_nr <= SPR_EEAR0+15) then outd := spr.EEAR;
                elsif (reg_nr >= SPR_ESR0 and reg_nr <= SPR_ESR0+15) then outd := spr.ESR;
                elsif (reg_nr >= SPR_GPR0 and reg_nr <= SPR_GPR0+511) then
                    -- pragma translate_off
                    report "EXU(" & str(CPU_ID) & ") get_spr: GPRs not supported / should be handled by main controller" severity warning;
                    -- pragma translate_on
                else
                    case to_integer(reg_nr) is
                        when SPR_VR =>
                            outd := X"1f000000"; -- VER = 0x1f, CFG = 0x0, RES = 0x0, UVRP = 0, REV = 0x0
                        when SPR_UPR =>
                            outd := X"00000007"; -- present: UP(0), DCP(1), ICP(2), nothing else
                        when SPR_CPUCFGR =>      -- CPUCFGR  - CPU Configuration register
                            outd := X"00000020";
                        when SPR_DMMUCFGR =>     -- DMMUCFGR - Data MMU Configuration register
                            outd := X"00000000"; -- TODO
                        when SPR_IMMUCFGR =>     -- IMMUCFGR - Instruction MMU Configuration register
                            outd := X"00000000"; -- TODO
                        when SPR_DCCFGR =>       -- DCCFGR   - Data Cache Configuration register
                            outd := get_dccfgr;
                        when SPR_ICCFGR =>       -- ICCFGR   - Instruction Cache Configuration register
                            outd := get_dccfgr;
                        when SPR_DCFGR =>        -- DCFGR    - Debug Configuration register
                            outd := X"00000000";
                        when SPR_PCCFGR =>       -- PCCFGR   - Performance Counters Configuration register
                            outd := X"00000000";
                        when SPR_NPC =>          -- NPC      - R/W PC mapped to SPR space (next PC)
                            -- Note: Due to pielining, when insn is committed, ifuo.pc already holds the NPC
                            outd := ifuo.pc;
                        when SPR_PPC =>          -- PPC      - R/W PC mapped to SPR space (previous PC)
                            -- Note: Due to pipelining, when insn is committed, ifuo.ppc holds current PC, not PPC
                            outd := r.x.pc;
                        when SPR_FPCSR =>        -- FPCSR    - FP Control/Status register
                            outd := X"00000000";
                        when SPR_SR =>           -- SR       - Supervision register
                            outd := spr.SR;
                        when others =>
                            -- pragma translate_off
                            spr_present := false;
                            -- pragma translate_on
                    end case;
                end if;
            when 24 =>
                if (reg_nr >= 32 and reg_nr <= 64) then
                    outd := X"00000000"; -- TODO
                else
                    case to_integer(reg_nr) is
                        when SPR_PNCPUS =>
                            outd := conv_std_logic_vector(CFG_NUT_CPU_CORES, 32);
                        when SPR_PNM2CAP =>
                            outd := (others => '1'); -- TODO
                        when SPR_PNCPUID =>
                            outd := conv_std_logic_vector(CPU_ID, 32);
                        when SPR_PNCE =>
                            --outd := spr.PNCE;
                        when SPR_PNLM =>
                            --outd := spr.PNLM;
                        when SPR_PNX =>
                            --outd := spr.PNX;
                            --spr.PNX := (others => '0'); TODO
                        when others =>
                            -- pragma translate_off
                            spr_present := false;
                            -- pragma translate_on
                    end case;
                end if;
            when 25 =>
                -- This group addresses 31 histograms with 64 entries each
                -- First 64 entries are mapped to HIST_CTRL reg
                if (CFG_NUT_HISTOGRAM) then
                    if (reg_nr >= 0 and reg_nr <= 63) then
                        outd := spr.HIST_CTRL;
                    elsif (reg_nr >= 64 and reg_nr <= 127) then
                        outd := alu_ho.data;
                    elsif (reg_nr >= 128 and reg_nr <= 191) then
                        outd := shift_ho.data;
                    elsif (reg_nr >= 192 and reg_nr <= 255) then
                        outd := mul_ho.data;
                    elsif (reg_nr >= 256 and reg_nr <= 319) then
                        outd := load_ho.data;
                    elsif (reg_nr >= 320 and reg_nr <= 383) then
                        outd := store_ho.data;
                    elsif (reg_nr >= 384 and reg_nr <= 447) then
                        outd := jump_ho.data;
                    elsif (reg_nr >= 448 and reg_nr <= 511) then
                        outd := other_ho.data;
                    elsif (reg_nr >= 512 and reg_nr <= 575) then
                        outd := ifu_ho.data;
                    elsif (reg_nr >= 576 and reg_nr <= 639) then
                        outd := clf_ho.data;
                    elsif (reg_nr >= 640 and reg_nr <= 703) then
                        outd := clwb_ho.data;
                    elsif (reg_nr >= 704 and reg_nr <= 767) then
                        outd := crhi_ho.data;
                    elsif (reg_nr >= 768 and reg_nr <= 831) then
                        outd := crmi_ho.data;
                    elsif (reg_nr >= 832 and reg_nr <= 895) then
                        outd := crhl_ho.data;
                    elsif (reg_nr >= 896 and reg_nr <= 959) then
                        outd := crml_ho.data;
                    elsif (reg_nr >= 960 and reg_nr <= 1023) then
                        outd := cwhl_ho.data;
                    elsif (reg_nr >= 1024 and reg_nr <= 1087) then
                        outd := cwml_ho.data;
                    elsif (reg_nr >= 1088 and reg_nr <= 1151) then
                        outd := lsuo.buf_fill_hist(to_integer(reg_nr(log2x(CFG_IFU_IBUF_SIZE) downto 0)));
                    elsif (reg_nr >= 1152 and reg_nr <= 1215) then
                        outd := ifuo.buf_fill_hist(to_integer(reg_nr(log2x(CFG_IFU_IBUF_SIZE) downto 0)));
                    end if;
                end if;
            when others =>
                -- pragma translate_off
                spr_present := false;
                -- pragma translate_on
        end case;
        -- pragma translate_off
        assert spr_present
        report "EXU(" & str(CPU_ID) & ") get_spr: Read access to unknown SPR Grp#" &
        to_ud_string("000"&reg_addr(15 downto 11)) & " Reg#" & to_ud_string("0"&reg_addr(10 downto 0)) severity warning;
        -- pragma translate_on
        return (outd);
    end;

    function set_spr (
                         reg_addr : std_logic_vector(15 downto 0);
                         val : TWord;
                         spr : special_purpose_registers
                     )
    return special_purpose_registers is
        variable vspr : special_purpose_registers;
        variable grp_nr : unsigned(4 downto 0);
        variable reg_nr : unsigned(10 downto 0);
        -- pragma translate_off
        variable spr_present : boolean := true;
        -- pragma translate_on
    begin
        vspr := spr;
        grp_nr := unsigned(reg_addr(15 downto 11));
        reg_nr := unsigned(reg_addr(10 downto 0));

        case to_integer(grp_nr) is
            when 0 =>
                if (reg_nr >= SPR_EPCR0 and reg_nr <= SPR_EPCR0+15) then
                    -- pragma translate_off
                    report "EXU(" & str(CPU_ID) & ") set_spr: SPR write to EPCRn - against specification" severity warning;
                    -- pragma translate_on
                    vspr.EPCR := val;
                elsif (reg_nr >= SPR_EEAR0 and reg_nr <= SPR_EEAR0+15) then
                    -- pragma translate_off
                    report "EXU(" & str(CPU_ID) & ") set_spr: ignoring SPR write to EEARn - against specification" severity warning;
                -- pragma translate_on
                --vspr.EEAR := val;
                elsif (reg_nr >= SPR_ESR0 and reg_nr <= SPR_ESR0+15) then
                    -- pragma translate_off
                    report "EXU(" & str(CPU_ID) & ") set_spr: ignoring SPR write to ESRn - against specification" severity warning;
                -- pragma translate_on
                --vspr.ESR := val;
                elsif (reg_nr >= SPR_GPR0 and reg_nr <= SPR_GPR0+511) then
                    -- pragma translate_off
                    report "EXU(" & str(CPU_ID) & ") set_spr: GPRs not supported / should be handled by main controller" severity error;
                    -- pragma translate_on
                else
                    case to_integer(reg_nr) is
                        when SPR_SR =>
                            vspr.SR(SUMRA) := val(SUMRA);
                            vspr.SR(DSX) := val(DSX);
                            vspr.SR(OV) := val(OV);
                            vspr.SR(CY) := val(CY);
                            vspr.SR(F) := val(F);
                            vspr.SR(ICE) := val(ICE);
                            vspr.SR(DCE) := val(DCE);
                            vspr.SR(IEE) := val(IEE);
                        when others => 
                            -- pragma translate_off
                            spr_present := false;
                            -- pragma translate_on
                    end case;
                end if;
            when 24 =>
                case to_integer(reg_nr) is
                    when SPR_PNCE =>
                        --vspr.PNCE := val;
                    when SPR_PNLM =>
                        --vspr.PNLM := val;
                    when others =>
                        -- pragma translate_off
                        spr_present := false;
                        -- pragma translate_on
                end case;
            when 25 =>
                if (CFG_NUT_HISTOGRAM) then
                    if (reg_nr >= 0 and reg_nr <= 63) then
                        vspr.HIST_CTRL := val;
                    else
                        -- pragma translate_off
                        spr_present := false;
                        -- pragma translate_on
                    end if;
                else
                    -- pragma translate_off
                    spr_present := false;
                    -- pragma translate_on
                end if;
            when others =>
                -- pragma translate_off
                spr_present := false;
                -- pragma translate_on
        end case;
        -- pragma translate_off
        assert spr_present
        report "EXU(" & str(CPU_ID) & ") set_spr: SPR write to read-only register Grp#" &
        to_ud_string("000"&reg_addr(15 downto 11)) & " Reg#" & to_ud_string("0"&reg_addr(10 downto 0)) severity warning;
        -- pragma translate_on
        return (vspr);
    end function;

    procedure exception_detect (
                                   r : in registers;
                                   spr : in special_purpose_registers;
                                   exceptions : in exceptions_type;
                                   xc_id : out std_logic_vector(3 downto 0);
                                   xc_pc_stage_id : out std_logic_vector(1 downto 0);
                                   xc_in_delay_slot : out std_logic;
                                   xc_save_eear : out std_logic
                               )
    is
        variable except_stage_id : std_logic_vector(1 downto 0);
        variable pc_stage_id : std_logic_vector(1 downto 0);
        variable except_id : unsigned (3 downto 0);
        variable except_restart : boolean;
        variable except_save_eear : boolean;
        variable in_delay_slot : std_logic;
        variable epcr : TWord;
    begin

        except_id := X"0"; except_restart := true; except_save_eear := false;

        -- except_stage_id := STAGE_EX;
        -- Get the stage where the exception happened (for now it always
        -- happens in STAGE_EX)
        if (spr.SR(IEE) = '1') then
            --if (exceptions(T_XC_RESET) = '1') then
            --    except_id := X"1";
            --    except_stage_id := STAGE_EX;
            --elsif (exceptions(T_XC_ITLB_MISS) = '1') then
            --    except_id := X"a";
            --    except_stage_id := STAGE_EX;
            --elsif (exceptions(T_XC_IPF) = '1') then
            --    except_id := X"4";
            --    except_stage_id := STAGE_EX;
            --elsif (exceptions(T_XC_IBUS_ERR) = '1') then
            --    except_id := X"2";
            --    except_stage_id := STAGE_EX;
            --elsif (exceptions(T_XC_ILL_OP) = '1') then
            if (exceptions(T_XC_ILL_OP) = '1') then
                except_id := X"7";
                except_stage_id := STAGE_EX;
            elsif (exceptions(T_XC_ALIGN) = '1') then
                except_id := X"6";
                except_stage_id := STAGE_EX;
                except_save_eear := true;
            --elsif (exceptions(T_XC_DTLB_MISS) = '1') then
            --    except_id := X"9";
            --    except_stage_id := STAGE_EX;
            elsif (exceptions(T_XC_SYS_CALL) = '1') then
                except_id := X"c";
                except_stage_id := STAGE_EX;
                except_restart := false;
            elsif (exceptions(T_XC_TRAP) = '1') then
                except_id := X"e";
                except_stage_id := STAGE_EX;
            --elsif (exceptions(T_XC_DPF) = '1') then
            --    except_id := X"3";
            --    except_stage_id := STAGE_EX;
            --elsif (exceptions(T_XC_DBUS_ERR) = '1') then
            --    except_id := X"2";
            --    except_stage_id := STAGE_EX;
            --elsif (exceptions(T_XC_RANGE) = '1') then
            --    except_id := X"b";
            --    except_stage_id := STAGE_EX;
            --elsif (exceptions(T_XC_FP) = '1') then
            --    except_id := X"d";
            --    except_stage_id := STAGE_EX;
            --    except_restart := false;
            --elsif (exceptions(T_XC_EXT_INT) = '1') then
            --    except_id := X"8";
            --    except_stage_id := STAGE_EX;
            --    except_restart := false;
            --elsif (exceptions(T_XC_TT) = '1') then
            --    except_id := X"5";
            --    except_stage_id := STAGE_EX;
            --    except_restart := false;
            end if;
        end if;

        case except_stage_id is
            when STAGE_ID => in_delay_slot := r.f.in_delay_slot;
            when STAGE_EX => in_delay_slot := r.d.in_delay_slot;
            when others => in_delay_slot := '0';
        end case;

        if (except_restart) then
            if (in_delay_slot = '0') then
                pc_stage_id := except_stage_id;
            else
                pc_stage_id := except_stage_id + 1;
            end if;
        else
            if (in_delay_slot = '0') then
                pc_stage_id := STAGE_ID;
            else
                pc_stage_id := STAGE_XC;
            end if;
        end if;

        if (not CEPU_FLAG and except_id /= X"0") then
                -- pragma translate_off
            report "EXU(" & str(CPU_ID) & ") CoPU exception asserted - not implemented yet." severity error;
                -- pragma translate_on
            null;
        end if;

        xc_id := std_logic_vector(except_id);
        xc_pc_stage_id := pc_stage_id;
        xc_in_delay_slot := in_delay_slot;
        xc_save_eear := conv_std_logic(except_save_eear);
    end procedure;

    procedure exception_save_registers (
                                           r : in registers;
                                           --pc_stage_id : in std_logic_vector(1 downto 0);
                                           --in_delay_slot : in std_logic;
                                           --save_eear : in std_logic;
                                           spr : in special_purpose_registers;
                                           ifuo : in ifu_out_type;
                                           vspr : out special_purpose_registers
                                       )
    is
        variable epcr : TWord;
    begin

        vspr := spr;

        --case pc_stage_id is
        case r.x.pc_stage_id is
            when STAGE_IF => epcr := ifuo.npc;
            when STAGE_ID => epcr := ifuo.pc;
            --when STAGE_EX => epcr := ifuo.ppc;
            when STAGE_EX => epcr := r.d.pc;
            when STAGE_XC => epcr := r.x.pc;
            when others => epcr := (others => '-');
        end case;
        vspr.EPCR := epcr;
        vspr.ESR := spr.SR;
        --if (save_eear = '1') then
        if (r.x.save_eear = '1') then
            -- Note: This only works because in the first cycle of S_EX_INIT
            -- r.e.wb_result (which is the l/s address) still has its old value
            vspr.EEAR := r.e.wb_result;
        end if;

        -- Not yet implemented because of missing MMU
        --vspr.SR(IME) := '0';
        --vspr.SR(DME) := '0';
        --vspr.SR(SM) := '1';
        vspr.SR(IEE) := '0';
        vspr.SR(TEE) := '0';
        --if (in_delay_slot = '1') then
        if (r.x.in_delay_slot = '1') then
            vspr.SR(DSX) := '1';
        else
            vspr.SR(DSX) := '0';
        end if;
    end procedure;

    procedure insn_decode (
                              r : in registers;
                              spr : in special_purpose_registers;
                              ifuo : in ifu_out_type;
                              nexti_invalid : in std_logic;
                              dout : out decode_reg_type;
                              rsel_a : out std_logic_vector(4 downto 0);
                              rsel_b : out std_logic_vector(4 downto 0);
                              alu_src_a : out AA_SRC;
                              alu_src_b : out AB_SRC;
                              next_in_delay_slot : out std_logic
                          )
    is
        variable op1 : op1_type := ifuo.ir(31 downto 26);
        variable op2 : op2_type := ifuo.ir(25 downto 21);
        variable op3 : op3_type := ifuo.ir(3 downto 0);
        variable width : std_logic_vector(2 downto 0);
        variable d : decode_reg_type;
    begin

        if (CFG_NUT_HISTOGRAM) then
            d.insn_valid := '0';
        end if;
        d.ill_op := '0';
        d.sys := '0';
        d.trap := '0';

        d.ex_op := EX_OP_NOP; d.ex_res_sel := EX_RES_ALU; d.wb_wdata_sel := RF_WRD_EX_RES;
        d.wb_jump_linked := '0';
        -- NOTE: The ALU from the EX-stage always has to be fed with an operation, so if
        -- there is no valid instruction, shift in a "NOP" bubble by default that
        -- does nothing harmful (in this case an xor operation)
        d.alu_func := AF_XOR;
        alu_src_a := AA_REG; alu_src_b := AB_REG;
        d.wb_set_reg_d := '0';
        d.ex_set_cy_ov := '0'; d.ex_set_f := '0';
        d.halt := '0';

        d.wb_rsel_d := op2;
        rsel_a := (others => '0');
        rsel_b := (others => '0');
        d.ex_shift_mode := ifuo.ir(7 downto 6);
        d.ex_bhw_exts := not ifuo.ir(7);
        d.ex_bhw_sel := ifuo.ir(6);

        d.mem_lsu_exts := not ifuo.ir(26);
        d.ex_signed := ifuo.ir(24);

        d.ex_comp_mode := ifuo.ir(23 downto 21);

        d.mem_lsu_load := '0'; d.mem_lsu_store := '0'; d.mem_lsu_flush := '0';
        d.mem_lsu_cache_invalidate := ifuo.ir(11);
        d.mem_lsu_cache_writeback := ifuo.ir(12);

        if (nexti_invalid = '1') then
            -- The PC and associated information must not be changed as long as
            -- no new valid instruction is committed (important for handling exceptions)
            d.pc := r.d.pc;
            d.in_delay_slot := r.d.in_delay_slot;
            next_in_delay_slot := r.f.in_delay_slot;
        else
            if (CFG_NUT_HISTOGRAM) then
                d.insn_valid := '1';
            end if;
            d.pc := ifuo.pc;
            d.in_delay_slot := r.f.in_delay_slot;
            next_in_delay_slot := '0';

            rsel_a := ifuo.ir(20 downto 16);
            rsel_b := ifuo.ir(15 downto 11);
            case op1 is
                when ALU =>
                    -- (ALU) w/o immediate...
                    case op3 is
                        when MULU =>
                            d.ex_op := EX_OP_MUL; d.ex_res_sel := EX_RES_MUL;
                            d.ex_signed := '0';
                        when MUL =>
                            d.ex_op := EX_OP_MUL; d.ex_res_sel := EX_RES_MUL;
                            d.ex_signed := '1';
                        when SHIFT =>
                            d.ex_op := EX_OP_SHIFT; d.ex_res_sel := EX_RES_SHIFT;
                        when others =>
                            d.ex_op := EX_OP_ALU; d.alu_func := '0' & op3;
                    end case;
                    d.wb_set_reg_d := '1'; d.ex_set_cy_ov := '1'; d.ex_set_f := '0';
                when ADDI | ADDIC | ANDI | ORI | XORI =>
                    -- (ALU) ALU w/ immediate...
                    d.ex_op := EX_OP_ALU;
                    case op1 is
                        when ADDI  => d.alu_func := AF_ADD; alu_src_b := AB_IMM16S;
                        when ADDIC => d.alu_func := AF_ADC; alu_src_b := AB_IMM16S;
                        when ANDI  => d.alu_func := AF_AND; alu_src_b := AB_IMM16Z;
                        when ORI   => d.alu_func := AF_OR; alu_src_b := AB_IMM16Z;
                        when XORI  => d.alu_func := AF_XOR; alu_src_b := AB_IMM16S;
                        when others => null;
                    end case;
                    d.wb_set_reg_d := '1'; d.ex_set_cy_ov := '1'; d.ex_set_f := '0';
                when MULI  =>
                    d.ex_op := EX_OP_MUL; d.ex_res_sel := EX_RES_MUL;
                    alu_src_b := AB_IMM16S; d.ex_signed := '1';
                    d.wb_set_reg_d := '1'; d.ex_set_cy_ov := '1'; d.ex_set_f := '0';
                when SETF =>
                    -- (ALU) Set-flag w/o immediate...
                    d.ex_op := EX_OP_ALU;
                    d.alu_func := AF_SUB;
                    d.wb_set_reg_d := '0'; d.ex_set_cy_ov := '0'; d.ex_set_f := '1';
                when SRLI =>
                    -- (ALU) Shift & rotate w/ immediate...
                    d.ex_op := EX_OP_SHIFT; d.ex_res_sel := EX_RES_SHIFT;
                    alu_src_b := AB_IMM16S;
                    d.wb_set_reg_d := '1'; d.ex_set_cy_ov := '1'; d.ex_set_f := '0';
                when SETFI =>
                    -- (ALU) Set-flag w/ immediate...
                    d.ex_op := EX_OP_ALU;
                    d.alu_func := AF_SUB; alu_src_b := AB_IMM16S;
                    d.wb_set_reg_d := '0'; d.ex_set_cy_ov := '0'; d.ex_set_f := '1';
                when MOVHI =>
                    -- (ALU) MOVHI...
                    d.ex_op := EX_OP_ALU;
                    d.alu_func := AF_MOVHI; alu_src_b := AB_IMM16HI;
                    d.wb_set_reg_d := '1'; d.ex_set_cy_ov := '0'; d.ex_set_f := '0';
                when LWZ | LWS | LBZ | LBS | LHZ | LHS =>
                    -- (LS) Load...
                    d.ex_op := EX_OP_LS; d.wb_wdata_sel := RF_WRD_LOAD;
                    d.alu_func := AF_ADD; alu_src_b := AB_IMM16S;
                    d.wb_set_reg_d := '1'; d.ex_set_cy_ov := '0'; d.ex_set_f := '0';
                    d.mem_lsu_load := '1';
                when SW | SB | SH =>
                    -- (LS) Store...
                    d.ex_op := EX_OP_LS;
                    d.alu_func := AF_ADD; alu_src_b := AB_IMM162;
                    d.wb_set_reg_d := '0'; d.ex_set_cy_ov := '0'; d.ex_set_f := '0';
                    d.mem_lsu_store := '1';
                when CUST7 =>
                    -- (LS, ParaNut extension) Cache control...
                    d.ex_op := EX_OP_LS;
                    d.alu_func := AF_ADD; alu_src_b := AB_IMM162;
                    d.wb_set_reg_d := '0'; d.ex_set_cy_ov := '0'; d.ex_set_f := '0';
                    d.mem_lsu_flush := '1';
                when J | JAL | BF | BNF | JR | JALR =>
                    -- (JMP) j, jal, bnf, bf, jr, jalr...
                    if (op1 = J or op1 = JAL or op1 = JR or op1 = JALR or spr.SR(F) = ifuo.ir(28)) then
                        -- branch taken
                        d.ex_op := EX_OP_JUMP;
                        if (op1 >= JR) then
                            d.ex_res_sel := EX_RES_REG;
                        else
                            d.alu_func := AF_ADD; alu_src_a := AA_PC; alu_src_b := AB_IMM26S;
                            d.wb_set_reg_d := '0'; d.ex_set_cy_ov := '0'; d.ex_set_f := '0';
                        end if;
                        if (op1 = JAL or op1 = JALR) then
                            d.wb_wdata_sel := RF_WRD_NPC;
                            d.wb_jump_linked := '1';
                        end if;
                        next_in_delay_slot := '1';
                    end if;
                when NOP =>
                    -- (other) NOP...
                    case ifuo.ir(15 downto 0) is
                        when X"0001" => -- HALT
                            d.halt := '1';
                        when others =>
                            null;
                    end case;
                when OTHER =>
                    -- (other) SYS/TRAP...
                    case op2 is
                        when SYS =>
                            d.sys := '1';
                        when TRAP =>
                            if (spr.SR(conv_integer(ifuo.ir(4 downto 0))) = '1') then
                                d.trap := '1';
                            end if;
                        when others => null;
                    end case;
                when RFE =>
                    -- (other) RFE...
                    d.ex_op := EX_OP_RFE;
                when MFSPR =>
                    -- (other) MFSPR...
                    d.ex_op := EX_OP_ALU; d.wb_wdata_sel := RF_WRD_SPR;
                    d.alu_func := AF_OR; alu_src_b := AB_IMM16Z;
                    d.wb_set_reg_d := '1'; d.ex_set_cy_ov := '0'; d.ex_set_f := '0';
                when MTSPR =>
                    -- (other) MTSPR...
                    d.ex_op := EX_OP_SETSPR;
                    d.alu_func := AF_OR; alu_src_b := AB_IMM162;
                    d.wb_set_reg_d := '0'; d.ex_set_cy_ov := '0'; d.ex_set_f := '0';
                when others =>
                    if (ifuo.ir_valid = '1') then
                        -- pragma translate_off
                        report "EXU(" & str(CPU_ID) & ") insn_decode: Unsupported or illegal opcode." severity warning;
                        -- pragma translate_on
                        d.ill_op := '1';
                    end if;
            end case;
        end if;

        width := std_logic_vector(unsigned(op1(2 downto 0)) - 1);
        if (d.mem_lsu_load = '1') then
            d.mem_lsu_width := width(2 downto 1);
        else -- store
            d.mem_lsu_width := width(1 downto 0);
        end if;

        dout := d;

    end procedure;

    function immediate_sign_extend (sel : AB_SRC; insn : TWord)
    return TWord is
        variable Imm : TWord;
    begin
        case sel is
            when AB_IMM16Z =>
                Imm := X"0000" & insn(15 downto 0);
            when AB_IMM16S =>
                if (insn(15) = '0') then
                    Imm := X"0000" & insn(15 downto 0);
                else
                    Imm := X"FFFF" & insn(15 downto 0);
                end if;
            when AB_IMM16HI =>
                Imm := insn(15 downto 0) & X"0000";
            when AB_IMM162 =>
                if (insn(25) = '0') then
                    Imm := X"0000" & insn(25 downto 21) & insn(10 downto 0);
                else
                    Imm := X"FFFF" & insn(25 downto 21) & insn(10 downto 0);
                end if;
            when AB_IMM26S =>
                if (insn(25) = '0') then
                    Imm := X"0" & insn(25 downto 0) & "00";
                else
                    Imm := X"F" & insn(25 downto 0) & "00";
                end if;
            when others =>
                Imm := (others => '-');
        end case;
        return Imm;
    end;

    function alu_input_mux (sel : std_logic; in1 : TWord; in2 : TWord)
    return TWord is
        variable outd : TWord;
    begin
        case sel is
            when '1' => outd := in1;
            when others => outd := in2;
        end case;
        return outd;
    end;

    procedure run_alu (
                          d : in decode_reg_type;
                          spr : in special_purpose_registers;
                          inA : in TWord;
                          inB : in TWord;
                          set_cy_ov : in std_logic;
                          set_f : in std_logic;
                          vs : out TWord;
                          alu_out : out TWord
                      )
    is
        variable op1, op2, alu_res : std_logic_vector(31 downto 0);
        variable res_add : unsigned(32 downto 0);
        variable outCY, outOV, outF : std_logic := '0';
        variable haveCyOv : boolean := false;
        variable zero, lt : std_logic;
        variable cin : std_logic;
    begin

        op1 := inA; op2 := inB;

        case d.alu_func is

            -- Add/Sub...
            when AF_ADD | AF_ADC | AF_SUB =>
                if (d.alu_func = AF_ADC) then
                    cin := spr.SR(CY);
                elsif (d.alu_func = AF_SUB) then
                    op2 := not op2;
                    cin := '1';
                else
                    cin := '0';
                end if;

                res_add := ('0' & unsigned(op1)) + ('0' & unsigned(op2)) + (X"00000000" & cin);

                if (d.alu_func /= AF_SUB) then
                    outOV := (inA(31) and inB(31) and not res_add(31)) or (not inA(31) and not inB(31) and res_add(31));
                    outCY := res_add(32);
                else
                    outOV := (not inA(31) and inB(31) and res_add(31)) or (inA(31) and not inB(31) and not res_add(31));
                    outCY := not res_add(32);
                end if;

                -- compute comparison flag 'outFlag'...
                zero := conv_std_logic(res_add(31 downto 0) = X"00000000");
                if (d.ex_signed = '1') then
                    lt := (outCY and not (inA(31) xor inB(31))) or (inA(31) and not inB(31));
                else
                    lt := outCY;
                end if;

                case d.ex_comp_mode is
                    when COMP_EQU => outF := zero;              -- equal
                    when COMP_NEQ => outF := not zero;          -- not equal
                    when COMP_LTH => outF := lt;                -- less than
                    when COMP_LEQ => outF := lt xor zero;       -- less or equal
                    when COMP_GTH => outF := not lt xor zero;   -- greater than
                    when COMP_GEQ => outF := not lt;            -- greater or equal
                    when others => outF := '-';
                end case;

                haveCyOv := true;
                alu_res := std_logic_vector(res_add(31 downto 0));

            -- Logical...
            when AF_AND =>
                alu_res := op1 and op2;
            when AF_OR =>
                alu_res := op1 or op2;
            when AF_XOR =>
                alu_res := op1 xor op2;

            -- Byte & half word extensions...
            when AF_EXT =>
                if (d.ex_bhw_sel = '0') then -- half word
                    alu_res(15 downto 0) := op1(15 downto 0);
                    if (d.ex_bhw_exts = '0' and op1(15) = '1') then
                        alu_res(31 downto 16) := (others => '1');
                    else
                        alu_res(31 downto 16) := (others => '0');
                    end if;
                else -- byte
                    alu_res(7 downto 0) := op1(7 downto 0);
                    if (d.ex_bhw_exts = '0' and op1(7) = '1') then
                        alu_res(31 downto 8) := (others => '1');
                    else
                        alu_res(31 downto 8) := (others => '0');
                    end if;
                end if;

            -- MOVHI...
            when AF_MOVHI =>
                alu_res := op2;
            -- CMOV...
            when AF_CMOV =>
                if (spr.SR(F) = '1') then
                    alu_res := op1;
                else
                    alu_res := op2;
                end if;
            -- unimplemented...
            -- when AF_DIV | AF_DIVU | AF_FX1 =>
            when others =>
                alu_res := (others => '-');
                -- pragma translate_off
                assert false report "EXU(" & str(CPU_ID) & ") illegal ALU operation";
                -- pragma translate_on
                null;
        end case;

        -- Write back results as requested...
        if (set_cy_ov = '1' and haveCyOv) then
            vs(CY) := outCY;
            vs(OV) := outOV;
        end if;
        if (set_f = '1') then
            vs(F) := outF;
        end if;

        alu_out := (alu_res);

    end procedure;

    signal r, rin : registers;
    signal spr, sprin : special_purpose_registers;

    signal rfi : regfile_in_type;
    signal rfo : regfile_out_type;

    signal shfti : shift_in_type;
    signal shfto : shift_out_type;

    signal muli : mul_in_type;
    signal mulo : mul_out_type;

begin

    -- pragma translate_off
    printf : or1ksim_putchar
    generic map (CPU_ID)
    port map (clk, ifuo.ir);

    debug_gen : if (CFG_DBG_INSN_TRACE_CPU_MASK_SLV(CPU_ID) = '1') generate
        disas : orbis32_disas
        generic map (CPU_ID)
        port map (clk, ifuo.ir, ifuo.pc);
    end generate;
    -- pragma translate_on

    comb : process (r, spr, reset, ifuo, lsuo, rfo, shfto, mulo)

        variable v : registers;
        variable vspr : special_purpose_registers;
        variable vifui : ifu_in_type;
        variable vlsui : lsu_in_type;
        variable vrfi : regfile_in_type;
        variable vshfti : shift_in_type;
        variable vmuli : mul_in_type;

        -- EXCEPTION
        variable xc_id : std_logic_vector(3 downto 0);
        variable xc_pc_stage_id : std_logic_vector(1 downto 0);
        variable xc_in_delay_slot : std_logic;
        variable xc_jump_addr : TWord;
        variable xc_assert, xc_jump, xc_skip_delay_slot, xc_save_eear : std_logic;
        variable xc_exceptions : exceptions_type;

        -- EXECUTE
        variable ex_alu_in_1, ex_alu_in_2 : TWord;
        variable ex_alu_res, ex_shift_res, ex_result : TWord;
        variable ex_jump_addr : TWord;
        variable ex_nexti : std_logic;
        variable ex_rf_write : std_logic;
        variable ex_jump : std_logic;
        variable ex_rfe_jump : std_logic;
        variable ex_mem_load : std_logic;
        variable ex_skip_delay_slot : std_logic;

        -- IDECODE
        variable vd : decode_reg_type;
        variable id_nexti_invalid : std_logic;
        variable id_rsel_a, id_rsel_b : std_logic_vector(4 downto 0);
        variable id_a, id_b, id_imm : TWord;
        variable id_alu_src_a : AA_SRC;
        variable id_alu_src_b : AB_SRC;
        variable id_next_in_delay_slot : std_logic;

        -- IFETCH
        variable vf : fetch_reg_type;

    begin

        v := r;
        vspr := spr;

        --------------------------------------------------------------------------------
        -- Exception stage
        --------------------------------------------------------------------------------

        xc_id := X"0";
        xc_jump := '0'; xc_skip_delay_slot := '0';
        xc_assert := '0';

        xc_exceptions := (T_XC_RESET => reset, T_XC_ILL_OP => r.d.ill_op,
        T_XC_ALIGN => lsuo.align_err, T_XC_SYS_CALL => r.d.sys, T_XC_TRAP => r.d.trap,
        others => '0');
        exception_detect(r, spr, xc_exceptions, xc_id, xc_pc_stage_id,
        xc_in_delay_slot, xc_save_eear);
        xc_jump_addr := X"00000" & r.x.id & X"00";

        case r.x.state is
            when S_XC_INIT =>
                if (xc_id /= X"0") then
                    xc_assert := '1';
                    v.x.id := xc_id;
                    v.x.pc_stage_id := xc_pc_stage_id;
                    v.x.in_delay_slot := xc_in_delay_slot;
                    v.x.save_eear := xc_save_eear;
                    --exception_save_registers(r, xc_pc_stage_id, xc_in_delay_slot, xc_save_eear, spr, ifuo, vspr);
                    v.x.state := S_XC_FLUSH_PIPL;
                end if;
            when S_XC_FLUSH_PIPL =>
                -- All issued instructions are required to complete
                xc_assert := '1';
                if (r.e.state = S_EX_INIT) then
                    exception_save_registers(r, spr, ifuo, vspr);
                    xc_jump := '1';
                    v.x.state := S_XC_JUMP;
                end if;
            when S_XC_JUMP =>
                xc_assert := '1';
                xc_skip_delay_slot := '1';
                v.x.state := S_XC_INIT;
        end case;

        --------------------------------------------------------------------------------
        -- Execute stage
        -- Control of execute stage encompasses all stages that follow (MEM, WB)
        --------------------------------------------------------------------------------

        alu_hist_ctrl.start <= '0';
        alu_hist_ctrl.stop <= '0';
        alu_hist_ctrl.abort <= '0';
        shift_hist_ctrl.start <= '0';
        shift_hist_ctrl.stop <= '0';
        shift_hist_ctrl.abort <= '0';
        mul_hist_ctrl.start <= '0';
        mul_hist_ctrl.stop <= '0';
        mul_hist_ctrl.abort <= '0';
        load_hist_ctrl.start <= '0';
        load_hist_ctrl.stop <= '0';
        load_hist_ctrl.abort <= '0';
        store_hist_ctrl.start <= '0';
        store_hist_ctrl.stop <= '0';
        store_hist_ctrl.abort <= '0';
        jump_hist_ctrl.start <= '0';
        jump_hist_ctrl.stop <= '0';
        jump_hist_ctrl.abort <= '0';
        other_hist_ctrl.start <= '0';
        other_hist_ctrl.stop <= '0';
        other_hist_ctrl.abort <= '0';

        vrfi.wr_en := '0'; 
        vshfti.start := '0'; vmuli.start := '0';
        vlsui.rd := '0'; vlsui.wr := '0'; vlsui.flush := '0'; vlsui.cache_invalidate := '0'; vlsui.cache_writeback := '0';

        ex_jump := '0'; ex_rfe_jump := '0'; ex_nexti := '0';
        ex_mem_load := '0'; ex_rf_write := '0'; ex_skip_delay_slot := '0';

        case r.e.state is
            when S_EX_INIT =>
                if (du_stall = '0') then
                    case r.d.ex_op is
                        when EX_OP_JUMP =>
                            jump_hist_ctrl.start <= '1';
                            -- needs one cycle to calculate jump address
                            ex_rf_write := r.d.wb_jump_linked;
                            v.e.state := S_EX_JUMP;
                        when EX_OP_LS =>
                            if (r.d.mem_lsu_load = '1') then
                                load_hist_ctrl.start <= '1';
                            elsif (r.d.mem_lsu_store = '1') then
                                store_hist_ctrl.start <= '1';
                            end if;
                            -- needs one cycle to calculate L/S address
                            v.e.state := S_EX_LS_MEM_STALL;
                        when EX_OP_ALU =>
                            alu_hist_ctrl.start <= '1';
                            v.e.state := S_EX_ALU_WB;
                        when EX_OP_SHIFT =>
                            shift_hist_ctrl.start <= '1';
                            if (CFG_EXU_SHIFT_IMPL = 0) then
                                vshfti.start := '1';
                                v.e.state := S_EX_SHIFT_STALL;
                            else
                                v.e.state := S_EX_SHIFT_WB;
                            end if;
                        when EX_OP_MUL =>
                            mul_hist_ctrl.start <= '1';
                            vmuli.start := '1';
                            v.e.state := S_EX_MUL_STALL;
                        when EX_OP_SETSPR =>
                            other_hist_ctrl.start <= '1';
                            v.e.state := S_EX_SPR_WB1;
                        when EX_OP_RFE =>
                            other_hist_ctrl.start <= '1';
                            ex_rfe_jump := '1';
                            vspr.sr := spr.ESR;
                            v.e.state := S_EX_RFE;
                        when others => -- incl. EX_OP_NOP...
                            if (CFG_NUT_HISTOGRAM) then
                                if (r.d.insn_valid = '1') then
                                    other_hist_ctrl.start <= '1';
                                    other_hist_ctrl.stop <= '1';
                                end if;
                            end if;
                            if (r.d.halt = '1') then
                                v.mode := "00";
                                -- pragma translate_off
                                if (not monitor(CPU_ID).halted) then
                                    monitor(CPU_ID).halted <= true;
                                    INFO("EXU(" & integer'image(CPU_ID) & ") halted.");
                                end if;
                                -- pragma translate_on
                            else
                                ex_nexti := '1';
                            end if;
                    end case;
                end if;
            when S_EX_RFE =>
                other_hist_ctrl.stop <= '1';
                ex_skip_delay_slot := '1';
                ex_nexti := '1';
                v.e.state := S_EX_INIT;
            when S_EX_ALU_WB =>
                alu_hist_ctrl.stop <= '1';
                ex_rf_write := r.d.wb_set_reg_d;
                ex_nexti := '1';
                v.e.state := S_EX_INIT;
            when S_EX_JUMP =>
                jump_hist_ctrl.stop <= '1';
                ex_jump := '1';
                ex_nexti := '1';
                v.e.state := S_EX_INIT;
            when S_EX_LS_MEM_STALL =>
                vlsui.rd := r.d.mem_lsu_load;
                vlsui.wr := r.d.mem_lsu_store;
                vlsui.flush := r.d.mem_lsu_flush;
                if (lsuo.ack = '1') then
                    if (r.d.mem_lsu_flush = '1') then
                        v.e.state := S_EX_CACHE_INVALIDATE_1;
                    elsif (r.d.mem_lsu_load = '1') then
                        -- data arrives in the next cycle...
                        v.e.state := S_EX_LOAD_MEM;
                    else
                        -- One could already assert 'ex_nexti' here but doing so yields
                        -- a long critical path from MEMU -> LSU -> EXU -> IFU,
                        -- so no mealy here based on 'lsuo.ack'!
                        v.e.state := S_EX_LS_WB;
                    end if;
                elsif (lsuo.align_err = '1') then
                    v.e.state := S_EX_INIT;
                end if;
            when S_EX_CACHE_INVALIDATE_1 =>
                -- wait cycle
                v.e.state := S_EX_CACHE_INVALIDATE_2;
            when S_EX_CACHE_INVALIDATE_2 =>
                vlsui.cache_invalidate := r.d.mem_lsu_cache_invalidate;
                vlsui.cache_writeback := r.d.mem_lsu_cache_writeback;
                if (lsuo.ack = '1') then
                    v.e.state := S_EX_LS_WB;
                end if;
            when S_EX_LOAD_MEM =>
                load_hist_ctrl.stop <= '1';
                --ex_mem_load := '1';
                ex_rf_write := r.d.wb_set_reg_d;
                --v.e.state := S_EX_LS_WB;
                ex_nexti := '1';
                v.e.state := S_EX_INIT;
            when S_EX_LS_WB =>
                --if (r.d.mem_lsu_load = '1') then
                --    load_hist_ctrl.stop <= '1';
                --elsif (r.d.mem_lsu_store = '1') then
                    store_hist_ctrl.stop <= '1';
                --end if;
                --ex_rf_write := r.d.wb_set_reg_d;
                ex_nexti := '1';
                v.e.state := S_EX_INIT;
            when S_EX_SHIFT_STALL =>
                if (shfto.rdy = '1') then
                    v.e.state := S_EX_SHIFT_WB;
                end if;
            when S_EX_SHIFT_WB =>
                shift_hist_ctrl.stop <= '1';
                ex_rf_write := '1';
                ex_nexti := '1';
                v.e.state := S_EX_INIT;
            when S_EX_MUL_STALL =>
                if (mulo.rdy = '1') then
                    v.e.state := S_EX_MUL_WB;
                end if;
            when S_EX_MUL_WB =>
                mul_hist_ctrl.stop <= '1';
                ex_rf_write := '1';
                ex_nexti := '1';
                v.e.state := S_EX_INIT;
            when S_EX_SPR_WB1 =>
                vspr := set_spr(r.e.wb_result(15 downto 0), r.d.b, spr);
                -- pragma translate_off
                monitor(CPU_ID).sr <= vspr.sr;
                -- pragma translate_on
                v.e.state := S_EX_SPR_WB2;
            when S_EX_SPR_WB2 =>
                other_hist_ctrl.stop <= '1';
                -- This state is to wait for the WB to SPR to have completed,
                -- because forwarding the SPR to insn_decode seriously hurts
                -- performance. Alternatively, make decisions based on SPR in execute stage?
                ex_nexti := '1';
                v.e.state := S_EX_INIT;
            when others =>
        end case;

        --ex_alu_in_1 := alu_input_mux(r.d.alu_src_a, r.d.a, r.d.pc);
        --ex_alu_in_2 := alu_input_mux(r.d.alu_src_b(3), r.d.b, r.d.imm);
        ex_alu_in_1 := r.d.alu_in_1; ex_alu_in_2 := r.d.alu_in_2;

        vshfti.value := ex_alu_in_1; vshfti.cnt := ex_alu_in_2(4 downto 0); vshfti.mode := r.d.ex_shift_mode;
        vmuli.signed := r.d.ex_signed; vmuli.a := ex_alu_in_1; vmuli.b := ex_alu_in_2;

        run_alu(r.d, spr, ex_alu_in_1, ex_alu_in_2, r.d.ex_set_cy_ov, r.d.ex_set_f,
        vspr.sr, ex_alu_res);

        -- pragma translate_off
        monitor(CPU_ID).sr(F) <= vspr.sr(F);
        -- pragma translate_on

        -- result mux
        case r.d.ex_res_sel is
            when EX_RES_SHIFT => ex_result := shfto.dout;
            when EX_RES_MUL => ex_result := mulo.p;
            when EX_RES_REG => ex_result := r.d.b;
            when others => ex_result := ex_alu_res;
        end case;

        v.e.wb_result := ex_result;
        ex_jump_addr := r.e.wb_result;

        --------------------------------------------------------------------------------
        -- Memory (no actual stage for now, controlled by execute stage)
        --------------------------------------------------------------------------------

        --if (ex_mem_load = '1') then
        --    v.m.mem_data := lsuo.rdata;
        --end if;

        vlsui.adr := r.e.wb_result;
        vlsui.width := r.d.mem_lsu_width;
        vlsui.wdata := r.d.b;
        vlsui.exts := r.d.mem_lsu_exts;

        --------------------------------------------------------------------------------
        -- Write back (no actual stage for now, controlled by execute stage)
        --------------------------------------------------------------------------------

        if (ex_rf_write = '1') then
            vrfi.wr_en := '1';
        end if;

        case r.d.wb_jump_linked is
            when '1' =>
                -- save to link register
                vrfi.wr_addr := conv_std_logic_vector(LINK_REGISTER, GPRS_LD);
            when others =>
                vrfi.wr_addr := r.d.wb_rsel_d;
        end case;

        -- regfile write back mux
        case r.d.wb_wdata_sel is
            when RF_WRD_NPC =>
                -- save link address
                vrfi.wr_data := ifuo.npc;
            when RF_WRD_LOAD =>
                --vrfi.wr_data := r.m.mem_data;
                vrfi.wr_data := lsuo.rdata;
            when RF_WRD_SPR =>
                vrfi.wr_data := get_spr(r.e.wb_result(15 downto 0), r, spr, ifuo);
            when others => -- incl. RF_WRD_EX_RES
                vrfi.wr_data := r.e.wb_result;
        end case;

        --------------------------------------------------------------------------------
        -- Decode/Register stage
        --------------------------------------------------------------------------------

        -- next instruction not valid?
        id_nexti_invalid := not ifuo.ir_valid or xc_assert or ex_skip_delay_slot or ex_jump;
        insn_decode(r, spr, ifuo, id_nexti_invalid, vd, id_rsel_a, id_rsel_b,
        id_alu_src_a, id_alu_src_b, id_next_in_delay_slot);
        vrfi.rd_addr1 := id_rsel_a; vrfi.rd_addr2 := id_rsel_b;
        id_a := rfo.rd_data1; id_b := rfo.rd_data2;
        -- hard wired zero for R0...
        if (id_rsel_a = "00000") then id_a := (others => '0'); end if;
        if (id_rsel_b = "00000") then id_b := (others => '0'); end if;
        id_imm := immediate_sign_extend(id_alu_src_b, ifuo.ir);
        vd.b := id_b;
        --vd.a := id_a; vd.imm := id_imm; vd.alu_src_a := id_alu_src_a; vd.alu_src_b := id_alu_src_b;

        vd.alu_in_1 := alu_input_mux(id_alu_src_a, id_a, vd.pc);
        vd.alu_in_2 := alu_input_mux(id_alu_src_b(3), id_b, id_imm);

        -- pragma translate_off
        monitor(CPU_ID).insn_issued <= false;
        if (id_nexti_invalid = '0' and ex_nexti = '1') then
            monitor(CPU_ID).insn_issued <= true;
        end if;
        -- pragma translate_on

        if (ex_nexti = '1') then
            v.d := vd;
        end if;

        --------------------------------------------------------------------------------
        -- Instruction fetch stage (controls IFU)
        --------------------------------------------------------------------------------

        vifui.jump := xc_jump or ex_rfe_jump or ex_jump;
        vifui.nexti := xc_skip_delay_slot or ex_skip_delay_slot or (ex_nexti and not ex_jump and not id_nexti_invalid);

        if (xc_jump = '1') then
            vifui.jump_adr := xc_jump_addr;
        elsif (ex_rfe_jump = '1') then
            vifui.jump_adr := spr.EPCR;
        else
            vifui.jump_adr := ex_jump_addr;
        end if;

        if (ex_nexti = '1') then
            v.f.in_delay_slot := id_next_in_delay_slot;
        end if;

        if (ex_nexti = '1' and id_nexti_invalid = '0') then
            v.x.pc := r.d.pc;
        end if;

        --------------------------------------------------------------------------------
        -- reset...
        --------------------------------------------------------------------------------

        if (reset = '1') then
            if (CEPU_FLAG) then
                v.mode := "11";
            else
                v.mode := "00";
            end if;
            v.f.in_delay_slot := '0';
            v.d.ex_op := EX_OP_NOP;
            v.d.halt := '0';
            v.e.state := S_EX_INIT;
            v.x.state := S_XC_INIT;
            vspr.SR := X"00008001";
            --vspr.PNCE := X"00000001";
            --vspr.PNLM := (others => '0');
            --vspr.PNX := (others => '0');
            if (CFG_NUT_HISTOGRAM) then
                vspr.HIST_CTRL := (others => '0');
            end if;
            vifui.nexti := '0';
        end if;

        if (CFG_NUT_HISTOGRAM) then
            vifui.hist_enable := spr.HIST_CTRL(0);
            vlsui.hist_enable := spr.HIST_CTRL(0);
        end if;

        rin <= v;
        sprin <= vspr;
        rfi <= vrfi;
        shfti <= vshfti;
        muli <= vmuli;
        ifui <= vifui;
        lsui <= vlsui;

    end process;

    icache_enable <= spr.SR(ICE);
    dcache_enable <= spr.SR(DCE);

    process (clk)
    begin
        if (clk'event and clk = '1') then
            r <= rin;
            spr <= sprin;
        end if;
    end process;

    regfile_0 : regfile
    generic map (AWIDTH => GPRS_LD, DWIDTH => 32, CPU_ID => CPU_ID)
    port map (clk, rfi, rfo);

    shift32_0 : shift32
    generic map (SHIFT_IMPL => CFG_EXU_SHIFT_IMPL)
    port map (clk, reset, shfti, shfto);

    mul32_0 : mult32x32s
    generic map (MUL_PIPE_STAGES => CFG_EXU_MUL_PIPE_STAGES)
    port map (clk, reset, muli, mulo);

    -- Histograms...
    hist_gen : if (CFG_NUT_HISTOGRAM) generate
        alu_hi.ctrl <= alu_hist_ctrl;
        alu_hi.enable <= spr.HIST_CTRL(0);
        alu_hi.addr <= r.e.wb_result;
        alu_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, alu_hi, alu_ho);

        shift_hi.ctrl <= shift_hist_ctrl;
        shift_hi.enable <= spr.HIST_CTRL(0);
        shift_hi.addr <= r.e.wb_result;
        shift_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, shift_hi, shift_ho);

        mul_hi.ctrl <= mul_hist_ctrl;
        mul_hi.enable <= spr.HIST_CTRL(0);
        mul_hi.addr <= r.e.wb_result;
        mul_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, mul_hi, mul_ho);

        load_hi.ctrl <= load_hist_ctrl;
        load_hi.enable <= spr.HIST_CTRL(0);
        load_hi.addr <= r.e.wb_result;
        load_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, load_hi, load_ho);

        store_hi.ctrl <= store_hist_ctrl;
        store_hi.enable <= spr.HIST_CTRL(0);
        store_hi.addr <= r.e.wb_result;
        store_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, store_hi, store_ho);

        jump_hi.ctrl <= jump_hist_ctrl;
        jump_hi.enable <= spr.HIST_CTRL(0);
        jump_hi.addr <= r.e.wb_result;
        jump_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, jump_hi, jump_ho);

        other_hi.ctrl <= other_hist_ctrl;
        other_hi.enable <= spr.HIST_CTRL(0);
        other_hi.addr <= r.e.wb_result;
        other_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, other_hi, other_ho);

        ifu_hi.ctrl <= ifuo.hist_ctrl;
        ifu_hi.enable <= spr.HIST_CTRL(0);
        ifu_hi.addr <= r.e.wb_result;
        ifu_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, ifu_hi, ifu_ho);

        hist_busif_gen : if (CPU_ID = 0) generate
            clf_hi.ctrl <= emhci.cache_line_fill;
            clf_hi.addr <= r.e.wb_result;
            clf_hi.enable <= spr.HIST_CTRL(0);
            clf_hist : mhistogram
            generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
            port map (clk, reset, clf_hi, clf_ho);

            clwb_hi.ctrl <= emhci.cache_line_wb;
            clwb_hi.addr <= r.e.wb_result;
            clwb_hi.enable <= spr.HIST_CTRL(0);
            clwb_hist : mhistogram
            generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
            port map (clk, reset, clwb_hi, clwb_ho);
        end generate;

        crhi_hi.ctrl <= emhci.cache_read_hit_ifu;
        crhi_hi.addr <= r.e.wb_result;
        crhi_hi.enable <= spr.HIST_CTRL(0);
        crhi_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, crhi_hi, crhi_ho);

        crmi_hi.ctrl <= emhci.cache_read_miss_ifu;
        crmi_hi.addr <= r.e.wb_result;
        crmi_hi.enable <= spr.HIST_CTRL(0);
        crmi_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, crmi_hi, crmi_ho);

        crhl_hi.ctrl <= emhci.cache_read_hit_lsu;
        crhl_hi.addr <= r.e.wb_result;
        crhl_hi.enable <= spr.HIST_CTRL(0);
        crhl_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, crhl_hi, crhl_ho);

        crml_hi.ctrl <= emhci.cache_read_miss_lsu;
        crml_hi.addr <= r.e.wb_result;
        crml_hi.enable <= spr.HIST_CTRL(0);
        crml_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, crml_hi, crml_ho);

        cwhl_hi.ctrl <= emhci.cache_write_hit_lsu;
        cwhl_hi.addr <= r.e.wb_result;
        cwhl_hi.enable <= spr.HIST_CTRL(0);
        cwhl_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, cwhl_hi, cwhl_ho);

        cwml_hi.ctrl <= emhci.cache_write_miss_lsu;
        cwml_hi.addr <= r.e.wb_result;
        cwml_hi.enable <= spr.HIST_CTRL(0);
        cwml_hist : mhistogram
        generic map (HIST_BINS_LD => MAX_HIST_BINS_LD)
        port map (clk, reset, cwml_hi, cwml_ho);
    end generate;

end RTL;
