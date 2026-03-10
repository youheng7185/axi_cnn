/*
iverilog -Wall -g2012 -o ./build/conv_out ./conv_tb.v ./conv.v ./mac.v
*/
/*
vvp -n ./build/conv_out -vcd ./build/conv_out.vcd
*/ 
module conv #(
    parameter KERNEL_W = 2,
    parameter KERNEL_H = 2,
    parameter STRIDE_W = 1,
    parameter STRIDE_H = 1,
    parameter INPUT_W = 3,
    parameter INPUT_H = 3,
    parameter PAD_W = 0,
    parameter PAD_H = 0,
    // parameter OUTPUT_W = (INPUT_W + 2*PAD_W - KERNEL_W) / STRIDE_W + 1,
    // parameter OUTPUT_H = (INPUT_H + 2*PAD_H - KERNEL_H) / STRIDE_H + 1,
    parameter OUTPUT_W = 20,
    parameter OUTPUT_H = 25,
    
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire start,
    
    input wire signed [DATA_WIDTH-1:0] input_data [0: INPUT_H*INPUT_W-1],
    
    output reg [7:0] weight_addr,
    input wire signed [DATA_WIDTH-1:0] weight_data,
    
    output reg signed [ACC_WIDTH-1:0] output_res,
    output reg output_valid,
    
    output reg signed [DATA_WIDTH:0] mac_data_in,  // 9 bits to handle +128 offset
    output reg signed [DATA_WIDTH-1:0] mac_weight_in,
    output reg mac_enable,
    output reg mac_clear,
    input wire signed [ACC_WIDTH-1:0] mac_acc_out
);

    localparam IDLE        = 3'd0;
    localparam SET_ADDR    = 3'd1;
    localparam WAIT_WEIGHT = 3'd2;
    localparam SET_DATA    = 3'd3;
    localparam WAIT_MAC    = 3'd4;
    localparam CLEAR_ACC   = 3'd5;
    localparam DONE        = 3'd6;

    reg [2:0] state, next_state;

    reg [7:0] x_idx, y_idx;
    reg [7:0] i_x_idx, i_y_idx;
    reg [7:0] j, k;

    reg output_valid_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = SET_ADDR;
            end

            SET_ADDR: begin
                next_state = WAIT_WEIGHT;
                // next_state = SET_DATA;
            end

            WAIT_WEIGHT: begin
                next_state = SET_DATA;
            end

            SET_DATA: begin
                next_state = WAIT_MAC;
            end

            WAIT_MAC: begin
                if (k == KERNEL_W - 1 && j == KERNEL_H - 1)
                    next_state = CLEAR_ACC;
                else
                    next_state = SET_ADDR;
            end

            CLEAR_ACC: begin
                next_state = DONE;
            end

            DONE: begin
                if (x_idx > OUTPUT_W - 1 || y_idx > OUTPUT_H - 1)
                    next_state = IDLE;
                else
                    next_state = SET_ADDR;
            end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            x_idx <= 8'd0;
            y_idx <= 8'd0;
            i_x_idx <= 8'd0;
            i_y_idx <= 8'd0;
            j <= 8'd0;
            k <= 8'd0;
            weight_addr <= 8'd0;
            mac_data_in <= 8'd0;
            mac_weight_in <= 8'd0;
            mac_enable <= 1'b0;
            mac_clear <= 1'b0;
            output_res <= 32'd0;
            output_valid_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        x_idx <= 8'd0;
                        y_idx <= 8'd0;
                        j <= 8'd0;
                        k <= 8'd0;
                        mac_clear <= 1'b0;
                        output_valid_reg <= 1'b0;
                    end
                end

                SET_ADDR: begin
                    i_x_idx <= x_idx * STRIDE_W + k;
                    i_y_idx <= y_idx * STRIDE_H + j;
                    weight_addr <= j * KERNEL_W + k;
                end

                WAIT_WEIGHT: begin
                    // mac_weight_in <= weight_data;
                end

                SET_DATA: begin
                    mac_weight_in <= weight_data;
                    // Padding logic: if index is in padding region, use 0
                    if (i_x_idx < PAD_W || i_x_idx >= INPUT_W + PAD_W ||
                        i_y_idx < PAD_H || i_y_idx >= INPUT_H + PAD_H) begin
                        mac_data_in <= 8'd0;  // Padding value (0)
                    end else begin
                        mac_data_in <= input_data[(i_y_idx - PAD_H) * INPUT_W + (i_x_idx - PAD_W)] + 128;
                    end
                    mac_enable <= 1'b1;
                end

                WAIT_MAC: begin
                    mac_enable <= 1'b0;

                    if (k < KERNEL_W - 1) begin
                        k <= k + 1;
                    end else if (j < KERNEL_H - 1) begin
                        k <= 8'd0;
                        j <= j + 1;
                    end
                end

                CLEAR_ACC: begin
                    mac_clear <= 1'b1;
                    output_res <= mac_acc_out;
                    output_valid_reg <= 1'b1;

                    if (x_idx == OUTPUT_W - 1) begin
                        x_idx <= 8'd0;
                        y_idx <= y_idx + 1;
                    end else begin
                        x_idx <= x_idx + 1;
                    end

                    j <= 8'd0;
                    k <= 8'd0;
                end

                DONE: begin
                    mac_clear <= 1'b0;
                    output_valid_reg <= 1'b0;
                end
            endcase
        end
    end

    assign output_valid = output_valid_reg;

endmodule

