`timescale 1us/1ps
`default_nettype  wire
`define MAX_STRING_LENGTH 6 //change this as required 
`define MAX_OUTPUT_SIZE 6  
`define DEBUG 1

//change it later as per number of states : FIXME???
`define INIT 3'b000
`define DATA_COLLECT 3'b001
`define FREQ_CALC 3'b010
`define SORT 3'b011
`define MERGE 3'b100
`define BUILD_TREE 3'b101
`define ENCODE 3'b110  
`define SEND_OUTPUT 3'b111


//left and right nodes are 0 for leaf nodes
typedef struct {
    //logic [7:0] ascii_char; //total 128 characters
    integer ascii_char;
    integer frequency;
    logic is_leaf_node;
    integer left_node;  //stores the index
    integer right_node; //stores the index
} node_t;

typedef struct {
    //logic [6:0] ascii_char; -replacing with integer as concatenating can cause > logic [6:0]
    integer ascii_char;
    integer frequency;
    logic is_leaf_node;
    integer left_node;  
    integer right_node;
    integer parent; 
    integer level;
} huff_tree_node_t; 

//main encoder module
module huff_encoder(input logic clk, input logic reset, input logic [7:0] data[`MAX_STRING_LENGTH], input logic data_en, output logic [`MAX_OUTPUT_SIZE-1:0] encoded_value[`MAX_STRING_LENGTH], output logic [`MAX_OUTPUT_SIZE-1:0] encoded_mask[`MAX_STRING_LENGTH], output logic[6:0] character[`MAX_STRING_LENGTH]);   //to fix the output logic width
integer count, unique_char_count;
node_t node [`MAX_STRING_LENGTH]; //initial node
node_t initial_node[`MAX_STRING_LENGTH];
//logic [7:0] data_in[`MAX_STRING_LENGTH];
logic [2:0] state;
integer index, ll;
huff_tree_node_t huff_tree[`MAX_STRING_LENGTH*2];
node_t in_huff_tree[`MAX_STRING_LENGTH][0:`MAX_STRING_LENGTH-1];
node_t out_huff_tree[`MAX_STRING_LENGTH][0:`MAX_STRING_LENGTH]; //size is  fixed now, can change based on level and number of elements required- FIXME???
node_t merged_nodes_list;   
node_t out_huff_tree_s[`MAX_STRING_LENGTH];
logic [`MAX_OUTPUT_SIZE-1:0] encoded_mask_h[2*`MAX_STRING_LENGTH];
logic [`MAX_OUTPUT_SIZE-1:0] encoded_value_h[2*`MAX_STRING_LENGTH];
int j, itr;
logic data_collect, sort_done;

//collecting data over every posedge clk
/*this setup is to collect 1 char data every posedge of cycle- TRY LATER
always_ff @(posedge clk) begin
    if (~reset) begin
        index = 0;
        for (int m=0; m< `MAX_STRING_LENGTH; m++) begin
            data_in[m] = 0;
        end
        data_collect = 0;
    end
    else begin
        if (data_en) begin
        data_in[index] = data;
        index = index +1;
        data_collect = 1'b0;
    end
    else begin
        data_collect = 1'b1;
    end
    end
end
*/

    freq_calc freq_calc_ins(.clk(clk), .state(state), .data_in(data), .data_en(data_en), .node(initial_node), .count(unique_char_count));
    node_sorter node_sorter_ins(.clk(clk), .reset(reset), .state(state), .count(unique_char_count), .input_node(in_huff_tree[ll][0:`MAX_STRING_LENGTH-1]), .output_node(out_huff_tree_s[0:`MAX_STRING_LENGTH-1]));
    merge_nodes merge_nodes_ins(.min_node(out_huff_tree_s[0]), .second_min_node(out_huff_tree_s[1]), .merged_node(merged_nodes_list));

