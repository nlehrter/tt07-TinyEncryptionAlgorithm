/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_nlehrter (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

// All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  for (genvar i = 2; i < 8;i++) begin
    assign uio_out[i] = 0;
    assign uio_oe[i]  = 0;
  end

  assign uio_oe[0] = 1;
  assign uio_oe[1] = 1;


  tea_encrypt u_tea_encrypt (
    .i_clk(clk),
    .i_rst(ui_in[0]),
    .i_key_update(ui_in[1]),
    .i_calculate(ui_in[2]),
    .i_rx(ui_in[3]),
    
    .o_tx(uo_out[0]),
    .o_ready(uo_out[1])
    );


endmodule
