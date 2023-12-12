`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: zyy_vga
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

module zyy_vga (clk_25M,rst,start,over,key_ascii,color_r,color_g,color_b,hs,vs,move_top,move_bottom,move_left,move_right,change);
input clk_25M;               // 25M时钟
input rst;                   // 低电平有效
input start;                 // 游戏开始
output reg over;             // 游戏结束
input [7:0] key_ascii;       // 键盘按键
output reg [3:0] color_r;    // 红色分量
output reg [3:0] color_g;    // 绿色分量
output reg [3:0] color_b;    // 蓝色分量
output hs;                   // 行同步
output vs;                   // 场同步

output reg move_top;            // 当顶部木板移动时亮起
output reg move_bottom;         // 当底部木板移动时亮起
output reg move_left;           // 当左侧木板移动时亮起
output reg move_right;          // 当右侧木板移动时亮起
output reg change;              // 木块被反弹时亮起

// 常量参数
parameter HS_SYNC = 96;         // 同步区域
parameter HS_BACK = 48;         // 后沿区域
parameter HS_ACTIVE = 640;      // 有效显示区域
parameter HS_FRONT = 16;        // 前沿区域

parameter VS_SYNC = 2;          // 同步区域
parameter VS_BACK = 33;         // 后沿区域
parameter VS_ACTIVE = 480;      // 有效显示区域
parameter VS_FRONT = 10;        // 前沿区域

parameter TOTAL_ROWS = 525;     // 总行数
parameter TOTAL_COLS = 800;     // 总列数

wire law;                       // 处于有效显示区域标志，高电平有效
reg [11:0] h_cnt = 0;           // 列计数器
reg [11:0] v_cnt = 0;           // 行计数器

// 接入输出
assign hs = (h_cnt < HS_SYNC)? 0 : 1;
assign vs = (v_cnt < VS_SYNC)? 0 : 1;
assign law = (h_cnt >= (HS_SYNC + HS_BACK)) &&                 
             (h_cnt <= (HS_SYNC + HS_BACK + HS_ACTIVE)) && 
             (v_cnt >= (VS_SYNC + VS_BACK)) &&
             (v_cnt <= (VS_SYNC + VS_BACK + VS_ACTIVE));

// 移动相关参数
integer length_block = 40;                     // 木块的长度
integer width_block = 40;                      // 木块的宽度
integer X_block = 50;                          // 木块中心的的X坐标
integer Y_block = 50;                          // 木块中心的的Y坐标
integer length_board = 100;                    // 木板的长度
integer width_board = 20;                      // 木板的宽度
integer X_board_bottom = 320;                  // 底部木板中心的的X坐标
integer Y_board_bottom = 450;                  // 底部木板中心的的Y坐标
integer X_board_top = 320;                     // 顶部木板中心的的X坐标
integer Y_board_top = 10;                      // 顶部木板中心的的Y坐标
integer X_board_left = 10;                     // 左侧木板中心的的X坐标
integer Y_board_left = 240;                    // 左侧木板中心的的Y坐标
integer X_board_right = 630;                   // 右侧木板中心的的X坐标
integer Y_board_right = 240;                   // 右侧木板中心的的Y坐标
integer direction = 1;                         // 木块移动方向  


// 行时序
always @(posedge clk_25M or negedge rst) begin
    if(!rst) begin
        h_cnt <= 0;
    end
    else if(start) begin
        if(h_cnt == TOTAL_COLS - 1) begin      // 显示完一行，重置
            h_cnt <= 0;
        end
        else begin
            h_cnt <= h_cnt + 1;
        end
    end
end

// 场时序
always @(posedge clk_25M or negedge rst) begin
    if(!rst) begin
        v_cnt <= 0;
        over <= 0;
        X_block <= 50;
        Y_block <= 50;
        X_board_bottom <= 320;
        Y_board_bottom <= 450;
        X_board_top <= 320;
        Y_board_top <= 10;
        X_board_left <= 10;
        Y_board_left <= 240;
        X_board_right <= 630;
        Y_board_right <= 240;
        direction <= 1;
        move_top <= 0;
        move_bottom <= 0;
        move_left <= 0;
        move_right <= 0;
        change <= 0;
    end
    else if(start) begin
        if(v_cnt == TOTAL_ROWS - 1) begin          // 显示完整个屏幕，重置更新
            v_cnt <= 0;
            // 重置灯
            move_top <= 0;
            move_bottom <= 0;
            move_left <= 0;
            move_right <= 0;
            change <= 0;
            // 进行木块的位置更新
           case (direction)
                1: begin
                X_block <= X_block + 1;
                Y_block <= Y_block + 1; 
                end
                2: begin
                X_block <= X_block + 1;
                Y_block <= Y_block - 1; 
                end
                3: begin
                X_block <= X_block - 1;
                Y_block <= Y_block - 1; 
                end
                4: begin
                X_block <= X_block - 1;
                Y_block <= Y_block + 1; 
                end
                default: ; 
            endcase
            // 木板位置更新
            if(key_ascii == 8'd3) begin             // 底部左移
                if(Y_block - Y_board_bottom <= (width_board + width_block) / 2 &&
                Y_block - Y_board_bottom >= -(width_board + width_block) / 2 &&
                X_board_bottom - 2 - X_block <= (length_board + length_block) / 2 &&
                X_board_bottom - 2 - X_block > 0) begin
                    X_board_bottom <= X_board_bottom;
                end
                else if(X_board_bottom > length_board / 2 + 30) X_board_bottom <= X_board_bottom - 2;
                else ;
                move_bottom <= 1;
            end
            if(key_ascii == 8'd4) begin             // 底部右移
                if(Y_block - Y_board_bottom <= (width_board + width_block) / 2 &&
                Y_block - Y_board_bottom >= -(width_board + width_block) / 2 &&
                X_block - X_board_bottom - 2 <= (length_board + length_block) / 2 &&
                X_block - X_board_bottom - 2 > 0) begin
                    X_board_bottom <= X_board_bottom;
                end
                else if(X_board_bottom < 640 - length_board / 2 - 30) X_board_bottom <= X_board_bottom + 2;
                else ;
                move_bottom <= 1;
            end
            if(key_ascii == 8'd7) begin             // 顶部左移
                if(Y_block - Y_board_top <= (width_board + width_block) / 2 &&
                Y_block - Y_board_top >= -(width_board + width_block) / 2 &&
                X_board_top - 2 - X_block <= (length_board + length_block) / 2 &&
                X_board_top - 2 - X_block > 0) begin
                    X_board_top <= X_board_top;
                end
                else if(X_board_top > length_board / 2 + 30) X_board_top <= X_board_top - 2;
                else ;
                move_top <= 1;
            end
            if(key_ascii == 8'd8) begin             // 顶部右移
                if(Y_block - Y_board_top <= (width_board + width_block) / 2 &&
                Y_block - Y_board_top >= -(width_board + width_block) / 2 &&
                X_block - X_board_top - 2 <= (length_board + length_block) / 2 &&
                X_block - X_board_top - 2 > 0) begin
                    X_board_top <= X_board_top;
                end
                else if(X_board_top < 640 - length_board / 2 - 30) X_board_top <= X_board_top + 2;
                else ;
                move_top <= 1;
            end
            if(key_ascii == 8'd1) begin             // 左部上移
                if(X_block - X_board_left <= (width_board + width_block) / 2 &&
                X_block - X_board_left >= -(width_board + width_block) / 2 &&
                Y_board_left - 2 - Y_block <= (length_board + length_block) / 2 &&
                Y_board_left - 2 - Y_block > 0) begin
                    Y_board_left <= Y_board_left;
                end
                else if(Y_board_left > length_board / 2 + 10) Y_board_left <= Y_board_left - 2;
                else ;
                move_left <= 1;
            end
            if(key_ascii == 8'd2) begin             // 左部下移
                if(X_block - X_board_left <= (width_board + width_block) / 2 &&
                X_block - X_board_left >= -(width_board + width_block) / 2 &&
                Y_block - Y_board_left - 2 <= (length_board + length_block) / 2 &&
                Y_block - Y_board_left - 2 > 0) begin
                    Y_board_left <= Y_board_left;
                end
                else if(Y_board_left < 460 - length_board / 2 - 10) Y_board_left <= Y_board_left + 2;
                else ;
                move_left <= 1;
            end
            if(key_ascii == 8'd5) begin             // 右部上移
                if(X_block - X_board_right <= (width_board + width_block) / 2 &&
                X_block - X_board_right >= -(width_board + width_block) / 2 &&
                Y_board_right - 2 - Y_block <= (length_board + length_block) / 2 &&
                Y_board_right - 2 - Y_block > 0) begin
                    Y_board_right <= Y_board_right;
                end
                else if(Y_board_right > length_board / 2 + 10) Y_board_right <= Y_board_right - 2;
                else ;
                move_right <= 1;
            end
            if(key_ascii == 8'd6) begin             // 右部下移
                if(X_block - X_board_right <= (width_board + width_block) / 2 &&
                X_block - X_board_right >= -(width_board + width_block) / 2 &&
                Y_block - Y_board_right - 2 <= (length_board + length_block) / 2 &&
                Y_block - Y_board_right - 2 > 0) begin
                    Y_board_right <= Y_board_right;
                end
                else if(Y_board_right < 460 - length_board / 2 - 10) Y_board_right <= Y_board_right + 2;
                else ;
                move_right <= 1;
            end
            
            // 木块与木板接触，反弹
            // 底部木板
            if(Y_board_bottom - Y_block == (width_board + width_block) / 2 &&
            X_board_bottom - X_block <= (length_board + length_block) / 2 && 
            X_board_bottom - X_block >= -(length_board + length_block) / 2) begin
                if(direction == 4) direction <= 3;
                else if(direction == 1) direction <= 2;
                else ;
                change <= 1;
            end
            if(X_block - X_board_bottom == (length_board + length_block) / 2 &&
            Y_block - Y_board_bottom <= (width_board + width_block) / 2 &&
            Y_block - Y_board_bottom >= -(width_board + width_block) / 2) begin
                if(direction == 4) direction <= 1;
                else if(direction == 3) direction <= 2;
                else ;
                change <= 1;
            end
            if(X_board_bottom - X_block == (length_board + length_block) / 2 &&
            Y_block - Y_board_bottom <= (width_board + width_block) / 2 &&
            Y_block - Y_board_bottom >= -(width_board + width_block) / 2) begin
                if(direction == 2) direction <= 3;
                else if(direction == 1) direction <= 4;
                else ;
                change <= 1;
            end
            // 顶部木板
            if(Y_block - Y_board_top == (width_board + width_block) / 2 &&
            X_board_top - X_block <= (length_board + length_block) / 2 && 
            X_board_top - X_block >= -(length_board + length_block) / 2) begin
                if(direction == 2) direction <= 1;
                else if(direction == 3) direction <= 4;
                else ;
                change <= 1;
            end
            if(X_block - X_board_top == (length_board + length_block) / 2 &&
            Y_block - Y_board_top <= (width_board + width_block) / 2 &&
            Y_block - Y_board_top >= -(width_board + width_block) / 2) begin
                if(direction == 4) direction <= 1;
                else if(direction == 3) direction <= 2;
                else ;
                change <= 1;
            end
            if(X_board_top - X_block == (length_board + length_block) / 2 &&
            Y_block - Y_board_top <= (width_board + width_block) / 2 &&
            Y_block - Y_board_top >= -(width_board + width_block) / 2) begin
                if(direction == 2) direction <= 3;
                else if(direction == 1) direction <= 4;
                else ;
                change <= 1;
            end
            // 左侧木板
            if(X_block - X_board_left == (width_board + width_block) / 2 &&
            Y_board_left - Y_block <= (length_board + length_block) / 2 && 
            Y_board_left - Y_block >= -(length_board + length_block) / 2) begin
                if(direction == 4) direction <= 1;
                else if(direction == 3) direction <= 2;
                else ;
                change <= 1;
            end
            if(Y_board_left - Y_block == (length_board + length_block) / 2 &&
            X_block - X_board_left <= (width_board + width_block) / 2 &&
            X_block - X_board_left >= -(width_board + width_block) / 2) begin
                if(direction == 4) direction <= 3;
                else if(direction == 1) direction <= 2;
                else ;
                change <= 1;
            end
            if(Y_block - Y_board_left == (length_board + length_block) / 2 &&
            X_block - X_board_left <= (width_board + width_block) / 2 &&
            X_block - X_board_left >= -(width_board + width_block) / 2) begin
                if(direction == 2) direction <= 1;
                else if(direction == 3) direction <= 4;
                else ;
                change <= 1;
            end
            // 右侧木板
            if(X_board_right - X_block == (width_board + width_block) / 2 &&
            Y_board_right - Y_block <= (length_board + length_block) / 2 && 
            Y_board_right - Y_block >= -(length_board + length_block) / 2) begin
                if(direction == 2) direction <= 3;
                else if(direction == 1) direction <= 4;
                else ;
                change <= 1;
            end
            if(Y_board_right - Y_block == (length_board + length_block) / 2 &&
            X_block - X_board_right <= (width_board + width_block) / 2 &&
            X_block - X_board_right >= -(width_board + width_block) / 2) begin
                if(direction == 4) direction <= 3;
                else if(direction == 1) direction <= 2;
                else ;
                change <= 1;
            end
            if(Y_block - Y_board_right == (length_board + length_block) / 2 &&
            X_block - X_board_right <= (width_board + width_block) / 2 &&
            X_block - X_board_right >= -(width_board + width_block) / 2) begin
                if(direction == 2) direction <= 1;
                else if(direction == 3) direction <= 4;
                else ;
                change <= 1;
            end

            // 判定结束
            if(X_block <= 0 || X_block >= 640 || Y_block <= 0 || Y_block >= 460) over <= 1;
        end
        else if(h_cnt == TOTAL_COLS - 1) begin          // 显示完一行，进行下一行显示
            v_cnt <= v_cnt + 1;
        end
        else begin
            v_cnt <= v_cnt;
        end
    end
    else ;
end

// 显示内容
always @(posedge clk_25M or negedge rst) begin
    if(!rst) begin
       color_r <= 4'b0000;
       color_g <= 4'b0000;
       color_b <= 4'b0000;
    end
    else if(law && start && over == 0) begin                               // 在有效显示区域，显示内容
        // 显示木块
        if((h_cnt >= HS_SYNC + HS_BACK + X_block - length_block / 2) &&
        (h_cnt <= HS_SYNC + HS_BACK + X_block + length_block / 2) && 
        (v_cnt >= VS_SYNC + VS_BACK + Y_block - width_block / 2) &&
        (v_cnt <= VS_SYNC + VS_BACK + Y_block + width_block / 2)) begin
            // 黑色
            color_r <= 4'b0000;
            color_g <= 4'b0000;
            color_b <= 4'b0000;
        end
        // 显示木板
        // 底部
        else if((h_cnt >= HS_SYNC + HS_BACK + X_board_bottom - length_board / 2) &&
        (h_cnt <= HS_SYNC + HS_BACK + X_board_bottom + length_board / 2) && 
        (v_cnt >= VS_SYNC + VS_BACK + Y_board_bottom - width_board / 2) &&
        (v_cnt <= VS_SYNC + VS_BACK + Y_board_bottom + width_board / 2)) begin
            // 蓝色
            color_r <= 4'b0000;
            color_g <= 4'b0000;
            color_b <= 4'b1111;
        end
        // 顶部
        else if((h_cnt >= HS_SYNC + HS_BACK + X_board_top - length_board / 2) &&
        (h_cnt <= HS_SYNC + HS_BACK + X_board_top + length_board / 2) && 
        (v_cnt >= VS_SYNC + VS_BACK + Y_board_top - width_board / 2) &&
        (v_cnt <= VS_SYNC + VS_BACK + Y_board_top + width_board / 2)) begin
            // 蓝色
            color_r <= 4'b0000;
            color_g <= 4'b0000;
            color_b <= 4'b1111;
        end
        // 左侧
        else if((h_cnt >= HS_SYNC + HS_BACK + X_board_left - width_board / 2) &&
        (h_cnt <= HS_SYNC + HS_BACK + X_board_left + width_board / 2) && 
        (v_cnt >= VS_SYNC + VS_BACK + Y_board_left - length_board / 2) &&
        (v_cnt <= VS_SYNC + VS_BACK + Y_board_left + length_board / 2)) begin
            // 蓝色
            color_r <= 4'b0000;
            color_g <= 4'b0000;
            color_b <= 4'b1111;
        end
        // 右侧
        else if((h_cnt >= HS_SYNC + HS_BACK + X_board_right - width_board / 2) &&
        (h_cnt <= HS_SYNC + HS_BACK + X_board_right + width_board / 2) && 
        (v_cnt >= VS_SYNC + VS_BACK + Y_board_right - length_board / 2) &&
        (v_cnt <= VS_SYNC + VS_BACK + Y_board_right + length_board / 2)) begin
            // 蓝色
            color_r <= 4'b0000;
            color_g <= 4'b0000;
            color_b <= 4'b1111;
        end
        // 显示背景
        else begin
            // 白色
            color_r <= 4'b1111;
            color_g <= 4'b1111;
            color_b <= 4'b1111;
        end
    end
    else if(law && start && over) begin
        // 白色
        color_r <= 4'b1111;
        color_g <= 4'b1111;
        color_b <= 4'b1111;
    end
    else begin                                      // 未在有效显示区域则重置颜色
        color_r <= 4'b0000;
        color_g <= 4'b0000;
        color_b <= 4'b0000;
    end
end

endmodule