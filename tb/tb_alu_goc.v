`timescale 1ns/1ps

module tb_ibex_alu_rv32imc;

    reg  [3:0]  operator_i;
    reg  [31:0] operand_a_i, operand_b_i;
    reg  [32:0] multdiv_operand_a_i, multdiv_operand_b_i;
    reg         multdiv_sel_i;

    wire [31:0] adder_result_o;
    wire [33:0] adder_result_ext_o;
    wire [31:0] result_o;
    wire        comparison_result_o;
    wire        is_equal_result_o;

    integer pass_count, fail_count;
    integer i;
    
    // Khai báo các thanh ghi trung gian phát số ngẫu nhiên giống hệt bản Adaptive
    reg [31:0] rand_a, rand_b;
    reg [3:0]  virtual_op;

    ibex_alu_rv32imc u_alu
    (
        .operator_i          (operator_i),
        .operand_a_i         (operand_a_i),
        .operand_b_i         (operand_b_i),
        .multdiv_operand_a_i (multdiv_operand_a_i),
        .multdiv_operand_b_i (multdiv_operand_b_i),
        .multdiv_sel_i       (multdiv_sel_i),
        .adder_result_o      (adder_result_o),
        .adder_result_ext_o  (adder_result_ext_o),
        .result_o            (result_o),
        .comparison_result_o (comparison_result_o),
        .is_equal_result_o   (is_equal_result_o)
    );

    function [31:0] golden_result;
        input [3:0]  op;
        input [31:0] a;
        input [31:0] b;
        reg [4:0] shamt;
        begin
            shamt = b[4:0];
            case (op)
                `ALU_ADD  : golden_result = a + b;
                `ALU_SUB  : golden_result = a - b;
                `ALU_XOR  : golden_result = a ^ b;
                `ALU_OR   : golden_result = a | b;
                `ALU_AND  : golden_result = a & b;
                `ALU_SLL  : golden_result = a << shamt;
                `ALU_SRL  : golden_result = a >> shamt;
                `ALU_SRA  : golden_result = $signed(a) >>> shamt;
                `ALU_LT,
                `ALU_SLT  : golden_result = ($signed(a) <  $signed(b)) ? 32'h1 : 32'h0;
                `ALU_LTU,
                `ALU_SLTU : golden_result = (a < b) ? 32'h1 : 32'h0;
                `ALU_GE   : golden_result = ($signed(a) >= $signed(b)) ? 32'h1 : 32'h0;
                `ALU_GEU  : golden_result = (a >= b) ? 32'h1 : 32'h0;
                `ALU_EQ   : golden_result = (a == b) ? 32'h1 : 32'h0;
                `ALU_NE   : golden_result = (a != b) ? 32'h1 : 32'h0;
                default   : golden_result = 32'h0;
            endcase
        end
    endfunction

    task check;
        input [3:0]   op;
        input [31:0]  a;
        input [31:0]  b;
        reg [31:0] expected;
        begin
            operator_i    = op;
            operand_a_i   = a;
            operand_b_i   = b;
            multdiv_sel_i = 1'b0;
            #1;

            expected = golden_result(op, a, b);

            if (result_o === expected) pass_count = pass_count + 1;
            else begin
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        $display("=====================================================");
        $display(" Kiem tra ibex_alu_rv32imc.v (Phien ban Dong Bo)");
        $display("=====================================================");

        // Vòng lặp đồng bộ cấu trúc dữ liệu phát ngẫu nhiên y hệt bản Adaptive
        for (i = 0; i < 500000; i = i + 1) begin
            virtual_op = $random % 16;
            
            if ($random % 2 == 0) begin
                rand_a = $random & 32'h0000_FFFF; 
                rand_b = $random & 32'h0000_FFFF;
            end else begin
                rand_a = $random;
                rand_b = $random;
            end

            check(virtual_op, rand_a, rand_b);
        end

        $display("=====================================================");
        $display(" KET QUA: %0d PASS / %0d FAIL", pass_count, fail_count);
        $display("=====================================================");
        $finish;
    end

endmodule