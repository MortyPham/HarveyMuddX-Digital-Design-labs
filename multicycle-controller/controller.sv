// controller.sv
//
// This file is for HMC E85A Lab 5.
// Place controller.tv in same computer directory as this file to test your multicycle controller.
//
// Starter code last updated by Ben Bracker (bbracker@hmc.edu) 1/14/21
// - added opcodetype enum
// - updated testbench and hash generator to accomodate don't cares as expected outputs
// Solution code by Minh (Ngoc) Pham

typedef enum logic[6:0] {r_type_op=7'b0110011, i_type_alu_op=7'b0010011, lw_op=7'b0000011, sw_op=7'b0100011, beq_op=7'b1100011, jal_op=7'b1101111} opcodetype;

typedef enum logic [3:0] {
    S0_FETCH    = 4'd0,
    S1_DECODE   = 4'd1,
    S2_MEMADR   = 4'd2,
    S3_MEMREAD  = 4'd3,
    S4_MEMWB    = 4'd4,
    S5_MEMWRITE = 4'd5,
    S6_EXECUTER = 4'd6,
    S7_ALUWB    = 4'd7,
    S8_EXECUTEI = 4'd8,
    S9_JAL      = 4'd9,
    S10_BEQ     = 4'd10
} state_t;

module controller(input  logic       clk,
                  input  logic       reset,  
                  input  opcodetype  op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ImmSrc,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite);
    state_t state, next_state;

    logic [1:0] ALUOp;
    logic       Branch, PCUpdate;

    // State Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= S0_FETCH;
        else
            state <= next_state;
    end

    // FSM State & Output Logic
    always_comb begin
        // Default Signal Assignments
        AdrSrc     = 1'b0;
        IRWrite    = 1'b0;
        RegWrite   = 1'b0;
        MemWrite   = 1'b0;
        PCUpdate   = 1'b0;
        Branch     = 1'b0;
        ALUSrcA    = 2'b00;
        ALUSrcB    = 2'b00;
        ResultSrc  = 2'b00;
        ALUOp      = 2'b00;
        next_state = S0_FETCH;

        case (state)
            S0_FETCH: begin
                AdrSrc     = 1'b0;
                IRWrite    = 1'b1;
                ALUSrcA    = 2'b00;
                ALUSrcB    = 2'b10;
                ALUOp      = 2'b00;
                ResultSrc  = 2'b10;
                PCUpdate   = 1'b1;
                next_state = S1_DECODE;
            end

            S1_DECODE: begin
                ALUSrcA = 2'b01;
                ALUSrcB = 2'b01;
                ALUOp   = 2'b00;
                
                case (op)
                    lw_op, sw_op:  next_state = S2_MEMADR;
                    r_type_op:     next_state = S6_EXECUTER;
                    i_type_alu_op: next_state = S8_EXECUTEI;
                    jal_op:        next_state = S9_JAL;
                    beq_op:        next_state = S10_BEQ;
                    default:       next_state = S0_FETCH;
                endcase
            end

            S2_MEMADR: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b01;
                ALUOp   = 2'b00;
                if (op == lw_op)      next_state = S3_MEMREAD;
                else if (op == sw_op) next_state = S5_MEMWRITE;
                else                  next_state = S0_FETCH;
            end

            S3_MEMREAD: begin
                ResultSrc  = 2'b00;
                AdrSrc     = 1'b1;
                next_state = S4_MEMWB;
            end

            S4_MEMWB: begin
                ResultSrc  = 2'b01;
                RegWrite   = 1'b1;
                next_state = S0_FETCH;
            end

            S5_MEMWRITE: begin
                ResultSrc  = 2'b00;
                AdrSrc     = 1'b1;
                MemWrite   = 1'b1;
                next_state = S0_FETCH;
            end

            S6_EXECUTER: begin
                ALUSrcA    = 2'b10;
                ALUSrcB    = 2'b00;
                ALUOp      = 2'b10;
                next_state = S7_ALUWB;
            end

            S7_ALUWB: begin
                ResultSrc  = 2'b00;
                RegWrite   = 1'b1;
                next_state = S0_FETCH;
            end

            S8_EXECUTEI: begin
                ALUSrcA    = 2'b10;
                ALUSrcB    = 2'b01;
                ALUOp      = 2'b10;
                next_state = S7_ALUWB;
            end

            S9_JAL: begin
                ALUSrcA    = 2'b01;
                ALUSrcB    = 2'b10;
                ALUOp      = 2'b00;
                ResultSrc  = 2'b00;
                PCUpdate   = 1'b1;
                next_state = S7_ALUWB;
            end

            S10_BEQ: begin
                ALUSrcA    = 2'b10;
                ALUSrcB    = 2'b00;
                ALUOp      = 2'b01;
                ResultSrc  = 2'b00;
                Branch     = 1'b1;
                next_state = S0_FETCH;
            end

            default: next_state = S0_FETCH;
        endcase
    end

    // Immediate Decoder
    always_comb begin
        case (op)
            lw_op, i_type_alu_op: ImmSrc = 2'b00;
            sw_op:                ImmSrc = 2'b01;
            beq_op:               ImmSrc = 2'b10;
            jal_op:               ImmSrc = 2'b11;
            default:              ImmSrc = 2'b00;
        endcase
    end

    // ALU Decoder
    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 3'b000;
            2'b01: ALUControl = 3'b001;
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if ((op == r_type_op) && funct7b5)
                            ALUControl = 3'b001;
                        else
                            ALUControl = 3'b000;
                    end
                    3'b010:  ALUControl = 3'b101;
                    3'b110:  ALUControl = 3'b011;
                    3'b111:  ALUControl = 3'b010;
                    default: ALUControl = 3'b000;
                endcase
            end
            default: ALUControl = 3'b000;
        endcase
    end

    assign PCWrite = PCUpdate | (Branch & Zero);
endmodule