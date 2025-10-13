`timescale 1ns / 1ps

module bfly4 #(
    parameter IN_WIDTH = 13,
    parameter OUT_WIDTH = 14
)(
    input clk,
    input rstn,
    input  signed [IN_WIDTH-1:0] din_i [0:3],
    input  signed [IN_WIDTH-1:0] din_q [0:3],
 
    output logic signed [OUT_WIDTH-1:0] dout_re [0:3],
    output logic signed [OUT_WIDTH-1:0] dout_im [0:3]
);

    // 단순 4포인트 버터플라이 예시
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout_re <= '{default:0};
            dout_im <= '{default:0};
        end else begin
            dout_re[0] <= din_i[0] + din_i[2];
            dout_re[1] <= din_i[1] + din_i[3];
            dout_re[2] <= din_i[0] - din_i[2];
            dout_re[3] <= din_i[1] - din_i[3];

            dout_im[0] <= din_q[0] + din_q[2];
            dout_im[1] <= din_q[1] + din_q[3];
            dout_im[2] <= din_q[0] - din_q[2];
            dout_im[3] <= din_q[1] - din_q[3];
        end
    end

endmodule