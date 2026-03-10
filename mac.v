module mac_unit #(
    parameter DATA_WIDTH = 9,  // Changed to 9 to handle +128 offset
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire clear,
    input wire enable,
    
    input wire signed [DATA_WIDTH - 1: 0] data_in,
    input wire signed [7: 0] weight_in,
    
    output wire signed [ACC_WIDTH-1:0] acc_out,
    output wire acc_valid
);

reg signed [ACC_WIDTH-1:0] accumulator;
reg valid_reg;

wire signed [DATA_WIDTH+8-1:0] mult_result;
assign mult_result = data_in * weight_in;

always @(posedge clk) begin
    if (!rst) begin
        accumulator <= 0;
        valid_reg <= 1'b0;
    end else if (clear) begin
        accumulator <= 0;
        valid_reg <= 1'b0;
    end else if (enable) begin
        // 符号扩展并截断到ACC_WIDTH
        if (ACC_WIDTH >= DATA_WIDTH+8) begin
            accumulator <= accumulator + {{(ACC_WIDTH-(DATA_WIDTH+8)){mult_result[DATA_WIDTH+8-1]}}, mult_result};
        end else begin
            accumulator <= accumulator + mult_result[ACC_WIDTH-1:0];
        end
        valid_reg <= 1'b1;
    end else begin
        valid_reg <= 1'b0;
    end
end

assign acc_out = accumulator;
assign acc_valid = valid_reg;

endmodule