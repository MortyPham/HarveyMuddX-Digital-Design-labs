module fulladder(input  logic a, b, cin,
                 output logic cout, s);
              
  logic n1, n2, n3;
  logic x1, x2, x3, x4, x5, x6, x7;
    
  nand g1(n1, a, b);
  nand g2(n2, a, cin);
  nand g3(n3, b, cin);
  nand g4(cout, n1, n2, n3);
  
  nand gx1(x1, a, b);
  nand gx2(x2, a, x1);
  nand gx3(x3, b, x1);
  nand gx4(x4, x2, x3);

  nand gx5(x5, x4, cin);
  nand gx6(x6, x4, x5);
  nand gx7(x7, cin, x5);
  nand gx8(s, x6, x7);
endmodule
