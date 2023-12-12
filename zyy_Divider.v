module zyy_Divider #(parameter num=100000000)
(
    input I_CLK,
    output reg O_CLK
);

reg [63:0] my_count;

initial
begin
O_CLK = 0;
my_count = 0;
end

always @ (posedge I_CLK)
begin
    my_count = my_count + 1;
    if(my_count >= num / 2) begin
        my_count = 0;
        O_CLK = ~O_CLK;
    end
end
endmodule