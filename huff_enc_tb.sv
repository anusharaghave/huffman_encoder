`define DEBUG 0
`define MAX_CHAR_COUNT 3    //fixed as increasing to 5 increases gates by 4 times
`define BIT_WIDTH 2
`define ITER_NUM 5


module tb_top;
  
 logic [0:`MAX_CHAR_COUNT-1][7:0] data_in[0:`ITER_NUM-1];
 // logic [0:`MAX_CHAR_COUNT-1][7:0] testvectors[0:`ITER_NUM-1];
//logic [16:0] testvectors[0:`ITER_NUM-1];
  int freq[0:`ITER_NUM-1];
  //string testvectors[0:`ITER_NUM-1];
  string input_string, temp;
  logic [0:`MAX_CHAR_COUNT-1][2:0] freq_in[0:`ITER_NUM-1];
 // logic [`MAX_CHAR_COUNT*`MAX_CHAR_COUNT-1:0] encoded_value;
  logic data_en;
  logic clk, reset, done;
  integer i;
  logic [11:0] io_out, io_in, temp1;
  logic [0:2*`MAX_CHAR_COUNT-1][11:0] expected_out[0:`ITER_NUM-1];
  integer j, vector_num, num, test_num;
    int f, f1;
logic vector_done;

   // logic [0:`MAX_CHAR_COUNT-1] input_string[$];

    int line, iter, line1, line2;
   //  string output_string;

    huff_encoder DUT(.clk(clk), .reset(reset), .io_in(io_in), .io_out(io_out));

    initial begin
        clk = 0;
        reset = 1;
        vector_num = 0;
        done = 1'b0;
        num = 0;
        test_num = 0;
      //  data_en = 1'b0;
       // iter = 'b0;

       //$readmemh("input_string.txt", testvectors); // Read vectors
       // $readmemh("expected_out.txt", expected_out); // Read vectors
       
        //data_in = "anm";

        // $readmemh("input_vector.hex", testvectors, 0, 2);

        // for(int i=0; i < `ITER_NUM; i++) begin
        //      $display("vectornum:%d, %h", i, testvectors[i]);
        // end

        //f = $fopen("input_string.txt", "r");
        f = $fopen("input_vector.txt", "r");
        f1 = $fopen("expected_out.txt", "r");

         while (!$feof(f1)) begin
        line1 = $fgets(input_string, f1);     //line1 = 13
        line2 =  $sscanf(input_string, "%b\n", temp1);
     if (line2 == 1) begin
        $display("line1:%d, line2:%d", line1, line2);
        expected_out[test_num][num] = temp1;
    
        $display("expected_out[%0d][%0d]=%b, num=%0d\n",  test_num, num, temp1, num);
    //    $display("vectornum:%d, %h", vector_num, testvectors[vector_num]);
        test_num = (num == 'd5)? test_num + 1: test_num;
        num =  (num < 'd5) ? num+1 : 'd0;
       

         end
        end


        while (!$feof(f)) begin
        line = $fgets(input_string, f);     //line = 3
        line =  $sscanf(input_string, "%0d,%0d,%0d,%s\n", freq[0], freq[1], freq[2], temp);
        
        $display("line:%d", line);
        data_in[vector_num] = temp;
        freq_in[vector_num][0] = freq[0];
        freq_in[vector_num][1] = freq[1];
        freq_in[vector_num][2] = freq[2];
    
        $display("out=%s, freq0:%0d, freq1:%0d, freq2:%0d\n", temp, freq[0], freq[1], freq[2]);
    //    $display("vectornum:%d, %h", vector_num, testvectors[vector_num]);
        vector_num = vector_num+1;
     //   if (vector_num == `ITER_NUM-1) data_en = 1;
        end
        $fclose(f); 
        $fclose(f1);       

     
    //   {freq_in[0], freq_in[1], freq_in[2]} = {3'h4,3'h2,3'h2};

/*
        expected_out[0] = 9'b101100001; //a
        expected_out[1] = 9'b100001001;
        expected_out[2] = 9'b101101110; //n
        expected_out[3] = 9'b100011001;
        expected_out[4] = 9'b101101101; //m
        expected_out[5] = 9'b100011000;
*/

         #5 reset = 0;
        #50; //increase if you increase the string length
        $finish;
    end


//input assignment
    always_ff @(posedge clk) begin
        if(reset) begin
            i <= 'b0;
            io_in = 'b0;
            iter = 'd0;
            data_en = 'b1;
        end
        else begin
            if ((i< `MAX_CHAR_COUNT)) begin
                io_in[11:0] = {1'b1, freq_in[iter][i], data_in[iter][i]}; 
            end
            else begin
                io_in[11] = 1'b0;
            end

            i <= (vector_done)? 'b0 : (i + 1'b1);    
        //    iter = vector_done ? iter + 1: (iter == `ITER_NUM-1) ? 'b0 : iter;
            iter = vector_done ? iter + 1: iter;
            $display("iter:%d, i:%d, state:%d\n", iter, i, DUT.state);
                if(iter == `ITER_NUM) begin
                    $finish;
                end
        end
    end

    always @(posedge clk) begin
         if( reset) begin
            j <= 'b0;
            vector_done <= 'b0;
        end
        else if (io_out[8] && !vector_done) begin
            $display("io_out:%b, expected_out[%0d][%0d]=%b\n", io_out, iter, j, expected_out[iter][j]);
            assert (io_out[8:0] == expected_out[iter][j]) 
            else   $display("Failed for io_out:%b\n", io_out);
            j <= (j == 2*`MAX_CHAR_COUNT-1)? 'b0 : j + 1;
            $display("j:%d, vector_done=%b\n", j, vector_done);
        end
        vector_done <= (j == 2*`MAX_CHAR_COUNT-1)? 'b1 : 'b0;
              
    end

    

    always begin
        #0.5 clk = ~clk;  //1MHz
    end

    always_comb begin
        if (`DEBUG) begin
        //$display("Count:%d\n", DUT.count);
        $display("time:%t, Input data: state:%0d\n", $time, DUT.state);
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


