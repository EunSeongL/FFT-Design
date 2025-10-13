`timescale 1ns / 1ps

module FFT #(
    parameter IN_WIDTH          = 9,   //<3.6>format
    parameter OUT_WIDTH         = 13,  //<9.4> foramt 
    parameter NUM               = 16,  //묶음 수
    parameter MODULE0_OUT_WIDTH = 11,
    parameter MODULE1_OUT_WIDTH = 12,
    parameter MODULE2_OUT_WIDTH = 13
) (
    input clk,
    input rstn,

    input                       valid_in,
    input signed [IN_WIDTH-1:0] din_i   [0:NUM-1],
    input signed [IN_WIDTH-1:0] din_q   [0:NUM-1],

    output                        valid_out,
    output signed [OUT_WIDTH-1:0] dout_i   [0:NUM-1],
    output signed [OUT_WIDTH-1:0] dout_q   [0:NUM-1]
);

    logic signed [MODULE0_OUT_WIDTH-1:0]
        o_module0_re[0:NUM-1], o_module0_im[0:NUM-1];
    logic valid_out_module0;

    logic signed [MODULE1_OUT_WIDTH-1:0]
        o_module1_re[0:NUM-1], o_module1_im[0:NUM-1];
    logic valid_out_module1;

    logic signed [MODULE2_OUT_WIDTH-1:0]
        o_module2_re[0:NUM-1], o_module2_im[0:NUM-1];
    logic valid_out_module2;

    
    logic [4:0] o_cbfp0_index[0:NUM-1];
    logic [4:0] o_cbfp1_index[0:NUM-1];

    module0 #() U_MODULE0 (
        .clk (clk),
        .rstn(rstn),

        .valid_in(valid_in),
        .din_i(din_i),  //re input
        .din_q(din_q),  //im input

        .valid_out(valid_out_module0),
        .dout_i(o_module0_re),  //re output
        .dout_q(o_module0_im),  //im output

        .cbfp_index(o_cbfp0_index)
    );

    module1 #() U_MODULE1 (
        .clk (clk),
        .rstn(rstn),

        .valid_in(valid_out_module0),
        .din_i(o_module0_re),  //re input
        .din_q(o_module0_im),  //im input

        .valid_out(valid_out_module1),
        .dout_i(o_module1_re),  //re output
        .dout_q(o_module1_im),  //im output

        .cbfp_index(o_cbfp1_index)
    );

    module2 #() U_MODULE2 (
        .clk (clk),
        .rstn(rstn),

        .valid_in(valid_out_module1),
        .din_i(o_module1_re),  //re input
        .din_q(o_module1_im),  //im input

        .index_in0  (o_cbfp0_index),
        .index_in1  (o_cbfp1_index),
        .valid_in_m0(valid_out_module0),
        .valid_in_m1(valid_out_module1),

        .valid_out(valid_out_module2),
        .dout_i(o_module2_re),  //re output
        .dout_q(o_module2_im)  //im output
    );

    reorder #() U_REORDER (
        .clk (clk),
        .rstn(rstn),

        .valid_in(valid_out_module2),
        .din_i(o_module2_re),
        .din_q(o_module2_im),

        .valid_out(valid_out),
        .dout_i(dout_i),
        .dout_q(dout_q)
    );


endmodule