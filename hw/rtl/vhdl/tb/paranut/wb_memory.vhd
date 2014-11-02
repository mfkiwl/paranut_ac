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
--  Wishbone memory simulation module. This module supports a registered
--  feedback read/write cycles.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library paranut;
use paranut.paranut_config.all;
use paranut.types.all;
use paranut.paranut_lib.all;
use paranut.text_io.all;

use paranut.txt_util.all;

entity wb_memory is
    generic (
                WB_SLV_ADDR : natural := 16#00#;
                CFG_NUT_MEM_SIZE : natural := 8 * MB;
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
end wb_memory;

architecture behav of wb_memory is

    constant WRITE_DELAY : integer := 5;
    constant READ_DELAY : integer := 2;

begin

    process

        variable mem : mem_type(0 to CFG_NUT_MEM_SIZE/4-1) := (others => X"00000000");

        impure function read_mem (addr : TWord; sel : TByteSel) return TWord is
            variable rdata : TWord;
            variable paddr : TWord := addr(29 downto 0) & "00";
        begin
            rdata := mem(conv_integer(addr));
            for i in 0 to 3 loop
                if (sel(i) = '0') then
                    rdata(7+8*i downto 8*i) := X"00";
                end if;
            end loop;
            return rdata;
        end;

        procedure write_mem (addr : TWord; data : TWord; sel : TByteSel) is
            variable wdata : TWord;
            variable paddr : TWord := addr(29 downto 0) & "00";
        begin
            wdata := mem(conv_integer(addr));
            for i in 0 to 3 loop
                if (sel(i) = '1') then
                    wdata(7+8*i downto 8*i) := data(7+8*i downto 8*i);
                end if;
            end loop;
            mem(conv_integer(addr)) := wdata;
        end procedure;

        variable adr, data : TWord;
        variable sel : TByteSel;
        
    begin

        err_o <= '0';
        rty_o <= '0';

        if (LOAD_PROG_DATA) then
            mem(0 to PROG_DATA'high) := PROG_DATA;
        end if;

        dat_o <= (others => 'Z');
        ack_o <= 'Z';
        while true loop
            wait until clk_i = '1';
            if (stb_i = '1' and cyc_i = '1') then
                adr := "00" & adr_i(31 downto 2);
                sel := sel_i;
                data := dat_i;
                if (unsigned(adr_i(31 downto 24)) = WB_SLV_ADDR) then
                    if (unsigned(adr_i) < (WB_SLV_ADDR*2**24 + CFG_NUT_MEM_SIZE)) then
                        if (we_i = '1') then
                            -- write...
                            for i in 0 to WRITE_DELAY-1 loop
                                wait until clk_i = '1';
                            end loop;
                            if (cti_i = "000") then
                                write_mem(adr, data, sel);
                                ack_o <= '1';
                                wait until clk_i = '1';
                            elsif (cti_i = "010") then
                                ack_o <= '1';
                                wait until clk_i = '1';
                                loop
                                    if (stb_i = '1') then
                                        data := dat_i;
                                        sel := sel_i;
                                        write_mem(adr, data, sel);
                                        case bte_i is
                                            when "01" => adr(1 downto 0) := adr(1 downto 0) + 1;
                                            when "10" => adr(2 downto 0) := adr(2 downto 0) + 1;
                                            when "11" => adr(3 downto 0) := adr(3 downto 0) + 1;
                                            when others => adr := adr + 1;
                                        end case;
                                        ack_o <= '1';
                                    else
                                        ack_o <= '0';
                                    end if;
                                    exit when (cti_i = "111");
                                    wait until clk_i = '1';
                                end loop;
                            end if;
                        else
                            -- read...
                            for i in 0 to READ_DELAY-1 loop
                                wait until clk_i = '1';
                            end loop;
                            if (cti_i = "000") then
                                dat_o <= read_mem(adr, sel);
                                ack_o <= '1';
                                wait until clk_i = '1';
                            elsif (cti_i = "010") then
                                wait until clk_i = '1';
                                while (cti_i /= "111") loop
                                    if (stb_i = '1') then
                                        dat_o <= read_mem(adr, sel);
                                        sel := sel_i;
                                        case bte_i is
                                            when "01" => adr(1 downto 0) := adr(1 downto 0) + 1;
                                            when "10" => adr(2 downto 0) := adr(2 downto 0) + 1;
                                            when "11" => adr(3 downto 0) := adr(3 downto 0) + 1;
                                            when others => adr := adr + 1;
                                        end case;
                                        ack_o <= '1';
                                    else
                                        ack_o <= '0';
                                    end if;
                                    wait until clk_i = '1';
                                end loop;
                            end if;
                        end if;
                        ack_o <= 'Z';
                        dat_o <= (others => 'Z');
                    else
                        if (we_i = '1') then
                            INFO ("MEM write to non-existing address: 0x" & hstr(adr_i) & " : 0x" & hstr(dat_i));
                        else
                            INFO ("MEM read from non-existing address: 0x" & hstr(adr_i));
                        end if;
                    end if;
                end if;
            end if;
        end loop;
    end process;

end behav;

