#include <stdio.h>
#include <stdint.h>

// Model constants
#define FC_OUTPUT_SIZE 4
#define FC_INPUT_SIZE 4000  // 20 * 17 * 8

// Include the original weight array
#include "final_fc_weights_read_transpose.h"

// Array to hold separated weights for each class
int8_t class_weights[FC_OUTPUT_SIZE][FC_INPUT_SIZE];

void separate_weights() {
    // Separate weights by class
    // Each class should have FC_INPUT_SIZE weights
    for (int c = 0; c < FC_OUTPUT_SIZE; c++) {
        for (int i = 0; i < FC_INPUT_SIZE; i++) {
            // Original indexing: weights are stored as [class][input]
            int weight_idx = c * FC_INPUT_SIZE + i;
            if (weight_idx < 16000) {
                class_weights[c][i] = final_fc_weights_read_transpose[weight_idx];
            } else {
                class_weights[c][i] = 0;  // Padding if needed
            }
        }
    }
}

void print_class_weights(int class_num) {
    printf("Class %d weights (first 20):\n", class_num);
    for (int i = 0; i < 20 && i < FC_INPUT_SIZE; i++) {
        printf("  [%d] = %d\n", i, class_weights[class_num][i]);
    }
}

void generate_verilog_rom(int class_num) {
    printf("// ROM for Class %d\n", class_num);
    printf("module class_%d_weight_rom (\n", class_num);
    printf("    input wire clk,\n");
    printf("    input wire [11:0] addr,  // 0-3999 (12 bits needed)\n");
    printf("    output reg signed [7:0] weight\n");
    printf(");\n");
    printf("    reg signed [7:0] rom [0: %d];\n", FC_INPUT_SIZE - 1);
    printf("    initial begin\n");
    
    for (int i = 0; i < FC_INPUT_SIZE; i++) {
        int8_t val = class_weights[class_num][i];
        if (val < 0) {
            printf("        rom[%d] = -8'sd%d;\n", i, -val);
        } else {
            printf("        rom[%d] = 8'sd%d;\n", i, val);
        }
    }
    
    printf("    end\n");
    printf("    always @(posedge clk) begin\n");
    printf("        if (addr < 12'd%d) begin\n", FC_INPUT_SIZE);
    printf("            weight <= rom[addr];\n");
    printf("        end else begin\n");
    printf("            weight <= 8'sd0;\n");
    printf("        end\n");
    printf("    end\n");
    printf("endmodule\n\n");
}

void generate_c_header() {
    printf("// C header file with separated class weights\n");
    printf("#ifndef FC_WEIGHTS_SEPARATED_H\n");
    printf("#define FC_WEIGHTS_SEPARATED_H\n\n");
    printf("#include <stdint.h>\n\n");
    printf("#define FC_OUTPUT_SIZE 4\n");
    printf("#define FC_INPUT_SIZE %d\n\n", FC_INPUT_SIZE);
    
    for (int c = 0; c < FC_OUTPUT_SIZE; c++) {
        printf("static const int8_t class_%d_weights[%d] = {\n    ", c, FC_INPUT_SIZE);
        for (int i = 0; i < FC_INPUT_SIZE; i++) {
            printf("%d", class_weights[c][i]);
            if (i < FC_INPUT_SIZE - 1) {
                printf(", ");
                if ((i + 1) % 10 == 0) {
                    printf("\n    ");
                }
            }
        }
        printf("\n};\n\n");
    }
    printf("#endif // FC_WEIGHTS_SEPARATED_H\n");
}

void generate_single_file_verilog() {
    printf("// Single Verilog file containing all class ROMs\n");
    printf("// Generated weight ROMs for all %d classes\n\n", FC_OUTPUT_SIZE);
    
    for (int c = 0; c < FC_OUTPUT_SIZE; c++) {
        generate_verilog_rom(c);
    }
}

int main() {
    printf("=== Separating FC Weights by Class ===\n\n");
    
    // Separate the weights
    separate_weights();
    
    // Print summary
    printf("Total weights in original array: 16000\n");
    printf("Classes: %d\n", FC_OUTPUT_SIZE);
    printf("Weights per class: %d\n", FC_INPUT_SIZE);
    printf("Total weights used: %d\n\n", FC_OUTPUT_SIZE * FC_INPUT_SIZE);
    
    // Verify the indexing
    printf("=== Verification ===\n");
    printf("Class 0 first few weights from original array:\n");
    printf("  Index 0: %d\n", final_fc_weights_read_transpose[0]);
    printf("  Index 1: %d\n", final_fc_weights_read_transpose[1]);
    printf("  Index 2: %d\n", final_fc_weights_read_transpose[2]);
    printf("\nClass 0 first few weights from separated array:\n");
    printf("  [0]: %d\n", class_weights[0][0]);
    printf("  [1]: %d\n", class_weights[0][1]);
    printf("  [2]: %d\n", class_weights[0][2]);
    printf("\nClass 1 first few weights from original array:\n");
    printf("  Index 4000: %d\n", final_fc_weights_read_transpose[4000]);
    printf("  Index 4001: %d\n", final_fc_weights_read_transpose[4001]);
    printf("  Index 4002: %d\n", final_fc_weights_read_transpose[4002]);
    printf("\nClass 1 first few weights from separated array:\n");
    printf("  [0]: %d\n", class_weights[1][0]);
    printf("  [1]: %d\n", class_weights[1][1]);
    printf("  [2]: %d\n", class_weights[1][2]);
    printf("\n");
    
    // Print all class weights (first 20 of each)
    for (int c = 0; c < FC_OUTPUT_SIZE; c++) {
        print_class_weights(c);
        printf("\n");
    }
    
    // Generate Verilog ROM modules
    printf("=== Verilog ROM Modules ===\n\n");
    for (int c = 0; c < FC_OUTPUT_SIZE; c++) {
        generate_verilog_rom(c);
    }
    
    // Generate a single file with all ROMs
    printf("=== All ROMs in One File ===\n\n");
    generate_single_file_verilog();
    
    // Generate C header file
    printf("=== C Header File ===\n\n");
    generate_c_header();
    
    return 0;
}
