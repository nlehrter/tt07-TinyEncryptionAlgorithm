module tea_frontend (
    input i_clk,
    input i_rst,
    input i_key_update,
    input i_rx,
    input i_encrypted_valid,
    input [7:0] i_encrypted,
    input i_calculate,

    output [7:0] o_key_update,
    output o_key_update_valid,
    output [7:0] o_plain_update,
    output o_plain_update_valid,
    output o_tx,
    output o_ready
);
    logic [7:0] rx_data_i;
    logic rx_data_valid_i;

    logic [7:0] tx_data_i;
    logic tx_data_valid_i;

    // Receive data from the FPGA
    uart_rx u1 (
        .clk(i_clk),
        .rst(i_rst),
        .Rx(i_rx),
        .data_valid(rx_data_valid_i),
        .data(rx_data_i)
    );

    // Transmit data back to the FPGA
    uart_tx u2 (
        .clk(i_clk),
        .rst(i_rst),
        .data_valid(tx_data_valid_i),
        .data(tx_data_i),
        .Tx(o_tx)
    );

    assign o_key_update = rx_data_i;
    assign o_plain_update = rx_data_i;

    // Only allow update to the register values when we are not calculating encrypted text
    assign o_plain_update_valid = rx_data_valid_i && !i_key_update && !i_calculate;
    assign o_key_update_valid = rx_data_valid_i && i_key_update && !i_calculate;

    // Only need valid for one cycle to send all of the valid data
    // For now only allow tx back to the host when calculation is complete
    assign tx_data_valid_i = i_encrypted_valid  && i_calculate;
    assign tx_data_i = i_encrypted;
    
endmodule