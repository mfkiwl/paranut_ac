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
--  ParaNut top level module. Contains EXU, LSU, IFU, MEMU.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.paranut_config.all;
use paranut.types.all;
use paranut.memu.all;
use paranut.ifu.all;
use paranut.lsu.all;
use paranut.exu.all;

-- pragma translate_off
use paranut.text_io.all;
use paranut.txt_util.all;
-- pragma translate_on

entity mparanut is
    --generic (
    --            CFG_NUT_CPU_CORES   : integer := 1;
    --            CFG_MEMU_CACHE_BANKS : integer := 1
    --        );
    port (
             -- Ports (WISHBONE master)
             clk_i    : in std_logic;
             rst_i    : in std_logic;
             ack_i    : in std_logic;                     -- normal termination
             err_i    : in std_logic;                     -- termination w/ error
             rty_i    : in std_logic;                     -- termination w/ retry
             dat_i    : in TWord;                         -- input data bus
             cyc_o    : out std_logic;                    -- cycle valid output
             stb_o    : out std_logic;                    -- strobe output
             we_o     : out std_logic;                    -- indicates write transfer
             sel_o    : out TByteSel;                     -- byte select outputs
             adr_o    : out TWord;                        -- address bus outputs
             dat_o    : out TWord;                        -- output data bus
             cti_o    : out std_logic_vector(2 downto 0); -- cycle type identifier
             bte_o    : out std_logic_vector(1 downto 0); -- burst type extension
             -- Other
             du_stall : in std_logic
         );
end mparanut;

architecture RTL of mparanut is

    -- MEMU: busif, read ports (rp), write ports (wp)
    signal mi : memu_in_type;
    signal mo : memu_out_type;
    -- IFU
    signal ifui : ifu_in_vector(0 to CFG_NUT_CPU_CORES-1);
    signal ifuo : ifu_out_vector(0 to CFG_NUT_CPU_CORES-1);
    -- LSU
    signal lsui : lsu_in_vector(0 to CFG_NUT_CPU_CORES-1);
    signal lsuo : lsu_out_vector(0 to CFG_NUT_CPU_CORES-1);
    -- others
    signal icache_enable, dcache_enable: std_logic;

    -- Histogram
    signal emhci : exu_memu_hist_ctrl_in_vector(0 to CFG_NUT_CPU_CORES-1);

    -- pragma translate_off
    signal lsui_reg : lsu_in_vector(0 to CFG_NUT_CPU_CORES-1);
    signal lsuo_reg : lsu_out_vector(0 to CFG_NUT_CPU_CORES-1);
    -- pragma translate_on

