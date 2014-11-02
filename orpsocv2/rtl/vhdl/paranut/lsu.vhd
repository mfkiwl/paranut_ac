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
--  Component and type declarations for the mlsu and mlsu_simple modules
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.paranut_config.all;
use paranut.types.all;
use paranut.memu_lib.all;

package lsu is

    type lsu_in_type is record
        rd               : std_logic;
        wr               : std_logic;
        flush            : std_logic;
        cache_writeback  : std_logic;
        cache_invalidate : std_logic;
        rlink_wcond      : std_logic;
        width            : TLSUWidth;
        exts             : std_logic;
        adr              : TWord;
        wdata            : TWord;
        -- Histogram...
        hist_enable      : std_logic;
    end record;
    type lsu_in_vector is array (natural range <>) of lsu_in_type;

    type lsu_out_type is record
        ack           : std_logic;
        align_err     : std_logic;
        wcond_ok      : std_logic;
        rdata         : TWord;
        -- Histogram...
        buf_fill_hist : TWord_Vec(0 to 2**CFG_LSU_WBUF_SIZE_LD+1);
    end record;
    type lsu_out_vector is array (natural range <>) of lsu_out_type;

    component mlsu
        generic (
                    LSU_WBUF_SIZE_LD : integer range 2 to 4 := 2
                );
        port (
                 clk            : in std_logic;
                 reset          : in std_logic;
                 -- to EXU...
                 lsui           : in lsu_in_type;
                 lsuo           : out lsu_out_type;
                 -- to MEMU/read port...
                 rpi            : out readport_in_type;
                 rpo            : in readport_out_type;
                 -- to MEMU/write port...
                 wpi            : out writeport_in_type;
                 wpo            : in writeport_out_type;
                 -- from CePU...
                 dcache_enable  : in std_logic
             );
    end component;

    component mlsu_simple
        port (
                 clk            : in std_logic;
                 reset          : in std_logic;
                 -- to EXU...
                 lsui           : in lsu_in_type;
                 lsuo           : out lsu_out_type;
                 -- to MEMU/read port...
                 rpi            : out readport_in_type;
                 rpo            : in readport_out_type;
                 -- to MEMU/write port...
                 wpi            : out writeport_in_type;
                 wpo            : in writeport_out_type;
                 -- from CePU...
                 dcache_enable  : in std_logic
             );
    end component;

end package;
