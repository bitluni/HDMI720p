module julia_iteration(
    input [31:0] cx,
    input [31:0] cy,
	input [31:0] zx,
    input [31:0] zy,
    output reg [31:0] zx1,
    output reg [31:0] zy1,
	output reg res
);
	reg [31:0] r;
    reg [31:0] l;
    
    always @(*) begin
        //zx1 = (zx * zx - zy * zy) >> 12 + cx;
        zx1 = ((zx >> 5) * (zx >> 5) - (zy >> 5) * (zy >> 5)) >> 2 + cx;
        //zy1 = ((zx * zy) >> 11) + cy; 
        zy1 = ((zx * zy) >> 11) + cy;
        //r = zx1 * zx1 + zy1 * zy1;
        l = zx1 * zx1 + zy1 * zy1;
        //res = r >= (4 << 24);
        res = |l[31:26];
    end

endmodule

module julia(
	input [10:0] x,
	input [10:0] y,
	output reg [3:0] its
);
    reg res;
    reg [31:0] zx;
    reg [31:0] zy;
    reg [31:0] cx;
    reg [31:0] cy;
    //wire [31:0] zx1;
    //wire [31:0] zy1;
    reg [31:0] zx1;
    reg [31:0] zy1;
    reg [31:0] r;

	//julia_iteration it0(.cx(cx),.cy(cy),.zx(zx),.zy(zy),.zx1(zx1),.zy1(zy1),.res(res));

    always @(*) begin
		//iteration start
		zx = (x - 640) << 4;	//hardcoded for 1280 xres
		zy = (y - 360) << 4;	// ..and 720 yres
		cx = 0;    //TODO fix -0.74543f
		cy = 32'h1000; //assign fixed 1. but should animate from -1.5 tp 1.5
        zx1 = (zx * zx - zy * zy) >> 12 + cx;
        zy1 = ((zx * zy) >> 11) + cy; 
        r = zx1 * zx1 + zy1 * zy1;
		res = r >= (4 << 24);
        if(res) begin
			its = 0;
		end else begin
			its = 1;
		end
	end

endmodule
