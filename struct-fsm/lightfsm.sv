// Resettable D Flip-Flop
module flopr(
  input  logic clk, reset, d,
  output logic q
);
  always_ff @(posedge clk or posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module lightfsm(
  input  logic clk,
  input  logic reset,
  input  logic left, right,
  output logic la, lb, lc, ra, rb, rc
);

  // Current State Bits and Inverted Variants
  logic s2, s1, s0;
  logic s2b, s1b, s0b;
  logic leftb, rightb;

  // Next-State D Inputs
  logic d2, d0, d1;

  // Product terms for state transitions
  logic p_l1, p_l2, p_l3;
  logic p_r1, p_r2, p_r3;
  logic p_haz;

  // Inverters
  not g_lb(leftb, left);
  not g_rb(rightb, right);
  not g_s2(s2b, s2);
  not g_s1(s1b, s1);
  not g_s0(s0b, s0);

  // -------------------------------------------------------------
  // 1. Next-State Logic (Product Terms)
  // -------------------------------------------------------------
  
  // From OFF (000): Go to L1 (001) if left & ~right
  and g_p_l1(p_l1, s2b, s1b, s0b, left, rightb);

  // From L1 (001): Go to L2 (010) unconditionally
  and g_p_l2(p_l2, s2b, s1b, s0);

  // From L2 (010): Go to L3 (011) unconditionally
  and g_p_l3(p_l3, s2b, s1, s0b);

  // From OFF (000): Go to R1 (100) if right & ~left
  and g_p_r1(p_r1, s2b, s1b, s0b, leftb, right);

  // From R1 (100): Go to R2 (101) unconditionally
  and g_p_r2(p_r2, s2, s1b, s0b);

  // From R2 (101): Go to R3 (110) unconditionally
  and g_p_r3(p_r3, s2, s1b, s0);

  // From OFF (000): Go to HAZ (111) if left & right
  and g_p_haz(p_haz, s2b, s1b, s0b, left, right);

  // -------------------------------------------------------------
  // 2. Next-State OR-Gating for D Flip-Flop Inputs
  // -------------------------------------------------------------
  // D2 = R1_next | R2_next | R3_next | HAZ_next
  or g_d2(d2, p_r1, p_r2, p_r3, p_haz);

  // D1 = L2_next | L3_next | R3_next | HAZ_next
  or g_d1(d1, p_l2, p_l3, p_r3, p_haz);

  // D0 = L1_next | L3_next | R2_next | HAZ_next
  or g_d0(d0, p_l1, p_l3, p_r2, p_haz);

  // -------------------------------------------------------------
  // 3. State Registers
  // -------------------------------------------------------------
  flopr ff2(.clk(clk), .reset(reset), .d(d2), .q(s2));
  flopr ff1(.clk(clk), .reset(reset), .d(d1), .q(s1));
  flopr ff0(.clk(clk), .reset(reset), .d(d0), .q(s0));

  // -------------------------------------------------------------
  // 4. Output Logic (Moore: Standard Logic from State Bits S2, S1, S0)
  // -------------------------------------------------------------
  
  // LA: ON during L1 (001), L2 (010), L3 (011), HAZ (111) -> (s2b AND (s1 OR s0)) OR (s2 AND s1 AND s0)
  logic term_la1, term_la_or;
  or  g_la_or(term_la_or, s1, s0);
  and g_la1(term_la1, s2b, term_la_or);
  logic term_haz;
  and g_haz_st(term_haz, s2, s1, s0);
  or  g_la_out(la, term_la1, term_haz);

  // LB: ON during L2 (010), L3 (011), HAZ (111) -> (s2b AND s1) OR HAZ
  logic term_lb1;
  and g_lb1(term_lb1, s2b, s1);
  or  g_lb_out(lb, term_lb1, term_haz);

  // LC: ON during L3 (011), HAZ (111) -> (s2b AND s1 AND s0) OR HAZ
  logic term_lc1;
  and g_lc1(term_lc1, s2b, s1, s0);
  or  g_lc_out(lc, term_lc1, term_haz);

  // RA: ON during R1 (100), R2 (101), R3 (110), HAZ (111) -> s2 is 1 for all these states!
  buf g_ra_out(ra, s2);

  // RB: ON during R2 (101), R3 (110), HAZ (111) -> (s2 AND (s1 OR s0))
  logic term_rb_or;
  or  g_rb_or(term_rb_or, s1, s0);
  and g_rb_out(rb, s2, term_rb_or);

  // RC: ON during R3 (110), HAZ (111) -> (s2 AND s1)
  and g_rc_out(rc, s2, s1);

endmodule
module testbench(); 
  logic        clk, reset;
  logic        left, right, la, lb, lc, ra, rb, rc;
  logic [5:0]  expected;
  logic [6:0]  hash;
  logic [31:0] vectornum, errors;
  logic [7:0]  testvectors[10000:0];

  // instantiate device under test 
  lightfsm dut(clk, reset, left, right, la, lb, lc, ra, rb, rc); 

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors and pulse reset
  initial 
    begin
      $readmemb("lightfsm.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0; 
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {left, right, expected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) 
    if (~reset) begin    // skip during reset
      if ({la, lb, lc, ra, rb, rc} !== expected) begin // check result 
        $display("Error: inputs = %b", {left, right});
        $display(" outputs = %b %b %b %b %b %b (%b expected)", 
          la, lb, lc, ra, rb, rc, expected); 
        errors = errors + 1; 
      end
      vectornum = vectornum + 1;
      hash = hash ^ {la, lb, lc, ra, rb, rc};
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 8'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors); 
        $display("Hash: %h", hash);
        $stop; 
      end 
    end 
endmodule 
 
