`timescale 1ns / 1ps

module cbfp_stage2 #(
    parameter int BW_IN           = 16,
    parameter int BW_OUT          = 13,
    parameter int TARGET_INT_BITS = 23,
    parameter int BATCH_SIZE      = 16
) (
    input logic clk,
    input logic rstn,

    input logic signed [BW_IN-1:0] real_in [0:BATCH_SIZE-1],
    input logic signed [BW_IN-1:0] imag_in [0:BATCH_SIZE-1],
    input logic                    in_valid,

    input logic [4:0] index0_in      [0:BATCH_SIZE-1],
    input logic       in_valid_index0,
    input logic [4:0] index1_in      [0:BATCH_SIZE-1],
    input logic       in_valid_index1,

    output logic signed [BW_OUT-1:0] real_out [0:BATCH_SIZE-1],
    output logic signed [BW_OUT-1:0] imag_out [0:BATCH_SIZE-1],
    output logic                     valid_out
);
    int i, j, k, a, b, c, d, e;

    logic index0_val_delay;
    logic index1_val_delay;

    logic signed [BW_IN-1:0]
        real_in_shift[0:BATCH_SIZE-1], imag_in_shift[0:BATCH_SIZE-1];

    shift_reg #(
        .WIDTH(16),
        .DELAY_LENGTH(26)
    ) U_SHIFT (
        .clk (clk),
        .rstn(rstn),

        .write(1'd1),  // 16개 묶음 복소수 쓰기
        .read (1'd1),  // 16개 묶음 복소수 읽기

        .data_in_real(real_in),
        .data_in_imag(imag_in),

        .data_out_real(real_in_shift),
        .data_out_imag(imag_in_shift)
    );

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            index1_val_delay <= 0;
            index0_val_delay <= 0;
        end else begin
            index1_val_delay <= in_valid_index1;
            index0_val_delay <= in_valid_index0;
        end
    end

    // index_0의 값 실시간 저장
    logic [4:0] ind0_reg[0:511];
    logic [5:0] input_cnt_0;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            input_cnt_0 <= 0;
            for (i = 0; i < 512; i++) begin
                ind0_reg[i] <= 0;
            end
        end else if (in_valid_index0 || index0_val_delay) begin
            for (i = 0; i < BATCH_SIZE; i++) begin
                automatic int idx_0 = input_cnt_0 * BATCH_SIZE + i;
                ind0_reg[idx_0] <= index0_in[i];
            end
            input_cnt_0 <= input_cnt_0 + 1;
        end else if (input_cnt_0 >= 32) begin
            input_cnt_0 <= 0;
        end
    end


    // index_1의 값 실시간 저장
    logic [4:0] ind1_reg[0:511];
    logic [5:0] input_cnt_1;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            input_cnt_1 <= 0;
            for (j = 0; j < 512; j++) begin
                ind1_reg[j] <= 0;
            end
        end else if (in_valid_index1 || index1_val_delay) begin
            for (j = 0; j < BATCH_SIZE; j++) begin
                automatic int idx_1 = input_cnt_1 * BATCH_SIZE + j;
                ind1_reg[idx_1] <= index1_in[j];
            end
            input_cnt_1 <= input_cnt_1 + 1;
        end else if (input_cnt_1 >= 32) begin
            input_cnt_1 <= 0;
        end
    end

    logic shift_ready, sum_ready;
    logic done_idx0, done_idx1;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            done_idx0 <= 0;
        end else if (input_cnt_0 >= 32) begin
            done_idx0 <= 1;
        end else if (sum_ready) done_idx0 <= 0;
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            done_idx1 <= 0;
        end else if (input_cnt_1 >= 32) begin
            done_idx1 <= 1;
        end else if (sum_ready) done_idx1 <= 0;
    end


    logic [5:0] index_sum[0:511];  // 최대 5+5비트 = 6비트

    logic [5:0] input_cnt_data;

    // index_sum 저장
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sum_ready <= 0;
            for (k = 0; k < 512; k++) begin
                index_sum[k] <= 0;
            end
        end else if (done_idx0 && done_idx1 && !sum_ready) begin
            for (k = 0; k < 512; k++) begin
                index_sum[k] <= ind0_reg[k] + ind1_reg[k];
            end
            sum_ready <= 1;
        end else if (shift_ready) sum_ready <= 0;
    end

    // shift 값 음수 방지
    logic signed [5:0] shift_amt_reg[0:511];
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shift_ready <= 0;
            for (a = 0; a < 512; a++) begin
                shift_amt_reg[a] <= 0;
            end
        end else if (sum_ready) begin
            for (a = 0; a < 512; a++) begin
                if ((index_sum[a] >= 9) && (index_sum[a] < TARGET_INT_BITS))
                    shift_amt_reg[a] <= -(index_sum[a] - 9);
                else shift_amt_reg[a] <= 9 - index_sum[a];
            end
            shift_ready <= 1;
        end else if (input_cnt_data >= 32) shift_ready <= 0;
    end


    logic signed [BW_IN-1:0] real_in_reg[0:BATCH_SIZE-1];
    logic signed [BW_IN-1:0] imag_in_reg[0:BATCH_SIZE-1];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (e = 0; e < BATCH_SIZE; e++) begin
                real_in_reg[e] <= '0;
                imag_in_reg[e] <= '0;
            end
        end else begin
            // real_in_reg <= real_in;
            // imag_in_reg <= imag_in;
            real_in_reg <= real_in_shift;
            imag_in_reg <= imag_in_shift;
        end
    end

    // input delay
    logic signed [BW_IN-1:0] real_buf[0:BATCH_SIZE-1];
    logic signed [BW_IN-1:0] imag_buf[0:BATCH_SIZE-1];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (c = 0; c < BATCH_SIZE; c = c + 1) begin
                real_buf[c] <= '0;
                imag_buf[c] <= '0;
            end
        end else begin
            for (c = 0; c < BATCH_SIZE; c = c + 1) begin
                real_buf[c] <= real_in_reg[c];
                imag_buf[c] <= imag_in_reg[c];
            end
        end
    end

    // input delay + 1
    logic signed [BW_IN-1:0] real_buf_d[0:BATCH_SIZE-1];
    logic signed [BW_IN-1:0] imag_buf_d[0:BATCH_SIZE-1];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (d = 0; d < BATCH_SIZE; d++) begin
                real_buf_d[d] <= '0;
                imag_buf_d[d] <= '0;
            end
        end else begin
            for (d = 0; d < BATCH_SIZE; d++) begin
                real_buf_d[d] <= real_buf[d];
                imag_buf_d[d] <= imag_buf[d];
            end
        end
    end


    // shift
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            input_cnt_data <= 0;
            valid_out <= 0;
            for (b = 0; b < BATCH_SIZE; b++) begin
                real_out[b] <= 0;
                imag_out[b] <= 0;
            end
        end else if (input_cnt_data == 32) begin
            valid_out <= 0;
            input_cnt_data <= 0;
        end else if (shift_ready && (input_cnt_data <= 31)) begin
            valid_out <= 1;
            for (b = 0; b < BATCH_SIZE; b++) begin
                automatic int idx = input_cnt_data * BATCH_SIZE + b;
                automatic logic signed [5:0] shift_amt = shift_amt_reg[idx];
                if (index_sum[idx] >= TARGET_INT_BITS) begin
                    real_out[b] <= 0;
                    imag_out[b] <= 0;
                end else if (shift_amt < 0) begin
                    real_out[b] <= (real_buf_d[b] >>> (-shift_amt));
                    imag_out[b] <= (imag_buf_d[b] >>> (-shift_amt));
                end else begin
                    real_out[b] <= (real_buf_d[b] <<< shift_amt);
                    imag_out[b] <= (imag_buf_d[b] <<< shift_amt);
                end
            end
            input_cnt_data <= input_cnt_data + 1;
        end else begin
            for (b = 0; b < BATCH_SIZE; b++) begin
                real_out[b] <= 0;
                imag_out[b] <= 0;
            end
        end


    end

endmodule
