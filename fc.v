module fc #(
    parameter LEN = 4,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire start,
    
    input wire signed [DATA_WIDTH-1:0] input_data [0: LEN-1],
    
    output reg [11:0] weight_addr,
    input wire signed [DATA_WIDTH-1:0] weight_data,
    
    output reg signed [ACC_WIDTH-1:0] output_res,
    output reg output_valid,
    
    output reg signed [DATA_WIDTH:0] mac_data_in,
    output reg signed [DATA_WIDTH-1:0] mac_weight_in,
    output reg mac_enable,
    output reg mac_clear,
    input wire signed [ACC_WIDTH-1:0] mac_acc_out
);

    localparam IDLE        = 3'd0;
    localparam SET_ADDR    = 3'd1;
    localparam SET_WEIGHT = 3'd2;
    localparam SET_DATA    = 3'd3;
    localparam WAIT_MAC    = 3'd4;
    localparam CLEAR_ACC   = 3'd5;
    localparam DONE        = 3'd6;
    localparam WAIT_WEIGHT = 3'd7;

    reg [2:0] state, next_state;

    reg [11:0] i;

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
                next_state = SET_WEIGHT;
            end

            SET_WEIGHT: begin
                next_state = WAIT_WEIGHT;
            end
            WAIT_WEIGHT: begin
                next_state = SET_DATA;
            end

            SET_DATA: begin
                next_state = WAIT_MAC;
            end

            WAIT_MAC: begin
                if (i % LEN == LEN - 1)
                    next_state = CLEAR_ACC;
                else
                    next_state = SET_ADDR;
            end

            CLEAR_ACC: begin
                next_state = DONE;
            end

            DONE: begin
                if (i == LEN - 1)
                    next_state = IDLE;
                else
                    next_state = SET_ADDR;
            end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            i <= 12'd0;
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
                        i <= 12'd0;
                        mac_clear <= 1'b0;
                        output_valid_reg <= 1'b0;
                    end
                end

                SET_ADDR: begin
                    weight_addr <= i;
                end

                SET_WEIGHT: begin
                end
                WAIT_WEIGHT: begin
                    mac_weight_in <= weight_data;
                end

                SET_DATA: begin
                    //mac_data_in <= input_data[i % LEN] + 128;
                    mac_data_in <= $signed({{1{input_data[i % LEN][7]}}, input_data[i % LEN]}) + 9'sd128;
                    mac_enable <= 1'b1;
                end

                WAIT_MAC: begin
                    mac_enable <= 1'b0;
                    i <= i + 1;
                end

                CLEAR_ACC: begin
                    mac_clear <= 1'b1;
                    output_res <= mac_acc_out;
                    output_valid_reg <= 1'b1;
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
