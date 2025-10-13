`timescale 1ns / 1ps

module cbfp_stage0 #(
    parameter int BW_IN = 23,
    parameter int BW_OUT = 11,
    parameter int TARGET_INT_BITS = 12,
    parameter int BLOCK_SIZE = 64,
    parameter int BATCH_SIZE = 16
) (
    input logic                    clk,
    input logic                    rstn,
    input logic signed [BW_IN-1:0] real_in [0:BATCH_SIZE-1],
    input logic signed [BW_IN-1:0] imag_in [0:BATCH_SIZE-1],
    input                          in_valid,

    output logic signed [BW_OUT-1:0] real_out [0:BATCH_SIZE-1],
    output logic signed [BW_OUT-1:0] imag_out [0:BATCH_SIZE-1],
    output logic        [       4:0] index_out[0:BATCH_SIZE-1],
    output                           valid_out
);
    // 입출력 및 shift 카운터
    logic [1:0] input_cnt;
    logic [1:0] output_cnt;
    int i, j, k, a,b,c;

    // 값 저장 버퍼
    logic signed [BW_IN-1:0] real_buf[0:BLOCK_SIZE-1];
    logic signed [BW_IN-1:0] imag_buf[0:BLOCK_SIZE-1];

    // 정규화 shift 관련 제어
    logic [4:0] shift_val;

    // 정규화 결과 저장
    logic signed [BW_OUT-1:0] norm_real[0:BLOCK_SIZE-1];
    logic signed [BW_OUT-1:0] norm_imag[0:BLOCK_SIZE-1];
    logic [4:0] norm_index[0:BLOCK_SIZE-1];

    logic last;
    logic [5:0] out_cnt;

    logic in_valid_d;
    
    always @(posedge clk, negedge rstn) begin
        if(!rstn) begin
            in_valid_d <= 0;
        end else begin
            in_valid_d <= in_valid;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            input_cnt <= 0;
            for (i = 0; i < BLOCK_SIZE; i++) begin
                real_buf[i] <= 0;
                imag_buf[i] <= 0;
            end            
        end else if (in_valid || in_valid_d) begin
            for (i = 0; i < BATCH_SIZE; i++) begin
                automatic int idx = input_cnt * BATCH_SIZE + i;
                real_buf[idx] <= real_in[i];
                imag_buf[idx] <= imag_in[i];
            end
            input_cnt <= input_cnt + 1;
        end else if (input_cnt == 3) begin
            input_cnt <= 0;
        end
    end



    logic signed [BW_IN-1:0] real_in_d [0:BATCH_SIZE-1];
    logic signed [BW_IN-1:0] imag_in_d [0:BATCH_SIZE-1];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (b = 0; b < BATCH_SIZE; b++) begin
                real_in_d[b] <= 0;
                imag_in_d[b] <= 0;
            end            
        end else if (in_valid || in_valid_d) begin
            for (b = 0; b < BATCH_SIZE; b++) begin
                real_in_d[b] <= real_in[b];
                imag_in_d[b] <= imag_in[b];
            end
        end
    end

    logic signed [BW_IN-1:0] real_buf_d[0:BLOCK_SIZE-1];
    logic signed [BW_IN-1:0] imag_buf_d[0:BLOCK_SIZE-1];
    logic mag_valid;

    // 버퍼용 always_ff
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (a = 0; a < BLOCK_SIZE; a++) begin
                real_buf_d[a] <= '0;
                imag_buf_d[a] <= '0;
            end
        end else if(in_valid || mag_valid)begin
            for (a = 0; a < BLOCK_SIZE; a++) begin
                real_buf_d[a] <= real_buf[a];
                imag_buf_d[a] <= imag_buf[a];
            end
        end
    end



    logic [6:0] valid_in_buf1;

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            valid_in_buf1 <= 0;
        end else begin
            valid_in_buf1[6:1] <= valid_in_buf1[5:0];
            valid_in_buf1[0]   <= in_valid;
        end
    end


    assign valid_out = valid_in_buf1[6];
    assign mag_valid = in_valid | valid_in_buf1[5];

    logic out_valid;
    mag_detect_0 #(
        .WIDTH(BW_IN)
    ) u_mag_block (
        .clk(clk),
        .rstn(rstn),
        .valid(mag_valid),
        .di_re(real_in_d),
        .di_im(imag_in_d),
        .min_chain(shift_val),
        .out_valid(out_valid)
    );

    
    always @(posedge clk, negedge rstn) begin
        if(~rstn) begin
            out_cnt <= 0;
        end else if (last) begin
            out_cnt <= out_cnt + 1;
        end else out_cnt <= 0;

    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                norm_real[j] <= 0;
                norm_imag[j] <= 0;
                norm_index[j] <= 0;
            end
            last <= 0;
        end else if (out_valid) begin
            for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                norm_real[j]  <= (shift_val > 12) ? (real_buf_d[j] <<< shift_val) >>> 12
                                  : (real_buf_d[j] >>> (12 - shift_val));
                norm_imag[j]  <= (shift_val > 12) ? (imag_buf_d[j] <<< shift_val) >>> 12
                                  : (imag_buf_d[j] >>> (12 - shift_val));
                norm_index[j] <= shift_val[4:0];
            end
            last <= 1;
        end else if(out_cnt >= 32) last <= 0;
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            output_cnt <= 0;
            for (k = 0; k < BATCH_SIZE; k = k + 1) begin
                real_out[k] <= 0;
                imag_out[k] <= 0;
                index_out[k] <= 0;
            end
        end else if (last == 1 && (out_cnt <= 31)) begin
            int idx_o;
            for (k = 0; k < BATCH_SIZE; k = k + 1) begin
                idx_o = output_cnt * BATCH_SIZE + k;
                real_out[k]  <= norm_real[idx_o];
                imag_out[k]  <= norm_imag[idx_o];
                index_out[k] <= norm_index[idx_o];
            end
            output_cnt <= output_cnt + 1;
        end else begin
            // 기본값 할당
            for (k = 0; k < BATCH_SIZE; k = k + 1) begin
                real_out[k] <= 0;
                imag_out[k] <= 0;
                index_out[k] <= 0;
            end
            if (output_cnt == 3) output_cnt <= 0;
        end
    end


endmodule