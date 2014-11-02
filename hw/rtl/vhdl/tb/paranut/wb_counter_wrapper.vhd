--------------------------------------------------------------------------------
-- This file is part of the ParaNut project.
-- 
-- Copyright (C) 2014  Michael Seider, Hochschule Augsburg
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
--  Wishbone interface wrapper for the Counter module used for simulation. 
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library paranut;
use paranut.types.all;
use paranut.paranut_lib.all;
use paranut.counter_pkg.all;

entity wb_counter_wrapper is
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
end wb_counter_wrapper;

architecture behav of wb_counter_wrapper is

    signal ctr_stb_i : std_logic;
    signal ctr_cyc_i : std_logic;
    signal ctr_we_i  : std_logic;
    signal ctr_sel_i : TByteSel;
    signal ctr_ack_o : std_logic;
    signal ctr_err_o : std_logic;
    signal ctr_rty_o : std_logic;
    signal ctr_adr_i : TWord;
    signal ctr_dat_i : TWord;
    signal ctr_dat_o : TWord;

begin

    ctr_dat_i <= dat_i;
    ctr_cyc_i <= cyc_i;
    ctr_sel_i <= "0000";
    ctr_adr_i <= adr_i;

    ctr_stb_i <= stb_i when conv_integer(adr_i(31 downto 24)) = WB_SLV_ADDR else
                 '0';
    ctr_we_i <= we_i when conv_integer(adr_i(31 downto 24)) = WB_SLV_ADDR else
                '0';
    ack_o <= ctr_ack_o when conv_integer(adr_i(31 downto 24)) = WB_SLV_ADDR else
             'Z';
    dat_o <= ctr_dat_o when conv_integer(adr_i(31 downto 24)) = WB_SLV_ADDR else
             (others => 'Z');

    counter0 : wb_counter
    generic map (N_COUNTER => N_COUNTER)
    port map (clk_i, rst_i, ctr_ack_o, ctr_err_o, ctr_rty_o, ctr_dat_i, ctr_cyc_i,
    ctr_stb_i, ctr_we_i, ctr_sel_i, ctr_adr_i, ctr_dat_o);

end behav;