begin

    mi.bifwbi.ack_i <= ack_i;
    mi.bifwbi.err_i <= err_i;
    mi.bifwbi.rty_i <= rty_i;
    mi.bifwbi.dat_i <= dat_i;
    cyc_o <= mo.bifwbo.cyc_o;
    stb_o <= mo.bifwbo.stb_o;
    we_o <= mo.bifwbo.we_o;
    bsel_le : if (CFG_NUT_LITTLE_ENDIAN) generate
        sel_o <= mo.bifwbo.sel_o;
    end generate;
    bsel_be : if (not CFG_NUT_LITTLE_ENDIAN) generate
        sel_o(3) <= mo.bifwbo.sel_o(0);
        sel_o(2) <= mo.bifwbo.sel_o(1);
        sel_o(1) <= mo.bifwbo.sel_o(2);
        sel_o(0) <= mo.bifwbo.sel_o(3);
    end generate;
    adr_o <= mo.bifwbo.adr_o;
    dat_o <= mo.bifwbo.dat_o;
    cti_o <= mo.bifwbo.cti_o;
    bte_o <= mo.bifwbo.bte_o;

    MemU : mmemu
    port map (
                 clk => clk_i,
                 reset => rst_i,
                 mi => mi,
                 mo => mo
             );

    -- IFUs
    IFUs : for n in 0 to CFG_NUT_CPU_CORES-1 generate
        IFU : mifu
        generic map (IFU_BUF_SIZE_MIN => CFG_IFU_IBUF_SIZE)
        port map (
                     clk => clk_i,
                     reset => rst_i,
                     ifui => ifui(n),
                     ifuo => ifuo(n),
                     rpi => mi.rpi(CFG_NUT_CPU_CORES+n),
                     rpo => mo.rpo(CFG_NUT_CPU_CORES+n),
                     icache_enable => icache_enable
                 );
    end generate IFUs;

    -- LSUs
    LSUs : for n in 0 to CFG_NUT_CPU_CORES-1 generate
        LSUs_SIMPLE : if (CFG_LSU_SIMPLE) generate
            LSU : mlsu_simple
            port map (
                         clk => clk_i,
                         reset => rst_i,
                         lsui => lsui(n),
                         lsuo => lsuo(n),
                         rpi => mi.rpi(n),
                         rpo => mo.rpo(n),
                         wpi => mi.wpi(n),
                         wpo => mo.wpo(n),
                         dcache_enable => dcache_enable
                     );
        end generate;
        LSUs_COMPLEX : if (not CFG_LSU_SIMPLE) generate
            LSU : mlsu
            generic map (LSU_WBUF_SIZE_LD => CFG_LSU_WBUF_SIZE_LD)
            port map (
                         clk => clk_i,
                         reset => rst_i,
                         lsui => lsui(n),
                         lsuo => lsuo(n),
                         rpi => mi.rpi(n),
                         rpo => mo.rpo(n),
                         wpi => mi.wpi(n),
                         wpo => mo.wpo(n),
                         dcache_enable => dcache_enable
                     );
        end generate;
    end generate LSUs;

    hist_ctrl_gen : if (CFG_NUT_HISTOGRAM) generate
        hist_ctrl_in_gen : for n in 0 to CFG_NUT_CPU_CORES-1 generate
            hist_ctrl_in_gen_cepu : if (n = 0) generate
                emhci(n).cache_line_fill <= mo.mhco.cache_line_fill;
                emhci(n).cache_line_wb <= mo.mhco.cache_line_wb;
            end generate;
            emhci(n).cache_read_hit_ifu <= mo.mhco.cache_read_hit(CFG_NUT_CPU_CORES+n);
            emhci(n).cache_read_miss_ifu <= mo.mhco.cache_read_miss(CFG_NUT_CPU_CORES+n);
            emhci(n).cache_read_hit_lsu <= mo.mhco.cache_read_hit(n);
            emhci(n).cache_read_miss_lsu <= mo.mhco.cache_read_miss(n);
            emhci(n).cache_write_hit_lsu <= mo.mhco.cache_write_hit(n);
            emhci(n).cache_write_miss_lsu <= mo.mhco.cache_write_miss(n);
        end generate;
    end generate;

    -- EXUs
    EXUs : for n in 0 to CFG_NUT_CPU_CORES-1 generate
        EXUCePUs : if (n = 0) generate -- CePU
            EXUCePU : mexu
            generic map (
                            CEPU_FLAG => true,
                            CAPABILITY_FLAG => 3,
                            CPU_ID => n
                        )
            port map (
                         clk => clk_i,
                         reset => rst_i,
                         -- to IFU
                         ifui => ifui(n),
                         ifuo => ifuo(n),
                         -- to Load/Store Unit (LSU)
                         lsui => lsui(n),
                         lsuo => lsuo(n),
                         icache_enable => icache_enable,
                         dcache_enable => dcache_enable,
                         du_stall => du_stall,
                         emhci => emhci(n)
                     );
        end generate EXUCePUs;

        EXUCoPUs: if (n > 0) generate -- CoPUs
            EXUCoPU: mexu
            generic map (
                            CEPU_FLAG => false,
                            CAPABILITY_FLAG => 2,
                            CPU_ID => n
                        )
            port map (
                         clk => clk_i,
                         reset => rst_i,
                         -- to IFU
                         ifui => ifui(n),
                         ifuo => ifuo(n),
                         -- to Load/Store Unit (LSU)
                         lsui => lsui(n),
                         lsuo => lsuo(n),
                         icache_enable => open,
                         dcache_enable => open,
                         du_stall => du_stall,
                         emhci => emhci(n)
                     );
        end generate EXUCoPUs;

    end generate EXUs;

    -- pragma translate_off
    process (clk_i)
    begin
        if (clk_i'event and clk_i='1') then

            if (CFG_DBG_LSU_TRACE) then
                for n in 0 to CFG_NUT_CPU_CORES-1 loop
                    if (lsui_reg(n).rd = '1' and lsuo_reg(n).ack = '1') then
                        INFO("EXU(" & str(n) & ") LSU read:  " & hstr(lsui_reg(n).adr) &
                        " DATA: " & hstr(lsuo(n).rdata) &
                        " WIDTH: " & hstr(lsui_reg(n).width));
                    end if;
                    if (lsui(n).wr = '1' and lsui_reg(n).wr = '0') then
                        INFO("EXU(" & str(n) & ") LSU write: " & hstr(lsui(n).adr) &
                        " DATA: " & hstr(lsui(n).wdata) &
                        " WIDTH: " & hstr(lsui(n).width));
                    end if;
                end loop;
                lsui_reg <= lsui;
                lsuo_reg <= lsuo;
            end if;

            if (CFG_DBG_BUS_TRACE) then
                if (mi.bifwbi.ack_i = '1') then
                    if (mo.bifwbo.we_o = '0') then
                        INFO ("MEM read:  " & hstr(mo.bifwbo.adr_o) &
                        " DATA: " & hstr(mi.bifwbi.dat_i) &
                        " BSEL: " & hstr(mo.bifwbo.sel_o));
                    else
                        INFO ("MEM write: " & hstr(mo.bifwbo.adr_o) &
                        " DATA: " & hstr(mo.bifwbo.dat_o) &
                        " BSEL: " & hstr(mo.bifwbo.sel_o));
                    end if;
                end if;
            end if;

        end if;
    end process;
    -- pragma translate_on

end RTL;