always_ff @(posedge clk) begin : huffman_enc
    if (~reset) begin
        state = `INIT;
    end

    case (state) 
    
        `INIT : begin
            ll = 0;
            for (int i=0; i < (2*`MAX_STRING_LENGTH); i++) begin
                encoded_value[i] = 'bz;
                encoded_mask[i] = 'b0;
                encoded_value_h[i] = 'bz;
                encoded_mask_h[i] = 'b0;
                huff_tree[i].ascii_char = 'bz;
                huff_tree[i].frequency = 0;
                huff_tree[i].is_leaf_node = 1'b0;
                huff_tree[i].parent = 'b0;
                huff_tree[i].left_node = 'b0;
                huff_tree[i].right_node = 'b0;
                huff_tree[i].level = 'b0;
            end
            for (int j=0; j< `MAX_STRING_LENGTH; j++) begin
                node[j].ascii_char = 0;
                node[j].frequency = 0;
                node[j].left_node = 0;   //ascii valud of null
                node[j].right_node = 0;
                node[j].is_leaf_node = 1'b1;  
            end
            
        //LATER    state = data_collect? `DATA_COLLECT : `INIT; 
        state <= `DATA_COLLECT;
        end

        `DATA_COLLECT: begin    //at every posedge of cycle- data comes in
            //    data_in = data;
                state <= `FREQ_CALC;
        end

        `FREQ_CALC: begin
            for (int j=0; j< `MAX_STRING_LENGTH; j++) begin
                node[j] = initial_node[j];  //from freq calc module 
            end
            count = unique_char_count;
            for (int i=0; i< `MAX_STRING_LENGTH; i++) begin
            in_huff_tree[0][i] = initial_node[i];
           // out_huff_tree[ll][i] = out_huff_tree_s[i];
          end
            state <= `SORT;
        end

        `SORT : begin   //state=3
          //  count = unique_char_count;
            state <= `MERGE;
        end

        `MERGE : begin  //state=4
               for (int i=0; i< `MAX_STRING_LENGTH; i++) begin
           // in_huff_tree[0][i] = initial_node[i];
            out_huff_tree[ll][i] = out_huff_tree_s[i];
          end
            in_huff_tree[ll+1][0:`MAX_STRING_LENGTH-1] = {merged_nodes_list, out_huff_tree[ll][2:`MAX_STRING_LENGTH]}; //somehow put this merged list in the end
            count = count - 1;
            if (count == 0) begin
                state <= `BUILD_TREE;
                ll = 0;
            end
            else begin
                state <= `SORT;
                ll = ll + 1;
            end
        end

        `BUILD_TREE: begin  //state=5   //might be a critical path
        for (int l=0; l< `MAX_STRING_LENGTH; l++) begin //initialy it was unique_char_count 
            if (l < unique_char_count) begin
            //assigning child nodes and leaf node fields 
        //    $display("count:%d\n", unique_char_count);
            j = unique_char_count - 1- l;   //2,1,0
        //    $display("j=%d, l=%d\n", j, l);
            if (j!= 0) begin
            huff_tree[2*j].ascii_char = out_huff_tree[l][0].ascii_char; 
            huff_tree[2*j + 1].ascii_char = out_huff_tree[l][1].ascii_char;
            huff_tree[2*j].is_leaf_node = out_huff_tree[l][0].is_leaf_node;
            huff_tree[2*j + 1].is_leaf_node = out_huff_tree[l][1].is_leaf_node;
            huff_tree[2*j].frequency = out_huff_tree[l][0].frequency;
            huff_tree[2*j + 1].frequency = out_huff_tree[l][1].frequency;
            huff_tree[2*j].left_node = out_huff_tree[l][0].left_node;
            huff_tree[2*j + 1].left_node = out_huff_tree[l][1].left_node;
            huff_tree[2*j].right_node = out_huff_tree[l][0].right_node;
            huff_tree[2*j + 1].right_node = out_huff_tree[l][1].right_node;
        //    huff_tree[2*j + 1].level = j;
        //    huff_tree[2*j].level = j;
            end
            else if (j==0) begin
            huff_tree[2*j + 1].ascii_char = out_huff_tree[l][0].ascii_char;
            huff_tree[2*j + 1].is_leaf_node = out_huff_tree[l][0].is_leaf_node;
            huff_tree[2*j + 1].frequency = out_huff_tree[l][0].frequency;
            huff_tree[2*j + 1].left_node = out_huff_tree[l][0].left_node;
            huff_tree[2*j + 1].right_node = out_huff_tree[l][0].right_node;
            end
            end    
    end

    //assigning parent field for a node if that node is present as a child node either in left or right node 
     for (int l=(2*`MAX_STRING_LENGTH)-1; l > 1; l--) begin
        for (int n=1; n< (2*`MAX_STRING_LENGTH); n++) begin
            if (huff_tree[n].left_node == huff_tree[l].ascii_char | huff_tree[n].right_node == huff_tree[l].ascii_char) begin
                huff_tree[l].parent = n;
            end
        end
    end

    //assigning levels
    for (int m=1; m < (2*`MAX_STRING_LENGTH); m++) begin
        if (huff_tree[m].is_leaf_node != 1) begin
        for (int n=2; n < (2*`MAX_STRING_LENGTH); n++) begin
            if (huff_tree[n].ascii_char == huff_tree[m].left_node) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
            if (huff_tree[n].ascii_char == huff_tree[m].right_node) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
        end
        end
    end
    state <= `ENCODE;
        end

        `ENCODE: begin  //state=6
               for (int n=2; n < (2*`MAX_STRING_LENGTH); n++) begin  //1-root node
                encoded_mask_h[n] = (1'b1 << huff_tree[n].level) -1;
            if (huff_tree[n].parent != 1) begin   
            //    encoded_value_h[n] = (n%2==0) ? (encoded_value_h[huff_tree[n].parent] << (huff_tree[n].level-1)): ((encoded_value_h[huff_tree[n].parent] << (huff_tree[n].level-1)) | 1'b1);
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
        itr = 0;
        for (int n=0; n< (2*`MAX_STRING_LENGTH); n++) begin
            if (huff_tree[n].is_leaf_node == 1) begin
                encoded_mask[itr] = encoded_mask_h[n];
                encoded_value[itr] = encoded_value_h[n];
                character[itr] = huff_tree[n].ascii_char;
                itr = itr + 1; 
            end
         //   $display("Output sent\n");
        end

        if (data_en) begin
        state <= `INIT;
        end
        else begin
            state <= `SEND_OUTPUT;
        end

        end

        default : begin
            state <= `INIT;
        end
    endcase

end //posedge_clk


    
     
 //   binary_tree_node binary_tree_node_ins0(.count(count), .input_node(node), .encoded_value(encoded_value), .encoded_mask(encoded_mask)); //cannot pass the count value calculated in freq_calc module
endmodule


module freq_calc(input logic clk, input logic [2:0] state, input logic [7:0] data_in[`MAX_STRING_LENGTH], input logic data_en, output node_t node[`MAX_STRING_LENGTH], output integer count);

integer cnt, index;    //initially 0
logic node_create;
logic matched, break1;
integer ctr;
logic [1:0] internal_state; 

//for now able to calculate frequency properly, but had to delete the extra nodes: FIXME????
  always_ff @(posedge clk) begin
        matched = '0;
        break1 = '0;
    //have to initialize entire node array- FIXME? - else it will impact count
     if (data_en && (state==`DATA_COLLECT)) begin
        //    if (state == `FREQ_CALC && data_en) begin
             for (int i=0; i< `MAX_STRING_LENGTH; i++) begin
            node[i].ascii_char = 'b0;
            node[i].frequency = 'b0;
            node[i].left_node = 'b0;   //ascii valud of null
            node[i].right_node = 'b0;
            node[i].is_leaf_node = 1'b0;
        end
        node_create = 'b0;
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
            for (int j=0; j< i; j++) begin
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
        node_create = 1'b1;
       end
    end
    end


    always_comb begin
            count = 0;
            for (int i=0; i< `MAX_STRING_LENGTH; i++) begin
                if (node[i].ascii_char != 0) begin
                    count = count + 1;
                end
            end
    end


endmodule 

/*
module comparator(input node_t node[`MAX_STRING_LENGTH], output node_t min_node, output node_t second_min_node);

//create a counter to check the max length of the node array
logic break1;
integer count;

//working
always_comb begin
    count = 0;
    break1 = 0;
foreach(node[i]) begin
    if (break1 == 0) begin
    if (node[i].frequency != 0) begin
        count = count + 1;
    end
    else begin
        break1 = 1;
    end
    end
end
end

always_comb begin
for(int j=0; j< count-1; j++)  begin  //if non-zero frequency
    if (node[j].frequency <= node[j+1].frequency) begin
        min_node = node[j];
        second_min_node = node[j+1];
    end
    else begin
        min_node = node[j+1];
        second_min_node = node[j];
    end
end
end
endmodule
*/


module node_sorter(input logic clk, input logic reset, input logic[2:0] state, input integer count, input node_t input_node[`MAX_STRING_LENGTH], output node_t output_node[`MAX_STRING_LENGTH]);
 
node_t temp_node;
  always_ff @(posedge clk) begin
    if (state==`SORT) begin
        temp_node.ascii_char = 'b0;
        temp_node.frequency = 'b0;
        temp_node.is_leaf_node = '0;
        temp_node.left_node = '0;
        temp_node.right_node = '0;
        for (int i=0; i< `MAX_STRING_LENGTH; i++) begin
            output_node = input_node;
        end
        //sorting logic 
        for(int j=0; j< `MAX_STRING_LENGTH-1; j++)  begin  //if non-zero frequency ??FIXME
            for (int k= 0; k< `MAX_STRING_LENGTH-1; k++) begin
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
 //   sort_done <= 1'b1;
end   
endmodule

module merge_nodes(input node_t min_node, input node_t second_min_node, output node_t merged_node);
//should inside loop
always_comb begin
    merged_node.ascii_char =  {min_node.ascii_char + second_min_node.ascii_char};    //not working- FIXME????
    merged_node.frequency = min_node.frequency + second_min_node.frequency;
    merged_node.left_node = min_node.ascii_char;
    merged_node.right_node = second_min_node.ascii_char;
    merged_node.is_leaf_node = 1'b0;    
end
endmodule

//Algorithm
//1. First sort the input node list, find 1st and 2nd minimum 
//2. Allocate them to huff_tree, assign only is_leaf_node, child nodes (not parent node)
//3. Merge nodes--> create internal node- sort and then add to huff tree -repeat 
//4. Iterate until root node 
//5. Start from i=count-1, left_node=2i, right_node=2i+1 (i decrementing from count-1 to 0)

//instead send the entire node list and keep on finding the internal node
//original list of nodes(leaf nodes) created is sent as an input
//FIXME- yet to fix the dimension of output encoded value  
//node 0 and node 1 are first and second minimum
//count-1 times sort plus and merge action with decreasing count every level
//hence create an 2-D array of that dimension 
/*
module binary_tree_node (input integer count, input node_t input_node[`MAX_STRING_LENGTH], output logic[`MAX_OUTPUT_SIZE-1:0] encoded_value[`MAX_STRING_LENGTH], output logic[`MAX_OUTPUT_SIZE-1:0] encoded_mask[`MAX_STRING_LENGTH], output logic[6:0] character[`MAX_STRING_LENGTH]);
node_t min_node, second_min_node, merged_node;
node_t min_node_tmp, second_min_node_tmp, merge_node_tmp;
node_t in_huff_tree[0:`MAX_STRING_LENGTH][0:`MAX_STRING_LENGTH], out_huff_tree[0:`MAX_STRING_LENGTH][0:`MAX_STRING_LENGTH]; //size is  fixed now, can change based on level and number of elements required- FIXME???
node_t merged_nodes_list[0:`MAX_STRING_LENGTH];
logic[`MAX_OUTPUT_SIZE-1:0] encoded_value_h[2*`MAX_STRING_LENGTH];
logic[`MAX_OUTPUT_SIZE-1:0] encoded_mask_h[2*`MAX_STRING_LENGTH];
integer itr;
//create an array of some struct to indicate parent and child index of size 2*count (2*MAX for now)
//Ignore 0th index
//Root node is in index 1
//Start allocating from bottom of the array
//new struct --> ascii-freq-is_leaf_node-parent-left_node-right_node-encoding
//traverse the array to produce the encoded value 

//defining index as integer is waste of resource - can be clog2(2*count) - FIXME???

//non leaf node- then check for it's child nodes and search recursively to assign parent and child fields 
*/

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
    input logic [7:0] data[`MAX_STRING_LENGTH], 
    input logic sw, 
    output logic [`MAX_OUTPUT_SIZE-1:0] encoded_value[`MAX_STRING_LENGTH], 
    output logic [`MAX_OUTPUT_SIZE-1:0] encoded_mask[`MAX_STRING_LENGTH], 
    output logic[7:0] character[`MAX_STRING_LENGTH]
);

    logic clk; // 25MHz, generated by PLL
    logic [0:`MAX_STRING_LENGTH-1] [7:0] input_string;
    logic [7:0] data_in[`MAX_STRING_LENGTH];

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