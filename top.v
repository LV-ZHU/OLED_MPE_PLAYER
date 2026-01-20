`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/19 02:08:35
// Design Name: 
// Module Name: top
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

module top(
    input CLK, // 输入主时钟，系统时钟
    input RST, // 低电平有效复位
    // MP3，接JC
    input DREQ,      // VS1003 数据请求信号
    output XDCS, // 数据片选
    output XCS,  // 命令片选
    output RSET, 
    output SI,   // 数据输入
    output SCLK,  // VS1003 时钟
    // 按键
    input BTNC,
    input BTNU,
    input BTND,
    input BTNL,
    input BTNR,
    // 开关用于直接选择歌曲
    input [15:0] SW,
    // 7 段数码管
    output [6: 0] SEG,
    output [7: 0] SHIFT,
    output DOT,
    // OLED 接口，接JB
    output DIN,
    output OLED_CLK,
    output CS,
    output DC,
    output RES,
    // 音量显示 LED
    output [15: 0] led
);
    wire [15:0] vol_code_bus;  // 音量（由按键模块驱动）
    wire [2:0] song_idx_bus;// 当前歌曲索引，目前最多8首
    reg [15:0] elapsed_secs;// 时间计数 (秒)
    integer clk_ticks_count; // 主时钟计数，用于秒级累加
    wire mp3_rst_sync; // 用于 MP3 的复位/显示复位信号
     // 7 段数码管显示
       Display7 u_seg7_display(
           .CLK(CLK),
           .DATA(elapsed_secs),
           .VOL(vol_code_bus),
           .CURRENT(song_idx_bus),
           .SEG(SEG),
           .SHIFT(SHIFT),
           .DOT(DOT)
       );
    // 按键控制
    btn_control u_button_ctrl(
        .CLK(CLK),
        .RST(RST),
        .BTNC(BTNC),
        .BTNU(BTNU),
        .BTND(BTND),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .SW(SW),
        .vol(vol_code_bus),
        .CURRENT(song_idx_bus)
    );
    // OLED 模块
    oled u_oled_display(
        .CLK(CLK), 
        .RST(RST),
        .current(song_idx_bus),
        .DIN(DIN),
        .OLED_CLK(OLED_CLK), 
        .CS(CS),
        .DC(DC),
        .RES(RES)
    );
    // MP3 模块
    MP3 u_mp3_player(
        .CLK(CLK), 
        .RST(RST), 
        .DREQ(DREQ),
        .vol(vol_code_bus),
        .current(song_idx_bus),
        .XDCS(XDCS), 
        .XCS(XCS), 
        .RSET(RSET), 
        .SI(SI),
        .SCLK(SCLK),
        .MP3_RST(mp3_rst_sync),
        .led(led)
    );
    //计数，顶层模块
    always @ (posedge CLK) begin
        if(!RST) begin
            elapsed_secs <= 16'd0;
            clk_ticks_count <= 0;
        end else if((clk_ticks_count+1)==100000000) begin
            clk_ticks_count <= 0;
            elapsed_secs <= elapsed_secs + 1;
        end else begin
            clk_ticks_count <= clk_ticks_count + 1;
        end
    end
endmodule
