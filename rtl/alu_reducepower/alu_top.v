module alu_top (
     input        clk           
    ,input  [3:0] sw_operator //4 đầu vào là 4 switch chọn chế độ  
    ,input        sw_power_save  //NÂNG CẤP: chân nhận tính hiệu gạt switch chọn chế độ bật/tắt tính năng tiết kiệm năng lượng
    ,input        btn_select  //nút bấm reset đồng bộ  
    ,output [7:0] led_result  //xuất kết quả ra 8 led bằng 8 bit thấp
    ,output       led_error   //NÂNG CẤP: khai báo chân ngõ ra kết nối 1 led để cạnh báo khi mạch xảy ra lỗi tính toán xấp xỉ vượt ngưỡng  
);

    reg [31:0] test_counter; //bộ đếm để tăng giá trị test
    
    always @(posedge clk) begin
        if (btn_select)
            test_counter <= 32'h0; //nếu có reset thì bộ đếm về 0
        else
            test_counter <= test_counter + 1'b1; //nếu k thì tăng 1 đơn vị
    end

    wire [31:0] operand_a = test_counter; //gán trực tiếp giá trị bộ đếm vào toán hạng a
    wire [31:0] operand_b = test_counter ^ 32'h5555_AAAA; //thực hiện xor với số đó để ra b khác a giúp đa dạng kết quả tính toán và bắt a b phải lật liên tục

    wire [31:0] alu_result; //kết quả tính toán số học/logic
    wire        error_flag; //cờ báo lỗi nếu tràn ở bộ cộng xấp xỉ

    (* keep_hierarchy = "yes" *) //phân cấp 2 module cha con để bảo toàn ranh giới tiện cho việc đo đạc công suất thiêu thụ của module con
    biriscv_alu_adaptive #(
        .APPROX_BITS(16) 
    ) u_adaptive_alu (
         .alu_op_i          ({1'b0, sw_operator}) //vì bộ alu này mở rộng tập lệnh với bus opcode 5bit (để tích hợp thêm phép nhân), thêm bit 0 vào bên phải 4 bit switch để chuẩn hóa dữ liệu
        ,.alu_a_i           (operand_a) //đầu vào toàn hạng A
        ,.alu_b_i           (operand_b) //đầu vào toán hạng B
        ,.power_save_en_i   (sw_power_save) //cần gạt tiết kiệm năng lượng. khi bật lên 1 hệ thống tự động kích hoạt bộ cộng xấp xỉ 16bit khi tắt 0 hệ thống chạy ở chính xác tuyệt đối
        ,.alu_p_o           (alu_result) //kết quả tính toán 32 bit
        ,.add_is_complex_o  ()
        ,.add_used_approx_o ()
        ,.error_flag_o      (error_flag) //cảnh báo tràn bit nhớ ra đường error_flag ở top
    );

    assign led_result = alu_result[7:0]; // lấy 8 bit thấp nhất từ 32 bit ALU gán trực tiếp vào 8 led
    assign led_error  = error_flag; //gán ra led board mạch

endmodule