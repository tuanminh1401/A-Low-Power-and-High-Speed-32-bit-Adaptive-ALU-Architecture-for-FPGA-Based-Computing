// Opcode ALU (4-bit, 16 gia tri, khong Bitmanip)
//-----------------------------------------------------------------
`define ALU_ADD   4'd0
`define ALU_SUB   4'd1
`define ALU_XOR   4'd2
`define ALU_OR    4'd3
`define ALU_AND   4'd4
`define ALU_SRA   4'd5 //dịch phải số học
`define ALU_SRL   4'd6 //dịch phải logic
`define ALU_SLL   4'd7 //dịch trái
`define ALU_LT    4'd8 //less than -> so sánh nhỏ hơn (có dấu) dùng để rẽ nhánh
`define ALU_LTU   4'd9 //less than unsigned -> so sánh không dấu dùng để rẽ nhánh
`define ALU_GE    4'd10 // great or equal
`define ALU_GEU   4'd11 // great or equal unsigned
`define ALU_EQ    4'd12 //equal
`define ALU_NE    4'd13 //not equal
`define ALU_SLT   4'd14 //set on less than -> so sánh có dấu và trả về kết quả vào thanh ghi
`define ALU_SLTU  4'd15 //set on les than unsign -> so sánh không dấu và trả về kết quả vào thanh ghi

/**
 * Arithmetic logic unit (RV32I only - no Bitmanip) - Verilog-2001
 */
