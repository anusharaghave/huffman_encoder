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


//Optimizations
//1. remove frequency calculator module- frequency in should be within 7 (3 bits)
//2. sorting logic- use some fields of nodes (don't pass entire node list)   , also can only find min and second min 
//3. limit the characters that can be encoded - no much help
//4. Use huff tree[0] as root node- accordingly change the indexing
//5. Use only minimal subset of characters - like from a ('h61) to 0 ('h6F)


`timescale 1us/1ps

//5,3,2

//`define MAX_CHAR_COUNT 3
`define MAX_CHAR_COUNT 3    //fixed as increasing to 5 increases gates by 4 times
`define BIT_WIDTH 2


`define INIT 3'b000
`define DATA_COLLECT 3'b001
`define FREQ_CALC 3'b010
`define SORT 3'b011
`define MERGE_BUILD 3'b100
`define ENCODE 3'b101  
`define SEND_OUTPUT 3'b110


//left and right nodes are 0 for leaf nodes
typedef struct {
    logic [8:0] ascii_char; //7 max bits + 1
    //logic [4:0] ascii_char;
    logic [`MAX_CHAR_COUNT:0] frequency;
    logic is_leaf_node;
     logic [8:0] left_node;  //stores the index
     logic [8:0] right_node; //stores the index
} node_t;

typedef struct {
    logic [8:0] ascii_char; 
    //logic [9:0] ascii_char;
   // logic [2:0] frequency;
    logic is_leaf_node;
    logic [8:0] left_node;  //stores the index
    logic [8:0] right_node; //stores the index
    logic [`BIT_WIDTH-1:0] parent;
    logic [`BIT_WIDTH-1:0] level;
} huff_tree_node_t; 

//main encoder module  
module huff_encoder (input logic clk, input logic reset, input logic [`MAX_CHAR_COUNT-1:0][7:0] data_in, input logic [0:`MAX_CHAR_COUNT-1][2:0] freq_in, output logic [0:`MAX_CHAR_COUNT-1][`MAX_CHAR_COUNT-1:0] encoded_value, output logic [0:`MAX_CHAR_COUNT-1][`MAX_CHAR_COUNT-1:0] encoded_mask, output logic done);

logic [0:`MAX_CHAR_COUNT-1][6:0] character;
logic [`BIT_WIDTH-1:0] count;
logic [`MAX_CHAR_COUNT-1:0] odd_idx, even_idx;
node_t initial_node[`MAX_CHAR_COUNT];
logic [2:0] state;
huff_tree_node_t huff_tree[`MAX_CHAR_COUNT*2];
node_t in_huff_tree[0:`MAX_CHAR_COUNT-1];
node_t out_huff_tree[0:`MAX_CHAR_COUNT]; 
node_t merged_node; 

logic [`MAX_CHAR_COUNT-1:0] encoded_value_h[2*`MAX_CHAR_COUNT];


    freq_calc freq_calc_ins(.data_in(data_in), .freq_in(freq_in), .node(initial_node));
    node_sorter node_sorter_ins(.clk(clk), .input_node(in_huff_tree[0:`MAX_CHAR_COUNT-1]), .output_node(out_huff_tree[0:`MAX_CHAR_COUNT-1]));
    merge_nodes merge_nodes_ins(.min_node(out_huff_tree[0]), .second_min_node(out_huff_tree[1]), .merged_node(merged_node));

always_ff @(posedge clk) begin : huffman_enc
    if (reset) begin    //active high reset
        state <= `INIT;
     //   level = 'b0;
     //   m =0;
           for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
                encoded_value[i] = 'b0;
                encoded_mask[i] = 'b0;
                character[i] = 'b0;
                in_huff_tree[i].ascii_char = 'b0;
                in_huff_tree[i].frequency = 'b0;
                in_huff_tree[i].is_leaf_node = 'b0;
                in_huff_tree[i].left_node = 'b0;
                in_huff_tree[i].right_node = 'b0;
            end
    end

    else begin
    case (state) 
    
        `INIT : begin
            done = 'b0;
         //   ll = 'b0;
            
            for (int i=0; i < (2*`MAX_CHAR_COUNT); i++) begin
                encoded_value_h[i] = 'b0;
                huff_tree[i].ascii_char = 'b0;
                huff_tree[i].is_leaf_node = 1'b0;
                huff_tree[i].parent = 'b0;
                huff_tree[i].left_node = 'b0;
                huff_tree[i].right_node = 'b0;
                huff_tree[i].level = 'b0;
            end
            
            
        
                state <= `DATA_COLLECT;
            
        end

        `DATA_COLLECT: begin    
                state <= `FREQ_CALC;
        end

        `FREQ_CALC: begin
            count = `MAX_CHAR_COUNT;
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

        
            count = count - 1'b1;
            even_idx = (count << 1'b1);
            odd_idx = even_idx + 1'b1;
            //assigning child nodes and leaf node fields 
       
                huff_tree[even_idx].ascii_char = out_huff_tree[0].ascii_char; 
                huff_tree[odd_idx].ascii_char = out_huff_tree[1].ascii_char;
                huff_tree[even_idx].is_leaf_node = out_huff_tree[0].is_leaf_node;
                huff_tree[odd_idx].is_leaf_node = out_huff_tree[1].is_leaf_node;
                huff_tree[even_idx].left_node = out_huff_tree[0].left_node;
                huff_tree[odd_idx].left_node = out_huff_tree[1].left_node;
                huff_tree[even_idx].right_node = out_huff_tree[0].right_node;
                huff_tree[odd_idx].right_node = out_huff_tree[1].right_node;
        
                //assigning root node
                huff_tree[1].ascii_char = out_huff_tree[0].ascii_char;
                huff_tree[1].is_leaf_node = out_huff_tree[0].is_leaf_node;
                huff_tree[1].left_node = out_huff_tree[0].left_node;
                huff_tree[1].right_node = out_huff_tree[0].right_node;
               
           // if (count == 1'b0) begin
            if (!(count[0] | count[1])) begin    
                state <= `ENCODE;
            end
            else begin
                state <= `SORT;
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
        if (huff_tree[m].is_leaf_node != 1'b1) begin
        for (int n=2; n < (2*`MAX_CHAR_COUNT); n++) begin
            if ((huff_tree[n].ascii_char == huff_tree[m].left_node) | (huff_tree[n].ascii_char == huff_tree[m].right_node)) begin
                huff_tree[n].level = huff_tree[m].level + 1;
            end
        end
        end
    end

            for (int n=2; n < (2*`MAX_CHAR_COUNT); n++) begin  //1-root node
                if (huff_tree[n].parent != 1'b1) begin   
                    encoded_value_h[n] = (n[0]==1'b0) ? (encoded_value_h[huff_tree[n].parent] << 1'b1): ((encoded_value_h[huff_tree[n].parent] << 1'b1) | 1'b1);
                end
                else if (huff_tree[n].parent == 1'b1) begin
                    encoded_value_h[n][0] = (n[0]==1'b0) ? {1'b0}: {1'b1};
                end
            end
            state <= `SEND_OUTPUT;
        end

     //extract only encodings for unique characters 
    `SEND_OUTPUT: begin     //state=7

        foreach(data_in[i]) begin
        for (int n=1; n< (2*`MAX_CHAR_COUNT); n++) begin
            if (huff_tree[n].ascii_char == data_in[i]) begin
                encoded_mask[i] = (1'b1 << huff_tree[n].level)-1'b1;
             character[i] = huff_tree[n].ascii_char;
                encoded_value[i] = encoded_value_h[n];
                end //if loop
        end //for loop
        end

        done = 1'b1;    //used in SV tb to stop the simulation
        end

        default : begin
            state <= `INIT;
        end
    endcase
    end

end //posedge_clk

endmodule


module freq_calc(input logic [0:`MAX_CHAR_COUNT-1][7:0] data_in, input logic [0:`MAX_CHAR_COUNT-1][2:0] freq_in, output node_t node[`MAX_CHAR_COUNT]);

