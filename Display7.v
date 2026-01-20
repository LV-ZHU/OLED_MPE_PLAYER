`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/19 02:08:39
// Design Name: 
// Module Name: Display7
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
module Display7(
    input CLK,
    input [15: 0] DATA,   // 时间（秒） mm:ss
    input [15: 0] VOL,    // 音量编码，例如 0x0000,0x1010..0xF0F0
    input [2:0]  CURRENT, // 当前歌曲索引 0..7
    output reg [6: 0] SEG,
    output reg [7: 0] SHIFT,
    output reg DOT
);
    wire scan_clock_divider;
    Divider #(.Time(200000)) u_scan_clock_div(CLK, scan_clock_divider);//分频
    initial SHIFT = 8'b01111111;
    reg [31: 0] scan_digits; // [31:16] 左侧两位（歌曲/音量），[15:0] 右侧四位（时间）
    integer volume_level;
    
    reg [4: 0] digit_select_index;
    always @ (posedge scan_clock_divider) begin 
        SHIFT <= {SHIFT[6:0], SHIFT[7]};
        digit_select_index <= digit_select_index+4;// 在扫描中间两位时点亮小数点以显示:      
        if(SHIFT[1]==0) 
            DOT <= 0;
        else 
            DOT <= 1;
        scan_digits[3: 0]  <= DATA % 10;              // 秒 1
        scan_digits[7: 4]  <= (DATA / 10) % 6;        // 秒 10
        scan_digits[11: 8] <= (DATA / 60) % 10;       // 分 1
        scan_digits[15:12] <= (DATA / 600);           // 分 10
        // 3-4位 VOL级别 1..16
        volume_level = 16-(VOL[15:12]);                 // 0x0..0xF  1..16
        scan_digits[23:20] <= (volume_level / 10);            // 音量十位
        scan_digits[19:16] <= (volume_level % 10);            // 音量个位
        // 左两位显示歌曲编号
        scan_digits[31:28] <= (CURRENT / 10);        // 歌曲十位
        scan_digits[27:24] <= (CURRENT % 10);        // 歌曲个位
        //下面直接用之前小作业的七段数码管模块
        case ({scan_digits[digit_select_index+3], scan_digits[digit_select_index+2], scan_digits[digit_select_index+1], scan_digits[digit_select_index]}) 
            4'b0000: begin
                SEG<=7'b1000000;
            end
            4'b0001: begin
                SEG<=7'b1111001;
            end
            4'b0010: begin
                SEG<=7'b0100100;
            end
            4'b0011: begin
                SEG<=7'b0110000;
            end
            4'b0100: begin
                SEG<=7'b0011001;
            end
            4'b0101: begin
                SEG<=7'b0010010;
            end
            4'b0110: begin
                SEG<=7'b0000010;
            end
            4'b0111: begin
                SEG<=7'b1111000;
            end
            4'b1000: begin
                SEG<=7'b0000000;
            end
            4'b1001: begin
                SEG<=7'b0010000;
            end
            default: begin
                SEG<=7'b1111111;
            end
        endcase
    end
endmodule
