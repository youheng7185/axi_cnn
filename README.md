```bash
iverilog -Wall -g2012 -o ./build/cnn_controller_tb_out ./cnn_controller_tb.v ./cnn_controller.v ./conv.v ./fc.v ./mac.v ./first_weights_seperate_filter.v ./final_weights_seperate_class.v prepare_data.v
```

```bash
vvp -n ./build/cnn_controller_tb_out -vcd ./build/cnn_controller_tb_out.vcd
```
