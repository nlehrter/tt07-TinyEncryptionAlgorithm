module uart_tx (
    input clk,
    input rst,
    input data_valid,
    input [7:0] data,

    output Tx,
	output [7:0] debug_led

);

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    localparam TX_BITS = 8;

    logic [1:0] Tx_FSM;
    logic [1:0] Tx_FSM_nxt;
    logic [3:0] count;
	 logic [3:0] count_n;
    logic output_i;
    logic tx_data_i;

    // FSM traversal logic - IDLE until we have data, then START for one cycle, DATA for 8 cycles and
    // STOP for one cycle.
    always_comb begin
        case (Tx_FSM)
            IDLE: Tx_FSM_nxt = (data_valid == 1) ? START : IDLE;
            START: Tx_FSM_nxt = DATA;
            DATA: Tx_FSM_nxt = (count == TX_BITS-1) ? STOP : DATA;
            STOP: Tx_FSM_nxt = IDLE;
            default: Tx_FSM_nxt = 2'bxx;
        endcase
    end

    // Register update on clock cycle
    always_ff @ (posedge clk, posedge rst) begin
        if (rst) begin
            Tx_FSM <= IDLE;
        end else if (clk) begin
            Tx_FSM <= Tx_FSM_nxt;
        end
    end

    assign count_n = (Tx_FSM == DATA) ? count + 1 : 0;
    assign tx_data_i = data[count];

    // Update count on clock cycle
    always_ff @ (posedge clk) begin
        if (clk) begin
            count <= count_n;
        end
    end

    // Assign the ouput based on the current state of the FSM
	assign output_i = (Tx_FSM == IDLE) ? 'b1 :
               (Tx_FSM == START) ? 'b0 : 
               (Tx_FSM == DATA) ? tx_data_i : 
               (Tx_FSM == STOP) ? 'b1 : 'bx;

    assign Tx = (Tx_FSM != DATA) ? output_i : tx_data_i;
	 
	 assign debug_led = data;
	 /*
	 assign debug_led[0] = count[0];
	 assign debug_led[1] = count[1];
	 assign debug_led[2] = count[2];
	 
	 assign debug_led[5] = Tx_FSM == STOP;
	 assign debug_led[6] = Tx_FSM == DATA;
	 assign debug_led[7] = Tx_FSM == START;
	 
	 assign debug_led[4] = 0;
	 assign debug_led[3] = 0;
	 */
endmodule