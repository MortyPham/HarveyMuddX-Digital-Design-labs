module twoscomp(
    input  logic clk,
    input  logic reset,
    input  logic a,
    output logic n
);
    logic ab;    
    logic s;      
    logic sb;       
    logic nextS;  

    logic node1, node2;

    not g1(ab, a);

    and g2(nextS, ab, s);

    flops state_reg (
        .clk(clk),
        .reset(reset),
        .d(nextS),
        .q(s)
    );

    not g3(sb, s);
    and g4(node1, a, s);
    and g5(node2, ab, sb);
    or  g6(n, node1, node2);

endmodule

// flip-flop
module flop(input  logic clk, d,
         output logic q);
            
  always_ff @(posedge clk)
    q <= d;
endmodule


// asynchronously resettable flip-flop
module flopr(input  logic clk, reset, d,
            output logic q);
            
  always_ff @(posedge clk or posedge reset)
    if (reset) q <= 0; // resets state to 0 on reset
    else       q <= d;
endmodule

// asynchronously settable flip-flop
module flops(input  logic clk, reset, d,
            output logic q);
            
  always_ff @(posedge clk or posedge reset)
    if (reset) q <= 1;  // sets state to 1 on reset
    else       q <= d;
endmodule	
 
