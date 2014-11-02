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
--  Component and type declarations for the mem_inferred modules
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package mem_tech is

    constant READ_FIRST  : natural range 0 to 2 := 0;
    constant WRITE_FIRST : natural range 0 to 2 := 1;
    constant NO_CHANGE   : natural range 0 to 2 := 2;

    component mem_sync_sp_inferred is
        generic (
                    AWIDTH : integer := 10;
                    DWIDTH : integer := 32;
                    INITD  : integer := 0;
                    WRITE_MODE : natural range 0 to 2 := 0
                );
        port (
                 clk   : in std_logic;
                 addr  : in std_logic_vector(AWIDTH-1 downto 0);
                 we    : in std_logic;
                 wdata : in std_logic_vector(DWIDTH-1 downto 0);
                 rdata : out std_logic_vector(DWIDTH-1 downto 0)
             );
    end component;

    component mem_sync_simple_dp_inferred is
        generic (
                    AWIDTH : natural := 10;
                    DWIDTH : natural := 32;
                    INITD  : integer := 0
                );
        port (
                 clk   : in std_logic;
                 raddr : in std_logic_vector(AWIDTH-1 downto 0);
                 waddr : in std_logic_vector(AWIDTH-1 downto 0);
                 we    : in std_logic;
                 wdata : in std_logic_vector(DWIDTH-1 downto 0);
                 rdata : out std_logic_vector(DWIDTH-1 downto 0)
             );
    end component;

    component mem_sync_true_dp_inferred is
        generic (
                    AWIDTH : natural := 10;
                    DWIDTH : natural := 32;
                    INITD  : integer := 0;
                    WRITE_MODE_1 : natural range 0 to 2 := 0;
                    WRITE_MODE_2 : natural range 0 to 2 := 0
                );
        port (
                 clk1   : in std_logic;
                 clk2   : in std_logic;
                 addr1  : in std_logic_vector(AWIDTH-1 downto 0);
                 addr2  : in std_logic_vector(AWIDTH-1 downto 0);
                 we1    : in std_logic;
                 we2    : in std_logic;
                 wdata1 : in std_logic_vector(DWIDTH-1 downto 0);
                 wdata2 : in std_logic_vector(DWIDTH-1 downto 0);
                 rdata1 : out std_logic_vector(DWIDTH-1 downto 0);
                 rdata2 : out std_logic_vector(DWIDTH-1 downto 0)
             );
    end component;

    component mem_3p_async_dist_inferred
        generic (
                    AWIDTH : integer := 5;
                    DWIDTH : integer := 32
                );
        port (
                 wclk    : in std_logic;
                 waddr   : in std_logic_vector(AWIDTH-1 downto 0);
                 wdata   : in std_logic_vector(DWIDTH-1 downto 0);
                 we      : in std_logic;
                 raddr1  : in std_logic_vector(AWIDTH-1 downto 0);
                 rdata1  : out std_logic_vector(DWIDTH-1 downto 0);
                 raddr2  : in std_logic_vector(AWIDTH-1 downto 0);
                 rdata2  : out std_logic_vector(DWIDTH-1 downto 0)
             );
    end component;

    component mem_3p_async_dist_rfirst_inferred
        generic (
                    AWIDTH : integer := 5;
                    DWIDTH : integer := 32
                );
        port (
                 wclk    : in std_logic;
                 waddr   : in std_logic_vector(AWIDTH-1 downto 0);
                 wdata   : in std_logic_vector(DWIDTH-1 downto 0);
                 we      : in std_logic;
                 raddr1  : in std_logic_vector(AWIDTH-1 downto 0);
                 rdata1  : out std_logic_vector(DWIDTH-1 downto 0);
                 raddr2  : in std_logic_vector(AWIDTH-1 downto 0);
                 rdata2  : out std_logic_vector(DWIDTH-1 downto 0)
             );
    end component;

end package;
