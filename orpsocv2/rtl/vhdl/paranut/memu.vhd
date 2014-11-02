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
--  Component and type declarations for the mmemu module (see memu_lib.vhd for
--  readport, writeport, and busif type declarations)
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.memu_lib.all;
use paranut.histogram.all;

package memu is

    type memu_hist_ctrl_type is record
        cache_line_fill  : hist_ctrl_type;
        cache_line_wb    : hist_ctrl_type;
        cache_read_hit   : hist_ctrl_vector(0 to RPORTS-1);
        cache_read_miss  : hist_ctrl_vector(0 to RPORTS-1);
        cache_write_hit  : hist_ctrl_vector(0 to WPORTS-1);
        cache_write_miss : hist_ctrl_vector(0 to WPORTS-1);
    end record;

    type memu_in_type is record
        -- Bus interface (Wishbone)...
        bifwbi : busif_wishbone_in_type;
        -- Read ports...
        -- ports 0 .. WPORT-1 are considered to be data ports, the others to be instruction ports (with lower priority)
        rpi    : readport_in_vector(0 to RPORTS-1);
        -- Write ports...
        wpi    : writeport_in_vector(0 to WPORTS-1);
    end record;

    type memu_out_type is record
        bifwbo : busif_wishbone_out_type;
        rpo    : readport_out_vector(0 to RPORTS-1);
        wpo    : writeport_out_vector(0 to WPORTS-1);
        mhco   : memu_hist_ctrl_type;
    end record;

    component mmemu
        --generic (
        --            CFG_MEMU_CACHE_BANKS : integer := 1;
        --            RPORTS      : integer := 2;
        --            WPORTS      : integer := 1
        --        );
        port (
                 clk    : in std_logic;
                 reset  : in std_logic;
                 mi     : in memu_in_type;
                 mo     : out memu_out_type
             );
    end component;

end package;
