module aludecoder(input  logic [1:0] ALUOp,
                  input  logic [2:0] funct3,
                  input  logic op_5, funct7_5,
                  output logic [2:0] ALUControl);
    wire funct3_2_n;
    wire funct3_1_n;
    wire funct3_0_n;
    wire ALUOp_0_n;
    wire ALUOp_1_n;

    not g_n2 (funct3_2_n, funct3[2]);
    not g_n1 (funct3_1_n, funct3[1]);
    not g_n0 (funct3_0_n, funct3[0]);
    not g_n3 (ALUOp_0_n, ALUOp[0]);
    not g_n4 (ALUOp_1_n, ALUOp[1]);

    and g_ctrl2 (ALUControl[2], ALUOp[1], funct3[1], funct3_2_n, funct3_0_n, ALUOp_0_n);

    and g_ctrl1 (ALUControl[1], ALUOp[1], ALUOp_0_n, funct3[2], funct3[1]);

    wire sub_op_match;
    wire sub_term;
    wire slt_or_term;
    wire rtype_or;
    wire rtype_combined;
    wire ALUOp_and;

    and g_sub_op (sub_op_match, op_5, funct7_5);

    and g_sub_term (sub_term, funct3_2_n, funct3_1_n, funct3_0_n, sub_op_match);

    and g_slt_or (slt_or_term, funct3[1], funct3_0_n);

    or  g_rtype_or (rtype_or, slt_or_term, sub_term);

    and g_rtype_and (rtype_combined, ALUOp_0_n, ALUOp[1], rtype_or);

    and g_ALUOp_and (ALUOp_and, ALUOp[0], ALUOp_1_n);

    or  g_ctrl0 (ALUControl[0], ALUOp_and, rtype_combined);
    
endmodule