module tea_encrypt (
    input i_clk,
    input i_rst,
    input i_key_update,
    input i_rx,
    // Input signal to tell the system to calculate the encrypted bits with the current
    // key and plaintext in the internal regs
    input i_calculate,

    output o_tx,
    output o_ready
);

    logic encrypted_valid_i;
    logic [7:0] encrypted_i;

    logic [7:0] key_update_i;
    logic key_update_valid_i;

    logic [7:0] plain_update_i;
    logic plain_update_valid_i;

    logic [3:0] [31:0] round_key_i;
    logic round_key_valid_i;

    tea_frontend frontend (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_key_update(i_key_update),
        .i_rx(i_rx),
        .i_encrypted_valid(encrypted_valid_i),
        .i_encrypted(encrypted_i),
        .i_calculate(i_calculate),

        .o_key_update(key_update_i),
        .o_key_update_valid(key_update_valid_i),
        .o_plain_update(plain_update_i),
        .o_plain_update_valid(plain_update_valid_i),
        .o_tx(o_tx),
        .o_ready(o_ready)
    );

    tea_key key (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_calculate(i_calculate),
        
        .i_key_update(key_update_i),
        .i_key_update_valid(key_update_valid_i),

        .o_key(round_key_i),
        .o_key_valid(round_key_valid_i)
    );
    
    tea_plain plain (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_calculate(i_calculate),
        
        .i_plain_update(plain_update_i),
        .i_plain_update_valid(plain_update_valid_i),

        .o_encrypted_valid(encrypted_valid_i),
        .o_encrypted_data(encrypted_i),

        .i_round_key_data(round_key_i),
        .i_round_key_valid(round_key_valid_i)
    );
    

endmodule