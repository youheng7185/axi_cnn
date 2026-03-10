```bash
iverilog -Wall -g2012 -o ./build/tb_out ./all_v2_tb.v ./conv.v ./fc.v ./mac.v ./first_weights_seperate_filter.v ./final_weights_seperate_class.v prepare_data.v
```

```bash
vvp -n ./build/tb_out -vcd ./build/tb_out.vcd
```