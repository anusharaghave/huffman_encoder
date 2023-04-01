`default_nettype wire
module huff_encoder (
	clk,
	reset,
	data,
	data_en,
	encoded_value,
	encoded_mask,
	character
);
	input wire clk;
	input wire reset;
	input wire [34:0] data;
	input wire data_en;
	output reg [24:0] encoded_value;
	output reg [24:0] encoded_mask;
	output reg [34:0] character;
	integer count;
	integer unique_char_count;
	reg [128:0] node [0:4];
	wire [644:0] initial_node;
	reg [34:0] data_in;
	reg [2:0] state;
	integer index;
	integer ll;
	reg [192:0] huff_tree [0:9];
	reg [644:0] in_huff_tree [0:4];
	reg [128:0] out_huff_tree [0:4][0:5];
	wire [128:0] merged_nodes_list;
	wire [644:0] out_huff_tree_s;
	reg [4:0] encoded_mask_h [0:9];
	reg [4:0] encoded_value_h [0:9];
	reg signed [31:0] j;
	reg signed [31:0] itr;
	wire data_collect;
	wire sort_done;
	freq_calc freq_calc_ins(
		.clk(clk),
		.reset(reset),
		.data_in(data_in),
		.data_en(data_en),
		.node(initial_node),
		.count(unique_char_count)
	);
	node_sorter node_sorter_ins(
		.clk(clk),
		.count(unique_char_count),
		.node(in_huff_tree[ll][0+:645]),
		.output_node(out_huff_tree_s[0+:645])
	);
	merge_nodes merge_nodes_ins(
		.min_node(out_huff_tree_s[516+:129]),
		.second_min_node(out_huff_tree_s[387+:129]),
		.merged_node(merged_nodes_list)
	);
	always @(posedge clk) begin : huffman_enc
		if (~reset)
			state = 3'b000;
		case (state)
			3'b000: begin
				ll = 0;
				begin : sv2v_autoblock_1
					reg signed [31:0] i;
					for (i = 0; i < 10; i = i + 1)
						begin
							encoded_value[(4 - i) * 5+:5] = 'bz;
							encoded_mask[(4 - i) * 5+:5] = 'b0;
							encoded_value_h[i] = 'bz;
							encoded_mask_h[i] = 'b0;
							huff_tree[i][192-:32] = 'bz;
							huff_tree[i][160-:32] = 0;
							huff_tree[i][128] = 1'b0;
							huff_tree[i][63-:32] = 'b0;
							huff_tree[i][127-:32] = 'b0;
							huff_tree[i][95-:32] = 'b0;
							huff_tree[i][31-:32] = 'b0;
						end
				end
				begin : sv2v_autoblock_2
					reg signed [31:0] j;
					for (j = 0; j < 5; j = j + 1)
						begin
							node[j][128-:32] = 0;
							node[j][96-:32] = 0;
							node[j][63-:32] = 0;
							node[j][31-:32] = 0;
							node[j][64] = 1'b1;
						end
				end
				state <= 3'b001;
			end
			3'b001: begin
				data_in = data;
				state <= 3'b010;
			end
			3'b010: begin
				begin : sv2v_autoblock_3
					reg signed [31:0] j;
					for (j = 0; j < 5; j = j + 1)
						node[j] = initial_node[(4 - j) * 129+:129];
				end
				count = unique_char_count;
				begin : sv2v_autoblock_4
					reg signed [31:0] i;
					for (i = 0; i < unique_char_count; i = i + 1)
						in_huff_tree[0][(4 - i) * 129+:129] = initial_node[(4 - i) * 129+:129];
				end
				state <= 3'b011;
			end
			3'b011: state <= 3'b100;
			3'b100: begin
				begin : sv2v_autoblock_5
					reg signed [31:0] i;
					for (i = 0; i < unique_char_count; i = i + 1)
						out_huff_tree[ll][i] = out_huff_tree_s[(4 - i) * 129+:129];
				end
				in_huff_tree[ll + 1][0+:645] = {merged_nodes_list, out_huff_tree[ll][2:5]};
				count = count - 1;
				if (count == 0) begin
					state <= 3'b101;
					ll = 0;
				end
				else begin
					state <= 3'b011;
					ll = ll + 1;
				end
			end
			3'b101: begin
				begin : sv2v_autoblock_6
					reg signed [31:0] l;
					for (l = 0; l < unique_char_count; l = l + 1)
						begin
							j = (unique_char_count - 1) - l;
							if (j != 0) begin
								huff_tree[2 * j][192-:32] = out_huff_tree[l][0][128-:32];
								huff_tree[(2 * j) + 1][192-:32] = out_huff_tree[l][1][128-:32];
								huff_tree[2 * j][128] = out_huff_tree[l][0][64];
								huff_tree[(2 * j) + 1][128] = out_huff_tree[l][1][64];
								huff_tree[2 * j][160-:32] = out_huff_tree[l][0][96-:32];
								huff_tree[(2 * j) + 1][160-:32] = out_huff_tree[l][1][96-:32];
								huff_tree[2 * j][127-:32] = out_huff_tree[l][0][63-:32];
								huff_tree[(2 * j) + 1][127-:32] = out_huff_tree[l][1][63-:32];
								huff_tree[2 * j][95-:32] = out_huff_tree[l][0][31-:32];
								huff_tree[(2 * j) + 1][95-:32] = out_huff_tree[l][1][31-:32];
							end
							else if (j == 0) begin
								huff_tree[(2 * j) + 1][192-:32] = out_huff_tree[l][0][128-:32];
								huff_tree[(2 * j) + 1][128] = out_huff_tree[l][0][64];
								huff_tree[(2 * j) + 1][160-:32] = out_huff_tree[l][0][96-:32];
								huff_tree[(2 * j) + 1][127-:32] = out_huff_tree[l][0][63-:32];
								huff_tree[(2 * j) + 1][95-:32] = out_huff_tree[l][0][31-:32];
							end
						end
				end
				begin : sv2v_autoblock_7
					reg signed [31:0] l;
					for (l = (2 * unique_char_count) - 1; l > 1; l = l - 1)
						begin : sv2v_autoblock_8
							reg signed [31:0] n;
							for (n = 1; n < (2 * unique_char_count); n = n + 1)
								if ((huff_tree[n][127-:32] == huff_tree[l][192-:32]) | (huff_tree[n][95-:32] == huff_tree[l][192-:32]))
									huff_tree[l][63-:32] = n;
						end
				end
				begin : sv2v_autoblock_9
					reg signed [31:0] m;
					for (m = 1; m < 10; m = m + 1)
						if (huff_tree[m][128] != 1) begin : sv2v_autoblock_10
							reg signed [31:0] n;
							for (n = 2; n < 10; n = n + 1)
								begin
									if (huff_tree[n][192-:32] == huff_tree[m][127-:32])
										huff_tree[n][31-:32] = huff_tree[m][31-:32] + 1;
									if (huff_tree[n][192-:32] == huff_tree[m][95-:32])
										huff_tree[n][31-:32] = huff_tree[m][31-:32] + 1;
								end
						end
				end
				state <= 3'b110;
			end
			3'b110: begin
				begin : sv2v_autoblock_11
					reg signed [31:0] n;
					for (n = 2; n < (2 * unique_char_count); n = n + 1)
						begin
							encoded_mask_h[n] = (1'b1 << huff_tree[n][31-:32]) - 1;
							if (huff_tree[n][63-:32] != 1)
								encoded_value_h[n] = ((n % 2) == 0 ? encoded_value_h[huff_tree[n][63-:32]] << 1'b1 : (encoded_value_h[huff_tree[n][63-:32]] << 1'b1) | 1'b1);
							else if (huff_tree[n][63-:32] == 1)
								encoded_value_h[n][0] = ((n % 2) == 0 ? 1'b0 : 1'b1);
						end
				end
				state <= 3'b111;
			end
			3'b111: begin
				itr = 0;
				begin : sv2v_autoblock_12
					reg signed [31:0] n;
					for (n = 0; n < (2 * unique_char_count); n = n + 1)
						begin
							if (huff_tree[n][128] == 1) begin
								encoded_mask[(4 - itr) * 5+:5] = encoded_mask_h[n];
								encoded_value[(4 - itr) * 5+:5] = encoded_value_h[n];
								character[(4 - itr) * 7+:7] = huff_tree[n][192-:32];
								itr = itr + 1;
							end
							$display("Output sent\n");
						end
				end
				if (data_en)
					state <= 3'b000;
				else
					state <= 3'b111;
			end
			default: state <= 3'b000;
		endcase
	end
endmodule
module freq_calc (
	clk,
	reset,
	data_in,
	data_en,
	node,
	count
);
	input wire clk;
	input wire reset;
	input wire [34:0] data_in;
	input wire data_en;
	output reg [644:0] node;
	output integer count;
	integer cnt;
	integer index;
	reg node_create;
	reg matched;
	reg break1;
	integer ctr;
	always @(posedge clk)
		if (~reset) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 5; i = i + 1)
				begin
					node[((4 - i) * 129) + 128-:32] = 'b0;
					node[((4 - i) * 129) + 96-:32] = 'b0;
					node[((4 - i) * 129) + 63-:32] = 'b0;
					node[((4 - i) * 129) + 31-:32] = 'b0;
					node[((4 - i) * 129) + 64] = 1'b0;
				end
		end
		else if (data_en) begin
			node_create = 1;
			ctr = 0;
			begin : sv2v_autoblock_2
				integer i;
				for (i = 0; i <= 4; i = i + 1)
					begin
						matched = 0;
						break1 = 0;
						cnt = 1'b1;
						index = ctr;
						node[((4 - index) * 129) + 64] = 1'b1;
						begin : sv2v_autoblock_3
							reg signed [31:0] j;
							for (j = 0; j < i; j = j + 1)
								if (break1 == 0)
									if (data_in[(4 - i) * 7+:7] == node[((4 - j) * 129) + 128-:32]) begin
										cnt = node[((4 - j) * 129) + 96-:32] + 1;
										index = j;
										matched = 1;
										break1 = 1;
									end
									else begin
										matched = 0;
										break1 = 0;
									end
						end
						if (i == 0)
							ctr = ctr + 1;
						else
							ctr = (matched ? ctr : ctr + 1);
						node[((4 - index) * 129) + 128-:32] = data_in[(4 - i) * 7+:7];
						node[((4 - index) * 129) + 96-:32] = cnt;
					end
			end
			node_create = 1'b1;
		end
	always @(*)
		if (node_create) begin
			count = 0;
			begin : sv2v_autoblock_4
				reg signed [31:0] i;
				for (i = 0; i < 5; i = i + 1)
					if (node[((4 - i) * 129) + 128-:32] != 0)
						count = count + 1;
			end
		end
endmodule
module node_sorter (
	clk,
	count,
	node,
	output_node
);
	input wire clk;
	input integer count;
	input wire [644:0] node;
	output reg [644:0] output_node;
	reg [128:0] temp_node;
	always @(posedge clk) begin
		temp_node[128-:32] = 1'sb0;
		temp_node[96-:32] = 1'sb0;
		temp_node[64] = 1'sb0;
		temp_node[63-:32] = 1'sb0;
		temp_node[31-:32] = 1'sb0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 5; i = i + 1)
				output_node = node;
		end
		begin : sv2v_autoblock_2
			reg signed [31:0] j;
			for (j = 0; j < 4; j = j + 1)
				begin : sv2v_autoblock_3
					reg signed [31:0] k;
					for (k = j + 1; k < 4; k = k + 1)
						if (output_node[((4 - j) * 129) + 96-:32] == output_node[((4 - k) * 129) + 96-:32]) begin
							if (output_node[((4 - j) * 129) + 128-:32] > output_node[((4 - k) * 129) + 128-:32]) begin
								temp_node = output_node[(4 - j) * 129+:129];
								output_node[(4 - j) * 129+:129] = output_node[(4 - k) * 129+:129];
								output_node[(4 - k) * 129+:129] = temp_node;
							end
						end
						else if (output_node[((4 - j) * 129) + 96-:32] > output_node[((4 - k) * 129) + 96-:32]) begin
							temp_node = output_node[(4 - j) * 129+:129];
							output_node[(4 - j) * 129+:129] = output_node[(4 - k) * 129+:129];
							output_node[(4 - k) * 129+:129] = temp_node;
						end
				end
		end
	end
endmodule
module merge_nodes (
	min_node,
	second_min_node,
	merged_node
);
	input wire [128:0] min_node;
	input wire [128:0] second_min_node;
	output reg [128:0] merged_node;
	always @(*) begin
		merged_node[128-:32] = {min_node[128-:32] + second_min_node[128-:32]};
		merged_node[96-:32] = min_node[96-:32] + second_min_node[96-:32];
		merged_node[63-:32] = min_node[128-:32];
		merged_node[31-:32] = second_min_node[128-:32];
		merged_node[64] = 1'b0;
	end
endmodule
