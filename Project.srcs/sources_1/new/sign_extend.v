/*
 * Module: sign_extend
 * Chức năng: Lấy một giá trị immediate 6-bit (có dấu)
 * và mở rộng dấu thành 16-bit.
 * Dùng cho các lệnh I-type: addi, slti, bneq, bgtz, lh, sh.
 */
module sign_extend(
    input [5:0] Imm_6bit,      // Giá trị immediate 6-bit từ lệnh
    output [15:0] Imm_16bit    // Giá trị 16-bit đã được mở rộng dấu
);

    // Logic mở rộng dấu:
    // Lấy 10 bản sao của bit dấu (bit [5])
    // và ghép nó vào bên trái của 6 bit ban đầu.
    
    assign Imm_16bit = { {10{Imm_6bit[5]}} , Imm_6bit };

endmodule