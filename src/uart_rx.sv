module uart_rx (
    input clk,
    input rst,
    input Rx,

    output data_valid,
    output [7:0] data,
	output [7:0] debug_rx,
	output rx_serial,
	output rx_serial_valid
);

    localparam IDLE = 2'b00;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    localparam RX_BITS = 8;

    logic [1:0] Rx_FSM;
    logic [1:0] Rx_FSM_nxt;
    logic [3:0] count;
	 logic [3:0] count_n;
    logic output_i;
    logic [7:0] rx_data_i;

	 logic rx_n;
	 logic rx_i;
	 
	 always_ff @ (posedge clk) begin
		if (clk) begin
			rx_n <= Rx;
			rx_i <= rx_n;
		end
	 end
	 
	 initial  begin
		rx_data_i <= 'b00000000;
	 end
    // FSM traversal logic - IDLE until we have data, then START for one cycle, DATA for 8 cycles and
    // STOP for one cycle.
    always_comb begin
        case (Rx_FSM)
            IDLE:  Rx_FSM_nxt = (rx_i == 1'b0) ? DATA : IDLE;
            DATA:  Rx_FSM_nxt = (count == RX_BITS-1) ? STOP : DATA;
            STOP:  Rx_FSM_nxt = IDLE;
            default: Rx_FSM_nxt = 'bxx;
        endcase
    end

    // Register update on clock cycle
    always_ff @ (posedge clk, posedge rst) begin
        if (rst) begin
            Rx_FSM <= IDLE;
        end else if (clk) begin
            Rx_FSM <= Rx_FSM_nxt;
        end
    end

    assign count_n = (Rx_FSM == DATA) ? count + 1 : 'b000;
	 assign rx_serial_valid = (Rx_FSM == DATA);
	 assign rx_serial = rx_i;
	 
    // Update count on clock cycle
    always_ff @ (posedge clk, posedge rst) begin
        if (rst) begin
            count <= 'b000;
				rx_data_i <= 'b00000000;
        end else if (clk) begin
				rx_data_i[count] <= rx_i;
            count <= count_n;
        end
    end

    // Assign the ouput based on the current state of the FSM
	assign output_i = (Rx_FSM == IDLE) ? 'b0 :
                      (Rx_FSM == DATA) ? 'b0 : 
                      (Rx_FSM == STOP) ? 'b1 : 'bx;

    // Set output rx data and indicate when it is valid data
    assign data_valid = output_i;
    assign data = rx_data_i;
	 
	 assign debug_rx[4] = Rx_FSM == STOP;
	 assign debug_rx[5] = Rx_FSM == DATA;
	 assign debug_rx[6] =  Rx_FSM == IDLE;
	 assign debug_rx[7] = output_i;
endmodule