`default_nettype  wire
`define MAX_CHAR_LENGTH 5 //change this as required 
`define DEBUG 0

//left and right nodes are 0 for leaf nodes

typedef struct {
    //logic [6:0] ascii_char;
    integer ascii_char;
    integer frequency;
    logic is_leaf_node;
    integer left_node;  //only ascii char
    integer right_node; //only ascii char
} node_t;

typedef struct {
    //logic [6:0] ascii_char; -replacing with integer as concatenating can cause > logic [6:0]
    integer ascii_char;
    integer frequency;
    logic is_leaf_node;
    integer left_node;  
    integer right_node;
    integer parent; 
} huff_tree_node_t; 

//main encoder module
module huff_encoder(input logic [6:0] data_in[`MAX_CHAR_LENGTH], input logic data_en, output logic [2*6+2:0] encoded_value[`MAX_CHAR_LENGTH]);   //to fix the output logic width
integer count;
node_t node[`MAX_CHAR_LENGTH]; 

    freq_calc freq_calc_ins0(.data_in(data_in), .data_en(data_en), .node(node), .count(count)); 
    binary_tree_node binary_tree_node_ins0(.count(count), .input_node(node), .encoded_value(encoded_value)); //cannot pass the count value calculated in freq_calc module
endmodule


module freq_calc(input logic [6:0] data_in[`MAX_CHAR_LENGTH], input logic data_en, output node_t node[`MAX_CHAR_LENGTH], output integer count);
//integer node[char];   //like an hash node[a] = frequency- not synthesizable 

//node_t node[`MAX_CHAR_LENGTH];
integer cnt, index;    //initially 0

//for now able to calculate frequency properly, but had to delete the extra nodes: FIXME????
  always_comb begin
    if (data_en) begin
        foreach(data_in[i]) begin
            cnt = 1;
            index = i;
            node[index].frequency = 0;
            node[index].left_node = 0;   //ascii valud of null
            node[index].right_node = 0;
            node[index].is_leaf_node = 1'b1;
            //compare against the existing nodes
            for (int j=0; j< i; j++) begin
                if (data_in[i] == node[j].ascii_char) begin
                    cnt = node[j].frequency + 1;
                    index = j;
                end
            end //for loop
                    node[index].ascii_char = data_in[i];
                    node[index].frequency = cnt;
        end
    end
  end

  always_comb begin
    count = cnt;
  end
endmodule 

