/*
 * Module: instruction_memory (Bộ nhớ Lệnh)
 * Chức năng: Hoạt động như một ROM.
 * Nhận địa chỉ từ PC và xuất ra lệnh 16-bit.
 * Bộ nhớ được khởi tạo từ file "program.hex".
 */
module instruction_memory(
    input [15:0] Address,      // Địa chỉ lệnh (từ PC)
    output [15:0] Instruction  // Lệnh 16-bit tại địa chỉ đó
);

    // Khai báo bộ nhớ. 
    // Kích thước 2^16 = 65536 từ, mỗi từ 16 bit.
    // (Địa chỉ là 16-bit, nhưng tài liệu nói PC nhảy 2,
    // nên ta chỉ dùng các địa chỉ chẵn)
    reg [15:0] mem [0:65535];

    // Khởi tạo bộ nhớ từ file .hex khi mô phỏng bắt đầu
    initial begin
        $readmemh("program.hex", mem);
    end
    
    // Logic đọc (Tổ hợp - Combinational)
    // Lấy lệnh tại địa chỉ được chỉ định.
    // Địa chỉ từ PC là địa chỉ byte, nhưng lệnh là 16-bit (2 byte).
    // Chúng ta giả định PC luôn trỏ đến địa chỉ chẵn (đã xử lý ở datapath)
    // Ta cần chia địa chỉ cho 2 (dịch phải 1 bit) để làm index cho mảng.
    assign Instruction = mem[Address >> 1];

endmodule