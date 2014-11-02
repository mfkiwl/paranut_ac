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
--  Component and type declarations for the mexu module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.types.all;
use paranut.ifu.all;
use paranut.lsu.all;
use paranut.histogram.all;

package exu is

    type regfile_in_type is record
        wr_en    : std_logic;
        wr_addr  : std_logic_vector(4 downto 0);
        wr_data  : std_logic_vector(31 downto 0);
        rd_addr1 : std_logic_vector(4 downto 0);
        rd_addr2 : std_logic_vector(4 downto 0);
    end record;

    type regfile_out_type is record
        rd_data1 : std_logic_vector(31 downto 0);
        rd_data2 : std_logic_vector(31 downto 0);
    end record;

    type shift_in_type is record
        start   : std_logic;
        value   : std_logic_vector(31 downto 0);
        cnt     : std_logic_vector(4 downto 0);
        mode    : std_logic_vector(1 downto 0);
    end record;

    type shift_out_type is record
        dout : std_logic_vector(31 downto 0);
        rdy  : std_logic;
    end record;

    type mul_in_type is record
        a       : std_logic_vector(31 downto 0);
        b       : std_logic_vector(31 downto 0);
        start   : std_logic;
        signed  : std_logic;
    end record;

    type mul_out_type is record
        p   : std_logic_vector(31 downto 0);
        rdy : std_logic;
    end record;

    component regfile
        generic (
                    AWIDTH : integer := 5;
                    DWIDTH : integer := 32;
                    CPU_ID : integer := 0
                );
        port (
                 clk : in std_logic;
                 rfi : in regfile_in_type;
                 rfo : out regfile_out_type
             );
    end component;

    component shift32 is
        generic (
                    SHIFT_IMPL : integer range 0 to 2 := 0 -- 0 : serial shifter, 1 : generic implementation, 2 : barrell shifter
                );
        port (
                 clk    : in std_logic;
                 reset  : in std_logic;
                 shfti   : in shift_in_type;
                 shfto   : out shift_out_type
             );
    end component;

    component mult32x32s is
        generic (
                    MUL_PIPE_STAGES : integer range 1 to 5 := 2;
                    IN_REG : integer range 0 to 1 := 0
                );
        port (
                 clk    : in std_logic;
                 reset  : in std_logic;
                 muli   : in mul_in_type;
                 mulo   : out mul_out_type
             );
    end component;

    type exu_debug_unit_in_type is record
        du_stall : std_logic;
    end record;

    type exu_memu_hist_ctrl_in_type is record
        cache_line_fill      : hist_ctrl_type;
        cache_line_wb        : hist_ctrl_type;
        cache_read_hit_ifu   : hist_ctrl_type;
        cache_read_miss_ifu  : hist_ctrl_type;
        cache_read_hit_lsu   : hist_ctrl_type;
        cache_read_miss_lsu  : hist_ctrl_type;
        cache_write_hit_lsu  : hist_ctrl_type;
        cache_write_miss_lsu : hist_ctrl_type;
    end record;
    type exu_memu_hist_ctrl_in_vector is array (natural range <>) of exu_memu_hist_ctrl_in_type;

    component mexu
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
    end component;

end package;
