`timescale 1ns / 1ps
/*
 * Module: cpu_tb (Testbench HOÀN CHỈNH)
 * Chức năng: Cung cấp Clock, Reset và theo dõi CPU.
 * * - Dùng `always @(posedge clk)`
 * - Dùng `$strobe` để in sau khi tất cả lệnh ghi (<=) đã hoàn tất.
 */
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
        forever #5 clk = ~clk; // Mỗi 5ns đảo clock (chu kỳ 10ns)
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
    // Dùng `$strobe` tại `posedge clk`
    // Đây là cách chuẩn để in giá trị *SAU KHI*
    // các lệnh ghi non-blocking (<=) đã được thực thi.
    always @(posedge clk) begin
        // Chỉ bắt đầu in SAU KHI reset đã kết thúc
        if (!rst) begin 
            
            $strobe("Time=%0t ps: PC=0x%h, Instr=0x%h, $1=0x%h, $2=0x%h, $3=0x%h, RegWrite=%b",
                $time,
                dut.datapath_inst.pc,                      // PC
                dut.datapath_inst.instruction,             // Lệnh
                dut.datapath_inst.reg_file.gen_registers[1], // $1
                dut.datapath_inst.reg_file.gen_registers[2], // $2
                dut.datapath_inst.reg_file.gen_registers[3], // $3
                dut.control_unit_inst.RegWrite // Tín hiệu RegWrite
            );
        end
    end

endmodule