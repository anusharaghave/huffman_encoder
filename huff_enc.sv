/*********Author: Anusha Raghavendra********/
//Project : Huffman Encoder


//Algorithm
//1. Read the character array, calculate the frequency of each node(leaf node/character)
//2. First sort the input node list, find 1st and 2nd minimum. If tied, sort according to the ascii value
//3. Allocate them to huff_tree, assign only is_leaf_node, child nodes (not parent node)
//4. Merge nodes--> create internal node- sort and then add to huff tree -repeat until only 1 node is left
//5. Iterate until the root node 
//6. Start from i=count-1, left_node=2i, right_node=2i+1 (i decrementing from count-1 to 0), where count is the number of unique character count
//7. Traverse the entire array to assign the parent node and level in the binary tree
//8. Traverse again to assign the encodings to each character



`timescale 1us/1ps

`define MAX_STRING_LENGTH 5 //change this as required 
`define MAX_CHAR_COUNT 3
//`define BIT_WIDTH clog2(`MAX_CHAR_COUNT)
`define BIT_WIDTH 2

//for displays
//`define DEBUG 1

`define INIT 3'b000
`define DATA_COLLECT 3'b001
`define FREQ_CALC 3'b010
`define SORT 3'b011
`define MERGE_BUILD 3'b100
`define ENCODE 3'b101  
`define SEND_OUTPUT 3'b110


//left and right nodes are 0 for leaf nodes
typedef struct {
   // integer ascii_char; //change this to the max value obtained by adding other nodes and levels possible
    logic [8:0] ascii_char;
   // integer frequency;
    logic [2:0] frequency; //max freq can go upto 8
    logic is_leaf_node;
    // integer left_node;  //stores the index
    // integer right_node; //stores the index
    logic [8:0] left_node;  //stores the index
    logic [8:0] right_node; //stores the index
} node_t;

typedef struct {
    integer ascii_char; //change this to the max value obtained by adding other nodes and levels possible
   // integer frequency;
    logic [2:0] frequency;
    logic is_leaf_node;
    // integer left_node;  
    // integer right_node;
    logic [8:0] left_node;  //stores the index
    logic [8:0] right_node; //stores the index
    //integer parent; 
    //integer level;
    logic [`BIT_WIDTH:0] parent;
    logic [`BIT_WIDTH:0] level;
} huff_tree_node_t; 

//main encoder module
module huff_encoder (input logic clk, input logic reset, input logic [0:`MAX_STRING_LENGTH-1][7:0] data_in, input logic data_en, output logic [0:`MAX_CHAR_COUNT-1][`MAX_CHAR_COUNT-1:0] encoded_value, output logic [0:`MAX_CHAR_COUNT-1][`MAX_CHAR_COUNT-1:0] encoded_mask, output logic [0:`MAX_CHAR_COUNT-1][6:0] character, output logic done);   
logic [`BIT_WIDTH-1:0] count, unique_char_count, ll;
node_t initial_node[`MAX_CHAR_COUNT];
logic [2:0] state;
//integer ll;
huff_tree_node_t huff_tree[`MAX_CHAR_COUNT*2];
node_t in_huff_tree[0:`MAX_CHAR_COUNT-1];
node_t out_huff_tree[0:`MAX_CHAR_COUNT]; //size is  fixed now, can change based on level and number of elements required- FIXME???
node_t merged_node;   

