/*
 * Module: data_memory (Bộ nhớ Dữ liệu)
 * Chức năng: Hoạt động như một RAM 16-bit.
 * Hỗ trợ đọc và ghi đồng bộ.
 * Địa chỉ là địa chỉ byte 16-bit, nhưng ta dùng [15:1]
 * để truy cập các từ 16-bit (half-word).
 */
 `timescale 1ns / 1ps
module data_memory(
    input clk,
    input [15:0] Address,      // Địa chỉ (từ ALU)
    input [15:0] DataIn,       // Dữ liệu ghi vào (từ $rt)
    
    input MemRead,             // Tín hiệu điều khiển Đọc
    input MemWrite,            // Tín hiệu điều khiển Ghi
    
    output [15:0] DataOut      // Dữ liệu đọc ra
);

    // Kích thước bộ nhớ: 2^15 = 32768 từ, mỗi từ 16 bit
    // (Tổng cộng 2^16 = 65536 bytes, khớp với không gian địa chỉ 2^16)
    reg [15:0] mem [0:32767];

    // Logic GHI (Tuần tự - Synchronous)
    // Chỉ ghi vào bộ nhớ ở cạnh lên của clock nếu MemWrite = 1
    always @(posedge clk) begin
        if (MemWrite) begin
            // Dùng 15 bit cao làm địa chỉ của từ 16-bit
            mem[Address[15:1]] <= DataIn;
        end
    end

    // Logic ĐỌC (Tổ hợp - Asynchronous)
    // Luôn luôn xuất ra dữ liệu tại địa chỉ được chỉ định.
    // Tín hiệu MemRead sẽ được Control Unit dùng để quyết định
    // có sử dụng giá trị DataOut này hay không.
    assign DataOut = mem[Address[15:1]];

endmodule