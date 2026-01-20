//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/19 02:08:49
// Design Name: 
// Module Name: MP3
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
module btn_control(
    input CLK,
    input RST,            // 低电平有效复位
    input BTNC,
    input BTNU,
    input BTND,
    input BTNL,
    input BTNR,
    input [15:0] SW,      // 滑动开关用于直接选择歌曲
    output reg [15:0] vol,
    output reg [2:0]  CURRENT
);
    // 两级同步寄存器用于消抖
    reg sync_c_0, sync_c_1, sync_u_0, sync_u_1, sync_d_0, sync_d_1, sync_l_0, sync_l_1, sync_r_0, sync_r_1;
    reg [15:0] sw_sync_0, sw_sync_1;
    wire rise_c =  sync_c_1 & ~sync_c_0;
    wire rise_u =  sync_u_1 & ~sync_u_0;
    wire rise_d =  sync_d_1 & ~sync_d_0;
    wire rise_l =  sync_l_1 & ~sync_l_0;
    wire rise_r =  sync_r_1 & ~sync_r_0;
    // 滑动开关电平同步
    wire [15:0] sw_level_sync = sw_sync_1;

    // 两级同步消抖
    always @(posedge CLK) begin
        if(!RST) begin
            sync_c_0 <= 1'b0; sync_c_1 <= 1'b0;
            sync_u_0 <= 1'b0; sync_u_1 <= 1'b0;
            sync_d_0 <= 1'b0; sync_d_1 <= 1'b0;
            sync_l_0 <= 1'b0; sync_l_1 <= 1'b0;
            sync_r_0 <= 1'b0; sync_r_1 <= 1'b0;
            sw_sync_0 <= 16'h0000; sw_sync_1 <= 16'h0000;
        end else begin
            sync_c_0 <= BTNC; sync_c_1 <= sync_c_0;
            sync_u_0 <= BTNU; sync_u_1 <= sync_u_0;
            sync_d_0 <= BTND; sync_d_1 <= sync_d_0;
            sync_l_0 <= BTNL; sync_l_1 <= sync_l_0;
            sync_r_0 <= BTNR; sync_r_1 <= sync_r_0;
            sw_sync_0 <= SW;  sw_sync_1 <= sw_sync_0;
        end
    end

    // 功能逻辑：音量增减、上一曲下一曲、直接选择
    always @(posedge CLK) begin
        if(!RST) begin
            vol <= 16'h4040;      // 默认音量，显示为 12
            CURRENT <= 3'd0;      // 默认歌曲 0
        end else begin
            // 中键复位到默认
            if(rise_c) begin
                vol <= 16'h4040;
                CURRENT <= 3'd0;
            end
            // 音量减
            if(rise_d) begin
                if(vol <= 16'h0000) vol <= 16'h0000;
                else vol <= vol - 16'h1010;
            end
            // 音量加
            if(rise_u) begin
                if(vol >= 16'hF0F0) vol <= 16'hF0F0;
                else vol <= vol + 16'h1010;
            end
            // 上一曲（循环）
            if(rise_l) begin
                CURRENT <= (CURRENT==0) ? 3'd7 : (CURRENT - 1);
            end
            // 下一曲（循环）
            if(rise_r) begin
                CURRENT <= (CURRENT==3'd7) ? 3'd0 : (CURRENT + 1);
            end
            // 滑动开关直接选择（优先）
            if(|sw_level_sync[7:0]) begin
                if(sw_level_sync[0]) CURRENT <= 3'd0;
                else if(sw_level_sync[1]) CURRENT <= 3'd1;
                else if(sw_level_sync[2]) CURRENT <= 3'd2;
                else if(sw_level_sync[3]) CURRENT <= 3'd3;
                else if(sw_level_sync[4]) CURRENT <= 3'd4;
                else if(sw_level_sync[5]) CURRENT <= 3'd5;
                else if(sw_level_sync[6]) CURRENT <= 3'd6;
                else if(sw_level_sync[7]) CURRENT <= 3'd7;
            end
        end
    end
endmodule
