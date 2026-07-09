module sdram_init #(
	parameter CLK_FREQ_HZ = 100000000,
	parameter CAS_LATENCY = 2
)(
	input wire clk,
	input wire rst,
	output reg done
);

