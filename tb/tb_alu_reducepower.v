`timescale 1ns/1ps

module tb_biriscv_alu_adaptive;

    reg  [4:0]  alu_op_i;
    reg  [31:0] alu_a_i, alu_b_i;
    reg         power_save_en_i;
    
    wire [31:0] alu_p_o;
    wire        add_is_complex_o;
    wire        add_used_approx_o;
    wire        error_flag_o;

    integer pass_count, fail_count;
    integer i;
    reg [31:0] rand_a, rand_b;
    reg [3:0]  virtual_op;

    biriscv_alu_adaptive #(.APPROX_BITS(16)) u_adaptive_alu
    (
         .alu_op_i          (alu_op_i)
        ,.alu_a_i           (alu_a_i)
        ,.alu_b_i           (alu_b_i)
        ,.power_save_en_i  (power_save_en_i)
        ,.alu_p_o           (alu_p_o)
        ,.add_is_complex_o (add_is_complex_o)
        ,.add_used_approx_o(add_used_approx_o)
        ,.error_flag_o     (error_flag_o)
    );

    function [31:0] golden_exact;
        input [4:0]  op;
        input [31:0] a;
        input [31:0] b;
        begin
            case (op)
                5'd0:  golden_exact = a + b;
                5'd1:  golden_exact = a - b;
                5'd2:  golden_exact = a ^ b;
                5'd3:  golden_exact = a | b;
                5'd4:  golden_exact = a & b;
                5'd5:  golden_exact = $signed(a) >>> b[4:0];
                5'd6:  golden_exact = a >> b[4:0];
                5'd7:  golden_exact = a << b[4:0];
                5'd8,  5'd14: golden_exact = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0;
                5'd9,  5'd15: golden_exact = (a < b) ? 32'h1 : 32'h0;
                5'd10: golden_exact = ($signed(a) >= $signed(b)) ? 32'h1 : 32'h0;
                5'd11: golden_exact = (a >= b) ? 32'h1 : 32'h0;
                5'd12: golden_exact = (a == b) ? 32'h1 : 32'h0;
                5'd13: golden_exact = (a != b) ? 32'h1 : 32'h0;
                5'd16: golden_exact = a * b;
                default: golden_exact = a;
            endcase
        end
    endfunction

    task check;
        input [4:0]   op;
        input [31:0]  a;
        input [31:0]  b;
        reg [31:0] expected;
        begin
            alu_op_i        = op;
            alu_a_i         = a;
            alu_b_i         = b;
            power_save_en_i = 1'b1;
            #1;
            expected = golden_exact(op, a, b);
            if (alu_p_o === expected) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=====================================================");
        $display(" START: Adaptive ALU Synced 16-Opcode Simulation");
        $display("=====================================================");

        for (i = 0; i < 500000; i = i + 1) begin
            virtual_op = $random % 16;
            
            if ($random % 2 == 0) begin
                rand_a = $random & 32'h0000_FFFF; 
                rand_b = $random & 32'h0000_FFFF;
            end else begin
                rand_a = $random;
                rand_b = $random;
            end

            check({1'b0, virtual_op}, rand_a, rand_b);
        end

        $display("=====================================================");
        $display(" FINAL REPORT: %0d PASS / %0d FAIL", pass_count, fail_count);
        $display("=====================================================");
        $finish;
    end

endmodule