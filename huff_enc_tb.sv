`define DEBUG 1

module tb_top;
  
 logic [0:`MAX_CHAR_COUNT-1][7:0] data_in;
 // logic [`MAX_CHAR_COUNT-1:0][3:0] data_in, string_input;
  logic [0:`MAX_CHAR_COUNT-1][1:0] freq_in;
  logic [`MAX_CHAR_COUNT*`MAX_CHAR_COUNT-1:0] encoded_value;
  logic data_en;
  logic clk, reset, done;
    integer i;
    logic [11:0] io_out, io_in;

    huff_encoder DUT(.clk(clk), .reset(reset), .io_in(io_in), .io_out(io_out));

    initial begin
        clk = 0;
        reset = 1;
        // data_in = "adity"; //working
        // data_in = "anusha";
        // data_in = "aabb";
        // data_in[0] = "~";   //7e    //no encoding for single character
        // data_in[1] = "|";   //7c
        // data_in[2] = "}";   //7d

        data_in[0] = "o";   //7e    //no encoding for single character
        data_in[1] = "n";   //7c
        data_in[2] = "m";   //7d

       // freq_in = {3'h2, 3'h1, 'h1};    //anu
        freq_in[0] = 3;
        freq_in[1] = 1;
        freq_in[2] = 2;
        // freq_in[3] = 1;
        // freq_in[4] = 1;
         #5 reset = 0;
        #70; //increase if you increase the string length
        $finish;
    end


    always_ff @(posedge clk) begin
        if( reset) begin
            i <= 'b0;
            io_in = 'b0;
        end
        else if (i< `MAX_CHAR_COUNT) begin
            io_in[11:0] = {1'b1, freq_in[i], data_in[i]}; 
            i <= i + 1'b1;
        end
        else if (io_out[8]) begin
          //   $display("io_out(mask):%b, io_out(value):%b\n", io_out[5:3], io_out[2:0]);
           $display("io_out:%b\n", io_out);
        end
    end

    always @(io_out[8]) begin
        if (io_out[8]) begin
            #8;
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
     //   $display("OUTPUT: character[%0d]:%s, encoded mask[%0d]:%b, encoded values[%0d]:%b\n", i, DUT.character[i], i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
$display("OUTPUT: encoded mask[%0d]:%b, encoded values[%0d]:%b\n", i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
        end

        $display("state:%p\n", DUT.state);

        

        end //`DEBUG

    end
endmodule 


