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
--  Component and type declarations for peripheral module for the testbench
--  (wishbone memory and wishbone uart).
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.types.all;

package peripherals is

    component wb_memory is
        generic (
                    WB_SLV_ADDR : natural := 16#00#;
                    CFG_NUT_MEM_SIZE : natural := 8 * 1024 * 1024;
                    LOAD_PROG_DATA : boolean := true;
                    PROG_DATA : mem_type
                );
        port (
                 -- Ports (WISHBONE slave)
                 clk_i   : in std_logic;
                 rst_i   : in std_logic;
                 stb_i   : in std_logic;                    -- strobe output
                 cyc_i   : in std_logic;                    -- cycle valid output
                 we_i    : in std_logic;                    -- indicates write transfer
                 sel_i   : in TByteSel;                     -- byte select outputs
                 ack_o   : out std_logic;                   -- normal termination
                 err_o   : out std_logic;                   -- termination w/ error
                 rty_o   : out std_logic;                   -- termination w/ retry
                 adr_i   : in TWord;                        -- address bus outputs
                 dat_i   : in TWord;                        -- input data bus
                 dat_o   : out TWord;                       -- output data bus
                 cti_i   : in std_logic_vector(2 downto 0); -- cycle type identifier
                 bte_i   : in std_logic_vector(1 downto 0)  -- burst type extension
             );
    end component;

    component wb_uart is
        generic (
                    WB_SLV_ADDR : natural := 16#90#
                );
        port (
                 -- Ports (WISHBONE slave)
                 clk_i   : in std_logic;
                 rst_i   : in std_logic;
                 stb_i   : in std_logic;    -- strobe output
                 cyc_i   : in std_logic;    -- cycle valid output
                 we_i    : in std_logic;    -- indicates write transfer
                 sel_i   : in TByteSel;     -- byte select outputs
                 ack_o   : out std_logic;   -- normal termination
                 err_o   : out std_logic;   -- termination w/ error
                 rty_o   : out std_logic;   -- termination w/ retry
                 adr_i   : in TWord;        -- address bus outputs
                 dat_i   : in TWord;        -- input data bus
                 dat_o   : out TWord        -- outout data bus
             );
    end component;

    component wb_counter_wrapper is
    generic (
                WB_SLV_ADDR : natural := 16#F0#;
                N_COUNTER : natural := 4
            );
    port (
             -- Ports (WISHBONE slave)
             clk_i   : in std_logic;
             rst_i   : in std_logic;
             stb_i   : in std_logic;    -- strobe output
             cyc_i   : in std_logic;    -- cycle valid output
             we_i    : in std_logic;    -- indicates write transfer
             sel_i   : in TByteSel;     -- byte select outputs
             ack_o   : out std_logic;   -- normal termination
             err_o   : out std_logic;   -- termination w/ error
             rty_o   : out std_logic;   -- termination w/ retry
             adr_i   : in TWord;        -- address bus outputs
             dat_i   : in TWord;        -- input data bus
             dat_o   : out TWord        -- outout data bus
         );
    end component;

end package;
