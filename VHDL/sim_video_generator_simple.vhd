-- sim_video_generator-simple.vhd
--
-- simple testbench for video generator
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 05.02.2025


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

entity sim_video_generator is
end sim_video_generator;

architecture sim of sim_video_generator is

-- signals of testbench
  signal clk       : std_logic := '0';
  signal reset_n   : std_logic;
  signal enable_in : std_logic_vector(2 downto 0);
  signal vs_out    : std_logic;
  signal hs_out    : std_logic;
  signal de_out    : std_logic;
  signal r_out     : std_logic_vector(7 downto 0);
  signal g_out     : std_logic_vector(7 downto 0);
  signal b_out     : std_logic_vector(7 downto 0);
  signal clk_o     : std_logic;

begin

  -- clock generation
  clk <= not clk after 5 ns;

  -- instantiation of design-under-verification
  duv : entity work.video_generator
    port map (clk       => clk,
              reset_n   => reset_n,
              enable_in => enable_in,
              vs_out    => vs_out,
              hs_out    => hs_out,
              de_out    => de_out,
              r_out     => r_out,
              g_out     => g_out,
              b_out     => b_out,
              clk_o     => clk_o);

  -- main process for stimuli
  stimuli_process : process
  begin

    -- init
    reset_n   <= '0', '1' after 50 ns;  -- reset for 5 clock cycles
    enable_in <= "000";

    -- wait for reset
    wait for 100 ns;

    -- one video-frame is 1650 pixel * 750 lines 
    for y in 1 to (1650*750) loop
        wait until falling_edge(clk);
    end loop;  -- y

-- stop simulation
    assert false
      report "Simulation completed"
      severity failure;

  end process;

end sim;
