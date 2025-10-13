`timescale 1ns / 1ps

module module2 #(
    parameter IN_BIT_WIDTH = 12,  //12bit 
    parameter OUT_BIT_WIDTH = 13,  //13bit
    parameter N = 16,  //묶음
    parameter BF00_BIT = 13,  //
    parameter BF01_BIT = 16,  //
    parameter BF02_BIT = 16,  //
    parameter TOTAL_BLOCK_CNT = 32  //total block cnt 32
) (
    input clk,
    input rstn,

    input                           valid_in,
    input signed [IN_BIT_WIDTH-1:0] din_i   [0:N-1],  //re input
    input signed [IN_BIT_WIDTH-1:0] din_q   [0:N-1],  //im input

    input logic [4:0] index_in0  [0:N-1],
    input logic [4:0] index_in1  [0:N-1],
    input       valid_in_m0,
    input       valid_in_m1,

    output                            valid_out,
    output signed [OUT_BIT_WIDTH-1:0] dout_i   [0:N-1],  //re output
    output signed [OUT_BIT_WIDTH-1:0] dout_q   [0:N-1]   //im output
);

    logic signed [BF00_BIT-1:0] o_bf20_re[0:N-1], o_bf20_im[0:N-1];
    logic valid_out_bf20;

    logic signed [BF01_BIT-1:0] o_bf21_re[0:N-1], o_bf21_im[0:N-1];
    logic valid_out_bf21;

    logic signed [BF02_BIT-1:0] o_bf22_re[0:N-1], o_bf22_im[0:N-1];
    logic valid_out_bf22;

    //logic signed [OUT_BIT_WIDTH-1:0] o_cbfp2_re[0:N-1], o_cbfp2_im[0:N-1];
    //logic valid_out_cbfp2;


    butterfly20 #() U_BF20 (
        .clk (clk),
        .rstn(rstn),

        .din_i   (din_i),    //Re value
        .din_q   (din_q),    //Im value
        .valid_in(valid_in), //valid input

        .do_re    (o_bf20_re),      //Re out
        .do_im    (o_bf20_im),      //Im out
        .valid_out(valid_out_bf20)  //valid output
    );

    butterfly21 #() U_BF21 (
        .clk (clk),
        .rstn(rstn),

        .din_i(o_bf20_re),
        .din_q(o_bf20_im),
        .valid_in(valid_out_bf20),

        .do1_re(o_bf21_re),
        .do1_im(o_bf21_im),
        .valid_out(valid_out_bf21)
    );

    butterfly22 #() U_BF22 (
        .clk (clk),
        .rstn(rstn),

        .din_i   (o_bf21_re),  // Re value
        .din_q   (o_bf21_im),  // Im value
        .valid_in(valid_out_bf21),  // valid input

        .do1_re(o_bf22_re),  // Re out (saturated)
        .do1_im(o_bf22_im),  // Im out (saturated)
        .valid_out(valid_out_bf22)         // valid output (output logic으로 직접 레지스터화)
    );

    cbfp_stage2 #() U_CBFP2 (
        .clk (clk),
        .rstn(rstn),

        .real_in (o_bf22_re),
        .imag_in (o_bf22_im),
        .in_valid(valid_out_bf22),

        .index0_in(index_in0),
        .in_valid_index0(valid_in_m0),
        .index1_in(index_in1),
        .in_valid_index1(valid_in_m1),

        .real_out (dout_i),
        .imag_out (dout_q),
        .valid_out(valid_out)
    );

    //assign dout_i = o_cbfp2_re;
    //assign dout_q = o_cbfp2_im;
    //assign valid_out = valid_out_cbfp2;

    // assign dout_i = o_cbfp2_re;
    // assign dout_q = o_cbfp2_im;
    // assign valid_out = valid_out_cbfp2;




















    // shift_reg_with_valid_out #(
    //     .WIDTH(OUT_BIT_WIDTH),
    //     .DELAY_LENGTH(TOTAL_BLOCK_CNT)
    // ) U_SHIFT_REG_OUTPUT (
    //     .clk (clk),
    //     .rstn(rstn),

    //     .write(valid_out_cbfp),  // 16개 묶음 복소수 쓰기
    //     .read(full_cnt),  // 16개 묶음 복소수 읽기

    //     .data_in_real(o_cbfp_re),
    //     .data_in_imag(o_cbfp_im),

    //     .data_out_real(dout_i),
    //     .data_out_imag(dout_q),

    //     .valid_out(valid_out)  //값이 나올때 같이 high
    // );

    // //index buffer
    // logic [4:0] index_out_buffer[0:TOTAL_BLOCK_CNT-1][0:N-1];
    // integer i, j;
    // always @(posedge clk, negedge rstn) begin
    //     if (~rstn) begin
    //         for (i = 0; i < TOTAL_BLOCK_CNT; i = i + 1) begin
    //             for (j = 0; j < N; j = j + 1) begin
    //                 index_out_buffer[i][j] <= 0;
    //             end
    //         end
    //     end else begin
    //         if (full_cnt) begin
    //             cbfp_index <= index_out_buffer[TOTAL_BLOCK_CNT-1];
    //             index_out_buffer[1:TOTAL_BLOCK_CNT-1] <= index_out_buffer[0:TOTAL_BLOCK_CNT-2];
    //             for (i = 0; i < N; i = i + 1) begin
    //                 index_out_buffer[0][i] <= 0;
    //             end
    //         end else if (valid_out_cbfp) begin
    //             index_out_buffer[1:TOTAL_BLOCK_CNT-1] <= index_out_buffer[0:TOTAL_BLOCK_CNT-2];
    //             index_out_buffer[0] <= cbfp_index_out;
    //         end
    //     end
    // end

endmodule
