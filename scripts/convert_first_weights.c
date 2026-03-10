#include <stdio.h>
#include <stdint.h>

// Model constants
#define CONV_FILTERS 8
#define CONV_KERNEL_H 10
#define CONV_KERNEL_W 8
#define WEIGHTS_PER_FILTER (CONV_KERNEL_H * CONV_KERNEL_W)  // 80

// Include the original weight array
#include "first_weights_read.h"

// Array to hold separated weights for each filter
int8_t filter_weights[CONV_FILTERS][WEIGHTS_PER_FILTER];

void separate_weights() {
    // Separate weights by filter
    for (int oc = 0; oc < CONV_FILTERS; oc++) {
        int idx = 0;
        for (int kh = 0; kh < CONV_KERNEL_H; kh++) {
            for (int kw = 0; kw < CONV_KERNEL_W; kw++) {
                // Original indexing: (kh * kernel_w * num_filters) + (kw * num_filters) + oc
                int weight_idx = (kh * CONV_KERNEL_W * CONV_FILTERS) + 
                                (kw * CONV_FILTERS) + 
                                oc;
                filter_weights[oc][idx++] = first_weights_read[weight_idx];
            }
        }
    }
}

void print_filter_weights(int filter_num) {
    printf("Filter %d weights:\n", filter_num);
    for (int i = 0; i < WEIGHTS_PER_FILTER; i++) {
        if (filter_weights[filter_num][i] < 0) {
            printf("    rom[%d] = -8'sd%d;\n", i, -filter_weights[filter_num][i]);
        } else {
            printf("    rom[%d] = 8'sd%d;\n", i, filter_weights[filter_num][i]);
        }
    }
}

void generate_verilog_rom(int filter_num) {
    printf("// ROM for Filter %d\n", filter_num);
    printf("module filter_%d_weight_rom (\n", filter_num);
    printf("    input wire clk,\n");
    printf("    input wire [6:0] addr,  // 0-79 (7 bits needed)\n");
    printf("    output reg signed [7:0] weight\n");
    printf(");\n");
    printf("    reg signed [7:0] rom [0: %d];\n", WEIGHTS_PER_FILTER - 1);
    printf("    initial begin\n");
    
    for (int i = 0; i < WEIGHTS_PER_FILTER; i++) {
        int8_t val = filter_weights[filter_num][i];
        if (val < 0) {
            // Fix: Move negative sign to the front for Verilog compatibility
            printf("        rom[%d] = -8'sd%d;\n", i, -val);
        } else {
            printf("        rom[%d] = 8'sd%d;\n", i, val);
        }
    }
    
    printf("    end\n");
    printf("    always @(posedge clk) begin\n");
    printf("        if (addr < 7'd%d) begin\n", WEIGHTS_PER_FILTER);
    printf("            weight <= rom[addr];\n");
    printf("        end else begin\n");
    printf("            weight <= 8'sd0;\n");
    printf("        end\n");
    printf("    end\n");
    printf("endmodule\n\n");
}

void generate_c_header() {
    printf("// C header file with separated filter weights\n");
    printf("#ifndef FILTER_WEIGHTS_SEPARATED_H\n");
    printf("#define FILTER_WEIGHTS_SEPARATED_H\n\n");
    printf("#include <stdint.h>\n\n");
    printf("#define CONV_FILTERS 8\n");
    printf("#define CONV_KERNEL_H 10\n");
    printf("#define CONV_KERNEL_W 8\n");
    printf("#define WEIGHTS_PER_FILTER %d\n\n", WEIGHTS_PER_FILTER);
    
    for (int f = 0; f < CONV_FILTERS; f++) {
        printf("static const int8_t filter_%d_weights[%d] = {\n    ", f, WEIGHTS_PER_FILTER);
        for (int i = 0; i < WEIGHTS_PER_FILTER; i++) {
            printf("%d", filter_weights[f][i]);
            if (i < WEIGHTS_PER_FILTER - 1) {
                printf(", ");
                if ((i + 1) % 10 == 0) {
                    printf("\n    ");
                }
            }
        }
        printf("\n};\n\n");
    }
    printf("#endif // FILTER_WEIGHTS_SEPARATED_H\n");
}

