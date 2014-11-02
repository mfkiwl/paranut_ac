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
--  Helper functions for printing debug ouput. Also includes a table to convert
--  bytes to ASCII values for printing on stdout
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;
use ieee.std_logic_textio.all;

package text_io is

    function slv2ascii (slv : std_logic_vector) return character;
    procedure put_char (l : inout line; c : character);

    procedure INFO (s : string);
    function to_h_string(slv : std_logic_vector) return string;
    function to_b_string(slv : std_logic_vector) return string;
    function to_ud_string(slv : std_logic_vector) return string;
    function to_sd_string(slv : std_logic_vector) return string;

    constant ascii_table : string (1 to 128) := (
        nul, soh, stx, etx, eot, enq, ack, bel, 
		bs,  ht,  lf,  vt,  ff,  cr,  so,  si, 
		dle, dc1, dc2, dc3, dc4, nak, syn, etb, 
		can, em,  sub, esc, fsp, gsp, rsp, usp, 

		' ', '!', '"', '#', '$', '%', '&', ''', 
		'(', ')', '*', '+', ',', '-', '.', '/', 
		'0', '1', '2', '3', '4', '5', '6', '7', 
		'8', '9', ':', ';', '<', '=', '>', '?', 

		'@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 
		'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 
		'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 
		'X', 'Y', 'Z', '[', '\', ']', '^', '_', 

		'`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 
		'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 
		'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 
		'x', 'y', 'z', '{', '|', '}', '~', del
    );

end package;

package body text_io is

    procedure INFO (s : string) is
        variable l : line;
    begin
        write(l, string'("INFO: "));
        write(l, now);
        write(l, string'(": "));
        write(l, s);
        writeline(OUTPUT, l);
    end procedure;
        
    function to_h_string(slv : std_logic_vector) return string is
        variable l: line;
    begin
        hwrite(l, slv);
        return l.all;
    end;

    function to_b_string(slv : std_logic_vector) return string is
        variable l: line;
    begin
        write(l, slv);
        return l.all;
    end;

    function to_ud_string(slv : std_logic_vector) return string is
        variable l: line;
    begin
        write(l, to_integer(unsigned(slv)));
        return l.all;
    end;

    function to_sd_string(slv : std_logic_vector) return string is
        variable l: line;
    begin
        write(l, to_integer(signed(slv)));
        return l.all;
    end;

    function slv2ascii (slv : std_logic_vector) return character is
        variable c : character;
    begin
        return ascii_table(1+to_integer(unsigned(slv)));
    end;

    procedure put_char (l : inout line; c : character) is
    begin
        if (c = lf) then
            writeline(OUTPUT, l);
        elsif (c /= cr) then
            write(l, c);
        end if;
    end;

end text_io;