logic [`MAX_CHAR_COUNT-1:0] encoded_value_h[2*`MAX_CHAR_COUNT];
//int j;
//integer level, m, itr;
logic [`BIT_WIDTH-1:0] level, m;

    freq_calc freq_calc_ins(.clk(clk), .state(state), .data_in(data_in), .node(initial_node), .count(unique_char_count));
    node_sorter node_sorter_ins(.clk(clk), .state(state),.input_node(in_huff_tree[0:`MAX_CHAR_COUNT-1]), .output_node(out_huff_tree[0:`MAX_CHAR_COUNT-1]));
    merge_nodes merge_nodes_ins(.min_node(out_huff_tree[0]), .second_min_node(out_huff_tree[1]), .merged_node(merged_node));

always_ff @(posedge clk) begin : huffman_enc
    if (~reset) begin
        state <= `INIT;
        level = 'b0;
        m =0;
           for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
                encoded_value[i] = 'b0;
                encoded_mask[i] = 'b0;
            end
    end

    case (state) 
    
        `INIT : begin
            done = 'b0;
            ll = 'b0;
            for (int i=0; i < (2*`MAX_CHAR_COUNT); i++) begin
                encoded_value_h[i] = 'b0;
                huff_tree[i].ascii_char = 'bz;
                huff_tree[i].frequency = 0;
                huff_tree[i].is_leaf_node = 1'b0;
                huff_tree[i].parent = 'b0;
                huff_tree[i].left_node = 'b0;
                huff_tree[i].right_node = 'b0;
                huff_tree[i].level = 'b0;
            end
         

            if (data_en) begin
                state <= `DATA_COLLECT;
            end
            else begin 
                state <= `INIT;
            end
        end

        `DATA_COLLECT: begin    
                state <= `FREQ_CALC;
        end

        `FREQ_CALC: begin
            count = unique_char_count;
            for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
           in_huff_tree[i] = initial_node[i];
          end
            state <= `SORT;
        end

        `SORT : begin   //state=3
            state <= `MERGE_BUILD;
        end

        `MERGE_BUILD : begin  //state=4
            in_huff_tree[0] = merged_node;
            in_huff_tree[1:`MAX_CHAR_COUNT-1] = out_huff_tree[2:`MAX_CHAR_COUNT];

            $display("count:%d\n", count);
        
            //assigning child nodes and leaf node fields 
            if ((count-1'b1)!= 0) begin
                huff_tree[2*(count-1'b1)].ascii_char = out_huff_tree[0].ascii_char; 
                huff_tree[2*(count-1'b1) + 1].ascii_char = out_huff_tree[1].ascii_char;
                huff_tree[2*(count-1'b1)].is_leaf_node = out_huff_tree[0].is_leaf_node;
                huff_tree[2*(count-1'b1) + 1].is_leaf_node = out_huff_tree[1].is_leaf_node;
                huff_tree[2*(count-1'b1)].frequency = out_huff_tree[0].frequency;
                huff_tree[2*(count-1'b1) + 1].frequency = out_huff_tree[1].frequency;
                huff_tree[2*(count-1'b1)].left_node = out_huff_tree[0].left_node;
                huff_tree[2*(count-1'b1) + 1].left_node = out_huff_tree[1].left_node;
                huff_tree[2*(count-1'b1)].right_node = out_huff_tree[0].right_node;
                huff_tree[2*(count-1'b1) + 1].right_node = out_huff_tree[1].right_node;
            end
            else if ((count-1'b1)==0) begin
                huff_tree[2*(count-1'b1) + 1].ascii_char = out_huff_tree[0].ascii_char;
                huff_tree[2*(count-1'b1) + 1].is_leaf_node = out_huff_tree[0].is_leaf_node;
                huff_tree[2*(count-1'b1) + 1].frequency = out_huff_tree[0].frequency;
                huff_tree[2*(count-1'b1) + 1].left_node = out_huff_tree[0].left_node;
                huff_tree[2*(count-1'b1) + 1].right_node = out_huff_tree[0].right_node;
            end
               
        



            count = count - 1;
            if (count == 0) begin
                state <= `ENCODE;
                ll = 0;
            end
            else begin
                state <= `SORT;
                ll = ll + 1;
            end
        end


        `ENCODE: begin  //state=6
          //assigning parent field for a node if that node is present as a child node either in left or right node 
     for (int l=(2*`MAX_CHAR_COUNT)-1; l > 1; l--) begin
        for (int n=1; n< (2*`MAX_CHAR_COUNT); n++) begin
            if (huff_tree[n].left_node == huff_tree[l].ascii_char | huff_tree[n].right_node == huff_tree[l].ascii_char) begin
                huff_tree[l].parent = n;
            end
        end
    end

    //assigning levels
    for (int m=1; m < (2*`MAX_CHAR_COUNT); m++) begin
        if (huff_tree[m].is_leaf_node != 1) begin
        for (int n=2; n < (2*`MAX_CHAR_COUNT); n++) begin
            if (huff_tree[n].ascii_char == huff_tree[m].left_node) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
            if (huff_tree[n].ascii_char == huff_tree[m].right_node) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
        end
        end
    end

            for (int n=2; n < (2*`MAX_CHAR_COUNT); n++) begin  //1-root node
            //    // encoded_mask_h[n] = (1'b1 << huff_tree[n].level) -1;
                if (huff_tree[n].parent != 1) begin   
                    encoded_value_h[n] = (n%2==0) ? (encoded_value_h[huff_tree[n].parent] << 1'b1): ((encoded_value_h[huff_tree[n].parent] << 1'b1) | 1'b1);
                end
                else if (huff_tree[n].parent == 1) begin
                    encoded_value_h[n][0] = (n%2==0) ? {1'b0}: {1'b1};
                end
            end
            state <= `SEND_OUTPUT;
        end

     //extract only encodings for unique characters 
    `SEND_OUTPUT: begin     //state=7
        m = 0;
        for (int n=0; n< (2*`MAX_CHAR_COUNT); n++) begin
            if (huff_tree[n].is_leaf_node == 1) begin
                /*working 
                encoded_value[itr] = encoded_value_h[n];
                */
               // encoded_mask[m] = encoded_mask_h[n];
                encoded_mask[m] = (1'b1 << huff_tree[n].level) -1;
                character[m] = huff_tree[n].ascii_char;
            //    frequency[m] = huff_tree[n].frequency;
                level = huff_tree[n].level;
                encoded_value[m] = encoded_value_h[n];
                /*
                foreach (encoded_mask_h[n][i]) begin
                    if (encoded_mask_h[n][i] === 1'b1) begin
                //    $display("I am here:%0d\n", n);
                   // encoded_value[m][((`MAX_CHAR_COUNT*`MAX_CHAR_COUNT)-1)-itr] = encoded_value_h[n][i];    //different bit assignment- might throw error
                    encoded_value[m][i] = encoded_value_h[n][i];
                    itr = itr + 1;  //like a pointer
                end
                end
                */

                //itr = itr + level;
                m = m+1;
                end //if loop
        end //for loop
        done = 1'b1;    //used in SV tb to stop the simulation
        end

        default : begin
            state <= `INIT;
        end
    endcase

end //posedge_clk

endmodule


module freq_calc(input logic clk, input logic [2:0] state, input logic [0:`MAX_STRING_LENGTH-1][7:0] data_in, output node_t node[`MAX_CHAR_COUNT], output logic [`BIT_WIDTH-1:0] count);

