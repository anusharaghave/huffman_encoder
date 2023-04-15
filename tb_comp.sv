module tb_comp;

logic [8:0] A, B;
logic clk, reset, compare_start, is_compare_done, is_equal, is_greater, is_less_than; 
integer cycle;

comparator dut(.clk(clk), .reset(reset), .compare_start(compare_start), .num_of_bits(9), .A(A), .B(B), .is_compare_done(is_compare_done), .is_equal(is_equal), .is_greater(is_greater), .is_less_than(is_less_than));

initial begin
    clk = 1'b0;
    A = 9'hfe;
    B = 9'hff; //B > A

     A = 9'hff;
    B = 9'hef; //A > B

     A = 9'h22;
     B = 9'h22; //B = A
    compare_start = 1'b1;
   // cycle = 1'b0;
    reset = 1'b1;
    #5 reset = 1'b0;
    #30;
  //  $finish;
end

always begin
    #0.5 clk = ~clk;    //MHz
end

always_ff @(posedge clk) begin
    if (reset) begin
        cycle = 'b0;
    end
    else if (compare_start && !is_compare_done) begin
        cycle = cycle + 1;
    end
end

always @(is_compare_done) begin
   if (is_compare_done) begin
    #4 $finish;
   end
end

always_ff @(posedge clk) begin
    $display("cycle:%d\n", cycle);
    $display("A:%b, B:%b\n", A, B);
    $display("is_compare_done:%b, m:%d\n", is_compare_done, dut.m);
    $display("is_greater:%b, is_equal:%b, is_less_than:%b\n", is_greater, is_equal, is_less_than);
end

endmodule