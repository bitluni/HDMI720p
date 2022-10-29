`timescale 1ns/1ps

module HDMI720p(
  input clk,
  input resetn,

  output       tmds_clk_n,
  output       tmds_clk_p,
  output [2:0] tmds_d_n,
  output [2:0] tmds_d_p

);

wire sys_resetn;

wire clk_p;
wire clk_p5;
wire pll_lock;

Gowin_rPLL u_pll (
  .clkin(clk),
  .clkout(clk_p5),
  .lock(pll_lock)
);

Gowin_CLKDIV u_div_5 (
    .clkout(clk_p),
    .hclkin(clk_p5),
    .resetn(pll_lock)
);

Reset_Sync u_Reset_Sync (
  .resetn(sys_resetn),
  .ext_reset(resetn & pll_lock),
  .clk(clk_p)
); 

svo_hdmi_top u_hdmi (
	.clk(clk_p),
	.resetn(sys_resetn),

	// video clocks
	.clk_pixel(clk_p),
	.clk_5x_pixel(clk_p5),
	.locked(pll_lock),

	// output signals
	.tmds_clk_n(tmds_clk_n),
	.tmds_clk_p(tmds_clk_p),
	.tmds_d_n(tmds_d_n),
	.tmds_d_p(tmds_d_p)
);

endmodule
