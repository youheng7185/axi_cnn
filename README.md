```bash
iverilog -Wall -g2012 -o ./build/cnn_controller_tb_out ./cnn_controller_tb.v ./cnn_controller.v ./conv.v ./fc.v ./mac.v ./first_weights_seperate_filter.v ./final_weights_seperate_class.v prepare_data.v
```

```bash
vvp -n ./build/cnn_controller_tb_out -vcd ./build/cnn_controller_tb_out.vcd
```

## with axi wrapper

| Offset | Name | Description | R/W |
|---|---|---|---|
| 0x000 | status | bit[0] to show inference status, 1 for done | RO |
| 0x004 | config | bit[0] to config start inferrence | RW |
| 0x008 to 0x7D4 | data_in | 32 bits, 4 btyes each | RW |
| 0x7D8 | data out | packed in 4 bytes | RO |