// integer cnt, index;    //initially 0
// logic matched, break1;
// integer ctr;

logic [`BIT_WIDTH:0] cnt, index, ctr;
logic matched, break1;

  always_ff @(posedge clk) begin
        matched = '0;
        break1 = '0;
    //have to initialize entire node array- FIXME? - else it will impact count
     if ((state==`DATA_COLLECT)) begin
        for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
            node[i].ascii_char = 'b0;
            node[i].frequency = 'b0;
            node[i].left_node = 'b0;   //ascii valud of null
            node[i].right_node = 'b0;
            node[i].is_leaf_node = 1'b0;
        end
        ctr = 'b0;
        cnt = 'b0;
        foreach(data_in[i]) begin
           if (data_in[i] != 0) begin
            matched = 0;
            break1 = 0;
            cnt = 1'b1;
            index = ctr;
            node[index].is_leaf_node = 1'b1;
            //compare against the existing nodes
            for (int j=0; j< `MAX_CHAR_COUNT; j++) begin
                if (break1 ==0) begin
                if (data_in[i] == node[j].ascii_char) begin //if matched 
                    cnt = node[j].frequency + 1;
                  //  index = j;
                    index = j;
                    matched = 1;
                    break1 = 1;
                end
                else begin      //if not match
                    matched = 0;
                    break1 = 0;
                end    
            end //for loop
            end
            if (i == 0) begin
                    ctr = ctr + 1;
            end 
            else begin
                ctr = matched ? ctr : ctr + 1;
            end    
                node[index].ascii_char = data_in[i];
                node[index].frequency = cnt;
        end
       end
    end
    end


    always_comb begin
            count = 0;
            for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
                if (node[i].ascii_char != 0) begin
                    count = count + 1;
                end
            end
    end


endmodule 


module node_sorter(input logic clk, input logic[2:0] state, input node_t input_node[`MAX_CHAR_COUNT], output node_t output_node[`MAX_CHAR_COUNT]);
 
node_t temp_node;
    //always_comb begin
        always_ff @(posedge clk) begin
    if (state==`SORT) begin
        temp_node.ascii_char = 'b0;
        temp_node.frequency = 'b0;
        temp_node.is_leaf_node = '0;
        temp_node.left_node = '0;
        temp_node.right_node = '0;
        for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
            output_node = input_node;
        end
        //sorting logic 
        for(int j=0; j< `MAX_CHAR_COUNT-1; j++)  begin  //if non-zero frequency ??FIXME
            for (int k= 0; k< `MAX_CHAR_COUNT-1; k++) begin
                if (!(output_node[k].ascii_char == 0 || output_node[k+1].ascii_char == 0)) begin
                if (output_node[k].frequency == output_node[k+1].frequency) begin
                    if (output_node[k].ascii_char > output_node[k+1].ascii_char) begin
                    temp_node = output_node[k];
                    output_node[k] = output_node[k+1];
                    output_node[k+1] = temp_node;
                    end
                end
                else if (output_node[k].frequency > output_node[k+1].frequency) begin
                    temp_node = output_node[k];
                    output_node[k] = output_node[k+1];
                    output_node[k+1] = temp_node;
                end
            end
            end
        end
    end
