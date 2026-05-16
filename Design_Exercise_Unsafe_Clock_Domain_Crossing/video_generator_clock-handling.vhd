-- video_generator_clock-handling.vhd
--
-- based on video_generator.vhd
-- demonstrates potential error when data crosses clock boundaries
-- please note: the design shows unsave design practice, marked with "problem"
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg and BayZiel, 09.05.2026


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity video_generator is
  port (clk       : in  std_logic;                      -- input clock 74.25 MHz, video 720p
        reset_n   : in  std_logic;                      -- reset (invoked during configuration)
        enable_in : in  std_logic_vector(2 downto 0);   -- three slide switches
        -- video out
        vs_out    : out std_logic;                      -- vertical sync signal
        hs_out    : out std_logic;                      -- horizontal sync signal                      
        de_out    : out std_logic;                      -- data enable, i.e. active pixel
        r_out     : out std_logic_vector(7 downto 0);   -- red
        g_out     : out std_logic_vector(7 downto 0);   -- green
        b_out     : out std_logic_vector(7 downto 0);   -- blue image information
        --
        clk_o     : out std_logic);                      -- output clock (do not modify)

end video_generator;

architecture behave of video_generator is

    -- input signals
    signal reset                    : std_logic;
    -- signal enable                    : std_logic_vector(2 downto 0); -- problem: no input FF for input enable_in
    -- internal signals
    signal h_count                  : integer range 0 to 2047 := 0;
    signal v_count                  : integer range 0 to 1023 := 0;
    signal new_frame                : std_logic;
    signal hs, vs, de               : std_logic;
    signal r, g, b                  : std_logic_vector(7 downto 0);
    signal h_start                  : integer range 0 to 2047 := 300;
    signal h_end                    : integer range 0 to 2047 := 500;
    signal enable_last              : std_logic_vector(2 downto 0) := "000";
    signal rec_col                  : std_logic := '0';

begin
    
process
begin   
  wait until rising_edge(clk);

    -- input signals need an input flip-flop (except clock)
    reset  <= not reset_n; -- reset, invert for positive logic
--    enable <= enable_in;   -- three control switches -- problem: no input FF for input enable_in

    -- use reset for control signals
    if (reset = '1') then
        h_count   <= 0;
        v_count   <= 0;
        new_frame <= '0';
    else
        new_frame  <= '0'; -- default
        -- count total pixel of a line
        if (h_count < 1650-1 ) then
                h_count <= h_count + 1;
        else 
            h_count <= 0;
            -- count total lines of a frame
            if (v_count < 750-1 ) then
                v_count <= v_count + 1;
            else 
                v_count <= 0;
                new_frame  <= '1'; -- indicate new frame for one clock cycle
            end if; -- v_count
        end if; -- h_count
    end if; -- reset

    -- timing for horizontal sync
    if ( h_count < 40 ) then
         hs <= '1'; else
         hs <= '0'; end if;

    -- timing for vertical sync
    if ( v_count < 5 ) then
        vs <= '1'; else
        vs <= '0'; end if;

    -- check if active image
    -- from back_porch to back_porch+active_lines/column (back_porch is at beginning of row/column)
    if ( h_count >= 220 and h_count < (220+1280) and
         v_count >=  20 and v_count < ( 20+ 720) ) then
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

    -- make one red rectangle, same size as green/blue rectangle
    if ( h_count >= 300 and h_count < 1000 and
         v_count >= 200 and v_count < 300 ) then
        -- set to red
        r  <= "11111111";
        g  <= "00000000";
        b  <= "00000000";
    end if;

    -- make one green/blue rectangle with size and color controlled by input enable_in
    enable_last <= enable_in; -- problem: enable_in does not originate from the clock domain "clk"
    if (enable_last /= enable_in) then -- problem: enable_in does not originate from the clock domain "clk"
        -- change rectangle color
        rec_col   <= not rec_col;
        -- and expand the box
        if h_end = 1000 then
            h_end <= 500;
        else
            h_end <= h_end + 100;
        end if;
    end if;

    if ( h_count >= h_start and h_count < h_end and
         v_count >= 400     and v_count < 500   ) then
        -- set to green or blue
        r  <= "00000000";
        if (rec_col = '0') then
            g  <= "11111111";
            b  <= "00000000";
        else
            g  <= "00000000";
            b  <= "11111111";
        end if; -- color
    end if;

    -- give the signals to the output
    vs_out  <= vs;
    hs_out  <= hs;
    de_out  <= de;
    r_out   <= r; 
    g_out   <= g;
    b_out   <= b;    

end process;

-- do not modify
clk_o <= clk;

end behave;
