module adventuregame(
  input  logic clk, reset,
  input  logic n, s, e, w,
  output logic win, die
);

  logic vsword;
  logic in_stash;

  roomfsm room (
    .clk(clk),
    .reset(reset),
    .n(n), .s(s), .e(e), .w(w),
    .vsword(vsword),
    .in_stash(in_stash),
    .win(win),
    .die(die)
  );

  swordfsm sword (
    .clk(clk),
    .reset(reset),
    .in_stash(in_stash),
    .vsword(vsword)
  );

endmodule

module roomfsm(
  input  logic clk, reset,
  input  logic n, s, e, w,
  input  logic vsword,
  output logic in_stash,
  output logic win, die
);

  typedef enum logic [2:0] {
    CAVE     = 3'b000,
    TUNNEL   = 3'b001,
    RIVER    = 3'b010,
    STASH    = 3'b011,
    DEN      = 3'b100,
    VAULT    = 3'b101,
    GRAVE    = 3'b110
  } statetype;

  statetype state, nextstate;

  always_ff @(posedge clk or posedge reset)
    if (reset) state <= CAVE;
    else state <= nextstate;

  always_comb begin
    case (state)
      CAVE:   if (e) nextstate = TUNNEL; else nextstate = CAVE;
      TUNNEL: if (w) nextstate = CAVE; else if (s) nextstate = RIVER; else nextstate = TUNNEL;
      RIVER:  if (n) nextstate = TUNNEL; else if (w) nextstate = STASH; else if (e) nextstate = DEN; else nextstate = RIVER;
      STASH:  if (e) nextstate = RIVER; else nextstate = STASH;
      DEN:    if (vsword) nextstate = VAULT; else nextstate = GRAVE;
      VAULT:  nextstate = VAULT;
      GRAVE:  nextstate = GRAVE;
      default: nextstate = CAVE;
    endcase
  end

  assign in_stash = (state == STASH);
  assign win = (state == VAULT);
  assign die = (state == GRAVE);

endmodule

module swordfsm(
  input  logic clk, reset,
  input  logic in_stash,
  output logic vsword
);

  typedef enum logic {
    NOSWORD = 1'b0,
    HASWORD = 1'b1
  } statetype;

  statetype state, nextstate;

  always_ff @(posedge clk or posedge reset)
    if (reset) state <= NOSWORD;
    else state <= nextstate;

  always_comb begin
    case (state)
      NOSWORD: if (in_stash) nextstate = HASWORD; else nextstate = NOSWORD;
      HASWORD: nextstate = HASWORD;
      default: nextstate = NOSWORD;
    endcase
  end

  assign vsword = (state == HASWORD);

endmodule

module testbench(); 
  logic        clk, reset;
  logic        n, s, e, w, win, die, winexpected, dieexpected;
  logic [31:0] vectornum, errors;
  logic [5:0]  testvectors[10000:0];
  logic [6:0]  hash;

  // instantiate device under test 
  adventuregame  dut(clk, reset, n, s, e, w, win, die); 

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors 
  // and pulse reset
  initial 
    begin
      $readmemb("adventuregame.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0; #70; reset = 1; #10; reset = 0;
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {n, s, e, w, winexpected, dieexpected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) 
    if (~reset) begin    // skip during reset
      if (win !== winexpected || die !== dieexpected) begin // check result 
        $display("Error: inputs = %b", {n, s, e, w});
        $display(" state = %b", dut.room.state);
        $display(" outputs = %b %b (%b %b expected)", 
                 win, die, winexpected, dieexpected); 
        errors = errors + 1; 
      end
      hash = hash ^ {win, die};
      hash = {hash[5:0], hash[6]^hash[5]};
      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 6'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors); 
        $display("hash: %h", hash);
        $stop; 
      end 
    end 
endmodule 

