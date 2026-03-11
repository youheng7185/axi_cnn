////////////////////////////////////////////////////////////////////////////////
//
// Filename:	rtl/easyaxil.v
// {{{
// Project:	WB2AXIPSP: bus bridges and other odds and ends
//
// Purpose:	Demonstrates a simple AXI-Lite interface.
//
//	This was written in light of my last demonstrator, for which others
//	declared that it was much too complicated to understand.  The goal of
//	this demonstrator is to have logic that's easier to understand, use,
//	and copy as needed.
//
//	Since there are two basic approaches to AXI-lite signaling, both with
//	and without skidbuffers, this example demonstrates both so that the
//	differences can be compared and contrasted.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2019-2025, Gisselquist Technology, LLC
// {{{
// This file is part of the WB2AXIP project.
//
// The WB2AXIP project contains free software and gateware, licensed under the
// Apache License, Version 2.0 (the "License").  You may not use this project,
// or this file, except in compliance with the License.  You may obtain a copy
// of the License at
// }}}
//	http://www.apache.org/licenses/LICENSE-2.0
// {{{
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//
////////////////////////////////////////////////////////////////////////////////
//
`default_nettype none
// }}}
module	axi_cnn #(
		// {{{
		//
		// Size of the AXI-lite bus.  These are fixed, since 1) AXI-lite
		// is fixed at a width of 32-bits by Xilinx def'n, and 2) since
		// we only ever have 4 configuration words.
		parameter	C_AXI_ADDR_WIDTH = 12,
		localparam	C_AXI_DATA_WIDTH = 32,
        parameter [0:0]	OPT_LOWPOWER = 0
		// }}}
	) (
		// {{{
		input	wire					S_AXI_ACLK,
		input	wire					S_AXI_ARESETN,
		//
		input	wire					S_AXI_AWVALID,
		output	wire					S_AXI_AWREADY,
		input	wire	[C_AXI_ADDR_WIDTH-1:0]		S_AXI_AWADDR,
		input	wire	[2:0]				S_AXI_AWPROT,
		//
		input	wire					S_AXI_WVALID,
		output	wire					S_AXI_WREADY,
		input	wire	[C_AXI_DATA_WIDTH-1:0]		S_AXI_WDATA,
		input	wire	[C_AXI_DATA_WIDTH/8-1:0]	S_AXI_WSTRB,
		//
		output	wire					S_AXI_BVALID,
		input	wire					S_AXI_BREADY,
		output	wire	[1:0]				S_AXI_BRESP,
		//
		input	wire					S_AXI_ARVALID,
		output	wire					S_AXI_ARREADY,
		input	wire	[C_AXI_ADDR_WIDTH-1:0]		S_AXI_ARADDR,
		input	wire	[2:0]				S_AXI_ARPROT,
		//
		output	wire					S_AXI_RVALID,
		input	wire					S_AXI_RREADY,
		output	wire	[C_AXI_DATA_WIDTH-1:0]		S_AXI_RDATA,
		output	wire	[1:0]				S_AXI_RRESP,
		// }}}
	);

    logic start_i;
    logic output_valid_o;

    logic signed [7:0] data_in [0:1959];
    logic signed [7:0] data_out [0:3];

    integer widx, ridx;

    reg inference_done;

	////////////////////////////////////////////////////////////////////////
	//
	// Register/wire signal declarations
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	localparam	ADDRLSB = 2; // last two least significant bit not used
    localparam ADDR_STATUS  = (12'h000 >> ADDRLSB);  // 0x000
    localparam ADDR_CONFIG  = (12'h004 >> ADDRLSB);  // 0x004
    localparam ADDR_DATA_IN = (12'h008 >> ADDRLSB);  // 0x008, 490 words
    localparam ADDR_DATA_OUT= (12'h7D8 >> ADDRLSB);  // 0x7D8
    localparam DATA_IN_WORDS = 490;

	wire	i_reset = !S_AXI_ARESETN;

	wire				axil_write_ready;
	wire	[C_AXI_ADDR_WIDTH-ADDRLSB-1:0]	awskd_addr;
	//
	wire	[C_AXI_DATA_WIDTH-1:0]	wskd_data;
	wire [C_AXI_DATA_WIDTH/8-1:0]	wskd_strb;
	reg				axil_bvalid;
	//
	wire				axil_read_ready;
	wire	[C_AXI_ADDR_WIDTH-ADDRLSB-1:0]	arskd_addr;
	reg	[C_AXI_DATA_WIDTH-1:0]	axil_read_data;
	reg				axil_read_valid;

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// AXI-lite signaling
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{

	//
	// Write signaling
	//
	// {{{

		// {{{
    reg	axil_awready;
	// Replace the write channel section in easyaxil.v

	reg                              aw_latched;
	reg  [C_AXI_ADDR_WIDTH-1:0]     aw_addr_lat;
	reg                              w_latched;
	reg  [C_AXI_DATA_WIDTH-1:0]     w_data_lat;
	reg  [C_AXI_DATA_WIDTH/8-1:0]   w_strb_lat;

	// accept write address any time we don't already have one pending
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			aw_latched   <= 0;
			aw_addr_lat  <= 0;
		end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
			aw_addr_lat  <= S_AXI_AWADDR;
			aw_latched   <= 1;
		end else if (axil_write_ready) begin
			aw_latched   <= 0;  // consumed
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN)
			axil_awready <= 0;
		else
			// ready whenever we don't have a pending address
			axil_awready <= !aw_latched && !S_AXI_AWREADY;
	end

	// accept write data any time we don't already have one pending
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			w_latched  <= 0;
			w_data_lat <= 0;
			w_strb_lat <= 0;
		end else if (S_AXI_WVALID && S_AXI_WREADY) begin
			w_data_lat <= S_AXI_WDATA;
			w_strb_lat <= S_AXI_WSTRB;
			w_latched  <= 1;
		end else if (axil_write_ready) begin
			w_latched  <= 0;  // consumed
		end
	end

	reg axil_wready_r;
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN)
			axil_wready_r <= 0;
		else
			axil_wready_r <= !w_latched && !S_AXI_WREADY;
	end

	assign S_AXI_AWREADY = axil_awready;
	assign S_AXI_WREADY  = axil_wready_r;

	// write fires when BOTH address and data are latched
	assign axil_write_ready = aw_latched && w_latched;

	// use aw_addr_lat and w_data_lat/w_strb_lat in your register write logic
	// instead of awskd_addr / wskd_data / wskd_strb
	assign awskd_addr = aw_addr_lat[C_AXI_ADDR_WIDTH-1:ADDRLSB];
	assign wskd_data  = w_data_lat;
	assign wskd_strb  = w_strb_lat;

	initial	axil_bvalid = 0;
	always @(posedge S_AXI_ACLK)
        if (i_reset)
            axil_bvalid <= 0;
        else if (axil_write_ready)
            axil_bvalid <= 1;
        else if (S_AXI_BREADY)
            axil_bvalid <= 0;

	assign	S_AXI_BVALID = axil_bvalid;
	assign	S_AXI_BRESP = 2'b00;
	// }}}

	//
	// Read signaling
	//
	// {{{

    reg	axil_arready;

    always @(*)
        axil_arready = !S_AXI_RVALID;

    assign	arskd_addr = S_AXI_ARADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB];
    assign	S_AXI_ARREADY = axil_arready;
    assign	axil_read_ready = (S_AXI_ARVALID && S_AXI_ARREADY);

	initial	axil_read_valid = 1'b0;
	always @(posedge S_AXI_ACLK)
        if (i_reset)
            axil_read_valid <= 1'b0;
        else if (axil_read_ready)
            axil_read_valid <= 1'b1;
        else if (S_AXI_RREADY)
            axil_read_valid <= 1'b0;

	assign	S_AXI_RVALID = axil_read_valid;
	assign	S_AXI_RDATA  = axil_read_data;
	assign	S_AXI_RRESP = 2'b00;
	// }}}

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// AXI-lite register logic
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{

	// apply_wstrb(old_data, new_data, write_strobes)

    reg [31:0] reg_config;

	always @(posedge S_AXI_ACLK)
	if (i_reset)
	begin
        reg_config <= 0;
    end else if (axil_write_ready)
	begin
        if (awskd_addr == ADDR_CONFIG)     begin
            reg_config <= apply_wstrb(reg_config , wskd_data, wskd_strb);
        end

        if (awskd_addr >= ADDR_DATA_IN && awskd_addr < ADDR_DATA_IN + DATA_IN_WORDS) begin
            widx = awskd_addr - ADDR_DATA_IN;
            // pack 4 bytes per word
            if (wskd_strb[0]) data_in[widx*4+0] <= wskd_data[ 7: 0];
            if (wskd_strb[1]) data_in[widx*4+1] <= wskd_data[15: 8];
            if (wskd_strb[2]) data_in[widx*4+2] <= wskd_data[23:16];
            if (wskd_strb[3]) data_in[widx*4+3] <= wskd_data[31:24];
        end
	end

    // generate start_i pulse
    always @(posedge S_AXI_ACLK) begin
        if (i_reset)
            start_i <= 0;
        else if (axil_write_ready && awskd_addr == ADDR_CONFIG)
            start_i <= wskd_data[0] & wskd_strb[0];
        else
            start_i <= 0;
    end

	always @(posedge S_AXI_ACLK)
	if (OPT_LOWPOWER && !S_AXI_ARESETN)
		axil_read_data <= 0;
	else if (!S_AXI_RVALID || S_AXI_RREADY) begin
        axil_read_data <= 0;

        if (arskd_addr == ADDR_STATUS)
            axil_read_data <= {31'b0, inference_done};
        
        else if (arskd_addr == ADDR_CONFIG)
            axil_read_data <= reg_config;

        else if (arskd_addr >= ADDR_DATA_IN && arskd_addr < ADDR_DATA_IN + DATA_IN_WORDS) begin
            ridx = arskd_addr - ADDR_DATA_IN;
            axil_read_data <= { data_in[ridx*4+3], data_in[ridx*4+2],
                            data_in[ridx*4+1], data_in[ridx*4+0] };
        end

        else if (arskd_addr == ADDR_DATA_OUT)
            axil_read_data <= {data_out[3], data_out[2], data_out[1], data_out[0]};

		if (OPT_LOWPOWER && !axil_read_ready)
			axil_read_data <= 0;
	end

	function [C_AXI_DATA_WIDTH-1:0]	apply_wstrb;
		input	[C_AXI_DATA_WIDTH-1:0]		prior_data;
		input	[C_AXI_DATA_WIDTH-1:0]		new_data;
		input	[C_AXI_DATA_WIDTH/8-1:0]	wstrb;

		integer	k;
		for(k=0; k<C_AXI_DATA_WIDTH/8; k=k+1)
		begin
			apply_wstrb[k*8 +: 8]
				= wstrb[k] ? new_data[k*8 +: 8] : prior_data[k*8 +: 8];
		end
	endfunction
	// }}}

	// Make Verilator happy
	// {{{
	// Verilator lint_off UNUSED
	wire	unused;
	assign	unused = &{ 1'b0, S_AXI_AWPROT, S_AXI_ARPROT,
			S_AXI_ARADDR[ADDRLSB-1:0],
			S_AXI_AWADDR[ADDRLSB-1:0] };
	// Verilator lint_on  UNUSED
	// }}}

    cnn_controller cnn_inst (
        .clk(S_AXI_ACLK),
        .rst(S_AXI_ARESETN),
        .start(start_i),
        .data_in(data_in),
        .data_out(data_out),
        .valid_out(output_valid_o)
    );

    always @(posedge S_AXI_ACLK) begin
        if (i_reset)
            inference_done <= 0;
        else if (start_i)          // auto-clear when new inference starts
            inference_done <= 0;
        else if (output_valid_o)   // latch the pulse high
            inference_done <= 1;
    end

endmodule