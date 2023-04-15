//sequential comparator 
`define MAX_CHAR_COUNT 4


module comparator(input logic clk, input logic reset, input logic compare_start, input integer num_of_bits, input logic [8:0] A, input logic [8:0] B, output logic is_compare_done, output logic is_equal, output logic is_greater, output logic is_less_than);

logic break1, break2;
integer m;
//1-bit comparator 
always_ff @(posedge clk) begin
    if (reset) begin
    //    m <= num_of_bits;
        break1 <= 1'b1; //reset everytime for new input
        break2 <= 1'b1;
        is_compare_done <= 1'b0;
        is_greater <= 'b0;
        is_equal <= 'b0;
        is_less_than <= 'b0;
        m <= 'b0;
    end
    else begin

    if (break1 && compare_start) begin
            m <= num_of_bits - 1'b1; 
            is_compare_done <= 1'b0;
            break2 <= 1'b0;
            break1 <= break2;
    end
    else if (!is_compare_done) begin
        if (A[m] > B[m]) begin  //greater than
            is_greater <= 1'b1;
            is_compare_done <= 1'b1;
        end
        else if (A[m] < B[m]) begin
            is_less_than <= 1'b1;
            is_compare_done <= 1'b1;
        end
        else if ((A[m] == B[m]) && (m != 'b0)) begin
        //    is_equal <= 1'b1;
            is_compare_done <= 1'b0;
        end
        else begin  //when m=0
            is_equal <= 1'b1;
            is_compare_done <= 1'b1;
        end
        m <= m - 1'b1;
   end
    end //else 

end

endmodule