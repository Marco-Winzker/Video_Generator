-- video_generator_de10_720p.vhd
--
-- generate a 720p video
-- top level for DE10-Lite board
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 24.06.2025

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity video_generator_de10_720p is
  port (max10_clk1_50  : in  std_logic;                     -- input clock 50 MHz
        key            : in  std_logic_vector(0 downto 0);  -- push button for reset
        sw             : in  std_logic_vector(2 downto 0);  -- three switches
        ledr           : out std_logic_vector(9 downto 0);  -- red LEDs
        vga_vs         : out std_logic;                     -- video out (4 bit resolution)
        vga_hs         : out std_logic;
        vga_r          : out std_logic_vector(3 downto 0);
        vga_g          : out std_logic_vector(3 downto 0);
        vga_b          : out std_logic_vector(3 downto 0));
end video_generator_de10_720p;

architecture shell of video_generator_de10_720p is

signal clk_74   : std_logic;
signal r, g, b  : std_logic_vector(7 downto 0);
signal count_74 : unsigned(29 downto 0);

begin

-- submodule PLL, generate clock 74.25 MHz
clock_gen: entity work.clock_74
    port map (inclk0    => max10_clk1_50,
              c0        => clk_74);

process
begin
  wait until rising_edge(clk_74);
     -- check correct function of PLL with LEDs
     -- count 74.25 million times per second
     -- 10 bit is about 1,000
     -- 20 bit is about 1,000,000
     -- 6 bit is 64
     -- 26 bit at 74 MHz is a little faster than 1 Hz
     -- for good observability use 30 bit counter
     count_74 <= count_74 + 1;
     ledr     <= std_logic_vector(count_74(29 downto 20));
end process;

-- submodule video_generator
generator: entity work.video_generator
    port map (clk       => clk_74,
              reset_n   => key(0),
              enable_in => sw,
              vs_out    => vga_vs,
              hs_out    => vga_hs,
              de_out    => open,
              r_out     => r,
              g_out     => g,
              b_out     => b,
              clk_o     => open);

-- output of DE10-Lite board is only 4 bit
vga_r <= r(7 downto 4);
vga_g <= g(7 downto 4);
vga_b <= b(7 downto 4);

end shell;
