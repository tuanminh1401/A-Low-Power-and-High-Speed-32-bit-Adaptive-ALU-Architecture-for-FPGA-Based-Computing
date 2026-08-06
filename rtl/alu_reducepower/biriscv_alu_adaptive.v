module biriscv_alu_adaptive
#(
    parameter APPROX_BITS = 16
)
(
     input  [ 4:0]  alu_op_i //ngõ vào mã lệnh 5 bit (mở rộng lên 32 lệnh)
    ,input  [31:0]  alu_a_i //đường bus dữ liệu vào a
    ,input  [31:0]  alu_b_i //đường bus dữ liệu vào b
    ,input          power_save_en_i //tín hiệu điều khiển chế độ tiết kiệm năng lượng

    ,output [31:0]  alu_p_o //bus ngõ ra, trả kết quả
    ,output         add_is_complex_o //cờ ra báo hiệu trạng thái dữ liệu đầu vào là phức tạp
    ,output         add_used_approx_o //cờ ra bảo hiệu ALU đang kích hoạt mạch cộng xấp xỉ để tiết kiệm điện
    ,output         error_flag_o //cờ cảnh báo lỗi phần cứng vật lý (nối ra led) để báo tràn khi chạy xấp xỉ
);

`define ALU_ADD   5'd0
`define ALU_SUB   5'd1
`define ALU_XOR   5'd2
`define ALU_OR    5'd3
`define ALU_AND   5'd4
`define ALU_SRA   5'd5
`define ALU_SRL   5'd6
`define ALU_SLL   5'd7
`define ALU_LT    5'd8
`define ALU_LTU   5'd9
`define ALU_GE    5'd10
`define ALU_GEU   5'd11
`define ALU_EQ    5'd12
`define ALU_NE    5'd13
`define ALU_SLT   5'd14
`define ALU_SLTU  5'd15
`define ALU_MUL   5'd16 //dành riêng cho bộ nhân 32bit

wire add_is_complex_w = (|alu_a_i[31:16]) | (|alu_b_i[31:16]); //kiểm tra 16 bit cao của a và b, nếu có bit 1 thì sẽ complex
assign add_is_complex_o = add_is_complex_w;                      //xuất trạng thái kiểm tra độ phức tạp

wire add_use_approx_w = power_save_en_i && !add_is_complex_w; //mạch cộng xấp xỉ tiết kiệm điện chỉ thực sự dùng khi thỏa mãn đồng thời 2 điều kiện bật tích kiệm điện và dữ liệu đơn giản
assign add_used_approx_o = add_use_approx_w;                    //xuất cờ báo hiệu mạch đang chạy chế độ xấp xỉ


//MẠCH CỘNG THÍCH ỨNG KẾT HỢP APPROXIMATE VÀ CARRY BREAKING
localparam UPPER_W = 32 - APPROX_BITS;                                                                      //khai báo độ rộng của bộ cộng phân đoaạn nửa trên
wire [APPROX_BITS:0] add_sum_lower_w = alu_a_i[APPROX_BITS-1:0] + alu_b_i[APPROX_BITS-1:0];                 //tổng 16 bit thấp của a và b là 1 số có 17 bit bao gồm bit MSB là bit tràn

wire actual_carry_out_lower = add_sum_lower_w[APPROX_BITS];                                                 //trích xuất bit 16 làm bit nhớ thực tế được sinh ra từ bộ cổng nửa dưới
wire error_detected_w = add_use_approx_w && actual_carry_out_lower;                                         //nếu có bit nhớ = 1 và đang sử dụng cộng xấp xỉ thì báo lỗi -> cờ lỗi lên 1
assign error_flag_o = error_detected_w;                                                                     //gán lỗi ra cờ để sáng led

wire add_carry_in_upper_w = error_detected_w ? actual_carry_out_lower :
                            add_use_approx_w ? 1'b0 : actual_carry_out_lower;                                   //nếu phát hiện lỗi thì ép bit nhớ (1) nạp vào bit thông minh (add_carry_in_upper_w) còn không thì check xem nếu đang dùng bộ cộng xấp xỉ thì ghim bit nhớ bằng 0 còn không thì nó thực hiện như 1 bộ cộng bth    
wire [UPPER_W:0] add_sum_upper_w = alu_a_i[31:APPROX_BITS] + alu_b_i[31:APPROX_BITS] + add_carry_in_upper_w;    //thực hiện phép cộng 16 bit cao của a b với bit thông minh
wire [31:0] add_result_w = {add_sum_upper_w[UPPER_W-1:0], add_sum_lower_w[APPROX_BITS-1:0]};                    //ghép 16 bit cao với 16 bit thấp ra kết quả


//CÔ LẬP TOÁN HẠNG BỘ NHÂN (OPERAND ISOLATION)
wire mul_enable_w = (alu_op_i == `ALU_MUL);                 //tín hiệu kích hoạt bộ nhân nếu chọn phép nhân

wire [31:0] gated_A_mul_i = mul_enable_w ? alu_a_i : 32'h0; // nếu có tín hiệu nhân thì nạp a vào bộ cộng a còn nếu không thì khóa cứng ở 0 -> áp dụng công thức P = alpha x C x Vdd^2 x f với alpha là tần suất lật bit -> trong quá trình thực hiện các phép tính kahcs thì cổng vào a và b luôn lật và làm công suất động tăng nên sẽ cô lập bộ nhân để tránh tăng công suất khi không cần dùng đến
wire [31:0] gated_B_mul_i = mul_enable_w ? alu_b_i : 32'h0;

wire [31:0] mul_res_w = gated_A_mul_i * gated_B_mul_i;      //thực hiện nhân


//BỘ TRỪ VÀ KHỐI MUX DỒN KÊNH NGÕ RA CHÍNH
wire [31:0] sub_res_w = alu_a_i - alu_b_i; //thực hiện trừ

reg [31:0] result_r; //thanh ghi tạm kết quả
always @(*) begin
    case (alu_op_i)
        `ALU_ADD:               result_r = add_result_w;
        `ALU_SUB:               result_r = sub_res_w;
        `ALU_XOR:               result_r = alu_a_i ^ alu_b_i;
        `ALU_OR:                result_r = alu_a_i | alu_b_i;
        `ALU_AND:               result_r = alu_a_i & alu_b_i;
        `ALU_SRA:               result_r = $signed(alu_a_i) >>> alu_b_i[4:0];
        `ALU_SRL:               result_r = alu_a_i >> alu_b_i[4:0];
        `ALU_SLL:               result_r = alu_a_i << alu_b_i[4:0];
        `ALU_LT, `ALU_SLT:      result_r = ($signed(alu_a_i) < $signed(alu_b_i)) ? 32'h1 : 32'h0;
        `ALU_LTU, `ALU_SLTU:    result_r = (alu_a_i < alu_b_i) ? 32'h1 : 32'h0;
        `ALU_GE:                result_r = ($signed(alu_a_i) >= $signed(alu_b_i)) ? 32'h1 : 32'h0;
        `ALU_GEU:               result_r = (alu_a_i >= alu_b_i) ? 32'h1 : 32'h0;
        `ALU_EQ:                result_r = (alu_a_i == alu_b_i) ? 32'h1 : 32'h0;
        `ALU_NE:                result_r = (alu_a_i != alu_b_i) ? 32'h1 : 32'h0;
        `ALU_MUL:               result_r = mul_res_w;
        default:                result_r = alu_a_i;
    endcase
end

assign alu_p_o = result_r;

endmodule