always_comb begin
        for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
        //    if (data_in[i] != 0) begin    //if commented this, you have to ensure all 3 char are always present
            node[i].ascii_char = data_in[i];
            node[i].frequency = freq_in[i];
            node[i].left_node = 'b0;   //ascii valud of null
            node[i].right_node = 'b0;
            node[i].is_leaf_node = 1'b1;
        //    end
        end
end

endmodule 


module node_sorter(input logic clk, input node_t input_node[`MAX_CHAR_COUNT], output node_t output_node[`MAX_CHAR_COUNT]);
 
node_t temp_node;
       always_ff @(posedge clk) begin
        for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
            output_node = input_node;
        end
        //sorting logic 
        for(int j=0; j< `MAX_CHAR_COUNT-1; j++)  begin  
            for (int k= 0; k< `MAX_CHAR_COUNT-1; k++) begin
                if (((output_node[k].frequency >= output_node[k+1].frequency) && (output_node[k].ascii_char > output_node[k+1].ascii_char)) || (output_node[k].frequency > output_node[k+1].frequency)) begin
                    temp_node = output_node[k];
                    output_node[k] = output_node[k+1];
                    output_node[k+1] = temp_node;
                    end

            end
        end
//    end
end   
endmodule

/*
//make it sequential 
module node_sorter1(input logic clk, input node_t input_node[`MAX_CHAR_COUNT], output node_t output_node[`MAX_CHAR_COUNT]);
 
node_t temp_node;
       always_ff @(posedge clk) begin
        for (int i=0; i< `MAX_CHAR_COUNT; i++) begin
            output_node = input_node;
        end
        //sorting logic 
        for(int j=0; j< `MAX_CHAR_COUNT-1; j++)  begin  
            for (int k= 0; k< `MAX_CHAR_COUNT-1; k++) begin
            //    if (!(output_node[k].ascii_char == 0 || output_node[k+1].ascii_char == 0)) begin
                if ((output_node[k].frequency >= output_node[k+1].frequency) && (output_node[k].ascii_char > output_node[k+1].ascii_char)) begin
                //    if (output_node[k].ascii_char > output_node[k+1].ascii_char) begin
                    temp_node = output_node[k];
                    output_node[k] = output_node[k+1];
                    output_node[k+1] = temp_node;
                    end
            end
        end
//    end
end 
endmodule
*/

module merge_nodes(input node_t min_node, input node_t second_min_node, output node_t merged_node);
//always_comb begin
    assign merged_node.ascii_char =  min_node.ascii_char + second_min_node.ascii_char;    
    assign merged_node.frequency = min_node.frequency + second_min_node.frequency;
    assign merged_node.left_node = min_node.ascii_char;
    assign merged_node.right_node = second_min_node.ascii_char;
    assign merged_node.is_leaf_node = 1'b0; 
//end   
endmodule

