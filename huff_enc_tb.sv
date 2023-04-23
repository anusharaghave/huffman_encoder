`define DEBUG 0
`define MAX_CHAR_COUNT 3    //fixed as increasing to 5 increases gates by 4 times
`define BIT_WIDTH 2


module tb_top;
  
 logic [0:`MAX_CHAR_COUNT-1][7:0] data_in;
  logic [0:`MAX_CHAR_COUNT-1][2:0] freq_in;
  logic [`MAX_CHAR_COUNT*`MAX_CHAR_COUNT-1:0] encoded_value;
  logic data_en;
  logic clk, reset, done;
  integer i;
  logic [11:0] io_out, io_in;
  logic [0:2*`MAX_CHAR_COUNT-1][11:0] expected_out;
  integer j;

    huff_encoder DUT(.clk(clk), .reset(reset), .io_in(io_in), .io_out(io_out));

    initial begin
        clk = 0;
        reset = 1;
        // data_in[0] = "~";   //7e    //no encoding for single character
        // data_in[1] = "|";   //7c
        // data_in[2] = "}";   //7d

        // data_in[0] = "a";   //61    //no encoding for single character
        // data_in[1] = "n";   //6e
        // data_in[2] = "m";   //6d
     

        data_in = "anm";

     
       {freq_in[0], freq_in[1], freq_in[2]} = {3'h4,3'h2,3'h2};

        expected_out[0] = 9'b101100001; //a
        expected_out[1] = 9'b100001001;
        expected_out[2] = 9'b101101110; //n
        expected_out[3] = 9'b100011000;
        expected_out[4] = 9'b101101101; //m
        expected_out[5] = 9'b100011001;


         #5 reset = 0;
        #30; //increase if you increase the string length
        $finish;
    end


    always_ff @(posedge clk) begin
        if( reset) begin
            i <= 'b0;
            io_in = 'b0;
        end
        else if ((i< `MAX_CHAR_COUNT)) begin
            io_in[11:0] = {1'b1, freq_in[i], data_in[i]}; 
            i <= i + 1'b1;    
        end
    end

    always @(posedge clk) begin
         if( reset) begin
            j <= 'b0;
        end
        else if (io_out[8]) begin
            //assert (io_out == 9'b101100001) 
            $display("io_out:%b, expected_out=%b\n", io_out, expected_out[j]);
            assert (io_out[8:0] == expected_out[j]) 
            else   $display("Failed for io_out:%b\n", io_out);
            j <= j +1;
            if (j == 2*`MAX_CHAR_COUNT-1) begin
            $finish;
            end
        end
    end

    

    always begin
        #0.5 clk = ~clk;  //1MHz
    end

    always_comb begin
        if (`DEBUG) begin
        //$display("Count:%d\n", DUT.count);
        $display("time:%t, Input data: data_en:%d, state:%0d\n", $time, data_en, DUT.state);
        $display("INPUT datain:%x\n", DUT.data_in);
        $display("INPUT freqin0:%x, freqin1:%x, freqin2:%x\n", DUT.freq_in[0], DUT.freq_in[1], DUT.freq_in[2]);
        $display("Initial node:%p\n", DUT.initial_node);

        
       
                 $display("in_huff_tree:%p\n\n",  DUT.in_huff_tree);
                 $display("out_huff_tree:%p\n\n", DUT.out_huff_tree);
        
        
        for (int i=0; i< 2*`MAX_CHAR_COUNT; i++) begin
            $display("binary_tree:  huff_tree[%0d]:%p, encoded_values_h[%0d]:%b\n", i, DUT.huff_tree[i],  i, DUT.encoded_value_h[i]);   
        end

        for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
        $display("OUTPUT: character[%0d]:%s, encoded mask[%0d]:%b, encoded values[%0d]:%b\n", i, {3'b011,DUT.character[i]}, i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
    //$display("OUTPUT: encoded mask[%0d]:%b, encoded values[%0d]:%b\n",  i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
        end

        $display("state:%p\n", DUT.state);

        

        end //`DEBUG

        if (io_out[8]) begin
        for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
            $display("OUTPUT: character[%0d]:%s, encoded mask[%0d]:%b, encoded values[%0d]:%b\n", i, {3'b011,DUT.character[i]}, i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
        end
        end


    end
endmodule 


