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
--  Component and type declarations for the register file of the ParaNut.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library paranut;
use paranut.exu.all;
use paranut.mem_tech.all;

-- pragma translate_off
use paranut.paranut_lib.all;
use paranut.tb_monitor.all;
-- pragma translate_on

entity regfile is
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
end regfile;

architecture rtl of regfile is

begin

    -- pragma translate_off
    process (rfi.wr_en, rfi.wr_data)
    begin
        if (rfi.wr_en = '1') then
            monitor(CPU_ID).regfile(conv_integer(rfi.wr_addr)) <= rfi.wr_data;
        end if;
    end process;
    -- pragma translate_on

    regfile_mem : mem_3p_async_dist_inferred
    generic map (AWIDTH => 5, DWIDTH => 32)
    port map (
                 wclk    => clk,
                 waddr   => rfi.wr_addr,
                 wdata   => rfi.wr_data,
                 we      => rfi.wr_en,
                 raddr1  => rfi.rd_addr1,
                 rdata1  => rfo.rd_data1,
                 raddr2  => rfi.rd_addr2,
                 rdata2  => rfo.rd_data2
             );

end rtl;
