`define KERNEL_W    8
`define KERNEL_H    10
`define INPUT_W     40
`define INPUT_H     49
`define OUTPUT_W    (`INPUT_W - `KERNEL_W + 1)
`define OUTPUT_H    (`INPUT_H - `KERNEL_H + 1)
`define OUTPUT_SIZE (`INPUT_H - `KERNEL_H + 1)*(`INPUT_W - `KERNEL_W + 1)

module cnn_controller (
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed[7: 0] data_in[0: 1959],
    output wire signed[7: 0] data_out[0: 3],
    output reg valid_out
);
    reg conv_start, fc_start;
    wire[7: 0] data_out_0; 
    assign data_out_0 = data_out[0];


    always @(posedge clk) begin
        if (!rst) begin

            // data_out[0] <= 8'b0;
            // data_out[1] <= 8'b0;
            // data_out[2] <= 8'b0;
            // data_out[3] <= 8'b0;
            valid_out <= 1'b0;

            output_count[0] <= 9'd0;
            output_count[1] <= 9'd0;
            output_count[2] <= 9'd0;
            output_count[3] <= 9'd0;
            output_count[4] <= 9'd0;
            output_count[5] <= 9'd0;
            output_count[6] <= 9'd0;
            output_count[7] <= 9'd0;
            storage_done <= 1'b0;
        end
    end

    wire [7: 0] weight_addr;

    wire signed [8: 0] mac_data_in;  // 9 bits to handle +128 offset
    wire signed [7: 0] mac_weight_in [0: 7];
    wire mac_enable;
    wire mac_clear;
    // wire signed [31: 0] mac_acc_out;

    wire signed [7:0] weight_data [0:7];
    wire signed [31:0] mac_acc_out [0:7];
    wire signed [31:0] output_res [0:7];
    wire signed [7: 0] scaled_output [0: 7];
    wire output_valid [0:7];

    // Convolution output storage - flattened array (4000 outputs total)
    // Storage order: Interleaved - Filter[0][0], Filter[1][0], ..., Filter[7][0], Filter[0][1], ...
    // Address formula: Filter[j] output k stored at address j + k*8
    reg signed [7: 0] conv_output_flattened [0: 3999];
    reg [8:0] output_count [0:7];   // Output counter for each filter (0-499)
    reg storage_done;                // Flag indicating all outputs stored
    filter_0_weight_rom weight_inst0 (.clk(clk), .addr(weight_addr), .weight(weight_data[0]));
    filter_1_weight_rom weight_inst1 (.clk(clk), .addr(weight_addr), .weight(weight_data[1]));
    filter_2_weight_rom weight_inst2 (.clk(clk), .addr(weight_addr), .weight(weight_data[2]));
    filter_3_weight_rom weight_inst3 (.clk(clk), .addr(weight_addr), .weight(weight_data[3]));
    filter_4_weight_rom weight_inst4 (.clk(clk), .addr(weight_addr), .weight(weight_data[4]));
    filter_5_weight_rom weight_inst5 (.clk(clk), .addr(weight_addr), .weight(weight_data[5]));
    filter_6_weight_rom weight_inst6 (.clk(clk), .addr(weight_addr), .weight(weight_data[6]));
    filter_7_weight_rom weight_inst7 (.clk(clk), .addr(weight_addr), .weight(weight_data[7]));

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : filter_core

            mac_unit #(
                .DATA_WIDTH(9),  // Changed to 9 to handle +128 offset
                .ACC_WIDTH(32)
            ) mac_inst (
                .clk        (clk),
                .rst        (rst),
                .clear      (mac_clear),
                .enable     (mac_enable),
                .data_in    (mac_data_in),
                .weight_in  (mac_weight_in[i]),
                .acc_out    (mac_acc_out[i]),
                .acc_valid  ()
            );

            conv #(
                .KERNEL_W(`KERNEL_W),
                .KERNEL_H(`KERNEL_H),
                .STRIDE_W(2),
                .STRIDE_H(2),
                .PAD_W(3),
                .PAD_H(4),
                .INPUT_W(`INPUT_W),
                .INPUT_H(`INPUT_H)
            ) conv_inst (
                .clk            (clk),
                .rst            (rst),
                .start          (conv_start),
                .input_data     (data_in),
                .weight_addr    (weight_addr),
                .weight_data    (weight_data[i]),
                .output_res     (output_res[i]),
                .output_valid   (output_valid[i]),
                .mac_data_in    (mac_data_in),
                .mac_weight_in  (mac_weight_in[i]),
                .mac_enable     (mac_enable),
                .mac_clear      (mac_clear),
                .mac_acc_out    (mac_acc_out[i])
            );
            prepare_conv_output conv_prepare_inst(
                .data_in            (mac_acc_out[i]),
                .filter_num         (i[2:0]),
                .enable             (output_valid[i]),
                .quant_data_out     (scaled_output[i]) 
            );
        end
    endgenerate


    wire signed [31: 0] fc_output_res[0: 3];
    wire fc_output_valid[0: 3];

    wire signed [7: 0] fc_weight_data[0: 3];
    wire [11: 0] fc_weight_addr;

    wire signed [7: 0] fc_mac_data_in[0: 3];
    wire signed [7: 0] fc_mac_weight_in[0: 3];
    wire fc_mac_enable[0: 3];
    wire fc_mac_clear[0: 3];
    wire signed [31: 0] fc_mac_acc_out[0: 3];
    // reg signed [7 :0] data_out[0: 3];

    // always @(posedge clk) begin
    //     if (!rst) begin
    //         fc_scaled_out[0] <= 8'b0;
    //         fc_scaled_out[1] <= 8'b0;
    //         fc_scaled_out[2] <= 8'b0;
    //         fc_scaled_out[3] <= 8'b0;
    //     end
    // end

    /* DEBUG */
    wire signed [7 :0] debug_fc_scaled_out = data_out[0];
    wire signed [7: 0] debug_fc_conv_output_flattened = conv_output_flattened[0];


    class_0_weight_rom fc_weight_inst0(.clk(clk), .addr(fc_weight_addr), .weight(fc_weight_data[0]));
    class_1_weight_rom fc_weight_inst1(.clk(clk), .addr(fc_weight_addr), .weight(fc_weight_data[1]));
    class_2_weight_rom fc_weight_inst2(.clk(clk), .addr(fc_weight_addr), .weight(fc_weight_data[2]));
    class_3_weight_rom fc_weight_inst3(.clk(clk), .addr(fc_weight_addr), .weight(fc_weight_data[3]));

    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin : class_core
            mac_unit #(
                .DATA_WIDTH(9),
                .ACC_WIDTH(32)
            ) mac_inst(
                .clk        (clk),
                .rst        (rst),
                .clear      (fc_mac_clear[j]),
                .enable     (fc_mac_enable[j]),
                .data_in    (fc_mac_data_in[j]),
                .weight_in  (fc_mac_weight_in[j]),
                .acc_out    (fc_mac_acc_out[j]),
                .acc_valid  ()
            );

            fc #(
                .LEN(4000)
            ) fc_inst(
                .clk        (clk),
                .rst        (rst),
                .start      (fc_start),
                .input_data (conv_output_flattened),
                .weight_addr(fc_weight_addr),
                .weight_data(fc_weight_data[j]),
                .output_res (fc_output_res[j]),
                .output_valid(fc_output_valid[j]),
                .mac_data_in(fc_mac_data_in[j]),
                .mac_weight_in(fc_mac_weight_in[j]),
                .mac_enable(fc_mac_enable[j]),
                .mac_clear(fc_mac_clear[j]),
                .mac_acc_out(fc_mac_acc_out[j])
            );
            prepare_fc_output prepare_inst(
                .data_in            (fc_mac_acc_out[j]),
                .class_num          (j[1: 0]),
                .enable             (fc_output_valid[j]),
                .quant_data_out     (data_out[j]) 
            );
        end
    endgenerate

    // Store convolution outputs to flattened array
    integer k;
    always @(posedge clk) begin
        if (!storage_done) begin
            for (k = 0; k < 8; k = k + 1) begin
                if (output_valid[k]) begin
                    // Store output to flattened array using interleaved pattern
                    conv_output_flattened[k + output_count[k] * 8] <= scaled_output[k];
                    // $display("Filter[%0d] Time: %0t, Output: %0d, Stored at addr: %0d (output_count: %0d)",
                    //          k, $time, scaled_output[k], k + output_count[k] * 8, output_count[k]);

                    // Increment output counter for this filter
                    if (output_count[k] <= 9'd499) begin
                        output_count[k] <= output_count[k] + 1'b1;
                    end
                end
            end
            // Check if all filters have completed storing 500 outputs
            if (output_count[0] == 9'd500 && output_count[1] == 9'd500 &&
                output_count[2] == 9'd500 && output_count[3] == 9'd500 &&
                output_count[4] == 9'd500 && output_count[5] == 9'd500 &&
                output_count[6] == 9'd500 && output_count[7] == 9'd500) begin
                storage_done <= 1'b1;
                $display("All 4000 convolution outputs stored successfully in conv_output_flattened!");
            end
        end
    end

    localparam CNN_CONTROLLER_IDLE = 2'd0;
    localparam CNN_CONTROLLER_CONV = 2'd1;
    localparam CNN_CONTROLLER_FC = 2'd2;
    reg[1: 0] state;

    always @(posedge clk) begin
        if (!rst) begin
            fc_start <= 1'b0;
            conv_start <= 1'b0;
            state <= CNN_CONTROLLER_IDLE;
        end
        else begin
            case (state)
                CNN_CONTROLLER_IDLE: begin
                    valid_out <= 1'b0;
                    if (start) begin
                        state <= CNN_CONTROLLER_CONV;
                        conv_start <= 1'b1;
                    end
                end
                CNN_CONTROLLER_CONV: begin
                    conv_start <= 1'b0;
                    if (storage_done) begin
                        state <= CNN_CONTROLLER_FC;
                        fc_start <= 1'b1;
                    end
                end
                CNN_CONTROLLER_FC: begin
                    fc_start <= 1'b0;
                    if (fc_output_valid[0]) begin
                        state <= CNN_CONTROLLER_IDLE;
                        valid_out <= 1'b1;
                    end
                end
                default: 
                    state <= CNN_CONTROLLER_IDLE;
            endcase
        end
    end
    // assign data_out[0] = fc_scaled_out[0];
    // assign data_out[1] = fc_scaled_out[1];
    // assign data_out[2] = fc_scaled_out[2];
    // assign data_out[3] = fc_scaled_out[3];

endmodule