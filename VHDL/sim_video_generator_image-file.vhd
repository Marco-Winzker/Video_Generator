-- sim_video_generator_image-file.vhd
--
-- testbench for video generator
-- output image is written in ppm-file format
--          ppm-file can be generated and viewed with IrfanView and probably other image viewers
--          verified with IrfanView version 4.54 - 64 bit and 4.44 - 64 bit
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

-- define constants for simulation
  constant response_filename : string  := "Video_Generator_Image.ppm";

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
  signal end_tb    : integer   :=    0;
  signal x_size    : integer   := 1280;
  signal y_size    : integer   :=  720;


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
    reset_n   <= '0', '1' after 50 ns;  -- reset for 10 clock cycles
    enable_in <= "000";

    -- wait for reset
    wait for 100 ns;

    -- one video-frame is 1650 pixel * 750 lines 
    for y in 1 to (1650*750) loop
        wait until falling_edge(clk);
    end loop;  -- y

    end_tb <= 1;                        -- signal to close response_file
    wait for 20 ns;

-- stop simulation
    assert false
      report "Simulation completed"
      severity failure;

  end process;

-- second process to handle DUT output
  response_process : process
-- variables for writing simulated response
    file response_file        : text;
    variable l_sim            : line;
    variable response_status  : file_open_status;
    variable r_sim, g_sim, b_sim        : integer;

  begin

    wait until (hs_out = '1');  -- wait until stimuli process is started


-- open file for output image
    file_open(response_status, response_file, response_filename, write_mode);
    write (l_sim, string'("P3"));       -- magic number
    writeline(response_file, l_sim);        
    write (l_sim, string'("# generated by VHDL testbench"));       -- comment
    writeline(response_file, l_sim);   
    write (l_sim, x_size);
    write (l_sim, string'(" "));
    write (l_sim, y_size);
    writeline(response_file, l_sim);        
    write (l_sim, string'("255"));       -- maximum value
    writeline(response_file, l_sim);        
    
    while (end_tb /= 1) loop
      wait until falling_edge(clk);
      if (de_out = '1') then

        -- get response and write to response file
          r_sim := to_integer(unsigned(r_out));
          g_sim := to_integer(unsigned(g_out));
          b_sim := to_integer(unsigned(b_out));
        write(l_sim, r_sim);
        write (l_sim, string'(" "));
        write(l_sim, g_sim);
        write (l_sim, string'(" "));
        write(l_sim, b_sim);
        writeline(response_file, l_sim);

      end if;
    end loop;

    file_close(response_file);
    wait until (end_tb = 2); -- wait forever, because end_tb will not become 2

  end process;

end sim;
