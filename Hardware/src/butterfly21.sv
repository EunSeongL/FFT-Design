`timescale 1ns / 1ps

module butterfly21 #(
    parameter IN_WIDTH  = 13,
    parameter OUT_WIDTH = 16, //15
    parameter NUM       = 16,
    parameter DATA      = 4,
    parameter COUNT     = NUM / DATA
)(
    input clk,
    input rstn,

    input  signed [IN_WIDTH-1:0] din_i [0:NUM-1],
    input  signed [IN_WIDTH-1:0] din_q [0:NUM-1],
    input                        valid_in,

    output signed [OUT_WIDTH-1:0] do1_re [0:NUM-1],
    output signed [OUT_WIDTH-1:0] do1_im [0:NUM-1],
    output                        valid_out
);

    // 내부 4포인트 버터플라이 출력
    logic signed [OUT_WIDTH-3:0] bfly_re [0:NUM-1];
    logic signed [OUT_WIDTH-3:0] bfly_im [0:NUM-1];

    localparam TMP_WIDTH = IN_WIDTH + 1;  // 버터플라이 add/sub 결과 <5.6>
    localparam TW_WIDTH  = 10;            // twiddle factor <2.8>
    localparam integer SHIFT = 8;
    localparam signed [TW_WIDTH+TMP_WIDTH:0] HALF = 1 << (SHIFT-1); // 256/2 = 128

    integer i;
    logic [1:0] valid_pipe; 
    logic valid_out_reg;

    // valid 파이프라인
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_pipe <= 0;
            valid_out_reg <= 0;
        end else begin
            valid_pipe <= {valid_pipe[0], valid_in};  // 시프트
            valid_out_reg <= valid_pipe[0];           // 1클럭 더 지연
        end
    end

    // 4포인트 버터플라이 그룹 생성
    genvar g;
    generate
        for (g = 0; g < COUNT; g = g + 1) begin : BFLY_GROUP
            bfly4 #(
                .IN_WIDTH (IN_WIDTH),
                .OUT_WIDTH(OUT_WIDTH-2)
            ) bfly4_inst (
                .clk      (clk),
                .rstn     (rstn),
                .din_i    (din_i[g*DATA +: DATA]),
                .din_q    (din_q[g*DATA +: DATA]),
                .dout_re  (bfly_re[g*DATA +: DATA]),
                .dout_im  (bfly_im[g*DATA +: DATA])
            );
        end
    endgenerate

    // twiddle factor <2.8> 8개 (real, imag)
    logic signed [9:0] tw_re [0:7];
    logic signed [9:0] tw_im [0:7];

    always_ff @(posedge clk or negedge rstn) begin
        integer i;
        if (!rstn) begin
            for (i = 0; i < 8; i++) begin
                tw_re[i] <= 0;
                tw_im[i] <= 0;
            end
        end else begin
            tw_re[0] <=  256; tw_im[0] <=    0;    // 256 + j*0
            tw_re[1] <=  256; tw_im[1] <=    0;    // 256 + j*0
            tw_re[2] <=  256; tw_im[2] <=    0;    // 256 + j*0
            tw_re[3] <=    0; tw_im[3] <= -256;    // -j*256
            tw_re[4] <=  256; tw_im[4] <=    0;    // 256 + j*0
            tw_re[5] <=  181; tw_im[5] <= -181;    // 181 - j*181
            tw_re[6] <=  256; tw_im[6] <=    0;    // 256 + j*0
            tw_re[7] <= -181; tw_im[7] <= -181;    // -181 - j*181
        end
    end

    // twiddle 곱 결과
    logic signed [TW_WIDTH+(OUT_WIDTH-1):0] mul_re [0:NUM-1];
    logic signed [TW_WIDTH+(OUT_WIDTH-1):0] mul_im [0:NUM-1];

    // 곱셈 결과 저장
    always_ff @(posedge clk or negedge rstn) begin
        integer i;
        if (!rstn) begin
            for (i = 0; i < NUM; i=i+1) begin
                mul_re[i] <= 0;
                mul_im[i] <= 0;
            end
        end else begin
            for (i = 0; i < NUM; i=i+1) begin
                int tw_idx;
                tw_idx = i % 8;  // twiddle index 반복
                mul_re[i] <= (bfly_re[i] * tw_re[tw_idx]) - (bfly_im[i] * tw_im[tw_idx]);
                mul_im[i] <= (bfly_re[i] * tw_im[tw_idx]) + (bfly_im[i] * tw_re[tw_idx]);
            end
        end
    end

    // 라운딩 + 절댓값 처리
    logic signed [OUT_WIDTH-1:0] out_re[0:NUM-1], out_im[0:NUM-1];
    logic signed [TW_WIDTH+TMP_WIDTH:0] abs_re, abs_im;
    logic [SHIFT-1:0]                 frac_re, frac_im;
    logic signed [TW_WIDTH+TMP_WIDTH:0] mag_int_re, mag_int_im;
    
    always @(*) begin
        for (i = 0; i < NUM; i = i + 1) begin
            abs_re = (mul_re[i] < 0) ? -mul_re[i] : mul_re[i];
            abs_im = (mul_im[i] < 0) ? -mul_im[i] : mul_im[i];
            mag_int_re = abs_re >>> SHIFT;
            mag_int_im = abs_im >>> SHIFT;
            frac_re    = abs_re[SHIFT-1:0];
            frac_im    = abs_im[SHIFT-1:0];
            if (frac_re >= HALF) mag_int_re += 1;
            if (frac_im >= HALF) mag_int_im += 1;
            out_re[i] = (mul_re[i] < 0) ? -mag_int_re : mag_int_re;
            out_im[i] = (mul_im[i] < 0) ? -mag_int_im : mag_int_im;
        end
    end

    // 최종 출력
    assign do1_re = out_re;
    assign do1_im = out_im;
    assign valid_out = valid_out_reg; 

endmodule