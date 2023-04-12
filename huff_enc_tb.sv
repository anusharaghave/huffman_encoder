`define DEBUG 1

module tb_top;
  
  logic [`MAX_STRING_LENGTH-1:0][7:0] data_in;
  logic [0:`MAX_STRING_LENGTH-1][2:0] freq_in;
  logic [`MAX_CHAR_COUNT*`MAX_CHAR_COUNT-1:0] encoded_value;
  logic data_en;
  logic clk, reset, done;
 
    huff_encoder DUT(.clk(clk), .reset(reset), .data_in(data_in), .freq_in(freq_in), .encoded_value(), .encoded_mask(), .character(), .done(done));

    initial begin
        clk = 0;
        reset = 0;
        data_in = 0;
       
     
     
        data_in = "adity"; //working
        data_in = "anusha";
        data_in = "aabb";
        data_in = "anu";     //no encoding for single character
     //   data_in = "aaf";     //working 
     //   data_in = "raghavendr";  //working 
     //   data_in = "anushaanua";    //working only if you maintain the max unique character length to be within limits
     //   data_in = "~{~zz";


       // freq_in = {3'h2, 3'h1, 'h1};    //anu
        freq_in[0] = 1;
        freq_in[1] = 3;
        freq_in[2] = 2;

         #5 reset = 1;
        #15; //increase if you increase the string length
        $finish;
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
        $display("INPUT freqin0:%x, freqin1:%x, freqin2:%x\n", DUT.freq_in[0], DUT.freq_in[1], DUT.freq_in[2]);
        $display("Initial node:%p\n", DUT.initial_node);

        if (`DEBUG) begin
       
                 $display("in_huff_tree:%p\n\n",  DUT.in_huff_tree);
                 $display("out_huff_tree:%p\n\n", DUT.out_huff_tree);
        
        
        for (int i=0; i< 2*`MAX_CHAR_COUNT; i++) begin
            $display("binary_tree:  huff_tree[%0d]:%p, encoded_values_h[%0d]:%b\n", i, DUT.huff_tree[i],  i, DUT.encoded_value_h[i]);   
        end

        for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
        $display("OUTPUT character:%s, encoded mask[%0d]:%b, encoded values[%0d]:%b\n", DUT.character[i], i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
        end

 
        end //`DEBUG

    end
endmodule 
