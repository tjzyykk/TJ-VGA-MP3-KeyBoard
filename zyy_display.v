`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: zyy_display
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
module zyy_BCD (game_time,data1,data2,data3,data4,data5,data6,data7,data8);
input [31:0] game_time;
output [3:0] data1;
output [3:0] data2;
output [3:0] data3;
output [3:0] data4;
output [3:0] data5;
output [3:0] data6;
output [3:0] data7;
output [3:0] data8;

reg [31:0]  bin;
reg [31:0]  tmp;
reg [31:0]  bcd;

always @(game_time) begin
    bin = game_time;
    tmp = 0;
    repeat (31)             
    begin
        tmp[0] = bin[31];
        if (tmp[3:0] > 4) tmp[3:0] = tmp[3:0] + 4'd3;
        else tmp[3:0] = tmp[3:0];
        if (tmp[7:4] > 4) tmp[7:4] = tmp[7:4] + 4'd3;
        else tmp[7:4] = tmp[7:4];
        if (tmp[11:8] > 4) tmp[11:8] = tmp[11:8] + 4'd3;
        else tmp[11:8] = tmp[11:8];
        if (tmp[15:12] > 4) tmp[15:12] = tmp[15:12] + 4'd3;
        else tmp[15:12] = tmp[15:12];
        if (tmp[19:16] > 4) tmp[19:16] = tmp[19:16] + 4'd3;
        else tmp[19:16] = tmp[19:16];                
        if (tmp[23:20] > 4) tmp[23:20] = tmp[23:20] + 4'd3;
        else tmp[23:20] = tmp[23:20];
        if (tmp[27:24] > 4) tmp[27:24] = tmp[27:24] + 4'd3;
        else tmp[27:24] = tmp[27:24];
        if (tmp[31:28] > 4) tmp[31:28] = tmp[31:28] + 4'd3;
        else tmp[31:28] = tmp[31:28];
        tmp = tmp << 1;
        bin = bin << 1;
    end
    tmp[0] = bin[31];
    bcd = tmp;
end
assign data1 = bcd[3:0];
assign data2 = bcd[7:4];
assign data3 = bcd[11:8];
assign data4 = bcd[15:12];
assign data5 = bcd[19:16];
assign data6 = bcd[23:20];
assign data7 = bcd[27:24];
assign data8 = bcd[31:28];
endmodule


module zyy_display (clk_1000,rst,start,over,oData,law);
input clk_1000;
input rst;
input start;            // 游戏开始
input over;             // 游戏结束
output reg [6:0] oData;
output reg [7:0] law;               // 数码管片选显示

reg [31:0] game_time = 0;
integer cnt = 0;
integer time_update_cnt = 0;        // 时间更新计数器
wire [3:0] store [7:0];             // 存储十进制的每一位的数值 
// 转换为 BCD 码
zyy_BCD bcd(
    .game_time(game_time),
    .data1(store[0]),
    .data2(store[1]),
    .data3(store[2]),
    .data4(store[3]),
    .data5(store[4]),
    .data6(store[5]),
    .data7(store[6]),
    .data8(store[7])
    );

// 片选输入
always @(posedge clk_1000 or negedge rst) begin
    if(!rst) begin
        game_time <= 0;
    end
    else begin
        if(start) begin
            if(over == 0) begin
                if(time_update_cnt == 1000) begin
                    game_time <= game_time + 1;
                    time_update_cnt <= 0;
                end
                else time_update_cnt <= time_update_cnt + 1;
            end
            else begin
                game_time <= game_time;
                time_update_cnt <= 0;
            end
        end
        else game_time <= 0;
        if(cnt == 8) cnt <= 0;
        else cnt <= cnt + 1;
        law <= 8'b1111_1111;
        law[cnt] <= 0;                      //片选数码管输出
        case (store[cnt])
            4'b0000: oData <= 7'b1000000;
            4'b0001: oData <= 7'b1111001;
            4'b0010: oData <= 7'b0100100;
            4'b0011: oData <= 7'b0110000;
            4'b0100: oData <= 7'b0011001;
            4'b0101: oData <= 7'b0010010;
            4'b0110: oData <= 7'b0000010;
            4'b0111: oData <= 7'b1111000;
            4'b1000: oData <= 7'b0000000;
            4'b1001: oData <= 7'b0010000;
            default: oData <= 7'b1111111; 
        endcase
    end
end

endmodule