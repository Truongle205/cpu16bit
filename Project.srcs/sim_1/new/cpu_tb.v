`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2025 08:38:18 PM
// Design Name: 
// Module Name: cpu_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*
 * Module: cpu_tb (Testbench cho CPU)
 * Chức năng: Cung cấp Clock, Reset và theo dõi
 * hoạt động của cpu_top.
 */
`timescale 1ns / 1ps

module cpu_tb;

    // --- 1. Tín hiệu để kết nối với CPU ---
    reg clk;
    reg rst;

    // --- 2. Hiện thực (Instantiate) CPU ---
    // (DUT - Device Under Test)
    cpu_top dut (
        .clk(clk),
        .rst(rst)
    );

    // --- 3. Tạo Clock ---
    // Tạo clock 100MHz (chu kỳ 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Mỗi 5ns đảo clock
    end

    // --- 4. Tạo Reset và Chạy Mô phỏng ---
    initial begin
        // Bắt đầu với Reset
        rst = 1;
        #20; // Giữ reset trong 20ns
        
        // Nhả reset để CPU bắt đầu chạy
        rst = 0;
        
        // Cho CPU chạy trong 500ns (50 chu kỳ)
        #500;
        
        // Dừng mô phỏng
        $stop;
    end
    
    // --- 5. Theo dõi (Monitor) ---
    // In ra thông tin mỗi khi clock đổi
    // Đây là cách chúng ta debug!
    // Chúng ta "hack" vào bên trong CPU để xem các thanh ghi
    initial begin
        $monitor("Time=%0t ns: PC=0x%h, Instr=0x%h, $1=0x%h, $2=0x%h, $3=0x%h",
            $time,
            dut.datapath_inst.pc,                      // Theo dõi PC
            dut.datapath_inst.instruction,             // Lệnh đang chạy
            dut.datapath_inst.reg_file.gen_registers[1], // Thanh ghi $1
            dut.datapath_inst.reg_file.gen_registers[2], // Thanh ghi $2
            dut.datapath_inst.reg_file.gen_registers[3]  // Thanh ghi $3
        );
    end

endmodule