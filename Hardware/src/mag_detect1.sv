`timescale 1ns/1ps

module mag_detect_1 #(
    parameter int WIDTH = 25
) (
    input logic clk,
    input logic rstn,
    input logic valid,
    input logic signed [WIDTH - 1:0] di_re[0:7],
    input logic signed [WIDTH - 1:0] di_im[0:7],
    output logic [4:0] min_chain,
    output logic out_valid  
);
    logic [WIDTH-1:0] mag_cnt_re[0:7];
    logic [WIDTH-1:0] mag_cnt_im[0:7];
    genvar i,j;

    for(i=0; i<8; i = i + 1) begin: gen_all
    // === Real Part ===
    assign mag_cnt_re[i] =
            (di_re[i][23:0] == 'h0) && ~di_re[i][24] ? 5'd24 :
            (di_re[i][23:1] == 'h0) && ~di_re[i][24] ? 5'd23 :
            (di_re[i][23:2] == 'h0) && ~di_re[i][24] ? 5'd22 :
            (di_re[i][23:3] == 'h0) && ~di_re[i][24] ? 5'd21 :
            (di_re[i][23:4] == 'h0) && ~di_re[i][24] ? 5'd20 :
            (di_re[i][23:5] == 'h0) && ~di_re[i][24] ? 5'd19 :
            (di_re[i][23:6] == 'h0) && ~di_re[i][24] ? 5'd18 :
            (di_re[i][23:7] == 'h0) && ~di_re[i][24] ? 5'd17 :
            (di_re[i][23:8] == 'h0) && ~di_re[i][24] ? 5'd16 :
            (di_re[i][23:9] == 'h0) && ~di_re[i][24] ? 5'd15 :
            (di_re[i][23:10] == 'h0) && ~di_re[i][24] ? 5'd14 :
            (di_re[i][23:11] == 'h0) && ~di_re[i][24] ? 5'd13 :
            (di_re[i][23:12] == 'h0) && ~di_re[i][24] ? 5'd12 :
            (di_re[i][23:13] == 'h0) && ~di_re[i][24] ? 5'd11 :
            (di_re[i][23:14] == 'h0)  && ~di_re[i][24] ? 5'd10  :
            (di_re[i][23:15] == 'h0)  && ~di_re[i][24] ? 5'd9  :
            (di_re[i][23:16] == 'h0)  && ~di_re[i][24] ? 5'd8  :
            (di_re[i][23:17] == 'h0)  && ~di_re[i][24] ? 5'd7  :
            (di_re[i][23:18] == 'h0)  && ~di_re[i][24] ? 5'd6  :
            (di_re[i][23:19] == 'h0)  && ~di_re[i][24] ? 5'd5  :
            (di_re[i][23:20] == 'h0)  && ~di_re[i][24] ? 5'd4  :
            (di_re[i][23:21] == 'h0)  && ~di_re[i][24] ? 5'd3  :
            (di_re[i][23:22] == 'h0)  && ~di_re[i][24] ? 5'd2  :
            (di_re[i][23:23] == 'h0)  && ~di_re[i][24] ? 5'd1  :
            (di_re[i][23:0] == 24'hFFFFFF) && di_re[i][24] ? 5'd24 :
            (di_re[i][23:1] == 23'h7FFFFF) && di_re[i][24] ? 5'd23 :
            (di_re[i][23:2] == 22'h3FFFFF) && di_re[i][24] ? 5'd22 :
            (di_re[i][23:3] == 21'h1FFFFF) && di_re[i][24] ? 5'd21 :
            (di_re[i][23:4] == 20'hFFFFF) && di_re[i][24] ? 5'd20 :
            (di_re[i][23:5] == 19'h7FFFF) && di_re[i][24] ? 5'd19 :
            (di_re[i][23:6] == 18'h3FFFF) && di_re[i][24] ? 5'd18 :
            (di_re[i][23:7] == 17'h1FFFF) && di_re[i][24] ? 5'd17 :
            (di_re[i][23:8] == 16'hFFFF) && di_re[i][24] ? 5'd16 :
            (di_re[i][23:9] == 15'h7FFF) && di_re[i][24] ? 5'd15 :
            (di_re[i][23:10] == 14'h3FFF) && di_re[i][24] ? 5'd14 :
            (di_re[i][23:11] == 13'h1FFF) && di_re[i][24] ? 5'd13 :
            (di_re[i][23:12] == 12'hFFF) && di_re[i][24] ? 5'd12 :
            (di_re[i][23:13] == 11'h7FF) && di_re[i][24] ? 5'd11 :
            (di_re[i][23:14] == 10'h3FF)  && di_re[i][24] ? 5'd10  :
            (di_re[i][23:15] == 9'h1FF)  && di_re[i][24] ? 5'd9  :
            (di_re[i][23:16] == 8'hFF)  && di_re[i][24] ? 5'd8  :
            (di_re[i][23:17] == 7'h7F)  && di_re[i][24] ? 5'd7  :
            (di_re[i][23:18] == 6'h3F)  && di_re[i][24] ? 5'd6  :
            (di_re[i][23:19] == 5'h1F)  && di_re[i][24] ? 5'd5  :
            (di_re[i][23:20] == 4'hF)  && di_re[i][24] ? 5'd4  :
            (di_re[i][23:21] == 3'h7)  && di_re[i][24] ? 5'd3  :
            (di_re[i][23:22] == 2'h3)  && ~di_re[i][24] ? 5'd2  :
            (di_re[i][23:23] == 1'h1)  && ~di_re[i][24] ? 5'd1  :
            5'd0;

    // === Imag Part ===
    assign mag_cnt_im[i] =
            (di_im[i][23:0] == 'h0) && ~di_im[i][24] ? 5'd24 :
            (di_im[i][23:1] == 'h0) && ~di_im[i][24] ? 5'd23 :
            (di_im[i][23:2] == 'h0) && ~di_im[i][24] ? 5'd22 :
            (di_im[i][23:3] == 'h0) && ~di_im[i][24] ? 5'd21 :
            (di_im[i][23:4] == 'h0) && ~di_im[i][24] ? 5'd20 :
            (di_im[i][23:5] == 'h0) && ~di_im[i][24] ? 5'd19 :
            (di_im[i][23:6] == 'h0) && ~di_im[i][24] ? 5'd18 :
            (di_im[i][23:7] == 'h0) && ~di_im[i][24] ? 5'd17 :
            (di_im[i][23:8] == 'h0) && ~di_im[i][24] ? 5'd16 :
            (di_im[i][23:9] == 'h0) && ~di_im[i][24] ? 5'd15 :
            (di_im[i][23:10] == 'h0) && ~di_im[i][24] ? 5'd14 :
            (di_im[i][23:11] == 'h0) && ~di_im[i][24] ? 5'd13 :
            (di_im[i][23:12] == 'h0) && ~di_im[i][24] ? 5'd12 :
            (di_im[i][23:13] == 'h0) && ~di_im[i][24] ? 5'd11 :
            (di_im[i][23:14] == 'h0)  && ~di_im[i][24] ? 5'd10  :
            (di_im[i][23:15] == 'h0)  && ~di_im[i][24] ? 5'd9  :
            (di_im[i][23:16] == 'h0)  && ~di_im[i][24] ? 5'd8  :
            (di_im[i][23:17] == 'h0)  && ~di_im[i][24] ? 5'd7  :
            (di_im[i][23:18] == 'h0)  && ~di_im[i][24] ? 5'd6  :
            (di_im[i][23:19] == 'h0)  && ~di_im[i][24] ? 5'd5  :
            (di_im[i][23:20] == 'h0)  && ~di_im[i][24] ? 5'd4  :
            (di_im[i][23:21] == 'h0)  && ~di_im[i][24] ? 5'd3  :
            (di_im[i][23:22] == 'h0)  && ~di_im[i][24] ? 5'd2  :
            (di_im[i][23:23] == 'h0)  && ~di_im[i][24] ? 5'd1  :
            (di_im[i][23:0] == 24'hFFFFFF) && di_im[i][24] ? 5'd24 :
            (di_im[i][23:1] == 23'h7FFFFF) && di_im[i][24] ? 5'd23 :
            (di_im[i][23:2] == 22'h3FFFFF) && di_im[i][24] ? 5'd22 :
            (di_im[i][23:3] == 21'h1FFFFF) && di_im[i][24] ? 5'd21 :
            (di_im[i][23:4] == 20'hFFFFF) && di_im[i][24] ? 5'd20 :
            (di_im[i][23:5] == 19'h7FFFF) && di_im[i][24] ? 5'd19 :
            (di_im[i][23:6] == 18'h3FFFF) && di_im[i][24] ? 5'd18 :
            (di_im[i][23:7] == 17'h1FFFF) && di_im[i][24] ? 5'd17 :
            (di_im[i][23:8] == 16'hFFFF) && di_im[i][24] ? 5'd16 :
            (di_im[i][23:9] == 15'h7FFF) && di_im[i][24] ? 5'd15 :
            (di_im[i][23:10] == 14'h3FFF) && di_im[i][24] ? 5'd14 :
            (di_im[i][23:11] == 13'h1FFF) && di_im[i][24] ? 5'd13 :
            (di_im[i][23:12] == 12'hFFF) && di_im[i][24] ? 5'd12 :
            (di_im[i][23:13] == 11'h7FF) && di_im[i][24] ? 5'd11 :
            (di_im[i][23:14] == 10'h3FF)  && di_im[i][24] ? 5'd10  :
            (di_im[i][23:15] == 9'h1FF)  && di_im[i][24] ? 5'd9  :
            (di_im[i][23:16] == 8'hFF)  && di_im[i][24] ? 5'd8  :
            (di_im[i][23:17] == 7'h7F)  && di_im[i][24] ? 5'd7  :
            (di_im[i][23:18] == 6'h3F)  && di_im[i][24] ? 5'd6  :
            (di_im[i][23:19] == 5'h1F)  && di_im[i][24] ? 5'd5  :
            (di_im[i][23:20] == 4'hF)  && di_im[i][24] ? 5'd4  :
            (di_im[i][23:21] == 3'h7)  && di_im[i][24] ? 5'd3  :
            (di_im[i][23:22] == 2'h3)  && ~di_im[i][24] ? 5'd2  :
            (di_im[i][23:23] == 1'h1)  && ~di_im[i][24] ? 5'd1  :
            5'd0;
    end
    
    logic [4:0] local_min;

    always_comb begin
        local_min = 5'd31;
        for (int i = 0; i < 8; i++) begin
            automatic logic [4:0] min_val = (mag_cnt_re[i] < mag_cnt_im[i]) ? mag_cnt_re[i] : mag_cnt_im[i];
            if (min_val < local_min)
                local_min = min_val;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            min_chain  <= 5'd0;
            out_valid <= 0;
        end else if(valid)begin
            out_valid <= 1;
            min_chain <= local_min;
        end else begin
            out_valid <= 0;
            min_chain <= 0;
        end
    end


endmodule
