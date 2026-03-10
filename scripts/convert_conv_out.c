#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

// Model constants from deepseek_cnn.c
#define CONV_OUTPUT_H 20
#define CONV_OUTPUT_W 17
#define CONV_FILTERS 8
#define FC_INPUT_SIZE 2720  // 20 * 17 * 8 = 2720

#define MAX_OUTPUTS 10000

// Structure to hold parsed data
typedef struct {
    int filter;
    int time;
    int output;
} ConvOutput;

ConvOutput outputs[MAX_OUTPUTS];
int output_count = 0;

// Parse conv_out file
void parse_conv_out_file(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Error: Cannot open file %s\n", filename);
        exit(1);
    }

    char line[256];
    while (fgets(line, sizeof(line), file) && output_count < MAX_OUTPUTS) {
        int filter, time, output;
        if (sscanf(line, "Filter[%d] Time: %d, Output: %d", &filter, &time, &output) == 3) {
            outputs[output_count].filter = filter;
            outputs[output_count].time = time;
            outputs[output_count].output = output;
            output_count++;
        }
    }

    fclose(file);
    printf("Parsed %d output values from %s\n", output_count, filename);
}

// Quantize output to int8 range (-128 to 127)
int8_t quantize_output(int32_t value) {
    // Simple scaling: divide by 1000 and clamp to int8 range
    int32_t scaled = value / 1000;
    if (scaled > 127) return 127;
    if (scaled < -128) return -128;
    return (int8_t)scaled;
}

// Flatten outputs in same order as deepseek_cnn.c
// Order: (oh, ow, oc) where oc is filter/channel index
// From deepseek_cnn.c line 149: output_idx = (oh * output_w + ow) * num_filters + oc
// The conv_out file is already organized with 8 filters per time step
// We just need to read them in order and flatten
void flatten_outputs(int8_t* flattened) {
    // The conv_out file has outputs organized as:
    // Time1: Filter[0], Filter[1], ..., Filter[7]
    // Time2: Filter[0], Filter[1], ..., Filter[7]
    // ...
    // This matches the flattening pattern in deepseek_cnn.c
    // where for each spatial position (oh, ow), we have all 8 filter outputs
    
    int idx = 0;
    for (int i = 0; i < output_count && idx < FC_INPUT_SIZE; i++) {
        flattened[idx++] = quantize_output(outputs[i].output);
    }
    
    // Fill remaining with zeros if needed
    while (idx < FC_INPUT_SIZE) {
        flattened[idx++] = 0;
    }
}

// Generate Verilog initial block for flattened array
void generate_verilog_initial_flattened(const int8_t* flattened) {
    printf("// Verilog initial block for flattened conv outputs\n");
    printf("// Format: flattened[oh][ow][oc] where oc is filter index\n");
    printf("// Total size: %d (20 * 17 * 8)\n", FC_INPUT_SIZE);
    printf("// This matches the format in deepseek_cnn.c line 149:\n");
    printf("// output_idx = (oh * output_w + ow) * num_filters + oc\n");
    printf("\ninitial begin\n");
    
    for (int i = 0; i < FC_INPUT_SIZE; i++) {
        printf("    conv_output_flattened[%d] = %d;", i, flattened[i]);
        
        // Print 10 assignments per line
        if ((i + 1) % 10 == 0 || i == FC_INPUT_SIZE - 1) {
            printf("\n");
        }
    }
    
    printf("end\n");
}

// Generate C header file with flattened array
void generate_c_header_flattened(const int8_t* flattened) {
    printf("// C header file with flattened conv outputs\n");
    printf("// Format: flattened[oh][ow][oc] where oc is filter index\n");
    printf("#ifndef CONV_OUTPUT_FLATTENED_H\n");
    printf("#define CONV_OUTPUT_FLATTENED_H\n\n");
    printf("#include <stdint.h>\n\n");
    printf("#define CONV_OUTPUT_H %d\n", CONV_OUTPUT_H);
    printf("#define CONV_OUTPUT_W %d\n", CONV_OUTPUT_W);
    printf("#define CONV_FILTERS %d\n", CONV_FILTERS);
    printf("#define FC_INPUT_SIZE %d\n\n", FC_INPUT_SIZE);
    
    printf("// Flattened conv output array\n");
    printf("// Order: [oh][ow][oc] where oc is filter/channel index\n");
    printf("// This matches the format in deepseek_cnn.c line 149:\n");
    printf("// output_idx = (oh * output_w + ow) * num_filters + oc\n");
    printf("static const int8_t conv_output_flattened[%d] = {\n    ", FC_INPUT_SIZE);
    for (int i = 0; i < FC_INPUT_SIZE; i++) {
        printf("%d", flattened[i]);
        if (i < FC_INPUT_SIZE - 1) {
            printf(", ");
            if ((i + 1) % 10 == 0) {
                printf("\n    ");
            }
        }
    }
    printf("\n};\n\n");
    
    printf("#endif // CONV_OUTPUT_FLATTENED_H\n");
}

// Print statistics
void print_statistics() {
    printf("\n=== Statistics ===\n");
    printf("Total outputs: %d\n", output_count);
    
    int counts[CONV_FILTERS] = {0};
    int min_output = 2147483647;
    int max_output = -2147483648;
    int64_t sum = 0;
    
    for (int i = 0; i < output_count; i++) {
        counts[outputs[i].filter]++;
        if (outputs[i].output < min_output) min_output = outputs[i].output;
        if (outputs[i].output > max_output) max_output = outputs[i].output;
        sum += outputs[i].output;
    }
    
    printf("Outputs per filter:\n");
    for (int f = 0; f < CONV_FILTERS; f++) {
        printf("  Filter %d: %d outputs\n", f, counts[f]);
    }
    
    printf("Output range: %d to %d\n", min_output, max_output);
    printf("Average output: %.2f\n", (double)sum / output_count);
}

int main(int argc, char* argv[]) {
    const char* filename = "conv_out";
    if (argc > 1) {
        filename = argv[1];
    }
    
    printf("=== Converting conv_out to Flattened Format ===\n");
    printf("Following deepseek_cnn.c conv output format\n\n");
    
    // Parse file
    parse_conv_out_file(filename);
    
    // Print statistics
    print_statistics();
    
    // Flatten outputs
    int8_t flattened[FC_INPUT_SIZE];
    flatten_outputs(flattened);
    
    // Generate outputs
    printf("\n=== Verilog Initial Block (Flattened) ===\n\n");
    generate_verilog_initial_flattened(flattened);
    
    printf("\n=== C Header File (Flattened) ===\n\n");
    generate_c_header_flattened(flattened);
    
    return 0;
}
