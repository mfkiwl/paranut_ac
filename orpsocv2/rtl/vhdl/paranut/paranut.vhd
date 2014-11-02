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
--  Component and type declarations for the ParaNut top level module.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library paranut;
use paranut.memu_lib.all;
use paranut.types.all;

package paranut_pkg is

    component mparanut
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
    end component;

end package;
