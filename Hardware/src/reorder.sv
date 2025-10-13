`timescale 1ns / 1ps

module reorder #(
    parameter WIDTH       = 13,  //<9.4> format
    parameter NUM         = 16,  //묶음
    parameter TOTAL_COUNT = 512
) (
    input clk,
    input rstn,

    input                    valid_in,
    input signed [WIDTH-1:0] din_i   [0:NUM-1],
    input signed [WIDTH-1:0] din_q   [0:NUM-1],

    output logic                    valid_out,
    output logic signed [WIDTH-1:0] dout_i   [0:NUM-1],
    output logic signed [WIDTH-1:0] dout_q   [0:NUM-1]
);

    logic signed [WIDTH-1:0]
        output_buffer_re[0:TOTAL_COUNT-1], output_buffer_im[0:TOTAL_COUNT-1];
    logic [4:0] reorder_count;
    logic [$clog2(TOTAL_COUNT)-1:0] temp_addr;
    logic [$clog2(TOTAL_COUNT)-1:0] reorder_idx[0:NUM-1];
    logic [$clog2(TOTAL_COUNT/16)-1:0] output_count;
    logic valid_in_post;
    logic [32:0] valid_in_reg;
    integer i;

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            reorder_count <= 0;
        end else begin
            if (valid_in) begin
                reorder_count <= reorder_count + 1;
            end else begin
                reorder_count <= 0;
            end
        end
    end

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            valid_in_reg <= 0;
        end else begin
            valid_in_reg[32:1] <= valid_in_reg[31:0];
            valid_in_reg[0] <= valid_in;
        end
    end
    assign valid_out = valid_in_reg[32];

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            output_count  <= 0;
        end else begin
            if (valid_in_reg[31]) begin
                output_count <= output_count + 1;
            end else if (output_count > 31)begin
                output_count <= 0;
            end
        end
    end

    always @(*) begin
        for (i = 0; i < NUM; i = i + 1) begin
            temp_addr = {reorder_count, 4'd0} + i;

            reorder_idx[i] = {
                temp_addr[0],
                temp_addr[1],
                temp_addr[2],
                temp_addr[3],
                temp_addr[4],
                temp_addr[5],
                temp_addr[6],
                temp_addr[7],
                temp_addr[8]
            };
        end
    end

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            for (i = 0; i < TOTAL_COUNT; i = i + 1) begin
                output_buffer_re[i] <= 0;
                output_buffer_im[i] <= 0;
            end
        end else if (valid_in) begin
            for (i = 0; i < NUM; i = i + 1) begin
                output_buffer_re[reorder_idx[i]] <= din_i[i];
                output_buffer_im[reorder_idx[i]] <= din_q[i];
            end
        end
    end

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            for (i = 0; i < NUM ; i = i + 1 ) begin
                dout_i[i] <= 0;
                dout_q[i] <= 0;
            end
        end
        else if (valid_in_reg[31]) begin
            for (i = 0; i < NUM ; i = i + 1 ) begin
                dout_i[i] <= output_buffer_re[output_count*16 + i];
                dout_q[i] <= output_buffer_im[output_count*16 + i];
            end    
        end
    end

endmodule
