`timescale 1ns / 1ps

module butterfly22 #(
    parameter IN_WIDTH  = 16,            // input bit width 16bit
    parameter OUT_WIDTH = 16,            // output bit width for saturation (16bit)
    parameter NUM       = 16             // number of line
) (
    input clk,
    input rstn,

    input signed [IN_WIDTH-1:0] din_i  [0:NUM-1],   // Re value
    input signed [IN_WIDTH-1:0] din_q  [0:NUM-1],   // Im value
    input                                valid_in,         // valid input

    output logic signed [OUT_WIDTH-1:0] do1_re  [0:NUM-1],   // Re out (saturated)
    output logic signed [OUT_WIDTH-1:0] do1_im  [0:NUM-1],   // Im out (saturated)
    output logic                               valid_out         // valid output (output logic으로 직접 레지스터화)
);

    // Stage 1: 버터플라이 연산 결과를 저장할 레지스터
    localparam MID_WIDTH = IN_WIDTH + 1; // 16 + 1 = 17bit
    logic signed [MID_WIDTH-1:0] temp_re_stage1 [0:NUM-1]; // Stage 1의 Re 결과 레지스터
    logic signed [MID_WIDTH-1:0] temp_im_stage1 [0:NUM-1]; // Stage 1의 Im 결과 레지스터

    // valid_in을 Stage 1에서 지연시킬 레지스터
    logic valid_stage1_reg; // valid_in을 1클럭 지연

    genvar i;

    // =========================================================
    // Pipeline Stage 1 (Butterfly Operation + Register)
    // Inputs: din_i, din_q, valid_in
    // Outputs (Registers, next clock cycle): temp_re_stage1, temp_im_stage1, valid_stage1_reg
    // =========================================================
    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            for (integer j = 0; j < NUM; j = j + 1) begin
                temp_re_stage1[j] <= 0;
                temp_im_stage1[j] <= 0;
            end // <--- 여기에 'end' 추가 (원래 에러의 원인)
            valid_stage1_reg <= 1'b0;
        end
        else begin
            // Perform butterfly operation on current inputs and store in Stage 1 registers
            temp_re_stage1[0]  <= din_i[0] + din_i[1];
            temp_re_stage1[1]  <= din_i[0] - din_i[1];
            temp_re_stage1[2]  <= din_i[2] + din_i[3];
            temp_re_stage1[3]  <= din_i[2] - din_i[3];
            temp_re_stage1[4]  <= din_i[4] + din_i[5];
            temp_re_stage1[5]  <= din_i[4] - din_i[5];
            temp_re_stage1[6]  <= din_i[6] + din_i[7];
            temp_re_stage1[7]  <= din_i[6] - din_i[7];
            temp_re_stage1[8]  <= din_i[8] + din_i[9];
            temp_re_stage1[9]  <= din_i[8] - din_i[9];
            temp_re_stage1[10] <= din_i[10] + din_i[11];
            temp_re_stage1[11] <= din_i[10] - din_i[11];
            temp_re_stage1[12] <= din_i[12] + din_i[13];
            temp_re_stage1[13] <= din_i[12] - din_i[13];
            temp_re_stage1[14] <= din_i[14] + din_i[15];
            temp_re_stage1[15] <= din_i[14] - din_i[15];

            temp_im_stage1[0]  <= din_q[0] + din_q[1];
            temp_im_stage1[1]  <= din_q[0] - din_q[1];
            temp_im_stage1[2]  <= din_q[2] + din_q[3];
            temp_im_stage1[3]  <= din_q[2] - din_q[3];
            temp_im_stage1[4]  <= din_q[4] + din_q[5];
            temp_im_stage1[5]  <= din_q[4] - din_q[5];
            temp_im_stage1[6]  <= din_q[6] + din_q[7];
            temp_im_stage1[7]  <= din_q[6] - din_q[7];
            temp_im_stage1[8]  <= din_q[8] + din_q[9];
            temp_im_stage1[9]  <= din_q[8] - din_q[9];
            temp_im_stage1[10] <= din_q[10] + din_q[11];
            temp_im_stage1[11] <= din_q[10] - din_q[11];
            temp_im_stage1[12] <= din_q[12] + din_q[13];
            temp_im_stage1[13] <= din_q[12] - din_q[13];
            temp_im_stage1[14] <= din_q[14] + din_q[15];
            temp_im_stage1[15] <= din_q[14] - din_q[15];

            valid_stage1_reg <= valid_in; // valid_in을 Stage 1 레지스터에 저장 (1클럭 지연)
        end
    end

    // =========================================================
    // Pipeline Stage 2 (Saturation and Final Output Registers)
    // Inputs (from Stage 1 Registers): temp_re_stage1, temp_im_stage1, valid_stage1_reg
    // Outputs (Registers directly to output ports): do1_re, do1_im, valid_out
    // =========================================================
    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            for (integer j = 0; j < NUM; j = j + 1) begin
                do1_re[j] <= 0;
                do1_im[j] <= 0;
            end
            valid_out <= 1'b0; // valid_out 레지스터 초기화
        end
        else begin
            // Stage 1의 레지스터 결과를 받아 새츄레이션 후 최종 출력 레지스터에 저장
            for (integer j = 0; j < NUM; j = j + 1) begin
                do1_re[j] <= saturate(temp_re_stage1[j], OUT_WIDTH);
                do1_im[j] <= saturate(temp_im_stage1[j], OUT_WIDTH);
            end
            // valid_out도 Stage 1 valid 레지스터를 받아 2클럭 지연되도록 함
            valid_out <= valid_stage1_reg;
        end
    end

    // Saturation function (no change)
    function automatic signed [OUT_WIDTH-1:0] saturate (
        input signed [MID_WIDTH-1:0] input_val,
        input integer target_width
    );
        logic signed [OUT_WIDTH-1:0] max_val = (2**(OUT_WIDTH-1)) - 1;
        logic signed [OUT_WIDTH-1:0] min_val = -(2**(OUT_WIDTH-1));

        if (input_val > max_val) begin
            saturate = max_val;
        end else if (input_val < min_val) begin
            saturate = min_val;
        end else begin
            saturate = input_val[OUT_WIDTH-1:0];
        end
    endfunction

endmodule