end   
endmodule

module merge_nodes(input node_t min_node, input node_t second_min_node, output node_t merged_node);
//should inside loop
//always_comb begin
    /*
    assign merged_node.ascii_char = 'b0 ;    
    assign merged_node.frequency = 'b0;
    assign merged_node.left_node = 'b0;
    assign merged_node.right_node = 'b0;
    */
    assign merged_node.ascii_char =  min_node.ascii_char + second_min_node.ascii_char;    
    assign merged_node.frequency = min_node.frequency + second_min_node.frequency;
    assign merged_node.left_node = min_node.ascii_char;
    assign merged_node.right_node = second_min_node.ascii_char;
    assign merged_node.is_leaf_node = 1'b0;    
//end
endmodule



/*
//For synthesis
module m_design (
    input logic clk100, // 100MHz clock- this should be 1MHz???
    input logic reset_n, // Active-low reset

    // output logic [7:0] base_led, // LEDs on the far right side of the board
    // output logic [23:0] led, // LEDs in the middle of the board

    // input logic [23:0] sw, // The tiny slide-switches

    // output logic [3:0] display_sel, // Select between the 4 segments
    // output logic [7:0] display // Seven-segment display
    input logic [7:0] data[`MAX_CHAR_COUNT], 
    input logic sw, 
    output logic [`MAX_CHAR_COUNT-1:0] encoded_value[`MAX_CHAR_COUNT], 
    output logic [`MAX_CHAR_COUNT-1:0] encoded_mask[`MAX_CHAR_COUNT], 
    output logic[7:0] character[`MAX_CHAR_COUNT]
);

    logic clk; // 25MHz, generated by PLL
    logic [0:`MAX_CHAR_COUNT-1] [7:0] input_string;
    logic [7:0] data_in[`MAX_CHAR_COUNT];

    // blinky my_blinky (
    //     .clk, .reset_n, .led
    // );

     huff_encoder DUT(.clk(clk), .reset(reset_n), .data(data_in), .data_en(sw), .encoded_value(encoded_value), .encoded_mask(), .character(character));

    initial begin
        input_string = "anush"; //working
       // input_string = "after"; //working
      //  input_string = "aaaaa";     //no encoding for single character
     //   input_string = "after";     //working  
        foreach(input_string[i]) begin
            data_in[i] = {input_string[i]};   //check in waves 
        end
    //    data_en = 1'b1;
        #100; //this should match the char count *20 (clock period)- else it will create x in data_in
    //    data_en = 1'b0;
    end

    // 100MHz -> 25MHz
    SB_PLL40_CORE #(
//        .FEEDBACK_PATH("SIMPLE"),
//        .DIVR(4'b0000),         // DIVR =  0
//        .DIVF(7'b0000111),      // DIVF =  7
//        .DIVQ(3'b101),          // DIVQ =  5
//        .FILTER_RANGE(3'b101)   // FILTER_RANGE = 5
.FEEDBACK_PATH("SIMPLE"),
.DIVR(4'b0000),         // DIVR =  0
.DIVF(7'b0000111),      // DIVF =  7
.DIVQ(3'b100),          // DIVQ =  4
.FILTER_RANGE(3'b101)   // FILTER_RANGE = 5    
) pll (
        .LOCK(),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk100),
        .PLLOUTCORE(clk)
    );

endmodule
*/