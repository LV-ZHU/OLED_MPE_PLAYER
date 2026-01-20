`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/19 02:08:45
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

module MP3(
    input CLK, // 主时钟输入
    input DREQ,// VS1003 数据请求输入
    input RST, // 低电平有效复位
    input [15:0] vol,// 音量值（来自按键模块）
    input [2: 0] current, // 歌曲选择
    output reg XDCS, // 数据片选
    output reg XCS,  // 命令片选
    output reg RSET, 
    output reg SI,  // 数据输入
    output reg SCLK, // VS1003 时钟
    output reg MP3_RST,
    output reg [15:0] led // 音量显示
);
    // 状态定义
    parameter boot_wait_cmd_ready = 0;
    parameter shift_cmd_bits = 1;
    parameter stream_data = 2;
    parameter shift_data_bits = 3;
    parameter boot_delay = 4;
    parameter wait_vol_cmd_ready = 5;
    parameter shift_vol_bits = 6;
    parameter pause_state = 7;
    reg [2: 0] mp3_state;
    
    // 基本参数
    parameter DELAY_TIME = 500000;
    parameter CMD_NUM = 2;
    
    // 1MHz 分频时钟（使用 Divider）
    wire clock_divider_1m;
    Divider #(.Time(100)) u_clock_divider_1m(CLK, clock_divider_1m);
    
    // 歌曲地址选择
    reg[2: 0] prev_song;
    reg[11:0] song_word_addr;
    
    // IP 核 ROM
    wire [15: 0] song_word_in;
    reg [15: 0] payload_shift_reg;
    blk_mem_gen_0 music_rom(.clka(CLK),.ena(1),.addra({current, song_word_addr}),.douta(song_word_in));
    
    // 命令寄存器
    reg pause_flag;
    reg [63: 0] pause_cmd_frame = {32'h02000808, 32'h02000800};
    reg [63: 0] cmd_frame = {32'h02000804, 32'h020B0000};
    reg [2: 0] frame_idx = 0;
    
    // 变量
    integer boot_tick_count = 0;
    integer bit_index = 0;
    reg [31: 0] vol_cmd_frame;

    // 合并 vol_control：一热 LED 显示当前歌曲（在主时钟上采样）
    always @ (posedge CLK) begin
        led <= (16'b1 << current);
    end
    
    always @ (posedge clock_divider_1m) begin
        prev_song <= current;
        if(!RST || prev_song!=current) begin
            MP3_RST <= 0;
            RSET <= 0;
            SCLK <= 0;
            XCS <= 1;
            XDCS <= 1;
            boot_tick_count <= 0;
            mp3_state <= boot_delay;
            frame_idx <= 0;
            song_word_addr <= 0;
        end 
        else begin 
            case (mp3_state)
                boot_wait_cmd_ready: begin 
                        SCLK <= 0;
                        if(frame_idx == CMD_NUM) begin
                            mp3_state <= stream_data;
                        end
                        else if(DREQ) begin 
                            mp3_state <= shift_cmd_bits;
                            bit_index <= 0;
                        end 
                    end
                    
                shift_cmd_bits: begin 
                        if(DREQ) begin
                            if(CLK) begin 
                                if(bit_index==32) begin
                                    frame_idx <= frame_idx+1;
                                    XCS <= 1;
                                    mp3_state <= boot_wait_cmd_ready;
                                    bit_index <= 0;
                                end 
                                else begin
                                    XCS <= 0;
                                    SI <= cmd_frame[63];
                                    cmd_frame <= {cmd_frame[62: 0], cmd_frame[63]};
                                    bit_index <= bit_index+1;
                                end 
                            end 
                            SCLK <= ~SCLK;
                        end 
                    end 
                    
                stream_data: begin
                        // 检测音量变化
                        if(vol[15:0] != cmd_frame[15: 0]) begin 
                            mp3_state <= wait_vol_cmd_ready;
                            vol_cmd_frame <= {16'h020B, vol};
                            cmd_frame[15: 0] <= vol[15: 0];
                        end 
                        else if(DREQ) begin 
                            SCLK <= 0;
                            mp3_state <= shift_data_bits;
                            payload_shift_reg <= song_word_in;
                            bit_index <= 0;
                        end 
                    end 
                    
                shift_data_bits: begin 
                        if(SCLK) begin 
                            if(bit_index == 16) begin 
                                XDCS <= 1;
                                song_word_addr <= song_word_addr+1;
                                mp3_state <= stream_data;
                            end 
                            else begin 
                                XDCS <= 0;
                                SI <= payload_shift_reg[15];
                                payload_shift_reg <= {payload_shift_reg[14:0], payload_shift_reg[15]};
                                bit_index <= bit_index+1;
                            end 
                        end 
                        SCLK = ~SCLK;
                    end 
                
                wait_vol_cmd_ready: begin 
                        if(DREQ) begin
                            mp3_state <= shift_vol_bits;
                            bit_index <= 0;
                        end 
                    end
                    
                shift_vol_bits: begin 
                        if(DREQ) begin
                            if(SCLK) begin 
                                if(bit_index==32) begin
                                    XCS <= 1;
                                    mp3_state <= stream_data;
                                    bit_index <= 0;
                                end 
                                else begin
                                    XCS <= 0;
                                    SI <= vol_cmd_frame[31];
                                    vol_cmd_frame <= {vol_cmd_frame[30: 0], vol_cmd_frame[31]};
                                    bit_index <= bit_index+1;
                                end 
                            end 
                            SCLK <= ~SCLK;
                        end 
                    end 
                    
                boot_delay: begin 
                        if(boot_tick_count == DELAY_TIME) begin 
                            boot_tick_count <= 0;
                            MP3_RST <= 1;
                            mp3_state <= boot_wait_cmd_ready;
                            RSET <= 1;
                        end 
                        else boot_tick_count <= boot_tick_count+1;
                    end 
                default: ;
                
            endcase
        end
    end 
endmodule
