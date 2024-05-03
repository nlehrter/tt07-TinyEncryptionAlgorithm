module tea_plain (
    input i_clk,
    input i_rst,
    input i_calculate,
    input i_round_key_valid,
    input [3:0] [31:0] i_round_key_data,
    
    input [7:0] i_plain_update,
    input i_plain_update_valid,

    output [7:0] o_encrypted_data,
    output o_encrypted_valid
);

    localparam IDLE = 2'b00;
    localparam RUNNING_0 = 2'b01;
    localparam RUNNING_1 = 2'b10;
    localparam DONE = 2'b11;

    logic [63:0] plain_input;
    logic [63:0] plain_input_n;

    logic [63:0] plain_update;

    logic [1:0] [31:0] plain;
    logic [1:0] [31:0] plain_n;

    logic [31:0] ls0;
    logic [31:0] ns0;
    logic [31:0] rs0;
    logic [31:0] x0;

    logic [31:0] ls1;
    logic [31:0] ns1;
    logic [31:0] rs1;

    logic [31:0] sum;
    logic [31:0] sum_n;

    logic [$clog2(15):0] count;
    logic [$clog2(15):0] count_n;

    logic [31:0] v1_n;
    logic [31:0] v0_n;

    logic [5:0] calc_count;
    logic [5:0] calc_count_n;

    logic [2:0] tx_count;
    logic [2:0] tx_count_n;

    logic [3:0] txu_count;
    logic [3:0] txu_count_n;

    logic [1:0] [31:0] calculation_out;
    // State machine for the tea encryption algorithm
    logic [1:0] tea_FSM;
    logic [1:0] tea_FSM_n;

    logic [7:0] encrypted_i;

    // Update logic
    always_ff @ (posedge i_clk, posedge i_rst) begin
        if (i_rst) begin
            count <= '0;
            plain_input <= '0;
        end else if (i_clk) begin
            count <= count_n;
            plain_input <= plain_update;
        end
    end

    assign count_n = (plain_update_valid_i) ? (count == 8) ? '0 : count + 1 : count;

	 always_comb begin
		 for (int i = 0; i < 8; i++) begin
             for (int j = 0; j < 8; j++) begin
                plain_input_n[(8*i) + j] = (plain_update_valid_i && i == count) ? i_plain_update[j] : plain_input[(8*i) + j];
            end	
		 end
	 end

    assign plain[0] = plain_input[31:0];
    assign plain[1] = plain_input[63:32];

    assign plain_update_valid_i = (!i_calculate) && i_plain_update_valid;

    // When running we disable the plain update logic - the run signal should be held high until computation is complete

    // Compute the tea 128 encrypted value

    // Register update on clock cycle
    always_ff @ (posedge i_clk, posedge i_rst) begin
        if (i_rst) begin
            tea_FSM <= IDLE;
        end else if (i_clk) begin
            tea_FSM <= tea_FSM_n;
        end
    end

    always_comb begin
        case (tea_FSM)
            IDLE: tea_FSM_n = (i_calculate&&i_round_key_valid) ? RUNNING_0 : IDLE;
            // Can we compute the ROUNDF xor in one cycle? Yes
            RUNNING_0: tea_FSM_n = RUNNING_1;
            RUNNING_1: tea_FSM_n = (calc_count == 32) ? DONE : RUNNING_0;
            DONE: tea_FSM_n = (tx_count == 7 && txu_count ==10) ? IDLE : DONE;
            default: tea_FSM_n = 2'bxx;
        endcase
    end


    assign ls0 = (plain[1] << 4) + i_round_key_data[0];
    assign ns0 = plain[1] + sum;
    assign rs0 = (plain[1] >> 5) + i_round_key_data[1];
    assign x0 = ls0 ^ ns0 ^ rs0;

    assign ls1 = (plain[0] << 4) + i_round_key_data[2];
    assign ns1 = plain[0] + sum;
    assign rs1 = (plain[0] >> 5) + i_round_key_data[3];


    // Calculation counter
    assign calc_count_n = (tea_FSM_n == RUNNING_0) ? (calc_count == 32) ? '0 : calc_count + 1 : calc_count;
    assign tx_count_n = (tea_FSM == DONE) ? (tx_count == 7 &&txu_count == 10) ? '0 : (txu_count == 10) ? tx_count + 1 : tx_count : tx_count;
    assign txu_count_n = (tea_FSM == DONE) ? (txu_count == 10) ? '0 : txu_count + 1 : txu_count;
    assign sum_n = (tea_FSM_n == RUNNING_0) ? sum + 'd2654435769 : sum;

    always_ff @ (posedge i_clk, posedge i_rst) begin
        if (i_rst) begin
            calc_count <= '0;
            tx_count <= '0;
            txu_count <= '0;
            sum <= '0;
        end else if (i_clk) begin
            calc_count <= calc_count_n;
            tx_count <= tx_count_n;
            txu_count <= txu_count_n;
            sum <= sum_n;
        end
    end

    assign v0_n = plain[0] + x0;
    assign v1_n = plain[1] + (ls1 ^ ns1 ^ rs1);
    always_comb begin
        if(i_calculate) begin
            if(tea_FSM == RUNNING_0) begin
                plain_update = {plain[1],v0_n};
            end else if (tea_FSM == RUNNING_1) begin
                plain_update = {v1_n,plain[0]};
            end else begin
                plain_update = plain_input;
            end
        end else begin
            plain_update = plain_input_n;
        end
    end

    
    
    assign o_encrypted_data = (tx_count == 'b000) ? plain_input[7:0]:
                              (tx_count == 'b001) ? plain_input[15:8]:
                              (tx_count == 'b010) ? plain_input[23:16]:
                              (tx_count == 'b011) ? plain_input[31:24]:
                              (tx_count == 'b100) ? plain_input[39:32]:
                              (tx_count == 'b101) ? plain_input[47:40]:
                              (tx_count == 'b110) ? plain_input[55:48]:
                              (tx_count == 'b111) ? plain_input[63:56]:
                              3'bx;

    assign o_encrypted_valid = tea_FSM == DONE;

endmodule