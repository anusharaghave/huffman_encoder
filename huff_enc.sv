`timescale 1us/1ps
`default_nettype  wire
`define MAX_STRING_LENGTH 5 //change this as required 
`define MAX_OUTPUT_SIZE 5  //ideally 64-1=63 bits
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
module huff_encoder(input logic clk, input logic reset, input logic [6:0] data[`MAX_STRING_LENGTH], input logic data_en, output logic [`MAX_OUTPUT_SIZE-1:0] encoded_value[`MAX_STRING_LENGTH], output logic [`MAX_OUTPUT_SIZE-1:0] encoded_mask[`MAX_STRING_LENGTH], output logic[6:0] character[`MAX_STRING_LENGTH]);   //to fix the output logic width
integer count, unique_char_count;
node_t node [`MAX_STRING_LENGTH]; //initial node
node_t initial_node[`MAX_STRING_LENGTH];
logic [6:0] data_in[`MAX_STRING_LENGTH];
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

    freq_calc freq_calc_ins(.data_in(data_in), .data_en(data_en), .node(initial_node), .count(unique_char_count));
    node_sorter node_sorter_ins(.clk(clk), .count(unique_char_count), .node(in_huff_tree[ll][0:`MAX_STRING_LENGTH-1]), .output_node(out_huff_tree_s[0:`MAX_STRING_LENGTH-1]));
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
                data_in = data;
                state <= `FREQ_CALC;
        end

        `FREQ_CALC: begin
            for (int j=0; j< `MAX_STRING_LENGTH; j++) begin
                node[j] = initial_node[j];  //from freq calc module 
            end
            count = unique_char_count;
            for (int i=0; i< count; i++) begin
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
               for (int i=0; i< count; i++) begin
           // in_huff_tree[0][i] = initial_node[i];
            out_huff_tree[ll][i] = out_huff_tree_s[i];
          end
            in_huff_tree[ll+1][0:`MAX_STRING_LENGTH-1] = {merged_nodes_list,out_huff_tree[ll][2:`MAX_STRING_LENGTH]};
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

        `BUILD_TREE: begin  //state=5
        for (int l=0; l< unique_char_count; l++) begin
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
            huff_tree[2*j + 1].level = j;
            huff_tree[2*j].level = j;
            end
            else if (j==0) begin
            huff_tree[2*j + 1].ascii_char = out_huff_tree[l][0].ascii_char;
            huff_tree[2*j + 1].is_leaf_node = out_huff_tree[l][0].is_leaf_node;
            huff_tree[2*j + 1].frequency = out_huff_tree[l][0].frequency;
            huff_tree[2*j + 1].left_node = out_huff_tree[l][0].left_node;
            huff_tree[2*j + 1].right_node = out_huff_tree[l][0].right_node;
            end
            
    end

    //assigning parent field for a node if that node is present as a child node wither in left or right node 
     for (int l=(2*count)-1; l > 1; l--) begin
        for (int n=1; n< (2*count); n++) begin
            if (huff_tree[n].left_node == huff_tree[l].ascii_char | huff_tree[n].right_node == huff_tree[l].ascii_char) begin
                huff_tree[l].parent = n;
            end
        end
    end

    //assigning levels
    for (int m=1; m < (2*count); m++) begin
        if (huff_tree[m].is_leaf_node != 1) begin
        for (int n=2; n < (2*count); n++) begin
            if (huff_tree[n].ascii_char == huff_tree[m].left_node) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
            if (huff_tree[n].ascii_char == huff_tree[m].right_node) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
        end
        end
    end
        end

        `ENCODE: begin  //state=6
               for (int n=2; n < (2*count); n++) begin  //1-root node
                encoded_mask_h[n] = (1'b1 << huff_tree[n].level) -1;
            if (huff_tree[n].parent != 1) begin   
                encoded_value_h[n] = (n%2==0) ? (encoded_value_h[huff_tree[n].parent] << (huff_tree[n].level-1)): ((encoded_value_h[huff_tree[n].parent] << (huff_tree[n].level-1)) | 1'b1);
            end
            else if (huff_tree[n].parent == 1) begin
               encoded_value_h[n][0] = (n%2==0) ? {1'b0}: {1'b1};
            end
        end
        end

     //extract only encodings for unique characters 
    `SEND_OUTPUT: begin     //state=7
        itr = 0;
        for (int n=0; n< (2*count); n++) begin
            if (huff_tree[n].is_leaf_node == 1) begin
                encoded_mask[itr] = encoded_mask_h[n];
                encoded_value[itr] = encoded_value_h[n];
                character[itr] = huff_tree[n].ascii_char;
                itr = itr + 1; 
            end
        end
        end

        default : begin
            state <= `INIT;
        end
    endcase

end //posedge_clk


    
     
 //   binary_tree_node binary_tree_node_ins0(.count(count), .input_node(node), .encoded_value(encoded_value), .encoded_mask(encoded_mask)); //cannot pass the count value calculated in freq_calc module
endmodule


module freq_calc(input logic [6:0] data_in[`MAX_STRING_LENGTH], input logic data_en, output node_t node[`MAX_STRING_LENGTH], output integer count);
//integer node[char];   //like an hash node[a] = frequency- not synthesizable 

//node_t node[`MAX_STRING_LENGTH];
integer cnt, index;    //initially 0
logic node_create;
logic matched, break1;
integer ctr;


//for now able to calculate frequency properly, but had to delete the extra nodes: FIXME????
  always_comb begin
    //have to initialize entire node array- FIXME? - else it will impact count
    if (data_en) begin
        node_create = 1;
        ctr = 0;
        foreach(data_in[i]) begin
            matched = 0;
            break1 = 0;
            cnt = 1'b1;
            index = ctr;
            node[index].ascii_char = 0;
            node[index].frequency = 0;
            node[index].left_node = 0;   //ascii valud of null
            node[index].right_node = 0;
            node[index].is_leaf_node = 1'b1;
            //compare against the existing nodes
            if (`DEBUG) begin
         //   $display("i:%d, ctr:%d\n", i, ctr);
            end
            for (int j=0; j< i; j++) begin
                if (break1 ==0) begin
                if (data_in[i] == node[j].ascii_char) begin
                    cnt = node[j].frequency + 1;
                  //  index = j;
                    index = j;
                    matched = 1;
                    break1 = 1;
                end
                else begin
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

    always_comb begin
        if (node_create) begin
            count = 0;
            for (int i=0; i< `MAX_STRING_LENGTH; i++) begin
                if (node[i].ascii_char != 0) begin
                    count = count + 1;
                end
            end
        end
    end


endmodule 

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

module node_sorter(input logic clk, input integer count, input node_t node[`MAX_STRING_LENGTH], output node_t output_node[`MAX_STRING_LENGTH]);
 
// logic count_done;
//count value keeps decrementing until 1 
/*

//working
always_comb begin
    count = 0;
    count_done = 0;
foreach(node[i]) begin
    if (count_done == 0) begin
    if (node[i].frequency != 0) begin
        count = count + 1;
    end
    else begin
        count_done = 0;
    end
    end
end
$display("node sorter count:%d, count_done:%d\n", count, count_done);
end
*/

node_t temp_node;
 //swap and sort
//always_comb begin
  always_ff @(posedge clk) begin
 //   sort_done <= 1'b0;
        temp_node.ascii_char = '0;
        temp_node.frequency = '0;
        temp_node.is_leaf_node = '0;
        temp_node.left_node = '0;
        temp_node.right_node = '0;
        for (int i=0; i< count; i++) begin
            output_node = node;
        end
        for(int j=0; j< count-1; j++)  begin  //if non-zero frequency ??FIXME
            if (output_node[j].frequency > output_node[j+1].frequency) begin
                temp_node = output_node[j];
                output_node[j] = output_node[j+1];
                output_node[j+1] = temp_node;
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



huff_tree_node_t huff_tree[`MAX_STRING_LENGTH*2];

//only for 0th level
always_comb begin
    merged_nodes_list[0] = input_node[0];
    for (int i=0; i<= `MAX_STRING_LENGTH; i++) begin
        in_huff_tree[0][i] = input_node[i];  
    end
end


genvar ll, cnt;

    int j;    
    generate
    for (ll=0; ll < `MAX_STRING_LENGTH-1; ll++) begin 
        node_sorter node_sorter_ins_level(.count(), .node(in_huff_tree[ll][0:`MAX_STRING_LENGTH-1]), .output_node(out_huff_tree[ll][0:`MAX_STRING_LENGTH-1]));
        merge_nodes merge_nodes_ins_level(.min_node(out_huff_tree[ll][0]), .second_min_node(out_huff_tree[ll][1]), .merged_node(merged_nodes_list[ll+1]));
      assign in_huff_tree[ll+1][0:`MAX_STRING_LENGTH-1] = {merged_nodes_list[ll+1],out_huff_tree[ll][2:`MAX_STRING_LENGTH]};
  
    end
    endgenerate

    always_comb begin
        //initializing 
        for (int i=0; i < (2*`MAX_STRING_LENGTH); i++) begin
            huff_tree[i].ascii_char = 'bz;
            huff_tree[i].frequency = 0;
            huff_tree[i].is_leaf_node = 1'b0;
            huff_tree[i].parent = 'b0;
            huff_tree[i].left_node = 'b0;
            huff_tree[i].right_node = 'b0;
            huff_tree[i].level = 'b0;
            encoded_value_h[i] = 'bz;
            encoded_mask_h[i] = 'b0;
        end

        for (int l=0; l< count; l++) begin
            //assigning child nodes and leaf node fields 
            $display("count:%d\n", count);
            j = count - 1- l;
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
            huff_tree[2*j + 1].level = j;
            huff_tree[2*j].level = j;
            end
            else if (j==0) begin
            huff_tree[2*j + 1].ascii_char = out_huff_tree[l][0].ascii_char;
            huff_tree[2*j + 1].is_leaf_node = out_huff_tree[l][0].is_leaf_node;
            huff_tree[2*j + 1].frequency = out_huff_tree[l][0].frequency;
            huff_tree[2*j + 1].left_node = out_huff_tree[l][0].left_node;
            huff_tree[2*j + 1].right_node = out_huff_tree[l][0].right_node;
            end
            
    end

    //assigning parent field for a node if that node is present as a child node wither in left or right node 
     for (int l=(2*count)-1; l > 1; l--) begin
        for (int n=1; n< (2*count); n++) begin
            if (huff_tree[n].left_node == huff_tree[l].ascii_char | huff_tree[n].right_node == huff_tree[l].ascii_char) begin
                huff_tree[l].parent = n;
            end
        end
    end

    //assigning levels
    for (int m=1; m < (2*count); m++) begin
        if (huff_tree[m].is_leaf_node != 1) begin
        for (int n=2; n < (2*count); n++) begin
            if (huff_tree[n].ascii_char == huff_tree[m].left_node) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
            if (huff_tree[n].ascii_char == huff_tree[m].right_node) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
        end
        end
    end

    //assigning encodings
        for (int n=2; n < (2*count); n++) begin  //1-root node
                encoded_mask_h[n] = (1'b1 << huff_tree[n].level) -1;
            if (huff_tree[n].parent != 1) begin   
                encoded_value_h[n] = (n%2==0) ? (encoded_value_h[huff_tree[n].parent] << (huff_tree[n].level-1)): ((encoded_value_h[huff_tree[n].parent] << (huff_tree[n].level-1)) | 1'b1);
            end
            else if (huff_tree[n].parent == 1) begin
               encoded_value_h[n][0] = (n%2==0) ? {1'b0}: {1'b1};
            end
        end

     //extract only encodings for unique characters 
    
        itr = 0;
        for (int n=0; n< (2*count); n++) begin
            if (huff_tree[n].is_leaf_node == 1) begin
            encoded_mask[itr] = encoded_mask_h[n];
            encoded_value[itr] = encoded_value_h[n];
            character[itr] = huff_tree[n].ascii_char;
            itr = itr + 1; 
            end
        end

    end
endmodule
*/

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
        #20 reset = 1;
      //  data_in = '{"a","e"," ","a","a"};
      //    input_string = "anusha is a good gir"; //should be able to read an input file with many strings
      //  input_string = "aftergraduation";
        input_string = "ae aa";
        foreach(input_string[i]) begin
            data_in[i] = {input_string[i]};   //check in waves 
        end
        data_en = 1'b1;
        #100; //this should match the char count *20 (clock period)- else it will create x in data_in
        data_en = 1'b0;
        $monitor("Input data: data:%p\n", data);
   //SEE LATER: #100 data_en = 1'b0;
   #1500;
   $finish;
    end

    always begin
        #1 clk = ~clk;
    end

    //always_ff @(posedge clk) cycle = cycle + 1;

/*this setup is to push data at every posedge of cycle
    always_ff @(posedge clk) begin
        if (~reset) begin
            i= 0;
            cycle = 0;
        end
        else begin
            data = data_in[i];
            i= i + 1;
            cycle = cycle + 1;
        end
    end
*/
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
       for (int i=0; i< 2*`MAX_STRING_LENGTH; i++) begin
      //  if (DUT.huff_tree[i].ascii_char != 1'bz) begin
            $display("binary_tree:  huff_tree[%0d]:%p\n", i, DUT.huff_tree[i]);   
      //  end
       end
        for (int i=0; i< count; i++) begin
       $display("OUTPUT character:%d, encoded mask[%0d]:%b, encoded values[%0d]:%b\n", DUT.character[i], i, DUT.encoded_mask[i], i, DUT.encoded_value[i]);
        end
    end
endmodule 