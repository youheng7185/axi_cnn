#include "Vaxi_cnn.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <cassert>
#include <cstdint>
#include "scripts/conv_input_data.h"

vluint64_t sim_time = 0;

// -------------------------------------------------
// CLOCK TICK
// -------------------------------------------------
void tick(Vaxi_cnn *dut, VerilatedVcdC* tfp) {
    dut->S_AXI_ACLK = 0;
    dut->eval();
    tfp->dump(sim_time++);
    dut->S_AXI_ACLK = 1;
    dut->eval();
    tfp->dump(sim_time++);
}

// -------------------------------------------------
// AXI WRITE
// -------------------------------------------------
void axi_write(Vaxi_cnn *dut, VerilatedVcdC* tfp,
               uint32_t addr, uint32_t data)
{
    dut->S_AXI_AWADDR  = addr;
    dut->S_AXI_AWVALID = 1;
    dut->S_AXI_WDATA   = data;
    dut->S_AXI_WSTRB   = 0xF;
    dut->S_AXI_WVALID  = 1;
    dut->S_AXI_BREADY  = 1;

    while (!dut->S_AXI_AWREADY)
        tick(dut, tfp);
    tick(dut, tfp);
    dut->S_AXI_AWVALID = 0;
    dut->S_AXI_WVALID  = 0;

    while (!dut->S_AXI_BVALID)
        tick(dut, tfp);
    tick(dut, tfp);
    dut->S_AXI_BREADY  = 0;
}

// -------------------------------------------------
// AXI READ
// -------------------------------------------------
uint32_t axi_read(Vaxi_cnn *dut, VerilatedVcdC* tfp,
                  uint32_t addr)
{
    dut->S_AXI_ARADDR  = addr;
    dut->S_AXI_ARVALID = 1;
    dut->S_AXI_RREADY  = 1;

    while (!dut->S_AXI_ARREADY)
        tick(dut, tfp);
    tick(dut, tfp);
    dut->S_AXI_ARVALID = 0;

    while (!dut->S_AXI_RVALID)
        tick(dut, tfp);
    uint32_t data = dut->S_AXI_RDATA;
    tick(dut, tfp);
    dut->S_AXI_RREADY  = 0;
    return data;
}

