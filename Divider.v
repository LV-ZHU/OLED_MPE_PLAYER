`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/19 02:08:47
// Design Name: 
// Module Name: Divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Divider #(parameter Time=20)
(
    input I_CLK,
    output reg O_CLK
);
    integer div_count=0;
    initial O_CLK = 0;
    always @ (posedge I_CLK)
    begin
        if((div_count+1)==Time/2)
        begin
            div_count <= 0;
            O_CLK <= ~O_CLK;
        end
        else
            div_count <= div_count+1;
    end
endmodule
