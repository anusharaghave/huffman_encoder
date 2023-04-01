

module tb_top;
  logic [6:0] data;
  logic [6:0] data_in[`MAX_STRING_LENGTH];
   logic [`MAX_OUTPUT_SIZE-1:0] encoded_value[`MAX_STRING_LENGTH];
  integer char_length;  //FIXME later
  logic data_en;
  node_t node[`MAX_STRING_LENGTH];
  integer count, i, cycle;
  logic clk, reset;
  string input_string;

//Instantiate the module that you need to verify
 //  freq_calc DUT(.data_in(data_in), .data_en(data_en), .node(node), .count(count)); 
 //  comparator DUT1(.node(DUT.node), .min_node(), .second_min_node());
 //  node_sorter DUT2(.node(DUT.node), .output_node());
 //   binary_tree_node DUT3(.count(count), .input_node(DUT.node), .encoded_value(), .encoded_mask(), .character());
    huff_encoder DUT(.clk(clk), .reset(reset), .data(data_in), .data_en(data_en), .encoded_value(encoded_value), .encoded_mask(), .character());

    initial begin
        clk = 0;
        reset = 0;
    //    cycle = 0;
        #5 reset = 1;
      //  data_in = '{"a","e"," ","a","a"};
      //    input_string = "anusha is a good gir"; //should be able to read an input file with many strings
      //  input_string = "aftergraduation";
     //   input_string = "ae aa"; //working
       // input_string = "after"; //working
      //  input_string = "aaaaa";     //no encoding for single character
        input_string = "aft";     //working  
        foreach(input_string[i]) begin
            data_in[i] = {input_string[i]};   //check in waves 
        end
        data_en = 1'b1;
        #100; //this should match the char count *20 (clock period)- else it will create x in data_in
        data_en = 1'b0;
        $monitor("Input data: data:%p\n", data);
   //SEE LATER: #100 data_en = 1'b0;
   #25;
   $finish;
    end

    always begin
        #1 clk = ~clk;
    end

    //always_ff @(posedge clk) cycle = cycle + 1;


    always_comb begin
        
       $display("Count:%d\n", DUT.count);
       $display("time:%t, Input data: data_in:%d, data_en:%d, cycle:%d, state:%0d\n", $time, data, data_en, cycle, DUT.state);
    //   $display("comparator results: node:%p, count=%d, min_node=%p, second_min_node=%p\n", DUT1.node, DUT1.count, DUT1.min_node, DUT1.second_min_node);
    //   $display("sorter results: input_node:%p,\n output_node:%p\n", DUT2.node, DUT2.output_node);
    //   $display("huffman encoder: INPUT: created node :%p\n", DUT.node);
        $display("INPUT datain:%p\n", DUT.data_in);
        $display("Initial node:%p\n", DUT.initial_node);
        $display("node:%p\n", DUT.node);

        if (`DEBUG) begin
    for (int j=0; j < DUT.unique_char_count; j++) begin //level
        $display("in_huff_tree[%0d]:%p\n\n", j, DUT.in_huff_tree[j]);
        $display("\n");
        $display("out_huff_tree[%0d]:%p\n\n", j, DUT.out_huff_tree[j]);
    end
        end
       for (int i=0; i< 2*DUT.unique_char_count; i++) begin
      //  if (DUT.huff_tree[i].ascii_char != 1'bz) begin
            $display("binary_tree:  huff_tree[%0d]:%p, encoded_mask_h[%0d]:%b, encoded_values_h[%0d]:%b\n", i, DUT.huff_tree[i], i, DUT.encoded_mask_h[i], i, DUT.encoded_value_h[i]);   
      //  end
       end
        for (int i=0; i< DUT.unique_char_count; i++) begin
       $display("OUTPUT character:%s, encoded mask[%0d]:%b, encoded values[%0d]:%b\n", DUT.character[i], i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
        end
    end
endmodule 
