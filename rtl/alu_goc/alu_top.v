module alu_top (
     input        clk //clock đã được setting trong file timing          
    ,input  [3:0] sw_operator //4 switch trên bo mạch  
    ,input        btn_select //nút bấm reset đồng bộ   
    ,output [7:0] led_result    // đầu ra 8 led
);

    // Sử dụng một mạch đếm để làm dữ liệu thay đổi liên tục
    reg [31:0] test_counter;
    
    always @(posedge clk) begin
        if (btn_select) // nếu có tín hiệu reset
            test_counter <= 32'h0; //gán giá trị bộ đếm về 0
        else
            test_counter <= test_counter + 1'b1; //nếu không thì tăng giá trị
    end

    // Gán mạch đếm vào toán hạng để Vivado KHÔNG THỂ tối ưu cắt mạch
    wire [31:0] operand_a = test_counter; //gán trực tiếp giá trị bộ đếm vào a
    wire [31:0] operand_b = test_counter ^ 32'h5555_AAAA; // Tạo sự khác biệt giữa a và b để kiểm tra tính đúng đắn của mạch

    wire [31:0] alu_result; //chứa kết quả tính toán số học/logic
    wire        cmp_result; //cờ kết quả của các phép SO SÁNH
    wire        eq_result; //cờ thông báo 2 TOÁN HẠNG BẰNG NHAU

    // Gọi khối ALU
    (* keep_hierarchy = "yes" *) //phân cấp rõ ràng module cha con
    ibex_alu_rv32imc u_alu (
         .operator_i            (sw_operator) //nối cổng nhận mã lệnh đến sw
        ,.operand_a_i            (operand_a) //nối toán hạng thứ 1 tới dây dữ liệu động operand_a
        ,.operand_b_i            (operand_b) //nối toán hạng thứ 2 tới dây dữ liệu động operand_b
        ,.multdiv_operand_a_i   (33'h0) //ghim cứng cổng dữ liệu nhân/chia A về 0
        ,.multdiv_operand_b_i   (33'h0) //ghim cứng cổng dữ liệu nhân/chia B về 0
        ,.multdiv_sel_i         (1'b0) //khóa chân chọn nguồn nhân/chia về 0 thì base không dùng tính năng nhân chia ngoại vi
        ,.result_o              (alu_result) //đưa kết quả tính toán ra dây alu_result
        ,.comparison_result_o   (cmp_result) //đưa kết quả so sánh ra dây cmp_result
        ,.is_equal_result_o     (eq_result) //đưa cờ bằng nhau ra dây eq_result
        ,.adder_result_o        ()
        ,.adder_result_ext_o    ()
    );

    // Thuộc tính bảo vệ ngõ ra
    assign led_result = alu_result[7:0]; //trích xuất 8-bit thấp nhất từ 32 bit của ALU để gán ra 8 led trên board

endmodule