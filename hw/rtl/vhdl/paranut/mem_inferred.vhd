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
--  Different types of synchronous and asynchronous memory
--
--------------------------------------------------------------------------------

-- single port synchronous memory (1 port for reading and writing)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_sync_sp_inferred is
    generic (
                AWIDTH : natural := 10;
                DWIDTH : natural := 32;
                INITD  : integer := 0;
                WRITE_MODE : natural range 0 to 2 := 0 -- 0: READ_FIRST, 1: WRITE_FIRST, 2: NO_CHANGE
            );
    port (
             clk   : in std_logic;
             addr  : in std_logic_vector(AWIDTH-1 downto 0);
             we    : in std_logic;
             wdata : in std_logic_vector(DWIDTH-1 downto 0);
             rdata : out std_logic_vector(DWIDTH-1 downto 0)
         );
end mem_sync_sp_inferred;

architecture rtl of mem_sync_sp_inferred is

    type mem_type is array (0 to 2**AWIDTH - 1) of std_logic_vector(DWIDTH-1 downto 0);
    shared variable mem : mem_type := (others => std_logic_vector(to_unsigned(INITD, DWIDTH)));

    attribute ram_style : string;
    attribute ram_style of mem : variable is "block";

begin
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (WRITE_MODE = 0) then
                rdata <= mem(to_integer(unsigned(addr)));
                if (we = '1') then
                    mem(to_integer(unsigned(addr))) := wdata;
                end if;
            end if;
            if (WRITE_MODE = 1) then
                if (we = '1') then
                    mem(to_integer(unsigned(addr))) := wdata;
                end if;
                rdata <= mem(to_integer(unsigned(addr)));
            end if;
            if (WRITE_MODE = 2) then
                if (we = '1') then
                    mem(to_integer(unsigned(addr))) := wdata;
                else
                    rdata <= mem(to_integer(unsigned(addr)));
                end if;
            end if;
        end if;
    end process;
end rtl;

--------------------------------------------------------------------------------

-- simple dual port synchronous memory (one port for reading only, the other
-- for writing only)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_sync_simple_dp_inferred is
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
end mem_sync_simple_dp_inferred;

architecture rtl of mem_sync_simple_dp_inferred is

    type mem_type is array (0 to 2**AWIDTH - 1) of std_logic_vector(DWIDTH-1 downto 0);
    shared variable mem : mem_type := (others => std_logic_vector(to_unsigned(INITD, DWIDTH)));

    attribute ram_style : string;
    attribute ram_style of mem : variable is "block";

begin
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (we = '1') then
                mem(to_integer(unsigned(waddr))) := wdata;
            end if;
            rdata <= mem(to_integer(unsigned(raddr)));
        end if;
    end process;
end rtl;

--------------------------------------------------------------------------------

-- true dual port synchronous memory (both ports can read/write with different clocks)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_sync_true_dp_inferred is
    generic (
                AWIDTH : natural := 10;
                DWIDTH : natural := 32;
                INITD  : integer := 0;
                WRITE_MODE_1 : natural range 0 to 2 := 0; -- 0: READ_FIRST, 1: WRITE_FIRST, 2: NO_CHANGE
                WRITE_MODE_2 : natural range 0 to 2 := 0 -- 0: READ_FIRST, 1: WRITE_FIRST, 2: NO_CHANGE
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
end mem_sync_true_dp_inferred;

architecture rtl of mem_sync_true_dp_inferred is

    type mem_type is array (0 to 2**AWIDTH - 1) of std_logic_vector(DWIDTH-1 downto 0);
    shared variable mem : mem_type := (others => std_logic_vector(to_unsigned(INITD, DWIDTH)));

    attribute ram_style : string;
    attribute ram_style of mem : variable is "block";

begin

    process (clk1)
    begin
        if (clk1'event and clk1 = '1') then
            if (WRITE_MODE_1 = 0) then
                rdata1 <= mem(to_integer(unsigned(addr1)));
                if (we1 = '1') then
                    mem(to_integer(unsigned(addr1))) := wdata1;
                end if;
            end if;
            if (WRITE_MODE_1 = 1) then
                if (we1 = '1') then
                    mem(to_integer(unsigned(addr1))) := wdata1;
                end if;
                rdata1 <= mem(to_integer(unsigned(addr1)));
            end if;
            if (WRITE_MODE_1 = 2) then
                if (we1 = '1') then
                    mem(to_integer(unsigned(addr1))) := wdata1;
                else
                    rdata1 <= mem(to_integer(unsigned(addr1)));
                end if;
            end if;
        end if;
    end process;
    process (clk2)
    begin
        if (clk2'event and clk2 = '1') then
            if (WRITE_MODE_2 = 0) then
                rdata2 <= mem(to_integer(unsigned(addr2)));
                if (we2 = '1') then
                    mem(to_integer(unsigned(addr2))) := wdata2;
                end if;
            end if;
            if (WRITE_MODE_2 = 1) then
                if (we2 = '1') then
                    mem(to_integer(unsigned(addr2))) := wdata2;
                end if;
                rdata2 <= mem(to_integer(unsigned(addr2)));
            end if;
            if (WRITE_MODE_2 = 2) then
                if (we2 = '1') then
                    mem(to_integer(unsigned(addr2))) := wdata2;
                else
                    rdata2 <= mem(to_integer(unsigned(addr2)));
                end if;
            end if;
        end if;
    end process;
end rtl;

--------------------------------------------------------------------------------

-- three port asynchronous memory (2 read ports, 1 write port, used for register file)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_3p_async_dist_inferred is
    generic (
                AWIDTH : natural := 5;
                DWIDTH : natural := 32
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
end mem_3p_async_dist_inferred;

architecture rtl of mem_3p_async_dist_inferred is

    type mem_type is array (0 to 2**AWIDTH - 1) of std_logic_vector(DWIDTH-1 downto 0);
    signal mem : mem_type;

    attribute ram_style : string;
    attribute ram_style of mem : signal is "distributed";

begin
    process (wclk)
    begin
        if (wclk'event and wclk = '1') then
            if (we = '1') then
                mem(to_integer(unsigned(waddr))) <= wdata;
            end if;
        end if;
    end process;

    rdata1 <= wdata when (we = '1' and waddr = raddr1) else
              mem(to_integer(unsigned(raddr1)));
    rdata2 <= wdata when (we = '1' and waddr = raddr2) else
              mem(to_integer(unsigned(raddr2)));
end rtl;

--------------------------------------------------------------------------------

-- three port asynchronous memory (2 read ports, 1 write port) with read first mode
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_3p_async_dist_rfirst_inferred is
    generic (
                AWIDTH : natural := 5;
                DWIDTH : natural := 32
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
end mem_3p_async_dist_rfirst_inferred;

architecture rtl of mem_3p_async_dist_rfirst_inferred is

    type mem_type is array (0 to 2**AWIDTH - 1) of std_logic_vector(DWIDTH-1 downto 0);
    signal mem : mem_type := (others => (others => '0'));

    attribute ram_style: string;
    attribute ram_style of mem : signal is "distributed";

begin
    process (wclk)
    begin
        if (wclk'event and wclk = '1') then
            if (we = '1') then
                mem(to_integer(unsigned(waddr))) <= wdata;
            end if;
        end if;
    end process;

    rdata1 <= mem(to_integer(unsigned(raddr1)));
    rdata2 <= mem(to_integer(unsigned(raddr2)));
end rtl;
