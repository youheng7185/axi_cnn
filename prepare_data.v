module prepare_input (
    input   signed[7: 0]    data_in,
    input   wire            enable,
    output  reg[7: 0]       quant_data_out
);
    always @(data_in) begin
        if (enable) begin
            quant_data_out <= data_in + 128;
        end
        else begin
            quant_data_out <= 0;
        end
    end
endmodule

module prepare_conv_output (
    input   reg signed[31: 0]   data_in,
    input   reg[2: 0]           filter_num,
    input   wire                enable,
    output  reg signed[7: 0]    quant_data_out
);
    localparam signed[31:0] CONV_BIAS0 = -32'd374;
    localparam signed[31:0] CONV_BIAS1 =  32'd169;
    localparam signed[31:0] CONV_BIAS2 = -32'd48;
    localparam signed[31:0] CONV_BIAS3 =  32'd208;
    localparam signed[31:0] CONV_BIAS4 =  32'd82;
    localparam signed[31:0] CONV_BIAS5 =  32'd6;
    localparam signed[31:0] CONV_BIAS6 = -32'd1201;
    localparam signed[31:0] CONV_BIAS7 = -32'd694;

    wire signed [31:0] CONV_BIAS [0:7];
    generate
        assign CONV_BIAS[0] = CONV_BIAS0;
        assign CONV_BIAS[1] = CONV_BIAS1;
        assign CONV_BIAS[2] = CONV_BIAS2;
        assign CONV_BIAS[3] = CONV_BIAS3;
        assign CONV_BIAS[4] = CONV_BIAS4;
        assign CONV_BIAS[5] = CONV_BIAS5;
        assign CONV_BIAS[6] = CONV_BIAS6;
        assign CONV_BIAS[7] = CONV_BIAS7;
    endgenerate


//   1653229999, 1516545207, 2000799311, 1159928266,
//   1498403863, 1285645282, 2146175029, 1756589032
// static const int32_t output_shift[8] = {
//   -10, -12, -10, -10, -10, -10, -10, -10
// };
    localparam signed[31:0] EFFECTIVE_SCALE0 = 32'd1653229999 >> 10;
    localparam signed[31:0] EFFECTIVE_SCALE1 = 32'd1516545207 >> 12;
    localparam signed[31:0] EFFECTIVE_SCALE2 = 32'd2000799311 >> 10;
    localparam signed[31:0] EFFECTIVE_SCALE3 = 32'd1159928266 >> 10;
    localparam signed[31:0] EFFECTIVE_SCALE4 = 32'd1498403863 >> 10;
    localparam signed[31:0] EFFECTIVE_SCALE5 = 32'd1285645282 >> 10;
    localparam signed[31:0] EFFECTIVE_SCALE6 = 32'd2146175029 >> 10;
    localparam signed[31:0] EFFECTIVE_SCALE7 = 32'd1756589032 >> 10;

    wire signed [31:0] EFFECTIVE_SCALE [0:7];
    generate
        assign EFFECTIVE_SCALE[0] = EFFECTIVE_SCALE0;
        assign EFFECTIVE_SCALE[1] = EFFECTIVE_SCALE1;
        assign EFFECTIVE_SCALE[2] = EFFECTIVE_SCALE2;
        assign EFFECTIVE_SCALE[3] = EFFECTIVE_SCALE3;
        assign EFFECTIVE_SCALE[4] = EFFECTIVE_SCALE4;
        assign EFFECTIVE_SCALE[5] = EFFECTIVE_SCALE5;
        assign EFFECTIVE_SCALE[6] = EFFECTIVE_SCALE6;
        assign EFFECTIVE_SCALE[7] = EFFECTIVE_SCALE7;
    endgenerate
    reg signed [63:0] _val;
    reg signed [63:0] _debug_val;

    wire signed [31:0] bias;
    wire signed [31:0] scale;

    reg signed [63:0] _val_temp;
    reg signed [63:0] _rounded_val;

    always @(*) begin
    //_debug_val = (data_in + bias) * scale;
    _debug_val = $signed({{32{data_in[31]}}, data_in}) + $signed({{32{bias[31]}}, bias});
    _debug_val = _debug_val * $signed({{32{scale[31]}}, scale});        
    
    // Correct rounding: add 2^30 with sign consideration, then shift right by 31
    if (_debug_val[63]) begin 
        _val_temp = _debug_val - 64'h0000000040000000;  // Subtract 2^30 for negative
    end else begin
        _val_temp = _debug_val + 64'h0000000040000000;  // Add 2^30 for positive
    end        
    
    _rounded_val = $signed(_val_temp) >>> 31;  // Use arithmetic shift
    
    _val = _rounded_val - 128;

    if (_val < -128) begin
        _val = -128;
    end else if (_val > 127) begin
        _val = 127;
    end

    if (enable) begin
        quant_data_out = _val[7:0];
    end else begin
        quant_data_out = 0;
    end
    end

    assign bias = CONV_BIAS[filter_num];
    assign scale = EFFECTIVE_SCALE[filter_num];
