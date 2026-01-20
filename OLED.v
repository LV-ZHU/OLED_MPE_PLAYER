`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/19 02:08:47
// Design Name: 
// Module Name: OLED
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

module oled(
    input CLK, 
    input RST,
    input [2: 0] current,
    output reg DIN, // 串行数据输入
    output reg OLED_CLK, 
    output reg CS, // 片选
    output reg DC, // 数据/命令选择
    output reg RES
);
    parameter DELAY_TIME = 25000;
    // DC 标志位
    parameter CMD = 1'b0;
    parameter DATA = 1'b1;
    // 初始化命令表
    reg [47:0] init_cmds [9:0];
    initial
        begin
            init_cmds[0]= {8'hAE, 8'hA0, 8'h76, 8'hA1, 8'h00, 8'hA2}; 
            init_cmds[1]= {8'h00, 8'hA4, 8'hA8, 8'h3F, 8'hAD, 8'h8E};  
            init_cmds[2]= {8'hB0, 8'h0B, 8'hB1, 8'h31, 8'hB3, 8'hF0};  
            init_cmds[3]= {8'h8A, 8'h64, 8'h8B, 8'h78, 8'h8C, 8'h64}; 
            init_cmds[4]= {8'hBB, 8'h3A, 8'hBE, 8'h3E, 8'h87, 8'h06};  
            init_cmds[5]= {8'h81, 8'h91, 8'h82, 8'h50, 8'h83, 8'h7D}; 
            init_cmds[6]= {8'h15, 8'h00, 8'h5F, 8'h75, 8'h00, 8'h3F};      
            init_cmds[7]= {8'hAF, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00}; 
        end
 
    // 像素，
    wire [1535:0] row_bitmap_word;
    reg [5: 0] row_addr;
    blk_mem_gen_1 bmp_rom(.clka(CLK),.ena(1),.addra({current, row_addr}),.douta(row_bitmap_word));
    
    // 状态定义
    parameter shift_byte_out = 0;
    parameter load_next_byte = 1;
    parameter DELY = 3;
    parameter init_cmd_ready = 4;
    parameter frame_data_ready = 5;
    
    // 2MHz 时钟分频
    wire clock_divider_2m;
    Divider #(.Time(20)) u_clock_divider_2m(CLK, clock_divider_2m);
    
    // 变量
    reg [1535:0] shift_buffer_1536;
    reg [15: 0] row_idx;
    reg [7: 0] out_byte_reg;
    reg [3: 0] oled_state;
    reg [3: 0] next_state_after_write;
    integer bit_index = 0;
    integer bytes_left = 0;
    
    // 状态机：初始化命令写入或像素数据写入
    always @ (posedge clock_divider_2m) begin 
        if(!RST) begin 
            oled_state <= init_cmd_ready;
            row_idx <= 0;
            CS <= 1'b1;
            RES <= 0;
        end
        else begin 
            RES <= 1;
            case(oled_state)
                // 准备写命令，将 cmds 行装入 temp
                init_cmd_ready: begin 
                        if(row_idx == 8) begin 
                            row_idx <= 0;
                            row_addr <= 0;
                            oled_state <= frame_data_ready;
                        end
                        else begin 
                            shift_buffer_1536 <= init_cmds[row_idx];
                            oled_state <= load_next_byte;
                            next_state_after_write <= init_cmd_ready;
                            bytes_left <= 6;
                            DC <= CMD;
                        end
                    end
                // 准备写像素数据
                frame_data_ready: begin 
                        if(row_idx == 64) begin 
                            row_idx <= 0;
                            oled_state <= frame_data_ready;
                        end
                        else begin 
                            shift_buffer_1536 <= row_bitmap_word;
                            oled_state <= load_next_byte;
                            next_state_after_write <= frame_data_ready;
                            bytes_left <= 192;
                            DC <= DATA;
                        end
                    end
                // 将 temp 拆成若干 8-bit 寄存器
                load_next_byte: begin 
                        if(bytes_left == 0) begin 
                            row_idx <= row_idx+1;
                            row_addr <= row_addr+1;
                            oled_state <= next_state_after_write;
                        end
                        else begin 
                            out_byte_reg[7: 0] <= (next_state_after_write==init_cmd_ready)? shift_buffer_1536[47: 40]: shift_buffer_1536[1535: 1528];
                            shift_buffer_1536 <= (next_state_after_write==init_cmd_ready)? {shift_buffer_1536[39: 0], shift_buffer_1536[47: 40]}: {shift_buffer_1536[1527: 0], shift_buffer_1536[1535: 1528]};
                            oled_state <= shift_byte_out;
                            OLED_CLK <= 0;
                            bit_index <= 0;
                        end
                    end
                // 将 8 位移入 DIN
                shift_byte_out: begin 
                        if(OLED_CLK) begin 
                            if(bit_index == 8) begin 
                                CS <= 1;
                                bytes_left <= bytes_left-1;
                                oled_state <= load_next_byte;
                            end
                            else begin 
                                CS <= 0;
                                DIN <= out_byte_reg[7];
                                bit_index <= bit_index+1;
                                out_byte_reg<={out_byte_reg[6:0], out_byte_reg[7]}; 
                            end
                        end
                        OLED_CLK <= ~OLED_CLK;
                    end
                default:;
            endcase
        end
    end 
endmodule
