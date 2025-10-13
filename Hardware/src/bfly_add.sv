`timescale 1ns/1ps

module bfly_add #(
    parameter N = 16,
    parameter IN_BIT = 10,
    parameter OUT_BIT = 11
)(
    input  clk,
    input  rstn,

    input  signed [IN_BIT-1:0] din1_i[0:15],  
    input  signed [IN_BIT-1:0] din1_q[0:15],  
    input  signed [IN_BIT-1:0] din2_i[0:15],  
    input  signed [IN_BIT-1:0] din2_q[0:15],  

    output logic signed [OUT_BIT-1:0] dout1_i[0:15],  // add  
    output logic signed [OUT_BIT-1:0] dout1_q[0:15],   
    output logic signed [OUT_BIT-1:0] dout2_i[0:15],  // sub
    output logic signed [OUT_BIT-1:0] dout2_q[0:15]
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin 
            assign dout1_i[i] = din2_i[i] + din1_i[i];
            assign dout1_q[i] = din2_q[i] + din1_q[i];
            assign dout2_i[i] = din2_i[i] - din1_i[i];
            assign dout2_q[i] = din2_q[i] - din1_q[i];
        end
    endgenerate

endmodule
