`define DEBUG 1

module tb_top;
  logic [7:0] data;
  logic [0:`MAX_STRING_LENGTH-1][7:0] data_in;
  logic [0:`MAX_STRING_LENGTH-1][7:0]  input_string;
  //logic [`MAX_CHAR_COUNT-1:0] encoded_value[`MAX_CHAR_COUNT];
  logic [`MAX_CHAR_COUNT*`MAX_CHAR_COUNT-1:0] encoded_value;
  integer char_length;  //FIXME later
  logic data_en;
  integer count, i;
  logic clk, reset, done;
 
    huff_encoder DUT(.clk(clk), .reset(reset), .data_in(data_in), .data_en(data_en), .encoded_value(), .encoded_mask(), .character(), .done(done));

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
        input_string = "anushaanua";    //working only if you maintain the max unique character length to be within limits
        data_in = "~{}|z";
      //  data_in = "aae e";
     //   data_in = "anushaanua";
        /*
        $display("input_string:%x\n", input_string);
        foreach(input_string[i]) begin
            data_in[i] = {input_string[i]};   //check in waves 
        end
        */

        data_en = 1'b1;
        #100; //this should match the char count *20 (clock period)- else it will create x in data_in
        data_en = 1'b0;
        //$monitor("Input data: data:%p\n", data);
        #20; //increase if you increase the string length
    end

    always @(done) begin
        if (done ==1) begin
            #1;
            $finish;
        end
    end

    always begin
        #0.5 clk = ~clk;  //1MHz
    end

    always_comb begin
        
        //$display("Count:%d\n", DUT.count);
        $display("time:%t, Input data: data_en:%d, state:%0d\n", $time, data_en, DUT.state);
        $display("INPUT datain:%x\n", DUT.data_in);
        $display("Initial node:%p\n", DUT.initial_node);

        if (`DEBUG && done) begin
        //     for (int j=0; j < DUT.unique_char_count; j++) begin //level
                 $display("in_huff_tree:%p\n\n",  DUT.in_huff_tree);
                 $display("out_huff_tree:%p\n\n", DUT.out_huff_tree);
        // end
        
        for (int i=0; i< 2*DUT.unique_char_count; i++) begin
            $display("binary_tree:  huff_tree[%0d]:%p, encoded_values_h[%0d]:%b\n", i, DUT.huff_tree[i],  i, DUT.encoded_value_h[i]);   
        end

        for (int i=0; i< DUT.unique_char_count; i++) begin
        $display("OUTPUT character:%s, encoded mask[%0d]:%b, encoded values[%0d]:%b\n", DUT.character[i], i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
       // $display("OUTPUT character:%s, encoded mask[%0d]:%b, encoded values:%b, frequency[%0d]:%d\n", DUT.character[i], i, DUT.encoded_mask[i], DUT.encoded_value, i, DUT.frequency[i]);
        end

    /*
        for (int i=0; i< DUT.unique_char_count; i++) begin
        $display("OUTPUT character:%s", DUT.character[i]);
        $display("FINAL: encoded_value[%0d]=%b\n", i, DUT.encoded_value[i]);
        end
       // $display("FINAL: encoded_out=%b\n", encoded_value);
      */
        end //`DEBUG

    end
endmodule 