module comparator(input node_t node[`MAX_CHAR_LENGTH], output node_t min_node, output node_t second_min_node);

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
    // min_node = node[0];
    // second_min_node = node[1];
    if (`DEBUG) begin
        $display("node inside consideration: %p\n", node[j]);
    end
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

module node_sorter(input node_t node[`MAX_CHAR_LENGTH], output node_t output_node[`MAX_CHAR_LENGTH]);
 
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

node_t temp_node;
 //swap and sort
always_comb begin
    for (int i=0; i< count; i++) begin
        output_node = node;
    end
for(int j=0; j< count-1; j++)  begin  //if non-zero frequency ??FIXME
     if (`DEBUG) begin
        $display("node inside consideration: %p\n", node[j]);
    end
    if (output_node[j].frequency > output_node[j+1].frequency) begin
        temp_node = output_node[j];
        output_node[j] = output_node[j+1];
        output_node[j+1] = temp_node;
    end
end
end   
endmodule

module merge_nodes(input node_t min_node, input node_t second_min_node, output node_t merged_node);
//should inside loop
always_comb begin
    merged_node.ascii_char =  {min_node.ascii_char,second_min_node.ascii_char};
    merged_node.frequency = min_node.frequency + second_min_node.frequency;
    merged_node.left_node = min_node.ascii_char;
    merged_node.right_node = second_min_node.ascii_char;
    merged_node.is_leaf_node = 1'b0;    
end
endmodule


//instead send the entire node list and keep on finding the internal node
//original list of nodes(leaf nodes) created is sent as an input
//FIXME- yet to fix the dimension of output encoded value  
//node 0 and node 1 are first and second minimum
//count-1 times sort plus and merge action with decreasing count every level
//hence create an 2-D array of that dimension 
module binary_tree_node (input integer count, input node_t input_node[`MAX_CHAR_LENGTH], output logic[2*6+2:0] encoded_value[`MAX_CHAR_LENGTH]);
node_t min_node, second_min_node, merged_node;
node_t min_node_tmp, second_min_node_tmp, merge_node_tmp;
node_t in_huff_tree[0:`MAX_CHAR_LENGTH][0:`MAX_CHAR_LENGTH], out_huff_tree[0:`MAX_CHAR_LENGTH][0:`MAX_CHAR_LENGTH]; //size is  fixed now, can change based on level and number of elements required- FIXME???
node_t merged_nodes_list[0:`MAX_CHAR_LENGTH];

//create an array of some struct to indicate parent and child index of size 2*count (2*MAX for now)
//Ignore 0th index
//Root node is in index 1
//Start allocating from bottom of the array
//new struct --> ascii-freq-is_leaf_node-parent-left_node-right_node-encoding
//traverse the array to produce the encoded value 

//defining index as integer is waste of resource - can be clog2(2*count) - FIXME???

//non leaf node- then check for it's child nodes and search recursively to assign parent and child fields 



huff_tree_node_t huff_tree[(`MAX_CHAR_LENGTH*2)+1];

//only for 0th level
always_comb begin
    merged_nodes_list[0] = input_node[0];
    for (int i=0; i< `MAX_CHAR_LENGTH; i++) begin
        in_huff_tree[0][i] = input_node[i];  
    end
    for(int j=0; j< `MAX_CHAR_LENGTH; j++) begin
        encoded_value[j] = 'bz;
    end
end


genvar level, cnt;
//initialize everything to `bz
/*
always_comb begin
    for (int i=0; i <= (2*`MAX_CHAR_LENGTH); i++) begin
        huff_tree[i].ascii_char = 'bz;
        huff_tree[i].frequency = 0;
        huff_tree[i].is_leaf_node = 1'b0;
        huff_tree[i].parent = 'b0;
        huff_tree[i].left_node = 'b0;
        huff_tree[i].right_node = 'b0;
    end
end
*/
    int j;    
    generate
    for (level=0; level < 3-1; level++) begin 
        node_sorter node_sorter_ins_level(.node(in_huff_tree[level][0:`MAX_CHAR_LENGTH-1]), .output_node(out_huff_tree[level][0:`MAX_CHAR_LENGTH-1]));
        merge_nodes merge_nodes_ins_level(.min_node(out_huff_tree[level][0]), .second_min_node(out_huff_tree[level][1]), .merged_node(merged_nodes_list[level+1]));
      assign in_huff_tree[level+1][0:`MAX_CHAR_LENGTH-1] = {merged_nodes_list[level+1],out_huff_tree[level][2:`MAX_CHAR_LENGTH]};
  
    end
    endgenerate

    always_comb begin
        //initializing 
        for (int i=0; i <= (2*`MAX_CHAR_LENGTH); i++) begin
            huff_tree[i].ascii_char = 'bz;
            huff_tree[i].frequency = 0;
            huff_tree[i].is_leaf_node = 1'b0;
            huff_tree[i].parent = 'b0;
            huff_tree[i].left_node = 'b0;
            huff_tree[i].right_node = 'b0;
        end

        for (int l=0; l< count; l++) begin
            j = count - 1- l;
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
    end
    end


//Algorithm
//1. First sort the input node list, find 1st and 2nd minimum 
//2. Allocate them to huff_tree, assign only is_leaf_node, child nodes (not parent node)
//3. Merge nodes--> create internal node- sort and then add to huff tree -repeat 
//4. Iterate until root node 
//5. Start from i=count-1, left_node=2i, right_node=2i+1 (i decrementing from count-1 to 0)






endmodule

module tb_top;
  logic [6:0] data_in[`MAX_CHAR_LENGTH];
  logic [2*6+2:0] encoded_value[`MAX_CHAR_LENGTH];
  integer char_length;  //FIXME later
  logic data_en;
  node_t node[`MAX_CHAR_LENGTH];
  integer count;
  string input_string;

//Instantiate the module that you need to verify
   freq_calc DUT(.data_in(data_in), .data_en(data_en), .node(node), .count(count)); 
 //  comparator DUT1(.node(DUT.node), .min_node(), .second_min_node());
 //  node_sorter DUT2(.node(DUT.node), .output_node());
    binary_tree_node DUT3(.count(count), .input_node(DUT.node), .encoded_value());
 //   huff_encoder DUT(.data_in(data_in), .data_en(data_en), .encoded_value(encoded_value));

    initial begin
      //  data_in = '{"a","e"," ","a","a"};
        input_string = "ae aa"; //should be able to read an input file with many strings
        foreach(input_string[i]) begin
            data_in[i] = {input_string[i]};
        end
        data_en = 1'b1;

   //SEE LATER: #100 data_en = 1'b0;
   #100;
   $finish;
    end

    always_comb begin
        $display("Input data: data_in:%p\n", data_in);
       //   $display("comparator results: node:%p, count=%d, min_node=%p, second_min_node=%p\n", DUT1.node, DUT1.count, DUT1.min_node, DUT1.second_min_node);
 //       $display("sorter results: input_node:%p,\n output_node:%p\n", DUT2.node, DUT2.output_node);
    //   $display("huffman encoder: INPUT: created node :%p\n", DUT.node);
       $display("Input node[0]:%p\n", DUT.node);
       for (int i=0; i<= 2*`MAX_CHAR_LENGTH; i++) begin
       $display("binary_tree:  huff_tree[%0d]:%p\n", i, DUT3.huff_tree[i]);
    end
    end
endmodule 