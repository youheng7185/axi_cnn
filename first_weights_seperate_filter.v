// === Separating First Weights by Filter ===

// Total weights: 640
// Filters: 8
// Weights per filter: 80

// === Verification ===
// Filter 0 first few weights from original array:
//   Index 0: -6
//   Index 8: 30
//   Index 16: 92

// Filter 0 first few weights from separated array:
//   [0]: -6
//   [1]: 30
//   [2]: 92

// Filter 1 first few weights from original array:
//   Index 1: -18
//   Index 9: -9
//   Index 17: -55

// Filter 1 first few weights from separated array:
//   [0]: -18
//   [1]: -9
//   [2]: -55

// === Verilog ROM Modules (Fixed Syntax) ===

// ROM for Filter 0
module filter_0_weight_rom (
    input wire clk,
    input wire [7:0] addr,  // 0-79 (7 bits needed)
    output reg signed [7:0] weight
);
    reg signed [7:0] rom [0: 79];
    initial begin
        rom[0] = -8'sd6;
        rom[1] = 8'sd30;
        rom[2] = 8'sd92;
        rom[3] = 8'sd9;
        rom[4] = 8'sd54;
        rom[5] = -8'sd62;
        rom[6] = 8'sd7;
        rom[7] = -8'sd89;
        rom[8] = -8'sd52;
        rom[9] = 8'sd0;
        rom[10] = 8'sd79;
        rom[11] = 8'sd5;
        rom[12] = 8'sd72;
        rom[13] = -8'sd33;
        rom[14] = 8'sd47;
        rom[15] = -8'sd49;
        rom[16] = -8'sd75;
        rom[17] = -8'sd28;
        rom[18] = 8'sd64;
        rom[19] = -8'sd28;
        rom[20] = 8'sd72;
        rom[21] = -8'sd19;
        rom[22] = 8'sd77;
        rom[23] = -8'sd8;
        rom[24] = -8'sd116;
        rom[25] = -8'sd45;
        rom[26] = 8'sd49;
        rom[27] = 8'sd2;
        rom[28] = 8'sd79;
        rom[29] = -8'sd19;
        rom[30] = 8'sd110;
        rom[31] = 8'sd18;
        rom[32] = -8'sd127;
        rom[33] = -8'sd70;
        rom[34] = 8'sd37;
        rom[35] = -8'sd23;
        rom[36] = 8'sd94;
        rom[37] = -8'sd29;
        rom[38] = 8'sd111;
        rom[39] = 8'sd31;
        rom[40] = -8'sd112;
        rom[41] = -8'sd62;
        rom[42] = 8'sd21;
        rom[43] = -8'sd15;
        rom[44] = 8'sd58;
        rom[45] = -8'sd11;
        rom[46] = 8'sd109;
        rom[47] = 8'sd22;
        rom[48] = -8'sd114;
        rom[49] = -8'sd63;
        rom[50] = 8'sd3;
        rom[51] = -8'sd7;
        rom[52] = 8'sd51;
        rom[53] = -8'sd11;
        rom[54] = 8'sd110;
        rom[55] = 8'sd40;
        rom[56] = -8'sd107;
        rom[57] = -8'sd51;
        rom[58] = 8'sd10;
        rom[59] = -8'sd15;
        rom[60] = 8'sd38;
        rom[61] = -8'sd17;
        rom[62] = 8'sd114;
        rom[63] = 8'sd23;
        rom[64] = -8'sd110;
        rom[65] = -8'sd49;
        rom[66] = -8'sd22;
        rom[67] = -8'sd10;
        rom[68] = 8'sd30;
        rom[69] = 8'sd10;
        rom[70] = 8'sd94;
        rom[71] = 8'sd16;
        rom[72] = -8'sd99;
        rom[73] = -8'sd81;
        rom[74] = -8'sd13;
        rom[75] = -8'sd42;
        rom[76] = 8'sd4;
        rom[77] = -8'sd9;
        rom[78] = 8'sd61;
        rom[79] = -8'sd23;
    end
    always @(posedge clk) begin
        if (addr < 8'd80) begin
            weight <= rom[addr];
        end else begin
            weight <= 8'sd0;
        end
    end
endmodule

// ROM for Filter 1
module filter_1_weight_rom (
    input wire clk,
    input wire [7:0] addr,  // 0-79 (7 bits needed)
    output reg signed [7:0] weight
);
    reg signed [7:0] rom [0: 79];
    initial begin
        rom[0] = -8'sd18;
        rom[1] = -8'sd9;
        rom[2] = -8'sd55;
        rom[3] = -8'sd14;
        rom[4] = -8'sd73;
        rom[5] = -8'sd99;
        rom[6] = -8'sd35;
        rom[7] = 8'sd22;
        rom[8] = -8'sd70;
        rom[9] = -8'sd3;
        rom[10] = -8'sd49;
        rom[11] = -8'sd59;
        rom[12] = 8'sd23;
        rom[13] = -8'sd18;
        rom[14] = 8'sd42;
        rom[15] = -8'sd86;
        rom[16] = 8'sd104;
        rom[17] = 8'sd73;
        rom[18] = -8'sd89;
        rom[19] = 8'sd85;
        rom[20] = -8'sd127;
        rom[21] = 8'sd75;
        rom[22] = -8'sd89;
        rom[23] = 8'sd31;
        rom[24] = 8'sd23;
        rom[25] = 8'sd81;
        rom[26] = 8'sd23;
        rom[27] = 8'sd15;
        rom[28] = -8'sd52;
        rom[29] = -8'sd68;
        rom[30] = 8'sd88;
        rom[31] = -8'sd121;
        rom[32] = 8'sd36;
        rom[33] = 8'sd0;
        rom[34] = -8'sd106;
        rom[35] = -8'sd12;
        rom[36] = -8'sd73;
        rom[37] = -8'sd31;
        rom[38] = -8'sd30;
        rom[39] = 8'sd70;
        rom[40] = 8'sd29;
        rom[41] = 8'sd60;
        rom[42] = 8'sd2;
        rom[43] = -8'sd62;
        rom[44] = 8'sd67;
        rom[45] = -8'sd20;
        rom[46] = -8'sd65;
        rom[47] = -8'sd83;
        rom[48] = -8'sd61;
        rom[49] = -8'sd77;
        rom[50] = 8'sd63;
        rom[51] = -8'sd89;
        rom[52] = -8'sd71;
        rom[53] = -8'sd78;
        rom[54] = 8'sd9;
        rom[55] = 8'sd20;
        rom[56] = 8'sd55;
        rom[57] = 8'sd49;
        rom[58] = 8'sd12;
        rom[59] = -8'sd75;
        rom[60] = -8'sd55;
        rom[61] = 8'sd3;
        rom[62] = -8'sd12;
        rom[63] = 8'sd94;
        rom[64] = 8'sd50;
        rom[65] = -8'sd68;
        rom[66] = 8'sd18;
        rom[67] = -8'sd32;
        rom[68] = 8'sd16;
        rom[69] = -8'sd37;
        rom[70] = 8'sd6;
        rom[71] = -8'sd97;
        rom[72] = 8'sd1;
        rom[73] = -8'sd24;
        rom[74] = 8'sd54;
        rom[75] = -8'sd98;
        rom[76] = -8'sd21;
        rom[77] = -8'sd83;
        rom[78] = -8'sd124;
        rom[79] = 8'sd60;
    end
    always @(posedge clk) begin
        if (addr < 8'd80) begin
            weight <= rom[addr];
        end else begin
            weight <= 8'sd0;
        end
    end
endmodule

// ROM for Filter 2
module filter_2_weight_rom (
    input wire clk,
    input wire [7:0] addr,  // 0-79 (7 bits needed)
    output reg signed [7:0] weight
);
    reg signed [7:0] rom [0: 79];
    initial begin
        rom[0] = 8'sd40;
        rom[1] = 8'sd31;
        rom[2] = 8'sd24;
        rom[3] = 8'sd24;
        rom[4] = 8'sd30;
        rom[5] = -8'sd15;
        rom[6] = -8'sd3;
        rom[7] = -8'sd43;
        rom[8] = 8'sd30;
        rom[9] = 8'sd40;
        rom[10] = 8'sd9;
        rom[11] = 8'sd23;
        rom[12] = -8'sd12;
        rom[13] = -8'sd28;
        rom[14] = -8'sd19;
        rom[15] = -8'sd46;
        rom[16] = 8'sd18;
        rom[17] = 8'sd20;
        rom[18] = -8'sd10;
        rom[19] = 8'sd29;
        rom[20] = -8'sd23;
        rom[21] = -8'sd19;
        rom[22] = -8'sd19;
        rom[23] = -8'sd39;
        rom[24] = 8'sd15;
        rom[25] = 8'sd46;
        rom[26] = -8'sd16;
        rom[27] = 8'sd31;
        rom[28] = -8'sd45;
        rom[29] = -8'sd12;
        rom[30] = -8'sd20;
        rom[31] = -8'sd40;
        rom[32] = -8'sd23;
        rom[33] = 8'sd25;
        rom[34] = -8'sd46;
        rom[35] = -8'sd11;
        rom[36] = -8'sd79;
        rom[37] = -8'sd32;
        rom[38] = -8'sd5;
        rom[39] = -8'sd13;
        rom[40] = -8'sd64;
        rom[41] = -8'sd6;
        rom[42] = -8'sd80;
        rom[43] = -8'sd12;
        rom[44] = -8'sd72;
        rom[45] = -8'sd7;
        rom[46] = 8'sd13;
        rom[47] = 8'sd10;
        rom[48] = -8'sd90;
        rom[49] = -8'sd39;
        rom[50] = -8'sd66;
        rom[51] = -8'sd9;
        rom[52] = -8'sd41;
        rom[53] = -8'sd2;
        rom[54] = 8'sd54;
        rom[55] = 8'sd46;
        rom[56] = -8'sd84;
        rom[57] = -8'sd34;
        rom[58] = -8'sd35;
        rom[59] = 8'sd4;
        rom[60] = -8'sd12;
        rom[61] = 8'sd10;
        rom[62] = 8'sd90;
        rom[63] = 8'sd87;
        rom[64] = -8'sd53;
        rom[65] = -8'sd24;
        rom[66] = -8'sd15;
        rom[67] = 8'sd8;
        rom[68] = 8'sd4;
        rom[69] = 8'sd42;
        rom[70] = 8'sd114;
        rom[71] = 8'sd90;
        rom[72] = -8'sd32;
        rom[73] = -8'sd50;
        rom[74] = 8'sd7;
        rom[75] = 8'sd10;
        rom[76] = 8'sd36;
        rom[77] = 8'sd28;
        rom[78] = 8'sd127;
        rom[79] = 8'sd54;
    end
    always @(posedge clk) begin
        if (addr < 8'd80) begin
            weight <= rom[addr];
        end else begin
            weight <= 8'sd0;
        end
    end
endmodule

// ROM for Filter 3
module filter_3_weight_rom (
    input wire clk,
    input wire [7:0] addr,  // 0-79 (7 bits needed)
    output reg signed [7:0] weight
);
    reg signed [7:0] rom [0: 79];
    initial begin
        rom[0] = -8'sd60;
        rom[1] = 8'sd6;
        rom[2] = -8'sd29;
        rom[3] = 8'sd52;
        rom[4] = -8'sd9;
        rom[5] = 8'sd7;
        rom[6] = -8'sd61;
        rom[7] = -8'sd15;
        rom[8] = -8'sd53;
        rom[9] = 8'sd68;
        rom[10] = -8'sd16;
        rom[11] = 8'sd93;
        rom[12] = -8'sd23;
        rom[13] = 8'sd8;
        rom[14] = -8'sd62;
        rom[15] = -8'sd6;
        rom[16] = -8'sd74;
        rom[17] = 8'sd21;
        rom[18] = -8'sd54;
        rom[19] = 8'sd48;
        rom[20] = -8'sd15;
        rom[21] = -8'sd6;
        rom[22] = -8'sd57;
        rom[23] = -8'sd6;
        rom[24] = -8'sd71;
        rom[25] = 8'sd73;
        rom[26] = -8'sd17;
        rom[27] = 8'sd120;
        rom[28] = -8'sd1;
        rom[29] = 8'sd11;
        rom[30] = -8'sd60;
        rom[31] = 8'sd6;
        rom[32] = -8'sd84;
        rom[33] = 8'sd88;
        rom[34] = -8'sd20;
        rom[35] = 8'sd105;
        rom[36] = -8'sd27;
        rom[37] = 8'sd13;
        rom[38] = -8'sd103;
        rom[39] = 8'sd4;
        rom[40] = -8'sd107;
        rom[41] = 8'sd36;
        rom[42] = -8'sd25;
        rom[43] = 8'sd100;
        rom[44] = -8'sd31;
        rom[45] = -8'sd27;
        rom[46] = -8'sd114;
        rom[47] = 8'sd2;
        rom[48] = -8'sd54;
        rom[49] = 8'sd53;
        rom[50] = -8'sd18;
        rom[51] = 8'sd127;
        rom[52] = -8'sd25;
        rom[53] = -8'sd24;
        rom[54] = -8'sd73;
        rom[55] = 8'sd24;
        rom[56] = -8'sd51;
        rom[57] = 8'sd4;
        rom[58] = 8'sd22;
        rom[59] = 8'sd82;
        rom[60] = -8'sd8;
        rom[61] = -8'sd64;
        rom[62] = -8'sd55;
        rom[63] = 8'sd0;
        rom[64] = -8'sd40;
        rom[65] = 8'sd87;
        rom[66] = -8'sd9;
        rom[67] = 8'sd112;
        rom[68] = -8'sd9;
        rom[69] = -8'sd90;
        rom[70] = -8'sd35;
        rom[71] = 8'sd23;
        rom[72] = -8'sd32;
        rom[73] = 8'sd2;
        rom[74] = -8'sd54;
        rom[75] = 8'sd42;
        rom[76] = -8'sd52;
        rom[77] = -8'sd100;
        rom[78] = -8'sd52;
        rom[79] = -8'sd18;
    end
    always @(posedge clk) begin
        if (addr < 8'd80) begin
            weight <= rom[addr];
        end else begin
            weight <= 8'sd0;
        end
    end
endmodule

// ROM for Filter 4
module filter_4_weight_rom (
    input wire clk,
    input wire [7:0] addr,  // 0-79 (7 bits needed)
    output reg signed [7:0] weight
);
    reg signed [7:0] rom [0: 79];
    initial begin
        rom[0] = -8'sd18;
        rom[1] = 8'sd13;
        rom[2] = -8'sd7;
        rom[3] = 8'sd98;
        rom[4] = 8'sd59;
        rom[5] = 8'sd94;
        rom[6] = -8'sd40;
        rom[7] = -8'sd61;
        rom[8] = -8'sd41;
        rom[9] = -8'sd5;
        rom[10] = -8'sd6;
        rom[11] = 8'sd100;
        rom[12] = 8'sd46;
        rom[13] = 8'sd56;
        rom[14] = -8'sd65;
        rom[15] = -8'sd84;
        rom[16] = -8'sd50;
        rom[17] = 8'sd3;
        rom[18] = -8'sd5;
        rom[19] = 8'sd69;
        rom[20] = 8'sd30;
        rom[21] = 8'sd47;
        rom[22] = -8'sd110;
        rom[23] = -8'sd111;
        rom[24] = -8'sd46;
        rom[25] = 8'sd31;
        rom[26] = -8'sd1;
        rom[27] = 8'sd106;
        rom[28] = 8'sd10;
        rom[29] = 8'sd66;
        rom[30] = -8'sd103;
        rom[31] = -8'sd94;
        rom[32] = -8'sd50;
        rom[33] = 8'sd41;
        rom[34] = 8'sd14;
        rom[35] = 8'sd107;
        rom[36] = 8'sd17;
        rom[37] = 8'sd79;
        rom[38] = -8'sd126;
        rom[39] = -8'sd58;
        rom[40] = -8'sd16;
        rom[41] = 8'sd2;
        rom[42] = 8'sd39;
        rom[43] = 8'sd56;
        rom[44] = 8'sd13;
        rom[45] = 8'sd34;
        rom[46] = -8'sd73;
        rom[47] = -8'sd114;
        rom[48] = -8'sd11;
        rom[49] = -8'sd8;
        rom[50] = 8'sd25;
        rom[51] = 8'sd29;
        rom[52] = -8'sd24;
        rom[53] = -8'sd13;
        rom[54] = -8'sd52;
        rom[55] = -8'sd89;
        rom[56] = -8'sd41;
        rom[57] = -8'sd23;
        rom[58] = -8'sd32;
        rom[59] = 8'sd1;
        rom[60] = -8'sd42;
        rom[61] = -8'sd44;
        rom[62] = -8'sd41;
        rom[63] = -8'sd76;
        rom[64] = -8'sd61;
        rom[65] = -8'sd101;
        rom[66] = -8'sd37;
        rom[67] = -8'sd94;
        rom[68] = -8'sd87;
        rom[69] = -8'sd74;
        rom[70] = -8'sd48;
        rom[71] = -8'sd79;
        rom[72] = -8'sd81;
        rom[73] = -8'sd118;
        rom[74] = -8'sd53;
        rom[75] = -8'sd127;
        rom[76] = -8'sd55;
        rom[77] = -8'sd92;
        rom[78] = -8'sd44;
        rom[79] = -8'sd43;
    end
    always @(posedge clk) begin
        if (addr < 8'd80) begin
            weight <= rom[addr];
        end else begin
            weight <= 8'sd0;
        end
    end
endmodule

// ROM for Filter 5
module filter_5_weight_rom (
    input wire clk,
    input wire [7:0] addr,  // 0-79 (7 bits needed)
    output reg signed [7:0] weight
);
    reg signed [7:0] rom [0: 79];
    initial begin
        rom[0] = -8'sd2;
        rom[1] = -8'sd19;
        rom[2] = 8'sd20;
        rom[3] = -8'sd22;
        rom[4] = 8'sd34;
        rom[5] = 8'sd11;
        rom[6] = 8'sd74;
        rom[7] = 8'sd5;
        rom[8] = 8'sd61;
        rom[9] = -8'sd14;
        rom[10] = 8'sd69;
        rom[11] = 8'sd0;
        rom[12] = 8'sd75;
        rom[13] = -8'sd15;
        rom[14] = 8'sd54;
        rom[15] = 8'sd19;
        rom[16] = 8'sd14;
        rom[17] = -8'sd19;
        rom[18] = 8'sd0;
        rom[19] = -8'sd30;
        rom[20] = -8'sd4;
        rom[21] = -8'sd46;
        rom[22] = -8'sd33;
        rom[23] = -8'sd11;
        rom[24] = -8'sd57;
        rom[25] = -8'sd67;
        rom[26] = -8'sd72;
        rom[27] = -8'sd80;
        rom[28] = -8'sd106;
        rom[29] = -8'sd56;
        rom[30] = -8'sd82;
        rom[31] = -8'sd62;
        rom[32] = -8'sd74;
        rom[33] = -8'sd74;
        rom[34] = -8'sd100;
        rom[35] = -8'sd75;
        rom[36] = -8'sd101;
        rom[37] = -8'sd91;
        rom[38] = -8'sd91;
        rom[39] = -8'sd54;
        rom[40] = 8'sd25;
        rom[41] = 8'sd77;
        rom[42] = 8'sd34;
        rom[43] = 8'sd64;
        rom[44] = 8'sd21;
        rom[45] = 8'sd54;
        rom[46] = 8'sd21;
        rom[47] = 8'sd20;
        rom[48] = 8'sd127;
        rom[49] = 8'sd127;
        rom[50] = 8'sd104;
        rom[51] = 8'sd118;
        rom[52] = 8'sd105;
        rom[53] = 8'sd91;
        rom[54] = 8'sd56;
        rom[55] = 8'sd38;
        rom[56] = 8'sd81;
        rom[57] = 8'sd106;
        rom[58] = 8'sd36;
        rom[59] = 8'sd80;
        rom[60] = 8'sd49;
        rom[61] = 8'sd79;
        rom[62] = 8'sd49;
        rom[63] = 8'sd58;
        rom[64] = -8'sd90;
        rom[65] = -8'sd23;
        rom[66] = -8'sd71;
        rom[67] = -8'sd19;
        rom[68] = -8'sd73;
        rom[69] = 8'sd16;
        rom[70] = -8'sd71;
        rom[71] = -8'sd25;
        rom[72] = -8'sd100;
        rom[73] = -8'sd69;
        rom[74] = -8'sd121;
        rom[75] = -8'sd41;
        rom[76] = -8'sd107;
        rom[77] = -8'sd42;
        rom[78] = -8'sd80;
        rom[79] = -8'sd49;
    end
    always @(posedge clk) begin
        if (addr < 8'd80) begin
            weight <= rom[addr];
        end else begin
            weight <= 8'sd0;
        end
    end
endmodule

// ROM for Filter 6
module filter_6_weight_rom (
    input wire clk,
    input wire [7:0] addr,  // 0-79 (7 bits needed)
    output reg signed [7:0] weight
);
    reg signed [7:0] rom [0: 79];
    initial begin
        rom[0] = -8'sd49;
        rom[1] = -8'sd23;
        rom[2] = 8'sd40;
        rom[3] = -8'sd17;
        rom[4] = 8'sd40;
        rom[5] = 8'sd30;
        rom[6] = -8'sd13;
        rom[7] = -8'sd3;
        rom[8] = -8'sd44;
        rom[9] = -8'sd13;
        rom[10] = 8'sd65;
        rom[11] = -8'sd8;
        rom[12] = 8'sd46;
        rom[13] = 8'sd22;
        rom[14] = -8'sd12;
        rom[15] = -8'sd10;
        rom[16] = -8'sd33;
        rom[17] = -8'sd6;
        rom[18] = 8'sd77;
        rom[19] = -8'sd4;
        rom[20] = 8'sd33;
        rom[21] = -8'sd6;
        rom[22] = -8'sd26;
        rom[23] = -8'sd27;
        rom[24] = -8'sd2;
        rom[25] = 8'sd1;
        rom[26] = 8'sd93;
        rom[27] = -8'sd7;
        rom[28] = 8'sd30;
        rom[29] = -8'sd15;
        rom[30] = -8'sd36;
        rom[31] = -8'sd26;
        rom[32] = 8'sd21;
        rom[33] = -8'sd2;
        rom[34] = 8'sd96;
        rom[35] = -8'sd31;
        rom[36] = 8'sd24;
        rom[37] = -8'sd34;
        rom[38] = -8'sd55;
        rom[39] = -8'sd42;
        rom[40] = 8'sd48;
        rom[41] = 8'sd6;
        rom[42] = 8'sd103;
        rom[43] = -8'sd33;
        rom[44] = 8'sd17;
        rom[45] = -8'sd28;
        rom[46] = -8'sd65;
        rom[47] = -8'sd38;
        rom[48] = 8'sd81;
        rom[49] = 8'sd4;
        rom[50] = 8'sd120;
        rom[51] = -8'sd37;
        rom[52] = 8'sd21;
        rom[53] = -8'sd30;
        rom[54] = -8'sd65;
        rom[55] = -8'sd53;
        rom[56] = 8'sd103;
        rom[57] = 8'sd0;
        rom[58] = 8'sd126;
        rom[59] = -8'sd35;
        rom[60] = 8'sd27;
        rom[61] = -8'sd30;
        rom[62] = -8'sd64;
        rom[63] = -8'sd56;
        rom[64] = 8'sd99;
        rom[65] = -8'sd9;
        rom[66] = 8'sd127;
        rom[67] = -8'sd52;
        rom[68] = 8'sd52;
        rom[69] = -8'sd22;
        rom[70] = -8'sd42;
        rom[71] = -8'sd64;
        rom[72] = 8'sd70;
        rom[73] = -8'sd28;
        rom[74] = 8'sd110;
        rom[75] = -8'sd49;
        rom[76] = 8'sd51;
        rom[77] = -8'sd7;
        rom[78] = -8'sd12;
        rom[79] = -8'sd51;
    end
    always @(posedge clk) begin
        if (addr < 8'd80) begin
            weight <= rom[addr];
        end else begin
            weight <= 8'sd0;
        end
    end
endmodule

// ROM for Filter 7
module filter_7_weight_rom (
    input wire clk,
    input wire [7:0] addr,  // 0-79 (7 bits needed)
    output reg signed [7:0] weight
);
    reg signed [7:0] rom [0: 79];
    initial begin
        rom[0] = 8'sd15;
        rom[1] = -8'sd125;
        rom[2] = 8'sd42;
        rom[3] = -8'sd42;
        rom[4] = 8'sd57;
        rom[5] = 8'sd44;
        rom[6] = 8'sd40;
        rom[7] = 8'sd39;
        rom[8] = 8'sd41;
        rom[9] = -8'sd74;
        rom[10] = 8'sd73;
        rom[11] = -8'sd18;
        rom[12] = 8'sd63;
        rom[13] = 8'sd19;
        rom[14] = 8'sd2;
        rom[15] = -8'sd24;
        rom[16] = 8'sd88;
        rom[17] = -8'sd44;
        rom[18] = 8'sd94;
        rom[19] = 8'sd1;
        rom[20] = 8'sd50;
        rom[21] = -8'sd5;
        rom[22] = -8'sd37;
        rom[23] = -8'sd59;
        rom[24] = 8'sd104;
        rom[25] = -8'sd21;
        rom[26] = 8'sd98;
        rom[27] = -8'sd2;
        rom[28] = 8'sd44;
        rom[29] = -8'sd22;
        rom[30] = -8'sd41;
        rom[31] = -8'sd94;
        rom[32] = 8'sd107;
        rom[33] = 8'sd1;
        rom[34] = 8'sd95;
        rom[35] = -8'sd10;
        rom[36] = 8'sd16;
        rom[37] = -8'sd27;
        rom[38] = -8'sd74;
        rom[39] = -8'sd105;
        rom[40] = 8'sd119;
        rom[41] = 8'sd7;
        rom[42] = 8'sd77;
        rom[43] = -8'sd10;
        rom[44] = -8'sd2;
        rom[45] = -8'sd3;
        rom[46] = -8'sd97;
        rom[47] = -8'sd101;
        rom[48] = 8'sd86;
        rom[49] = 8'sd10;
        rom[50] = 8'sd80;
        rom[51] = -8'sd24;
        rom[52] = -8'sd9;
        rom[53] = 8'sd6;
        rom[54] = -8'sd118;
        rom[55] = -8'sd78;
        rom[56] = 8'sd68;
        rom[57] = 8'sd19;
        rom[58] = 8'sd73;
        rom[59] = -8'sd11;
        rom[60] = -8'sd48;
        rom[61] = -8'sd3;
        rom[62] = -8'sd114;
        rom[63] = -8'sd46;
        rom[64] = 8'sd38;
        rom[65] = 8'sd28;
        rom[66] = 8'sd22;
        rom[67] = -8'sd15;
        rom[68] = -8'sd86;
        rom[69] = -8'sd8;
        rom[70] = -8'sd96;
        rom[71] = 8'sd1;
        rom[72] = -8'sd40;
        rom[73] = -8'sd10;
        rom[74] = -8'sd52;
        rom[75] = -8'sd64;
        rom[76] = -8'sd127;
        rom[77] = -8'sd26;
        rom[78] = -8'sd94;
        rom[79] = 8'sd45;
    end
    always @(posedge clk) begin
        if (addr < 8'd80) begin
            weight <= rom[addr];
        end else begin
            weight <= 8'sd0;
        end
    end
endmodule