endmodule

module prepare_fc_output (
    input wire signed[31: 0]   data_in,
    input wire[1: 0]    class_num,
    input wire          enable,
    output reg signed[7: 0] quant_data_out
);
    localparam signed [31:0] BIAS0 =  32'sd427;
    localparam signed [31:0] BIAS1 = -32'sd518;
    localparam signed [31:0] BIAS2 = -32'sd94;
    localparam signed [31:0] BIAS3 =  32'sd186;
    
    // FC_OUTPUT_MULTIPLIER = 1932201031
    // FC_OUTPUT_SHIFT = -11
    localparam signed [31:0] FC_QUANTIZED_MULTIPLIER = 32'sd1932201031;
    localparam FC_OUTPUT_SHIFT = -11;
    localparam FC_OUTPUT_OFFSET = 14;
    localparam FC_ACT_MIN = -128;
    localparam FC_ACT_MAX = 127;

    wire signed [31:0] FC_BIAS [0:3];
    generate
        assign FC_BIAS[0] = BIAS0;
        assign FC_BIAS[1] = BIAS1;
        assign FC_BIAS[2] = BIAS2;
        assign FC_BIAS[3] = BIAS3;
    endgenerate
    
    wire signed [31:0] reduced_multiplier;
    assign reduced_multiplier = (FC_QUANTIZED_MULTIPLIER < 32'sh7FFF0000) ? 
                                 ((FC_QUANTIZED_MULTIPLIER + (1 << 15)) >>> 16) : 
                                 32'sh7FFF;
    
    // total_shift = 15 - shift
    wire signed [31:0] total_shift;
    assign total_shift = 15 - FC_OUTPUT_SHIFT;  // 15 - (-11) = 26
    
    reg signed [63:0] acc_with_bias;
    reg signed [63:0] multiplied;
    reg signed [63:0] with_rounding;
    reg signed [63:0] shifted_result;
    reg signed [31:0] quantized_result;
    reg signed [31:0] with_offset;
    reg signed [31:0] clamped;
    
    wire signed [31:0] bias;
    assign bias = FC_BIAS[class_num];
    
    always @(*) begin
        // acc_with_bias = data_in + bias;
        acc_with_bias = $signed({{32{data_in[31]}}, data_in}) + $signed({{32{bias[31]}}, bias});
        
        //multiplied = acc_with_bias * reduced_multiplier;
        multiplied = acc_with_bias * $signed({{32{reduced_multiplier[31]}}, reduced_multiplier});

        with_rounding = multiplied + (64'sd1 << (total_shift - 1));
        
        shifted_result = with_rounding >>> total_shift;
        quantized_result = shifted_result[31:0];
        
        with_offset = quantized_result + FC_OUTPUT_OFFSET;
        
        // Step 6: Clamp
        if (with_offset > FC_ACT_MAX) begin
            clamped = FC_ACT_MAX;
        end else if (with_offset < FC_ACT_MIN) begin
            clamped = FC_ACT_MIN;
        end else begin
            clamped = with_offset;
        end
        
        if (enable) begin
            quant_data_out = clamped[7:0];
            // $display("acc = %0d", data_in);
            // $display("bias = %0d", bias);
            // $display("acc_with_bias = %0d", acc_with_bias);

            $display("FC class%0d: data_in=%0d bias=%0d acc_with_bias=%0d", 
                    class_num, data_in, bias, acc_with_bias);
            $display("FC class%0d: reduced_mult=%0d multiplied=%0d",
                    class_num, reduced_multiplier, multiplied);
            $display("FC class%0d: with_rounding=%0d shifted=%0d quantized=%0d with_offset=%0d",
                    class_num, with_rounding, shifted_result, quantized_result, with_offset);

        end else begin
            quant_data_out = 0;
        end
    end
    
endmodule