module ibex_alu_rv32imc
(
    // Inputs
     input  [ 3:0]  operator_i //cổng nhận mã lệnh opcode 4 bit là 4 switch để chọn phép toán
    ,input  [31:0]  operand_a_i //toán hạng đầu vào 32 bit thường a
    ,input  [31:0]  operand_b_i //toán hạng đầu vào 32 bit thường b

    ,input  [32:0]  multdiv_operand_a_i //toán hạng đầu vào 33 bit để sử dụng cho tác vụ chia của khối ngoài a
    ,input  [32:0]  multdiv_operand_b_i //toán hạng đầu vào 33 bit để sử dụng cho tác vụ chia của khối ngoài b

    ,input          multdiv_sel_i //chân chọn chế độ chuyển mạch (1: chạy các cổng multdiv, 0: chạy ALU thường)

    // Outputs
    ,output [31:0]  adder_result_o //cổng xuất kết quả bộ cộng 32-bit
    ,output [33:0]  adder_result_ext_o //cổng xuất kết quả mở rộng 34 bit phục vụ khối ngoài

    ,output [31:0]  result_o //cổng xuất kết quả tính toán FINAL
    ,output         comparison_result_o //cổng xuất kết quả so sánh dạng 1-bit
    ,output         is_equal_result_o //cổng xuất cờ báo hiệu trạng thái hai toán hạng khác nhau
);

    integer i; //dùng làm beiens đếm cho vòng lật bit

    wire [31:0] operand_a_rev; //chứa giá trị của toán hạng A sau khi đảo bit từ trái->phải

    genvar k;
    generate
        for (k = 0; k < 32; k = k + 1) begin : gen_rev_operand_a
            assign operand_a_rev[k] = operand_a_i[31-k]; //gán operand_a_rev cho 32 bit đảo ngược thứ tự của bộ đếm (operand_a)
        end
    endgenerate

    //-----------------------------------------------------------------
    // Adder
    //-----------------------------------------------------------------
    reg         adder_op_b_negate; // cờ báo hiệu cần đảo dấu toán hạng B (dùng có phép so sánh hoặc trừ)
    wire [32:0] adder_in_a; //đường dẫn 33 bit cho bộ cộng A
    reg  [32:0] adder_in_b; //đường dẫn 33 bit cho bộ cộng B
    wire [31:0] adder_result; //kết quả 32 bit thu được từ bộ cộng
    wire [32:0] operand_b_neg; //chứa giá trị đảo bit của B để thực hiện trừ

    always @(*) begin
        adder_op_b_negate = 1'b0; //gán giá trị mặc định cờ đảo dấu = 0
        case (operator_i) //xét mã phép toán đầu vào
            `ALU_SUB,
            `ALU_EQ,   `ALU_NE,
            `ALU_GE,   `ALU_GEU,
            `ALU_LT,   `ALU_LTU,
            `ALU_SLT,  `ALU_SLTU: adder_op_b_negate = 1'b1; //nếu gặp các phép toán trên thì kích hoạt cờ đảo dấu B
            default: adder_op_b_negate = 1'b0; // nếu các phép toán khác thì không kích hoạt đảo dấu B
        endcase
    end
    
    //nếu chọn nhân/chia ngoài thì giá trị đầu vào A được lấy thẳng giá trị multdiv_operand 33bit còn không thì chạy ALU thường - lấy toán hạng operand_a_i gộp thêm 1 vào cuối để chuẩn bị cho bù 2 -> 2A + 1
    assign adder_in_a = multdiv_sel_i ? multdiv_operand_a_i : {operand_a_i, 1'b1};

    // chuan bi operand b
    assign operand_b_neg = {operand_b_i, 1'b0} ^ {33{1'b1}}; //tạo ra 33 bit đảo của toán hạng B
    always @(*) begin
        case (1'b1)
            multdiv_sel_i:     adder_in_b = multdiv_operand_b_i; // nếu bộ chia ngoài được chọn, lấy thẳng multdiv_operand_b_i
            adder_op_b_negate: adder_in_b = operand_b_neg; //nếu là phép trừ/so sánh thì lấy operand_b_neg (chuỗi đảo 33 bit của B)
            default:           adder_in_b = {operand_b_i, 1'b0}; //nếu là phép cộng bình thường, chỉ cần gộp thêm bit 0 vào cuối B mà không cần đảo ->2B
        endcase
    end
    
    //KHỐI CỘNG TỔNG QUÁT
    assign adder_result_ext_o = $unsigned(adder_in_a) + $unsigned(adder_in_b); // thực hiện cộng không dấu của 2 toán hạng đã chuẩn bị và lưu ra 34 bit cổng ngoài
    assign adder_result       = adder_result_ext_o[32:1]; // cắt lấy 32 bit giữa bằng cách bỏ bit cuối cùng và bit tràn đi đi -> (2A + 1 + 2B) / 2 = A + B
    assign adder_result_o     = adder_result; // đưa kết quả 32 bit cuối cùng ra cổng ngoài

    //KHỐI SO SÁNH 
    wire is_equal; //cờ báo hiệu A = B
    reg  is_greater_equal; // Cờ báo hiệu A >= B
    reg  cmp_signed; //cờ xác định phép so sánh hiện tại có dấu(1) hay không dấu (0)

    always @(*) begin
        case (operator_i)
            `ALU_GE,
            `ALU_LT,
            `ALU_SLT: cmp_signed = 1'b1; //các phép toán so sánh có dấu nên cờ dấu nhảy lên 1
            default:  cmp_signed = 1'b0; //mặc định phép toán so sánh khác thì không dấu
        endcase
    end

    assign is_equal          = (adder_result == 32'h0); //nếu A - B = 0 thì bằng nhau nên cờ equal = 1
    assign is_equal_result_o = is_equal; //đưa kết quả ra chân is_equal_result_o

    always @(*) begin
        if ((operand_a_i[31] ^ operand_b_i[31]) == 1'b0) //nếu a và b cùng dấu
            is_greater_equal = (adder_result[31] == 1'b0); //kết quả so sánh dựa vào bit dấu của kết quả phép a - b, nếu bit dấu  = 0 thì a >= b
        else
            is_greater_equal = operand_a_i[31] ^ cmp_signed; //lúc này so sánh có dấu nên cmp_signed = 1 và ta thực hiện dùng bit dấu của a để xor, ví dụ a = -5. b = 3 thì a[31] ^ cmp_signed = 0 tức là a không lớn hơn b
    end
    
    //Khối gán kết quả so sánh
    reg cmp_result;
    always @(*) begin
        case (operator_i)
            `ALU_EQ:              cmp_result =  is_equal;
            `ALU_NE:              cmp_result = ~is_equal;
            `ALU_GE,   `ALU_GEU:  cmp_result = is_greater_equal;
            `ALU_LT,   `ALU_LTU,
            `ALU_SLT,  `ALU_SLTU: cmp_result = ~is_greater_equal;
            default:              cmp_result = is_equal;
        endcase
    end

    assign comparison_result_o = cmp_result; //đưa kết quá so sánh ra chân comparison_result_o

    //KHỐI DỊCH BIT
    reg        shift_left; //cờ báo hiệu dịch trái
    wire       shift_arith; //cờ báo hiệu dịch phải số học
    wire [4:0] shift_amt; //lưu giữ khoảng cách dịch (dịch tôi đa 31 vị trí nên cần 5 bit)

    reg  [31:0] shift_operand; //đầu vào thực tế
    wire [32:0] shift_result_ext; //kết quả đầu ra mở rộng của bộ dịch phải
    wire        unused_shift_result_ext;
    reg  [31:0] shift_result;
    reg  [31:0] shift_result_rev;

    assign shift_amt = operand_b_i[4:0]; //lấy tạm 5 bit thấp nhất của toán hạng B làm lượng dịch bit (mô phỏng ví dụ)

    //khối kiểm tra dịch trái
    always @(*) begin
        case (operator_i)
            `ALU_SLL: shift_left = 1'b1;
            default:  shift_left = 1'b0;
        endcase
    end

    assign shift_arith = (operator_i == `ALU_SRA); //nếu đang chọn dịch phải số học thì kích hoạt cờ dịch số học
    
    //sử dụng dịch thông minh, nếu shift_arith = 0 thì auto chèn thêm số 0 vào bên trái của đầu vào để thành 33 bit còn nếu 
    //arith = 1 thì số được chèn vào sẽ là [31] đúng với dịch phải số học, và để dịch giữ dấu vì phải gán cho nó là sign sau khi dịch xong thì đẩy lại về unsign để giữ kiểu mẫu
    assign shift_result_ext = $unsigned($signed({shift_arith & shift_operand[31], shift_operand}) >>> shift_amt);
    
    //KHỐI DỊCH TRÁI THÔNG QUA PHÉP DỊCH PHẢI
    always @(*) begin
        shift_operand = shift_left ? operand_a_rev : operand_a_i; //nếu dịch trái thì lấy bộ đảo của A nạp vào bộ dịch phải

        shift_result = shift_result_ext[31:0]; //lấy kết quả 32 bit sau khi chạy qua bộ dịch phải nạp vào shift_result

        for (i = 0; i < 32; i = i + 1) begin
            shift_result_rev[i] = shift_result[31-i]; //đảo chiều toàn bộ kết quả để về dịch trái
        end

        shift_result = shift_left ? shift_result_rev : shift_result; //nếu là phép dịch trái thì lấy giá trị sau khi được đảo lại lần 2 còn không thì giữ giá trị dịch phải thông thường
    end

    assign unused_shift_result_ext = shift_result_ext[32]; //gán bit thứ 33 của kết quả dịch ra dây phụ để tránh treo

    //KHỐI LOGIC BITWISE
    wire        bwlogic_or;
    wire        bwlogic_and;
    wire [31:0] bwlogic_or_result;
    wire [31:0] bwlogic_and_result;
    wire [31:0] bwlogic_xor_result;
    reg  [31:0] bwlogic_result;

    assign bwlogic_or_result  = operand_a_i | operand_b_i; //or từng bit
    assign bwlogic_and_result = operand_a_i & operand_b_i; //and từng bit
    assign bwlogic_xor_result = operand_a_i ^ operand_b_i; //xor từng bit

    assign bwlogic_or  = (operator_i == `ALU_OR); //khởi tạo cờ xem có phải đang chọn OR hay không
    assign bwlogic_and = (operator_i == `ALU_AND);//khởi tạo cờ xem có phải đang chọn AND hay không

    always @(*) begin
        case (1'b1)
            bwlogic_or:  bwlogic_result = bwlogic_or_result; //nếu cờ or bật thì gán kết quả or vào đầu ra
            bwlogic_and: bwlogic_result = bwlogic_and_result;
            default:     bwlogic_result = bwlogic_xor_result; // ALU_XOR
        endcase
    end

    //BỘ DỒN KÊNH
    reg [31:0] result_r; //thanh ghi tạm 32 bit chứa kết quả cuối cùng của ALU trước khi xuất ra cổng ngoai

    always @(*) begin
        result_r = 32'h0;
        case (operator_i)
            // Bitwise Logic
            `ALU_XOR, `ALU_OR, `ALU_AND: result_r = bwlogic_result;
            // Adder
            `ALU_ADD, `ALU_SUB: result_r = adder_result;
            // Shift
            `ALU_SLL, `ALU_SRL, `ALU_SRA: result_r = shift_result;
            // Comparison
            `ALU_EQ,   `ALU_NE,
            `ALU_GE,   `ALU_GEU,
            `ALU_LT,   `ALU_LTU,
            `ALU_SLT,  `ALU_SLTU: result_r = {31'h0, cmp_result};
            default: result_r = 32'h0;
        endcase
    end

    assign result_o = result_r; //gán kết quả thanh ghi ra kết quả chính thức

endmodule