module comparator (
	clk,
	reset,
	compare_start,
	num_of_bits,
	A,
	B,
	is_compare_done,
	is_equal,
	is_greater,
	is_less_than
);
	input wire clk;
	input wire reset;
	input wire compare_start;
	input integer num_of_bits;
	input wire [8:0] A;
	input wire [8:0] B;
	output reg is_compare_done;
	output reg is_equal;
	output reg is_greater;
	output reg is_less_than;
	reg break1;
	reg break2;
	integer m;
	always @(posedge clk)
		if (reset) begin
			break1 <= 1'b1;
			break2 <= 1'b1;
			is_compare_done <= 1'b0;
			is_greater <= 'b0;
			is_equal <= 'b0;
			is_less_than <= 'b0;
			m <= 'b0;
		end
		else if (break1 && compare_start) begin
			m <= num_of_bits - 1'b1;
			is_compare_done <= 1'b0;
			break2 <= 1'b0;
			break1 <= break2;
		end
		else if (!is_compare_done) begin
			if (A[m] > B[m]) begin
				is_greater <= 1'b1;
				is_compare_done <= 1'b1;
			end
			else if (A[m] < B[m]) begin
				is_less_than <= 1'b1;
				is_compare_done <= 1'b1;
			end
			else if ((A[m] == B[m]) && (m != 'b0))
				is_compare_done <= 1'b0;
			else begin
				is_equal <= 1'b1;
				is_compare_done <= 1'b1;
			end
			m <= m - 1'b1;
		end
endmodule
