/*
 * Module: alu (Arithmetic Logic Unit)
 * Chức năng: Thực hiện các phép toán và logic dựa trên tín hiệu ALUOp.
 * Bao gồm các phép toán cho ALUO, ALU1, ALU2, và các lệnh Immediate.
 */
 `timescale 1ns / 1ps
module alu(
    input  [15:0] A,          // Toán hạng A (ví dụ: từ $rs)
    input  [15:0] B,          // Toán hạng B (ví dụ: từ $rt hoặc immediate)
    input  [4:0]  ALUOp,      // Tín hiệu điều khiển (từ Control Unit)
    
    output reg [15:0] Result, // Kết quả chính (cho $rd hoặc địa chỉ)
    output reg [15:0] HI_Out, // Kết quả $HI (cho mult/div)
    output reg [15:0] LO_Out, // Kết quả $LO (cho mult/div)
    
    output Zero               // Cờ Zero, = 1 nếu Result == 0
);

    // Định nghĩa mã cho từng hoạt động của ALU
    parameter OP_ADD   = 5'b00001; 
    parameter OP_ADDU  = 5'b00010; 
    parameter OP_SUB   = 5'b00011;
    parameter OP_SUBU  = 5'b00100; 
    parameter OP_AND   = 5'b00101; 
    parameter OP_OR    = 5'b00110;  
    parameter OP_NOR   = 5'b00111;  
    parameter OP_XOR   = 5'b01000;  
    parameter OP_SLT   = 5'b01001;  
    parameter OP_SLTU  = 5'b01010;  
    parameter OP_SEQ   = 5'b01011;  

    // Shift Operations
    parameter OP_SHR   = 5'b01100; // shift right logical
    parameter OP_SHL   = 5'b01101; // shift left logical
    parameter OP_ROR   = 5'b01110; // rotate right
    parameter OP_ROL   = 5'b01111; // rotate left

    // Multiply / Divide Operations
    parameter OP_MULT  = 5'b10000; 
    parameter OP_MULTU = 5'b10001; 
    parameter OP_DIV   = 5'b10010;
    parameter OP_DIVU  = 5'b10011; 

    // Dây nội bộ cho phép toán có dấu
    wire signed [15:0] signed_A = A;
    wire signed [15:0] signed_B = B;

    // Biến tạm cho phép nhân
    reg signed [31:0] mult_result;
    reg [31:0] multu_result;

    // Lượng dịch bit lấy từ 4 bit thấp của A ([$rs]_{3:0})
    wire [3:0] shift_amount = A[3:0];

    // Mạch tổ hợp chính của ALU
    always @(*) begin
        // Giá trị mặc định
        Result = 16'h0000;
        HI_Out = 16'h0000;
        LO_Out = 16'h0000;
        mult_result = 32'd0;
        multu_result = 32'd0;
        
        case (ALUOp)
            // Phép toán số học
            OP_ADD:   Result = signed_A + signed_B;
            OP_ADDU:  Result = A + B;
            OP_SUB:   Result = signed_A - signed_B;
            OP_SUBU:  Result = A - B;

            // Phép toán logic
            OP_AND:   Result = A & B;
            OP_OR:    Result = A | B;
            OP_NOR:   Result = ~(A | B);
            OP_XOR:   Result = A ^ B;

            // So sánh
            OP_SLT:   Result = (signed_A < signed_B) ? 16'd1 : 16'd0;
            OP_SLTU:  Result = (A < B) ? 16'd1 : 16'd0;
            OP_SEQ:   Result = (A == B) ? 16'd1 : 16'd0;
            
            // Dịch bit
            OP_SHR:   Result = B >> shift_amount;
            OP_SHL:   Result = B << shift_amount;
            OP_ROR:   Result = (B >> shift_amount) | (B << (16 - shift_amount));
            OP_ROL:   Result = (B << shift_amount) | (B >> (16 - shift_amount));

            // Nhân có dấu
            OP_MULT: begin
                mult_result = signed_A * signed_B;
                LO_Out = mult_result[15:0];
                HI_Out = mult_result[31:16];
                Result = LO_Out;
            end

            // Nhân không dấu
            OP_MULTU: begin
                multu_result = A * B;
                LO_Out = multu_result[15:0];
                HI_Out = multu_result[31:16];
                Result = LO_Out;
            end

            // Chia có dấu
            OP_DIV: begin
                if (signed_B == 0) begin
                    LO_Out = 16'h0000;
                    HI_Out = 16'h0000;
                end else begin
                    LO_Out = signed_A / signed_B; // Thương
                    HI_Out = signed_A % signed_B; // Dư
                end
                Result = LO_Out;
            end

            // Chia không dấu
            OP_DIVU: begin
                if (B == 0) begin
                    LO_Out = 16'h0000;
                    HI_Out = 16'h0000;
                end else begin
                    LO_Out = A / B; // Thương
                    HI_Out = A % B; // Dư
                end
                Result = LO_Out;
            end

            // Mặc định
            default: begin
                Result = 16'h0000;
                HI_Out = 16'h0000;
                LO_Out = 16'h0000;
            end
        endcase
    end

    // Gán cờ Zero
    assign Zero = (Result == 16'h0000);

endmodule
