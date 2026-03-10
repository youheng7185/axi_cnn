#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_ARRAY_SIZE 2000
#define MAX_LINE_LENGTH 1024

// 存储解析出的数组数据
typedef struct {
    char name[100];
    int8_t data[MAX_ARRAY_SIZE];
    int size;
} ArrayData;

// 解析数组数据
int parse_array_data(const char *filename, ArrayData *arrays, int *array_count) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        fprintf(stderr, "错误: 无法打开文件 '%s'\n", filename);
        return -1;
    }

    char line[MAX_LINE_LENGTH];
    int current_array = -1;
    int data_index = 0;
    int in_array = 0;

    while (fgets(line, sizeof(line), file) != NULL) {
        // 去除行尾的换行符
        line[strcspn(line, "\r\n")] = '\0';

        // 检查是否是数组定义行
        if (strstr(line, "const int8_t") != NULL && strstr(line, "[") != NULL) {
            // 提取数组名称
            char *start = strstr(line, "micro_speech_input_");
            if (start != NULL) {
                char *end = strchr(start, '[');
                if (end != NULL) {
                    int len = end - start;
                    if (len < sizeof(arrays[*array_count].name)) {
                        strncpy(arrays[*array_count].name, start, len);
                        arrays[*array_count].name[len] = '\0';
                        current_array = *array_count;
                        arrays[current_array].size = 0;
                        data_index = 0;
                        in_array = 1;
                        (*array_count)++;
                    }
                }
            }
            continue;
        }

        // 检查是否是数组结束
        if (in_array && strstr(line, "};") != NULL) {
            in_array = 0;
            arrays[current_array].size = data_index;
            continue;
        }

        // 解析数组数据
        if (in_array && current_array >= 0) {
            char *ptr = line;
            while (*ptr != '\0') {
                // 跳过空白字符
                while (isspace(*ptr)) ptr++;
                if (*ptr == '\0') break;

                // 检查是否是数字
                if (*ptr == '-' || isdigit(*ptr)) {
                    int value;
                    if (sscanf(ptr, "%d", &value) == 1) {
                        if (data_index < MAX_ARRAY_SIZE) {
                            arrays[current_array].data[data_index++] = (int8_t)value;
                        }
                        // 跳过数字
                        while (*ptr == '-' || isdigit(*ptr)) ptr++;
                    }
                } else {
                    ptr++;
                }
            }
        }
    }

    fclose(file);
    return 0;
}

// 生成 Verilog initial 块
void generate_verilog_initial(FILE *output, ArrayData *array, const char *rom_name) {
    fprintf(output, "initial\n");
    fprintf(output, "begin\n");
    
    // 正常映射：输出索引与输入索引一一对应
    for (int i = 0; i < array->size; i++) {
        int8_t value = array->data[i];
        fprintf(output, "    %s[%d] = %d;\n", rom_name, i, value);
    }
    
    fprintf(output, "end\n");
}

int main() {
    const char *input_filename = "input_data_array.h";
    const char *output_filename = "input_data_initial.v";

    ArrayData arrays[10];
    int array_count = 0;

    // 解析输入文件
    if (parse_array_data(input_filename, arrays, &array_count) != 0) {
        return EXIT_FAILURE;
    }

    printf("成功解析 %d 个数组:\n", array_count);
    for (int i = 0; i < array_count; i++) {
        printf("  - %s: %d 个元素\n", arrays[i].name, arrays[i].size);
    }

    // 打开输出文件
    FILE *output = fopen(output_filename, "w");
    if (output == NULL) {
        fprintf(stderr, "错误: 无法创建输出文件 '%s'\n", output_filename);
        return EXIT_FAILURE;
    }

    // 为每个数组生成 Verilog initial 块
    for (int i = 0; i < array_count; i++) {
        char rom_name[150];
        snprintf(rom_name, sizeof(rom_name), "%s_rom", arrays[i].name);
        
        fprintf(output, "// %s initial block (index shifted left by 1)\n", arrays[i].name);
        generate_verilog_initial(output, &arrays[i], rom_name);
        fprintf(output, "\n");
    }

    fclose(output);
    printf("\n成功生成 Verilog 文件: %s\n", output_filename);

    return EXIT_SUCCESS;
}