// -------------------------------------------------
// MAIN
// -------------------------------------------------
int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vaxi_cnn *dut = new Vaxi_cnn;
    VerilatedVcdC* tfp = new VerilatedVcdC;

    Verilated::traceEverOn(true);
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");

    // Initialize signals
    dut->S_AXI_ARESETN = 0;
    dut->S_AXI_AWVALID = 0;
    dut->S_AXI_WVALID  = 0;
    dut->S_AXI_BREADY  = 0;
    dut->S_AXI_ARVALID = 0;
    dut->S_AXI_RREADY  = 0;

    // Reset sequence
    for (int i = 0; i < 5; i++)
        tick(dut, tfp);
    dut->S_AXI_ARESETN = 1;
    for (int i = 0; i < 5; i++)
        tick(dut, tfp);

    std::cout << "=== axi_cnn testbench start ===\n";

    // -------------------------------------------------
    // STEP 1: Status register should be 0 at reset
    // -------------------------------------------------
    uint32_t status = axi_read(dut, tfp, 0x000);
    std::cout << "[STEP 1] status = 0x" << std::hex << status << std::dec;
    assert((status & 0x1) == 0);
    std::cout << "  [PASS]\n";

    // -------------------------------------------------
    // STEP 2: Write first 4 words and read back immediately
    //         Verifies single write->read round trip before bulk
    // -------------------------------------------------
    std::cout << "\n[STEP 2] Write first 4 words, read back each immediately\n";
    for (int w = 0; w < 4; w++) {
        uint32_t word =
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+0])        |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+1] << 8)   |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+2] << 16)  |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+3] << 24);
        uint32_t byte_addr = 0x008 + w * 4;

        axi_write(dut, tfp, byte_addr, word);
        uint32_t rb = axi_read(dut, tfp, byte_addr);

        std::cout << "  word[" << std::dec << w
                  << "] @ 0x" << std::hex << byte_addr
                  << "  wrote=0x" << word
                  << "  read=0x"  << rb << std::dec;
        if (rb == word)
            std::cout << "  [PASS]\n";
        else {
            std::cout << "  [FAIL] MISMATCH — AXI data_in path is broken\n";
            dut->final(); tfp->close(); delete dut; return 1;
        }
    }

    // -------------------------------------------------
    // STEP 3: Bulk write all 490 words
    // -------------------------------------------------
    std::cout << "\n[STEP 3] Bulk writing all 490 input words...\n";
    for (int w = 0; w < 490; w++) {
        uint32_t word =
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+0])        |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+1] << 8)   |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+2] << 16)  |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+3] << 24);
        axi_write(dut, tfp, 0x008 + w * 4, word);
    }
    std::cout << "[STEP 3] Bulk write done\n";

    // -------------------------------------------------
    // STEP 4: Full readback — all 490 words
    //         Stop at first 5 mismatches to avoid flood
    // -------------------------------------------------
    std::cout << "\n[STEP 4] Full readback of all 490 words...\n";
    int mismatch_count = 0;
    for (int w = 0; w < 490; w++) {
        uint32_t expected =
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+0])        |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+1] << 8)   |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+2] << 16)  |
            ((uint32_t)(uint8_t)conv2d_input_no[w*4+3] << 24);
        uint32_t byte_addr = 0x008 + w * 4;
        uint32_t rb = axi_read(dut, tfp, byte_addr);

        if (rb != expected) {
            std::cout << "  [FAIL] word[" << std::dec << w
                      << "] @ 0x" << std::hex << byte_addr
                      << "  expected=0x" << expected
                      << "  got=0x"      << rb << "\n";
            mismatch_count++;
            if (mismatch_count >= 5) {
                std::cout << "  (stopped at 5 mismatches)\n";
                break;
            }
        }
    }

    if (mismatch_count == 0) {
        std::cout << "[STEP 4] All 490 words match  [PASS]\n";
    } else {
        std::cout << "[STEP 4] " << std::dec << mismatch_count
                  << " mismatch(es)  [FAIL] — fix data_in before continuing\n";
        dut->final(); tfp->close(); delete dut; return 1;
    }

    // -------------------------------------------------
    // STEP 5: Trigger inference
    // -------------------------------------------------
    std::cout << "\n[STEP 5] Triggering inference (config @ 0x004 = 0x1)\n";
    axi_write(dut, tfp, 0x004, 0x00000001);
    uint32_t cfg = axi_read(dut, tfp, 0x004);
    std::cout << "  config readback = 0x" << std::hex << cfg << std::dec;
    assert((cfg & 0x1) == 1);
    std::cout << "  [PASS]\n";

    // -------------------------------------------------
    // STEP 6: Poll status register until done
    // -------------------------------------------------
    std::cout << "\n[STEP 6] Polling status until inference done...\n";

    status = axi_read(dut, tfp, 0x000);

    while ((status & 0x1) == 0) {
        tick(dut, tfp);
        status = axi_read(dut, tfp, 0x000);
    }

    // std::cout << "[STEP 6] status = 0x" << std::hex << status
    //           << std::dec << "  [PASS]\n";

    // // -------------------------------------------------
    // // STEP 7: Probe output region to find where data landed
    // //         ADDR_DATA_OUT = 0x7D8 >> 2 = word 502
    // //         Last input word = 2 + 489 = 491 → byte 0x7AC
    // //         So 0x7D8 should be safely after input region
    // // -------------------------------------------------
    std::cout << "\n[STEP 7] Probing output region\n";
    for (uint32_t probe = 0x7C8; probe <= 0x7E8; probe += 4) {
        uint32_t val = axi_read(dut, tfp, probe);
        std::cout << "  @ 0x" << std::hex << probe << " = 0x" << val;
        // highlight non-zero
        if (val != 0) std::cout << "  <-- non-zero";
        std::cout << "\n";
    }

    // // -------------------------------------------------
    // // STEP 8: Read and decode output word at 0x7D8
    // // -------------------------------------------------
    // std::cout << "\n[STEP 8] Reading output @ 0x7D8\n";
    // uint32_t output_word = axi_read(dut, tfp, 0x7D8);
    // std::cout << "  raw = 0x" << std::hex << output_word << std::dec << "\n";

    // int8_t class0 = (int8_t)((output_word >>  0) & 0xFF);
    // int8_t class1 = (int8_t)((output_word >>  8) & 0xFF);
    // int8_t class2 = (int8_t)((output_word >> 16) & 0xFF);
    // int8_t class3 = (int8_t)((output_word >> 24) & 0xFF);

    // std::cout << "  class0 (silence) = " << (int)class0 << "\n";
    // std::cout << "  class1 (unknown) = " << (int)class1 << "\n";
    // std::cout << "  class2 (yes)     = " << (int)class2 << "\n";
    // std::cout << "  class3 (no)      = " << (int)class3 << "\n";

    // int8_t scores[4] = {class0, class1, class2, class3};
    // const char* labels[4] = {"silence", "unknown", "yes", "no"};
    // int winner = 0;
    // for (int i = 1; i < 4; i++)
    //     if (scores[i] > scores[winner]) winner = i;
    // std::cout << "  Predicted: " << labels[winner]
    //           << " (class" << winner << ")\n";

    // assert(class2 > class0 && class2 > class1 && class2 > class3);
    // std::cout << "[STEP 8] class2 (yes) is highest  [PASS]\n";

    // std::cout << "\n=== All steps PASSED ===\n";

    dut->final();
    tfp->close();
    delete dut;
    return 0;
}