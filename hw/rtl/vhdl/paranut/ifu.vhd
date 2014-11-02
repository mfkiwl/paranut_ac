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
--  Component and type declarations for the mifu module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.paranut_config.all;
use paranut.types.all;
use paranut.memu_lib.all;
use paranut.histogram.all;

package ifu is

    type ifu_in_type is record
        nexti       : std_logic;
        jump        : std_logic;
        -- (next, jump) = (1, 1) lets the (current + 2)'th instruction be the jump target.
        -- Logically, 'next' is performed before 'jump'. Hence, jump instructions may either sequentially first
        -- assert 'next' and then 'jump' or both signals in the same cycle. The former way is required for JAL instructions
        -- to get the right return address, which is PC+8 (or NPC+4).
        jump_adr    : TWord;
        -- Histogram...
        hist_enable : std_logic;
    end record;
    type ifu_in_vector is array (natural range <>) of ifu_in_type;

    type ifu_out_type is record
        ir            : TWord; -- registered outputs
        ppc           : TWord;
        pc            : TWord;
        npc           : TWord;
        ir_valid      : std_logic;
        npc_valid     : std_logic;
        -- Histogram...
        buf_fill_hist : TWord_Vec(0 to CFG_IFU_IBUF_SIZE+1);
        hist_ctrl     : hist_ctrl_type;
    end record;
    type ifu_out_vector is array (natural range <>) of ifu_out_type;

    component mifu
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
                 icache_enable   : in std_logic
             );
    end component;

    component mifu_bs
        generic (
                    IFU_BUF_SIZE : integer range 4 to 16 := 4
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
                 icache_enable   : in std_logic
             );
    end component;

end package;
