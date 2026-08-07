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