# DE10_timing.sdc
# 
# Timing constraints for video_generator on DE10-Lite Board
#
# FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
# (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 24.06.2025

# Create Clock
create_clock -name input_clk -period "50.0 MHz" [get_ports MAX10_CLK1_50]

# Create Generated Clock
derive_pll_clocks
