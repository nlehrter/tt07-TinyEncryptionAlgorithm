module tea_key (

    input i_clk,
    input i_rst,
    input i_calculate,
    
    input [7:0] i_key_update,
    input i_key_update_valid,

    output [3:0] [31:0] o_key,
    output o_key_valid
);

    logic [3:0] [31:0] key;
    logic [127:0] input_key;
    logic [127:0] input_key_n;
    logic [$clog2(15):0] count;
    logic [$clog2(15):0] count_n;

    logic key_update_valid_i;

    // Update logic
    always_ff @ (posedge i_clk, posedge i_rst) begin
        if (i_rst) begin
            count <= '0;
            input_key <= '0;
        end else if (i_clk) begin
            count <= count_n;
            input_key <= input_key_n;
        end
    end

    assign count_n = (key_update_valid_i) ? (count == 15) ? '0 : count + 1 : count;

	always_comb begin
		for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 8; j++) begin
                input_key_n[(8*i) + j] = (key_update_valid_i && i == count) ? i_key_update[j] : input_key[(8*i) + j];
            end
		end
	end

    assign key[0] = input_key[31:0];
    assign key[1] = input_key[63:32];
    assign key[2] = input_key[95:64];
    assign key[3] = input_key[127:96];

    assign key_update_valid_i = (!i_calculate) && i_key_update_valid;
    assign o_key = key;
    assign o_key_valid = !key_update_valid_i;
    // When running we disable the key update logic - the run signal should be held high until computation is complete
endmodule