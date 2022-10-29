`timescale 1ns / 1ps

module pixels 
#(
    SVO_HOR_PIXELS = 1280,
    SVO_VER_PIXELS = 720
)

(
	input clk, resetn,
	// output stream
	//   tuser[0] ... start of frame
	output reg out_axis_tvalid,
	input out_axis_tready,
	output reg [23:0] out_axis_tdata,
	output reg [0:0] out_axis_tuser
);

    localparam SVO_XYBITS = 11;

	reg [SVO_XYBITS-1:0] x;
	reg [SVO_XYBITS-1:0] y;

	reg [7:0] r;
	reg [7:0] g;
	reg [7:0] b;
    //wire [3:0] its;

    reg [3:0] its;
    reg res;
    reg [31:0] zx;
    reg [31:0] zy;
    reg [31:0] cx;
    reg [31:0] cy;
    //wire [31:0] zx1;
    //wire [31:0] zy1;
    reg [31:0] zx1 = 0;
    reg [31:0] zy1 = 0;
    reg [31:0] l;
    reg [31:0] l1;

    reg res1;

//julia julia(.x(x), .y(y), .its(its));

	always @(posedge clk) begin
		if (!resetn) begin
			x <= 0;
			y <= 0;
			out_axis_tvalid <= 0;
			out_axis_tdata <= 0;
			out_axis_tuser <= 0;
		end else
		if (!out_axis_tvalid || out_axis_tready) begin


//************** pixel magic at (x, y)


        zx = (x - 640) << 4;	//hardcoded for 1280 xres
		zy = (y - 360) << 4;	// ..and 720 yres
		cx = 0;    //TODO fix -0.74543f
		cy = 32'h1000; //assign fixed 1. but should animate from -1.5 tp 1.5
        l = zx * zx + zy * zy;
        zx1 = (zx[31:6] * zx[31:6] - zy[31:6] * zy[31:6]) + cx;
        zy1 = ((zx * zy) >> 11) + cy; 
        if(|l[31:26]) begin
            r = 0;
            g = 0;
            b = 255;
		end else begin

//            zx1 = (zx[31:6] * zx[31:6] - zy[31:6] * zy[31:6]) + cx;
//            zy1 = ((zx * zy) >> 11) + cy; 
            l1 = zx1 * zx1 + zy1 * zy1;
            if(|l1[31:26]) begin
                r = 255;
                g = 0;
                b = 0;
            end else begin
                r = 0;
                g = 0;
                b = 0;
            end
		end

/*            if(its == 0) begin
                r = x[7:0];
                g = 0;
                b = y[7:0];
            end else begin
                r = 0;
                g = 0;
                b = 0;
            end*/


//*******************
			out_axis_tvalid <= 1;
			out_axis_tdata <= {b, g, r};
			out_axis_tuser[0] <= !x && !y;

			if (x == SVO_HOR_PIXELS-1) begin
				x <= 0;
				if (y == SVO_VER_PIXELS-1) begin
					y <= 0;
				end else begin
					y <= y + 1'd1;
				end
			end else begin
				x <= x + 1'd1;
			end
		end
	end
endmodule
