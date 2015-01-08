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
--  Bank RAM module for a single bank
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.paranut_config.all;
use paranut.types.all;
use paranut.memu_lib.all;
use paranut.mem_tech.all;

entity mbankram is
    port (
             clk : in std_logic;
             bri : in bankram_in_type;
             bro : out bankram_out_type
         );
end mbankram;

architecture rtl of mbankram is

begin

    bram_gen_1p : if CFG_MEMU_BANK_RAM_PORTS = 1 generate
        bankram : mem_sync_sp_inferred
        generic map (AWIDTH => CFG_MEMU_CACHE_SETS_LD+CFG_MEMU_CACHE_WAYS_LD,
                     DWIDTH => 32, WRITE_MODE => READ_FIRST)
        port map (clk, bri.wiadr(0), bri.wr(0), bri.wdata(0), bro.rdata(0));
    end generate;

    bram_gen_2p : if CFG_MEMU_BANK_RAM_PORTS = 2 generate
        bankram : mem_sync_true_dp_inferred
        generic map (AWIDTH => CFG_MEMU_CACHE_SETS_LD+CFG_MEMU_CACHE_WAYS_LD,
                     DWIDTH => 32, WRITE_MODE_1 => READ_FIRST, WRITE_MODE_2 =>
                     READ_FIRST)
        port map (clk, clk, bri.wiadr(0), bri.wiadr(CFG_MEMU_BANK_RAM_PORTS-1), bri.wr(0),
        bri.wr(CFG_MEMU_BANK_RAM_PORTS-1), bri.wdata(0), bri.wdata(CFG_MEMU_BANK_RAM_PORTS-1), bro.rdata(0),
        bro.rdata(CFG_MEMU_BANK_RAM_PORTS-1));
    end generate;

end rtl;
