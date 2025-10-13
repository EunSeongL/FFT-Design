`timescale 1ns / 1ps

module cbfp_stage1 #(
    parameter int BW_IN = 25,
    parameter int BW_OUT = 12,
    parameter int TARGET_INT_BITS = 13,
    parameter int BLOCK_SIZE = 8,
    parameter int BATCH_SIZE = 16
) (
    input logic                    clk,
    input logic                    rstn,
    input logic signed [BW_IN-1:0] real_in [0:BATCH_SIZE-1],
    input logic signed [BW_IN-1:0] imag_in [0:BATCH_SIZE-1],
    input logic                    in_valid,

    output logic signed [BW_OUT-1:0] real_out [0:BATCH_SIZE-1],
    output logic signed [BW_OUT-1:0] imag_out [0:BATCH_SIZE-1],
    output logic        [       4:0] index_out[0:BATCH_SIZE-1],
    output logic                     valid_out
);

    logic signed [ BW_IN-1:0] real_buf  [0:1] [0:BLOCK_SIZE-1];
    logic signed [ BW_IN-1:0] imag_buf  [0:1] [0:BLOCK_SIZE-1];

    // 정규화 shift 관련 제어
    logic        [       4:0] shift_val [0:1];

    // 정규화 결과 저장
    logic signed [BW_OUT-1:0] norm_real [0:1] [0:BLOCK_SIZE-1];
    logic signed [BW_OUT-1:0] norm_imag [0:1] [0:BLOCK_SIZE-1];
    logic        [       4:0] norm_index[0:1] [0:BLOCK_SIZE-1];

    int i, j, k, a, b, c, d;

    logic in_valid_d;
    logic valid_delay;
    logic valid_delay2;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            in_valid_d  <= 0;
            valid_delay <= 0;
            valid_delay2 <= 0;
        end else begin
            in_valid_d  <= in_valid;
            valid_delay <= in_valid_d;
            valid_delay2 <= valid_delay;
        end
    end

    logic signed [BW_IN-1:0] real_in_reg[0:BATCH_SIZE-1];
    logic signed [BW_IN-1:0] imag_in_reg[0:BATCH_SIZE-1];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (d = 0; d < BATCH_SIZE; d++) begin
                real_in_reg[d] <= '0;
                imag_in_reg[d] <= '0;
            end
        end else begin
            real_in_reg <= real_in;
            imag_in_reg <= imag_in;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < BATCH_SIZE; i++) begin
                automatic int block = i / BLOCK_SIZE;
                automatic int idx = i % BLOCK_SIZE;
                real_buf[block][idx] <= 0;
                imag_buf[block][idx] <= 0;
            end
        end else if (in_valid || valid_delay) begin
            for (i = 0; i < BATCH_SIZE; i++) begin
                automatic int block = i / BLOCK_SIZE;
                automatic int idx = i % BLOCK_SIZE;
                real_buf[block][idx] <= real_in_reg[i];
                imag_buf[block][idx] <= imag_in_reg[i];
            end
        end
    end

    logic signed [BW_IN-1:0] real_delay[0:1][0:BLOCK_SIZE-1];
    logic signed [BW_IN-1:0] imag_delay[0:1][0:BLOCK_SIZE-1];

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (b = 0; b < 2; b++) begin
                for (c = 0; c < BLOCK_SIZE; c = c + 1) begin
                    real_delay[b][c] <= '0;
                    imag_delay[b][c] <= '0;
                end
            end
        end else begin
            for (b = 0; b < 2; b++) begin
                for (c = 0; c < BLOCK_SIZE; c = c + 1) begin
                    real_delay[b][c] <= real_buf[b][c];
                    imag_delay[b][c] <= imag_buf[b][c];
                end
            end
        end
    end

    logic out_valid_0;
    logic out_valid_1;
    mag_detect_1 #(
        .WIDTH(BW_IN)
    ) u_mag_detect_0 (
        .clk(clk),
        .rstn(rstn),
        .valid(valid_delay ),
        .di_re(real_buf[0]),
        .di_im(imag_buf[0]),
        .min_chain(shift_val[0]),
        .out_valid(out_valid_0)
    );

    mag_detect_1 #(
        .WIDTH(BW_IN)
    ) u_mag_detect_1 (
        .clk(clk),
        .rstn(rstn),
        .valid(valid_delay ),
        .di_re(real_buf[1]),
        .di_im(imag_buf[1]),
        .min_chain(shift_val[1]),
        .out_valid(out_valid_1)
    );

    logic last;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            last <= 0;
            for (a = 0; a < 2; a++) begin
                for (j = 0; j < BLOCK_SIZE; j++) begin
                    norm_real[a][j]  <= 0;
                    norm_imag[a][j]  <= 0;
                    norm_index[a][j] <= 0;
                end
            end
        end else if (out_valid_0 && out_valid_1) begin
            for (a = 0; a < 2; a++) begin
                for (j = 0; j < BLOCK_SIZE; j++) begin
                    norm_real[a][j] <= (shift_val[a] > TARGET_INT_BITS)
                        ? (real_delay[a][j] <<< shift_val[a]) >>> TARGET_INT_BITS
                        : (real_delay[a][j] >>> (TARGET_INT_BITS - shift_val[a]));

                    norm_imag[a][j] <= (shift_val[a] > TARGET_INT_BITS)
                        ? (imag_delay[a][j] <<< shift_val[a]) >>> TARGET_INT_BITS
                        : (imag_delay[a][j] >>> (TARGET_INT_BITS - shift_val[a]));

                    norm_index[a][j] <= shift_val[a];
                end
            end
            last <= 1;
        end else begin
            last <= 0;
        end
    end

    logic [5:0] val_cnt;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (k = 0; k < BATCH_SIZE; k++) begin
                real_out[k]  <= 0;
                imag_out[k]  <= 0;
                index_out[k] <= 0;
            end
            val_cnt   <= 0;
            valid_out <= 0;
        end else if (last == 1) begin
            valid_out <= 1;
            for (k = 0; k < BATCH_SIZE; k++) begin
                automatic int block_o = k / BLOCK_SIZE;
                automatic int idx_o = k % BLOCK_SIZE;
                real_out[k]  <= norm_real[block_o][idx_o];
                imag_out[k]  <= norm_imag[block_o][idx_o];
                index_out[k] <= norm_index[block_o][idx_o];
            end
            val_cnt <= val_cnt + 1;
        end else if (val_cnt >= 31) begin
            valid_out <= 0;
            val_cnt   <= 0;
            // 기본값 할당
            for (k = 0; k < BATCH_SIZE; k++) begin
                real_out[k]  <= 0;
                imag_out[k]  <= 0;
                index_out[k] <= 0;
            end
        end else begin
            // 기본값 할당
            for (k = 0; k < BATCH_SIZE; k++) begin
                real_out[k]  <= 0;
                imag_out[k]  <= 0;
                index_out[k] <= 0;
            end
            valid_out <= 0;
        end
    end

endmodule
