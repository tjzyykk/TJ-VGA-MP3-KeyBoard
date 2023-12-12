`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: zyy_top
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
module zyy_top(clk,rst,start,over,color_r,color_g,color_b,hs,vs,move_top,move_bottom,move_left,move_right,change,key_clk,key_data,DREQ,XCS,XDCS,SCK,SI,XRESET,oData,law);
input clk;                     // 系统时钟 100M
input rst;                     // 低电平有效

// 游戏相关
input start;                 // 游戏开始
output over;                 // 游戏结束

// VGA 相关
output [3:0] color_r;          // 红色分量
output [3:0] color_g;          // 绿色分量
output [3:0] color_b;          // 蓝色分量
output hs;                     // 行同步
output vs;                     // 场同步
output move_top;               // 当顶部木板移动时亮起
output move_bottom;            // 当底部木板移动时亮起
output move_left;              // 当左侧木板移动时亮起
output move_right;             // 当右侧木板移动时亮起
output change;                 // 木块被反弹时亮起

//键盘相关
input   key_clk;               // 键盘时钟
input   key_data;              // 键盘输入数据
wire [8:0] keys;

// mp3相关
input     DREQ;           //数据请求，高电平时可传输数据
output    XCS;            // SCI 传输读写指令
output    XDCS;           // SDI 传输数据
output    SCK;            // 时钟
output    SI;             // 传入mp3
output    XRESET;          // 硬件复位，低电平有效

// 数码管相关
output [6:0] oData;        // 显示时间
output [7:0] law;          // 片选数码管

wire clk_25M;              // 25M时钟
zyy_Divider #(.num(4)) clk_vga(clk,clk_25M);
wire clk_1000;              // 1000时钟
zyy_Divider #(.num(100000)) clk_display(clk,clk_1000);

// VGA
zyy_vga vga_inst(
    .clk_25M(clk_25M),
    .rst(rst),
    .start(start),
    .over(over),
    .key_ascii(keys),
    .color_r(color_r),
    .color_g(color_g),
    .color_b(color_b),
    .hs(hs),
    .vs(vs),
    .move_top(move_top),
    .move_bottom(move_bottom),
    .move_left(move_left),
    .move_right(move_right),
    .change(change)
);

//键盘
zyy_keyboard keyboard_inst(
    .clk(clk),
    .rst(1),
    .key_clk(key_clk),
    .key_data(key_data),
    .key_ascii(keys)
);

// mp3
zyy_mp3 mp3_inst(
    .clk(clk),
    .DREQ(DREQ),
    .rst(rst),
    .music_id(0),
    .XDCS(XDCS),
    .XCS(XCS),
    .XRSET(XRESET),
    .SI(SI),
    .SCK(SCK),
    .start(start)
    );

// 数码管
zyy_display display_inst(
    .clk_1000(clk_1000),
    .rst(rst),
    .start(start),
    .over(over),
    .oData(oData),
    .law(law)
    );

endmodule