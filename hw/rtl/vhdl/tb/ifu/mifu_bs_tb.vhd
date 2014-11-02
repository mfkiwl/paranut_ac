library ieee;
use ieee.std_logic_1164.all;

library work;
use work.types.all;
use work.memu_lib.all;
use work.ifu.all;

entity mifu_bs_tb is
    end mifu_bs_tb;

architecture tb of mifu_bs_tb is

    signal clk    : std_logic;
    signal reset  : std_logic;
    signal ifui   : IfuInType;
    signal ifuo   : IfuOutType;
    signal rpi    : ReadPortInType;
    signal rpo    : ReadPortOutType;
    signal icache_enable : std_logic;

    constant clk_period : time := 10 ns;

    signal halt: boolean := false;

begin

    uut: mifu_bs
    port map (clk, reset, ifui, ifuo, rpi, rpo, icache_enable);

    clock: process
    begin
        while (not halt) loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    tb: process
    begin

        reset <= '1';
        icache_enable <= '0';
        ifui.nexti <= '0';
        ifui.jump <= '0';
        wait for clk_period/4;
        wait for clk_period;

        reset <= '0';
        ifui.jump <= '1';
        ifui.jump_adr <= X"00001000";
        wait for clk_period;

        ifui.jump <= '0';
        rpo.port_ack <= '1';
        rpo.port_data <= X"01234567";
        wait for clk_period;
        rpo.port_ack <= '0';
        wait for 3*clk_period;

        rpo.port_ack <= '1';
        rpo.port_data <= X"23456789";
        wait for clk_period;
        rpo.port_ack <= '0';
        wait for clk_period;

        ifui.nexti <= '1';
        wait for clk_period;
        ifui.nexti <= '0';
        wait for clk_period;

        ifui.nexti <= '1';
        wait for clk_period;
        ifui.nexti <= '0';
        wait for clk_period;

        wait for 10*clk_period;

        rpo.port_ack <= '1';
        rpo.port_data <= X"456789ab";
        wait for clk_period;
        rpo.port_ack <= '0';
        wait for 3*clk_period;

        rpo.port_ack <= '1';
        rpo.port_data <= X"6789abcd";
        wait for clk_period;
        rpo.port_ack <= '0';
        wait for 3*clk_period;

        rpo.port_ack <= '1';
        rpo.port_data <= X"89abcdef";
        wait for clk_period;
        rpo.port_ack <= '0';
        wait for 3*clk_period;

        rpo.port_ack <= '1';
        rpo.port_data <= X"01234567";
        ifui.nexti <= '1';
        wait for 1*clk_period;
        rpo.port_ack <= '0';
        ifui.nexti <= '0';
        wait for clk_period;

        ifui.jump <= '1';
        ifui.jump_adr <= X"11111100";
        wait for clk_period;

        ifui.nexti <= '1';
        ifui.jump <= '0';
        wait for 1*clk_period;
        ifui.nexti <= '1';
        wait for 1*clk_period;
        ifui.nexti <= '1';
        wait for 1*clk_period;
        ifui.nexti <= '1';
        wait for 1*clk_period;

        ifui.nexti <= '0';
        wait for 5*clk_period;

        halt <= true;
        report "Simulation halted";
        wait;

    end process;


end tb;
