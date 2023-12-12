`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/01 15:19:25
// Design Name: 
// Module Name: zyy_mp3
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

module zyy_mp3(clk,rst,start,music_id,XRSET,DREQ,XCS,XDCS,SI,SCK);
input clk;                // 系统100M时钟
input rst;                // 低电平有效
input start;              // 是否播放，高电平为播放
input [2:0] music_id;     // 选择的音乐
// mp3 相关
output reg XRSET;          // 硬件复位，低电平有效
input DREQ;                // 数据请求，高电平有效
output reg XCS;            // SCI 用于传输命令
output reg XDCS;           // SDI 用来传输数据
output reg SI;             // 向MP3写入数据、命令
output reg SCK;            // MP3时钟

reg init = 0;
// 1M时钟
wire clk_1M;
zyy_Divider #(.num(100)) clk_mp3(clk, clk_1M);

// IP 核
reg[11:0] addr;
wire [15: 0] get_data;
reg [15: 0] music_data;
blk_mem_gen_0 music_0 (.clka(clk),.ena(1),.addra({music_id, addr}),.douta(get_data));

reg [3:0] condition = 0;     // 状态
reg [63: 0] cmd = {32'h02000804, 32'h020B8080};     // 要写入的命令

// 变量
integer cnt = 0;           // 计数器
integer num = 0;           // 记录进度

// 状态常量
parameter DELAY = 1;
parameter PRE_CMD = 2;
parameter WRITE_CMD = 3;
parameter PRE_DATA = 4;
parameter WRITE_DATA = 5;
// 延时常量
parameter DELAY_TIME = 500000;

always @(posedge clk_1M)
begin
   if(!rst || !init) begin              // 进行初始化
        init <= 1;
        XRSET <= 0;
        SCK <= 0;
        XCS <= 1;                       //禁止写入命令
        XDCS <= 1;                      //禁止将数据传入MP3
        condition <= DELAY;
        addr <= 0;
        cnt <= 0;
   end
   else begin
    if(start) begin
    case (condition)
        DELAY: begin
            if(cnt == DELAY_TIME) begin         // 延时结束
                cnt <= 0;
                condition <= PRE_CMD;
                XRSET <= 1;                     // 硬复位
            end
            else begin                          // 等待延时
                cnt <= cnt + 1;
            end
        end
        PRE_CMD: begin
            SCK <= 0;                      // MP3时钟下降沿，更新数据
            if(num == 2) begin              // 写入命令完成
                condition <= PRE_DATA;
                num <= 0;
            end
            else begin
                if(DREQ) begin
                    cnt <= 0;
                    condition <= WRITE_CMD;
                end
            end
        end
        WRITE_CMD: begin
            if(DREQ) begin
                if(clk) begin
                    if(cnt == 32) begin         // 配置寄存器命令完毕
                        cnt <= 0;               // 重置计数器
                        XCS <= 1;               //禁止写入命令
                        condition <= PRE_CMD;
                        num <= num + 1;
                    end
                    else begin
                        XCS <= 0;               //允许写入命令
                        SI <= cmd[63];          // 写入命令，更新
                        cmd <= {cmd[62: 0], cmd[63]};   // 命令移位
                        cnt <= cnt + 1;
                    end
                end
                SCK <= ~SCK;                  // 交替变换，进行数据更新与采样
            end
        end
        PRE_DATA: begin
            if(DREQ) begin
                SCK <= 0;
				condition <= WRITE_DATA;
				music_data <= get_data;       // 音乐数据传递，方便移位
				cnt <= 0;
            end
        end
        WRITE_DATA: begin
            if(SCK) begin
                if(cnt == 16) begin           // 结束一次2字节数据写入，进行下一次数据的准备、更新
                    XDCS <= 1;                //禁止将数据传入MP3
                    addr <= addr + 1;         // ROM地址增加
                    cnt <= 0;
                    condition <= PRE_DATA;
                end
                else begin                   //  进行音乐数据的写入
                    XDCS <= 0;               //  允许将数据传入MP3
                    SI <= music_data[15];    //  写入音乐数据
                    music_data <= {music_data[14:0],music_data[15]};
                    cnt <= cnt + 1;
                end
            end
             SCK <= ~SCK;                  // 交替变换，进行数据更新与采样
        end
        default: ;
    endcase 
    end
   end
end

endmodule