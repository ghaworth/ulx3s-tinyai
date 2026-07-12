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

	localparam POWERUP   = 5'b00001;
	localparam PRECHARGE = 5'b00010;
	localparam REFRESH   = 5'b00100;
	localparam MODE_REG  = 5'b01000;
	localparam DONE      = 5'b10000;

	reg [4:0] state;
	reg [$clog2(POWERUP_PAUSE_CYCLES)-1 : 0] wait_counter;

	always @(posedge clk) begin
		if (rst) begin
			wait_counter <= POWERUP_PAUSE_CYCLES;
			done <= 0;
			state <= POWERUP;
		end else begin
			case(state)
			POWERUP: begin
				if (wait_counter == 0) begin
					state <= PRECHARGE;
					wait_counter <= tRP_CYCLES;   // arm PRECHARGE's wait
				end else begin
					wait_counter <= wait_counter - 1;
				end
				end

			PRECHARGE: begin

				end

			REFRESH: begin

				end

			MODE_REG: begin

				end

			DONE: begin

				end
			endcase
		end
	end

endmodule
