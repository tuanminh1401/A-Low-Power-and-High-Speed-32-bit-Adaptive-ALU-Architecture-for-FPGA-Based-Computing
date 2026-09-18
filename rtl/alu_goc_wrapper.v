module alu_goc_wrapper (
    input wire        clk,
    input wire        rst_n,
    input wire [3:0]  operator_i,
    input wire [31:0] operand_a_i,
    input wire [31:0] operand_b_i,
    output reg [31:0] result_o
);
    reg [3:0]  op_r;
    reg [31:0] a_r, b_r;
    wire [31:0] alu_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_r     <= 4'd0;
            a_r      <= 32'd0;
            b_r      <= 32'd0;
            result_o <= 32'd0;
        end else begin
            op_r     <= operator_i;
            a_r      <= operand_a_i;
            b_r      <= operand_b_i;
            result_o <= alu_out;
        end
    end

    ibex_alu_rv32imc u_alu_goc (
        .operator_i          (op_r),
        .operand_a_i         (a_r),
        .operand_b_i         (b_r),
        .multdiv_operand_a_i (33'd0),
        .multdiv_operand_b_i (33'd0),
        .multdiv_sel_i       (1'b0),
        .adder_result_o      (),
        .adder_result_ext_o  (),
        .result_o            (alu_out),
        .comparison_result_o (),
        .is_equal_result_o   ()
    );
endmodule
