module sdram_init #(
	parameter CLK_FREQ_HZ = 100_000_000,
	parameter CAS_LATENCY = 2,
	parameter BURST_LENGTH = 8,
	parameter ADDRESSING_MODE = 0   // 0 = sequential
)(
	input wire clk,
	input wire rst,
	output reg done,
	output wire cs,
	output wire ras,
	output wire cas,
	output wire we,
	output reg cke,
	output reg [12:0] addr,
	output reg [1:0] ba,
	output wire ldqm,
	output wire udqm  
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
	localparam tRSC_CYCLES = 2;   // Winbond -6, §9.5, mode register set, 2 tCK

	localparam POWERUP   = 5'b00001;
	localparam PRECHARGE = 5'b00010;
	localparam REFRESH   = 5'b00100;
	localparam MODE_REG  = 5'b01000;
	localparam DONE      = 5'b10000;

	localparam CMD_NOP           = 4'b0111;  // Winbond, §8 Table 1, {CS,RAS,CAS,WE}
	localparam CMD_PRECHARGE_ALL = 4'b0010;  // ...
	localparam CMD_AUTO_REFRESH  = 4'b0001;  // ...
	localparam CMD_MODE_REG_SET  = 4'b0000;  // ...
	localparam CMD_DESELECT      = 4'b1111;  // Winbond, §7.19

	localparam BL_CODE = $clog2(BURST_LENGTH);
	localparam MODE_REG_WORD = { 3'b000,              // A12:A10 reserved
                             1'b0,                // A9  write mode
                             1'b0,                // A8  reserved
                             1'b0,                // A7  test mode
                             CAS_LATENCY[2:0],    // A6:A4
                             ADDRESSING_MODE[0],  // A3
                             BL_CODE[2:0]
                           };

	reg [4:0] state;
	reg [3:0] cmd;
	reg [$clog2(POWERUP_PAUSE_CYCLES)-1 : 0] wait_counter;
	reg [$clog2(AUTO_REFRESH_COUNT+1)-1 : 0] refresh_counter;

	assign {cs, ras, cas, we} = cmd;
	assign ldqm = 1'b1;
	assign udqm = 1'b1;
	
	always @(posedge clk) begin
		if (rst) begin
			wait_counter <= POWERUP_PAUSE_CYCLES;
			done <= 0;
			state <= POWERUP;
			cmd <= CMD_DESELECT;
			cke <= 1;
	
		end else begin
			case(state)
			POWERUP: begin
				if (wait_counter == 0) begin
					state <= PRECHARGE;
					cmd <= CMD_PRECHARGE_ALL;
					addr <= 13'b0_0100_0000_0000;
					wait_counter <= tRP_CYCLES;   // arm PRECHARGE's wait
				end else begin
					wait_counter <= wait_counter - 1;
					cmd <= CMD_NOP;
					end
				end

			PRECHARGE: begin
				if (wait_counter == 0) begin
					state <= REFRESH;
					ba <= 2'b00;
					cmd <= CMD_AUTO_REFRESH;
					wait_counter <= tRC_CYCLES;   // arm REFRESH's wait
					refresh_counter <= AUTO_REFRESH_COUNT-1;
				end else begin
					wait_counter <= wait_counter - 1;
					cmd <= CMD_NOP;
					end
				end

			REFRESH: begin
				if (wait_counter != 0) begin
					wait_counter <= wait_counter - 1;
					cmd <= CMD_NOP;
				end else if (refresh_counter != 0) begin
					wait_counter <= tRC_CYCLES;
					refresh_counter <= refresh_counter - 1;
					cmd <= CMD_AUTO_REFRESH;
				end else begin
					state <= MODE_REG;
					addr <= MODE_REG_WORD;
					ba <= 2'b00;
					wait_counter <= tRSC_CYCLES;
					cmd <= CMD_MODE_REG_SET;
					end
				end

			MODE_REG: begin
				if (wait_counter != 0) begin
					wait_counter <= wait_counter - 1;
					cmd <= CMD_NOP;
				end else begin 
					state <= DONE;
					end 
				end 

			DONE: begin
				done <= 1;
				cmd <= CMD_NOP;
				end
			endcase
		end
	end

endmodule
