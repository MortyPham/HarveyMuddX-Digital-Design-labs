module fulladder(input  logic a, b, cin,
                 output logic cout, s);
              
  logic n1, n2, n3;
  
  and g1(n1, a, b);
  and g2(n2, a, cin);
  and g3(n3, b, cin);
  or g4(cout, n1, n2, n2);

  xor g5(s, a, b, cin); 
endmodule