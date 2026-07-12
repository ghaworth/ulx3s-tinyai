module sdram_init #(
	parameter CLK_FREQ_HZ = 100_000_000,
	parameter CAS_LATENCY = 2
)(
	input wire clk,
	input wire rst,
	output reg done
);

localparam tRP_NS = 15;                 		// Winbond -6, §9.5
localparam tRC_NS = 60;     		    		// ...
localparam tRAS_NS = 42; 						// ...
localparam tRCD_NS = 15; 						// ...
localparam POWERUP_PAUSE_NS = 200_000;	// Winbond -6, §7.1
localparam AUTO_REFRESH_COUNT = 8;     			// ...
localparam tRP_CYCLES = (64'd1 * tRP_NS  * CLK_FREQ_HZ + 999_999_999) / 1_000_000_000;
localparam tRC_CYCLES = (64'd1 * tRC_NS  * CLK_FREQ_HZ + 999_999_999) / 1_000_000_000;
localparam tRAS_CYCLES = (64'd1 * tRAS_NS  * CLK_FREQ_HZ + 999_999_999) / 1_000_000_000;
localparam tRCD_CYCLES = (64'd1 * tRCD_NS  * CLK_FREQ_HZ + 999_999_999) / 1_000_000_000;
localparam POWERUP_PAUSE_CYCLES = (64'd1 * POWERUP_PAUSE_NS  * CLK_FREQ_HZ + 999_999_999) / 1_000_000_000;
