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

  logic s2, s1, s0;
  logic s2b, s1b, s0b;
  logic leftb, rightb;

  logic d2, d0, d1;

  logic p_l1, p_l2, p_l3;
  logic p_r1, p_r2, p_r3;
  logic p_haz;

  not g_lb(leftb, left);
  not g_rb(rightb, right);
  not g_s2(s2b, s2);
  not g_s1(s1b, s1);
  not g_s0(s0b, s0);

  and g_p_l1(p_l1, s2b, s1b, s0b, left, rightb);

  and g_p_l2(p_l2, s2b, s1b, s0);

  and g_p_l3(p_l3, s2b, s1, s0b);

  and g_p_r1(p_r1, s2b, s1b, s0b, leftb, right);

  and g_p_r2(p_r2, s2, s1b, s0b);

  and g_p_r3(p_r3, s2, s1b, s0);

  and g_p_haz(p_haz, s2b, s1b, s0b, left, right);

  or g_d2(d2, p_r1, p_r2, p_r3, p_haz);

  or g_d1(d1, p_l2, p_l3, p_r3, p_haz);

  or g_d0(d0, p_l1, p_l3, p_r2, p_haz);

  flopr ff2(.clk(clk), .reset(reset), .d(d2), .q(s2));
  flopr ff1(.clk(clk), .reset(reset), .d(d1), .q(s1));
  flopr ff0(.clk(clk), .reset(reset), .d(d0), .q(s0));

  logic term_la1, term_la_or;
  or  g_la_or(term_la_or, s1, s0);
  and g_la1(term_la1, s2b, term_la_or);
  logic term_haz;
  and g_haz_st(term_haz, s2, s1, s0);
  or  g_la_out(la, term_la1, term_haz);

  logic term_lb1;
  and g_lb1(term_lb1, s2b, s1);
  or  g_lb_out(lb, term_lb1, term_haz);

  logic term_lc1;
  and g_lc1(term_lc1, s2b, s1, s0);
  or  g_lc_out(lc, term_lc1, term_haz);

  buf g_ra_out(ra, s2);

  logic term_rb_or;
  or  g_rb_or(term_rb_or, s1, s0);
  and g_rb_out(rb, s2, term_rb_or)

  and g_rc_out(rc, s2, s1);

endmodule
