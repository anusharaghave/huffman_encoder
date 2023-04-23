module tb_top;
	reg [23:0] data_in;
	reg [8:0] freq_in;
	wire [8:0] encoded_value;
	wire data_en;
	reg clk;
	reg reset;
	wire done;
	integer i;
	wire [11:0] io_out;
	reg [11:0] io_in;
	reg [71:0] expected_out;
	integer j;
	huff_encoder DUT(
		.clk(clk),
		.reset(reset),
		.io_in(io_in),
		.io_out(io_out)
	);
	initial begin
		clk = 0;
		reset = 1;
		data_in = "anm";
		{freq_in[6+:3], freq_in[3+:3], freq_in[0+:3]} = 9'h0da;
		expected_out[60+:12] = 9'b101100001;
		expected_out[48+:12] = 9'b100011011;
		expected_out[36+:12] = 9'b101101110;
		expected_out[24+:12] = 9'b100001000;
		expected_out[12+:12] = 9'b101101101;
		expected_out[0+:12] = 9'b100011010;
		#(5) reset = 0;
		#(30)
			;
		$finish;
	end
	always @(posedge clk)
		if (reset) begin
			i <= 'b0;
			io_in = 'b0;
		end
		else if (i < 3) begin
			io_in[11:0] = {1'b1, freq_in[(2 - i) * 3+:3], data_in[(2 - i) * 8+:8]};
			i <= i + 1'b1;
		end
		else if (io_out[8])
			$display("io_out:%b\n", io_out);
	always @(posedge clk)
		if (reset)
			j <= 'b0;
		else if (io_out[8]) begin
			j <= j + 1;
			if (j == 5)
				$finish;
		end
	always #(0.5) clk = ~clk;
	always @(*)
		;
endmodule
