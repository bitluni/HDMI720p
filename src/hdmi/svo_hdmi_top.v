/* modified by bitluni 2022*/

/*
 *  SVO - Simple Video Out FPGA Core
 *
 *  Copyright (C) 2014  Clifford Wolf <clifford@clifford.at>
 *  
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`timescale 1ns / 1ps

module svo_hdmi_top 
#(
    SVO_HOR_PIXELS = 1280,
    SVO_VER_PIXELS = 720,
    SVO_VER_FRONT_PORCH = 3,
    SVO_VER_SYNC = 5,
    SVO_VER_BACK_PORCH = 20,
    SVO_HOR_FRONT_PORCH = 64,
    SVO_HOR_SYNC = 128,
    SVO_HOR_BACK_PORCH = 192
)
(
	input clk,
	input resetn,

	// video clocks
	input clk_pixel,
	input clk_5x_pixel,
	input locked,

	// output signals
	output       tmds_clk_n,
	output       tmds_clk_p,
	output [2:0] tmds_d_n,
	output [2:0] tmds_d_p
);

	wire vdma_tvalid;
	wire vdma_tready;
	wire [23:0] vdma_tdata;
	wire [0:0] vdma_tuser;

	wire video_tvalid;
	wire video_tready;
	wire [23:0] video_tdata;
	wire [0:0] video_tuser;


	wire video_enc_tvalid, video_enc_tready;
	wire [23:0] video_enc_tdata;
	wire [3:0] video_enc_tuser;

	wire [2:0] tmds_d;
	wire [2:0] tmds_serdes_shift1;
	wire [2:0] tmds_serdes_shift2;
	wire [2:0] tmds_d0, tmds_d1, tmds_d2, tmds_d3, tmds_d4;
	wire [2:0] tmds_d5, tmds_d6, tmds_d7, tmds_d8, tmds_d9;

	reg [3:0] locked_clk_q;
	reg [3:0] resetn_clk_pixel_q;

	always @(posedge clk)
		locked_clk_q <= {locked_clk_q[2:0], locked};

	always @(posedge clk_pixel)
		resetn_clk_pixel_q <= {resetn_clk_pixel_q[2:0], resetn};

	wire clk_resetn = resetn && locked_clk_q[3];
	wire clk_pixel_resetn = locked && resetn_clk_pixel_q[3];

	pixels pixels (
		.clk(clk_pixel),
		.resetn(resetn),
        
        .out_axis_tvalid(video_tvalid),
		.out_axis_tready(video_tready),
		.out_axis_tdata(video_tdata),
		.out_axis_tuser(video_tuser)
	);

	svo_enc svo_enc (
		.clk(clk_pixel),
		.resetn(clk_pixel_resetn),

		.in_axis_tvalid(video_tvalid),
		.in_axis_tready(video_tready),
		.in_axis_tdata(video_tdata),
		.in_axis_tuser(video_tuser),

		.out_axis_tvalid(video_enc_tvalid),
		.out_axis_tready(video_enc_tready),
		.out_axis_tdata(video_enc_tdata),
		.out_axis_tuser(video_enc_tuser)
	);

	assign video_enc_tready = 1;

	svo_tmds svo_tmds_0 (
		.clk(clk_pixel),
		.resetn(clk_pixel_resetn),
		.de(!video_enc_tuser[3]),
		.ctrl(video_enc_tuser[2:1]),
		.din(video_enc_tdata[23:16]),
		.dout({tmds_d9[0], tmds_d8[0], tmds_d7[0], tmds_d6[0], tmds_d5[0],
		       tmds_d4[0], tmds_d3[0], tmds_d2[0], tmds_d1[0], tmds_d0[0]})
	);

	svo_tmds svo_tmds_1 (
		.clk(clk_pixel),
		.resetn(clk_pixel_resetn),
		.de(!video_enc_tuser[3]),
		.ctrl(2'b0),
		.din(video_enc_tdata[15:8]),
		.dout({tmds_d9[1], tmds_d8[1], tmds_d7[1], tmds_d6[1], tmds_d5[1],
		       tmds_d4[1], tmds_d3[1], tmds_d2[1], tmds_d1[1], tmds_d0[1]})
	);

	svo_tmds svo_tmds_2 (
		.clk(clk_pixel),
		.resetn(clk_pixel_resetn),
		.de(!video_enc_tuser[3]),
		.ctrl(2'b0),
		.din(video_enc_tdata[7:0]),
		.dout({tmds_d9[2], tmds_d8[2], tmds_d7[2], tmds_d6[2], tmds_d5[2],
		       tmds_d4[2], tmds_d3[2], tmds_d2[2], tmds_d1[2], tmds_d0[2]})
	);
    
	OSER10 tmds_serdes [2:0] (
		.Q(tmds_d),
		.D0(tmds_d0),
		.D1(tmds_d1),
		.D2(tmds_d2),
		.D3(tmds_d3),
		.D4(tmds_d4),
		.D5(tmds_d5),
		.D6(tmds_d6),
		.D7(tmds_d7),
		.D8(tmds_d8),
		.D9(tmds_d9),
		.PCLK(clk_pixel),
		.FCLK(clk_5x_pixel),
		.RESET(~clk_pixel_resetn)
	);
	
	ELVDS_OBUF tmds_bufds [3:0] (
		.I({clk_pixel, tmds_d}),
		.O({tmds_clk_p, tmds_d_p}),
		.OB({tmds_clk_n, tmds_d_n})
	);

endmodule
