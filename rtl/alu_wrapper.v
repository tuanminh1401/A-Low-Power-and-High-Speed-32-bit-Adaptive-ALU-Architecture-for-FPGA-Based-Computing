module alu_wrapper (
    input wire        clk,
    input wire        rst_n,
    input wire [4:0]  alu_op_i,
    input wire [31:0] alu_a_i,
    input wire [31:0] alu_b_i,
    input wire        power_save_en_i,
    output reg [31:0] alu_p_o
);
    // Thanh ghi chốt đầu vào
    reg [4:0]  op_r;
    reg [31:0] a_r, b_r;
    reg        ps_r;
    wire [31:0] alu_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_r    <= 5'd0;
            a_r     <= 32'd0;
            b_r     <= 32'd0;
            ps_r    <= 1'b0;
            alu_p_o <= 32'd0;
        end else begin
            op_r    <= alu_op_i;
            a_r     <= alu_a_i;
            b_r     <= alu_b_i;
            ps_r    <= power_save_en_i;
            alu_p_o <= alu_out; // Chốt kết quả đầu ra
        end
    end

    // Gọi module ALU của bạn (chọn bản adaptive hoặc alu_top)
    biriscv_alu_adaptive u_alu (
        .alu_op_i(op_r),
        .alu_a_i(a_r),
        .alu_b_i(b_r),
        .power_save_en_i(ps_r),
        .alu_p_o(alu_out)
    );
endmodule