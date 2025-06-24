-- video_generator_de10_svga.vhd
--
-- variation of video_generator.vhd
--   use the 50 MHz clock for SVGA video signal
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 24.06.2025

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity video_generator_de10_svga is
  port (max10_clk1_50  : in  std_logic;                     -- input clock 50 MHz
        key            : in  std_logic_vector(0 downto 0);  -- push button for reset
        sw             : in  std_logic_vector(2 downto 0);  -- three switches
        vga_vs         : out std_logic;                     -- video out (4 bit resolution)
        vga_hs         : out std_logic;
        vga_r          : out std_logic_vector(3 downto 0);
        vga_g          : out std_logic_vector(3 downto 0);
        vga_b          : out std_logic_vector(3 downto 0));
end video_generator_de10_svga;

architecture behave of video_generator_de10_svga is

    -- input signals
    signal reset                    : std_logic;
    signal enable                   : std_logic_vector(2 downto 0);
    -- internal signals
    signal h_count                  : integer range 0 to 2047 := 0;
    signal v_count                  : integer range 0 to 1023 := 0;
    signal new_frame                : std_logic;
    signal hs, vs, de               : std_logic;
    signal r, g, b                  : std_logic_vector(7 downto 0);
    signal h_start                  : integer range 0 to 2047 := 600;
    signal h_end                    : integer range 0 to 2047 := 700;

begin

process
begin
  wait until rising_edge(max10_clk1_50);

    -- input signals need an input flip-flop (except clock)
    reset  <= not key(0);  -- reset, invert for positive logic
    enable <= sw;          -- three control switches

    -- use reset for control signals
    if (reset = '1') then
        h_count   <= 0;
        v_count   <= 0;
        new_frame <= '0';
    else
        new_frame  <= '0'; -- default
        -- count total pixel of a line
        if (h_count < 1040-1 ) then
                h_count <= h_count + 1;
        else
            h_count <= 0;
            -- count total lines of a frame
            if (v_count < 666-1 ) then
                v_count <= v_count + 1;
            else
                v_count <= 0;
                new_frame  <= '1'; -- indicate new frame for one clock cycle
            end if; -- v_count
        end if; -- h_count
    end if; -- reset

    -- timing for horizontal sync
    if ( h_count < 120 ) then
         hs <= '1'; else
         hs <= '0'; end if;

    -- timing for vertical sync
    if ( v_count < 6 ) then
        vs <= '1'; else
        vs <= '0'; end if;

    -- check if active image
    -- from back_porch to back_porch+active_lines/column (back_porch is at beginning of row/column)
    if ( h_count >= 120 and h_count < (120+ 800) and
         v_count >=  23 and v_count < ( 23+ 600) ) then
        -- active image, set to gray
        de <= '1';
        r  <= "10000000";
        g  <= "10000000";
        b  <= "10000000";
    else
        -- blanking, i.e. no image, set to black
        de <= '0';
        r  <= "00000000";
        g  <= "00000000";
        b  <= "00000000";
    end if;

    -- make one red square
    if ( h_count >= 400 and h_count < 500 and
         v_count >= 200 and v_count < 300 ) then
        -- set to red
        r  <= "11111111";
        g  <= "00000000";
        b  <= "00000000";
    end if;

    -- make one moving green square
    if (reset = '1' or h_start=800) then
        h_start   <= 600;
        h_end     <= 700;
    elsif (new_frame = '1') then
        -- move the square by one pixel for each frame
        h_start   <= h_start+1;
        h_end     <= h_end  +1;
    end if;
    
    if ( h_count >= h_start and h_count < h_end and
         v_count >= 400     and v_count < 500   ) then
        -- set to green
        r  <= "00000000";
        g  <= "11111111";
        b  <= "00000000";
    end if;

    -- give the signals to the output
    vga_vs  <= vs;
    vga_hs  <= hs;
    vga_r   <= r(7 downto 4);
    vga_g   <= g(7 downto 4);
    vga_b   <= b(7 downto 4);


end process;

end behave;