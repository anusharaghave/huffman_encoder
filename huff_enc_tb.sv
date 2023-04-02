

module tb_top;
  logic [7:0] data;
  logic [7:0] data_in[`MAX_STRING_LENGTH];
  logic [0:`MAX_STRING_LENGTH-1][7:0]  input_string;
  logic [`MAX_OUTPUT_SIZE-1:0] encoded_value[`MAX_STRING_LENGTH];
  integer char_length;  //FIXME later
  logic data_en;
  integer count, i;
  logic clk, reset;
 
    huff_encoder DUT(.clk(clk), .reset(reset), .data(data_in), .data_en(data_en), .encoded_value(encoded_value), .encoded_mask(), .character());

    initial begin
        clk = 0;
        reset = 0;
        input_string = 0;
        #5 reset = 1;
     
     
        input_string = "adity"; //working
        input_string = "anusha";
        input_string = "aabb";
        input_string = "aaaaa";     //no encoding for single character
        input_string = "aaf";     //working 
        input_string = "raghavendr";  //working 
        input_string = "anush";
        $display("input_string:%x\n", input_string);
        foreach(input_string[i]) begin
            data_in[i] = {input_string[i]};   //check in waves 
        end
        
        data_en = 1'b1;
        #100; //this should match the char count *20 (clock period)- else it will create x in data_in
        data_en = 1'b0;
        $monitor("Input data: data:%p\n", data);
        #150; //increase if you increase the string length
        $finish;
    end

    always begin
        #0.5 clk = ~clk;  //1MHz
    end

    always_comb begin
        
        //$display("Count:%d\n", DUT.count);
        $display("time:%t, Input data: data_en:%d, state:%0d\n", $time, data_en, DUT.state);
        $display("INPUT datain:%p\n", DUT.data);
        $display("Initial node:%p\n", DUT.initial_node);

        if (`DEBUG) begin
            for (int j=0; j < DUT.unique_char_count; j++) begin //level
                $display("in_huff_tree[%0d]:%p\n\n", j, DUT.in_huff_tree[j]);
                $display("out_huff_tree[%0d]:%p\n\n", j, DUT.out_huff_tree[j]);
        end
        
        for (int i=0; i< 2*DUT.unique_char_count; i++) begin
            $display("binary_tree:  huff_tree[%0d]:%p, encoded_mask_h[%0d]:%b, encoded_values_h[%0d]:%b\n", i, DUT.huff_tree[i], i, DUT.encoded_mask_h[i], i, DUT.encoded_value_h[i]);   
        end

        for (int i=0; i< DUT.unique_char_count; i++) begin
            $display("OUTPUT character:%s, encoded mask[%0d]:%b, encoded values[%0d]:%b, frequency[%0d]:%d\n", DUT.character[i], i, DUT.encoded_mask[i], i, DUT.encoded_value[i], i, DUT.frequency[i]);
        end
        end //`DEBUG

    end
endmodule 