void generate_single_file_verilog() {
    printf("// Single Verilog file containing all filter ROMs\n");
    printf("// Generated weight ROMs for all %d filters\n\n", CONV_FILTERS);
    
    for (int f = 0; f < CONV_FILTERS; f++) {
        generate_verilog_rom(f);
    }
}

void generate_alternative_syntax(int filter_num) {
    printf("// Alternative syntax examples for Filter %d\n", filter_num);
    printf("module filter_%d_weight_rom_alt (\n", filter_num);
    printf("    input wire clk,\n");
    printf("    input wire [6:0] addr,\n");
    printf("    output reg signed [7:0] weight\n");
    printf(");\n");
    printf("    reg signed [7:0] rom [0: %d];\n", WEIGHTS_PER_FILTER - 1);
    printf("    initial begin\n");
    
    for (int i = 0; i < WEIGHTS_PER_FILTER; i++) {
        int8_t val = filter_weights[filter_num][i];
        if (val < 0) {
            // Show all valid syntax options for negative numbers
            printf("        // rom[%d] = %d;  // Direct decimal (SystemVerilog)\n", i, val);
            printf("        rom[%d] = -8'sd%d;  // Correct Verilog syntax\n", i, -val);
            printf("        // rom[%d] = -8'd%d;  // Alternative syntax\n", i, -val);
            printf("        // rom[%d] = 8'h%02X;  // Hex representation\n", i, (uint8_t)val);
        } else {
            printf("        rom[%d] = 8'sd%d;\n", i, val);
        }
    }
    
    printf("    end\n");
    printf("    // ... (rest of module)\n");
    printf("endmodule\n\n");
}

int main() {
    printf("=== Separating First Weights by Filter ===\n\n");
    
    // Separate the weights
    separate_weights();
    
    // Print summary
    printf("Total weights: %d\n", CONV_KERNEL_H * CONV_KERNEL_W * CONV_FILTERS);
    printf("Filters: %d\n", CONV_FILTERS);
    printf("Weights per filter: %d\n\n", WEIGHTS_PER_FILTER);
    
    // Verify the indexing
    printf("=== Verification ===\n");
    printf("Filter 0 first few weights from original array:\n");
    printf("  Index 0: %d\n", first_weights_read[0]);
    printf("  Index 8: %d\n", first_weights_read[8]);
    printf("  Index 16: %d\n", first_weights_read[16]);
    printf("\nFilter 0 first few weights from separated array:\n");
    printf("  [0]: %d\n", filter_weights[0][0]);
    printf("  [1]: %d\n", filter_weights[0][1]);
    printf("  [2]: %d\n", filter_weights[0][2]);
    printf("\nFilter 1 first few weights from original array:\n");
    printf("  Index 1: %d\n", first_weights_read[1]);
    printf("  Index 9: %d\n", first_weights_read[9]);
    printf("  Index 17: %d\n", first_weights_read[17]);
    printf("\nFilter 1 first few weights from separated array:\n");
    printf("  [0]: %d\n", filter_weights[1][0]);
    printf("  [1]: %d\n", filter_weights[1][1]);
    printf("  [2]: %d\n", filter_weights[1][2]);
    printf("\n");
    
    // Generate Verilog ROM modules with correct syntax
    printf("=== Verilog ROM Modules (Fixed Syntax) ===\n\n");
    for (int f = 0; f < CONV_FILTERS; f++) {
        generate_verilog_rom(f);
    }
    
    // Optional: Generate a single file with all ROMs
    printf("=== All ROMs in One File ===\n\n");
    generate_single_file_verilog();
    
    // Generate C header file
    printf("=== C Header File ===\n\n");
    generate_c_header();
    
    return 0;
}