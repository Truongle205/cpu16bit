`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2025 10:08:28 AM
// Design Name: 
// Module Name: register_file_tb
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
`timescale 1ns / 1ps

module register_file_tb;
    reg clk;
    reg rst;
    reg [2:0] ReadAddr_rs;
    reg [2:0] ReadAddr_rt;
    reg WriteEn_Gen;
    reg [2:0] WriteAddr_Gen;
    reg [15:0] WriteData_Gen;
    
    // Các tín hiệu Special Reg (gán 0 nếu không test)
    reg [15:0] PC_in;
    reg HILO_WriteEn;
    reg [15:0] HI_in;
    reg [15:0] LO_in;
    reg WriteEn_Spec;
    reg [2:0] Funct_MTSR;
    reg [15:0] Data_MTSR;
    reg [2:0] Funct_MFSR;

    wire [15:0] ReadData_rs;
    wire [15:0] ReadData_rt;
    wire [15:0] ReadData_MFSR;

    register_file uut (
        .clk(clk), .rst(rst),
        .ReadAddr_rs(ReadAddr_rs), .ReadAddr_rt(ReadAddr_rt),
        .ReadData_rs(ReadData_rs), .ReadData_rt(ReadData_rt),
        .WriteEn_Gen(WriteEn_Gen), .WriteAddr_Gen(WriteAddr_Gen), .WriteData_Gen(WriteData_Gen),
        .PC_in(PC_in), .HILO_WriteEn(HILO_WriteEn), .HI_in(HI_in), .LO_in(LO_in),
        .WriteEn_Spec(WriteEn_Spec), .Funct_MTSR(Funct_MTSR), .Data_MTSR(Data_MTSR), .Funct_MFSR(Funct_MFSR),
        .ReadData_MFSR(ReadData_MFSR)
    );

    // Clock gen
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        WriteEn_Gen = 0; WriteAddr_Gen = 0; WriteData_Gen = 0;
        PC_in=0; HILO_WriteEn=0; HI_in=0; LO_in=0; WriteEn_Spec=0; Funct_MTSR=0; Data_MTSR=0; Funct_MFSR=0;

        #20 rst = 0; // Release reset

        // Test 1: Ghi vào $1
        @(negedge clk); // Đợi cạnh xuống để ghi an toàn
        WriteEn_Gen = 1; WriteAddr_Gen = 3'd1; WriteData_Gen = 16'hAAAA;
        @(posedge clk); // Đợi cạnh lên để thực hiện ghi

        // Test 2: Đọc $1
        @(negedge clk);
        WriteEn_Gen = 0; // Tắt ghi
        ReadAddr_rs = 3'd1;
        #1; // Đợi một xíu cho logic tổ hợp
        if (ReadData_rs == 16'hAAAA) $display("Read/Write $1: PASS");
        else $display("Read/Write $1: FAIL (Got %h)", ReadData_rs);

        // Test 3: Cố tình ghi vào $0 (Phải thất bại, $0 luôn = 0)
        @(negedge clk);
        WriteEn_Gen = 1; WriteAddr_Gen = 3'd0; WriteData_Gen = 16'hFFFF;
        @(posedge clk);
        
        @(negedge clk);
        WriteEn_Gen = 0;
        ReadAddr_rs = 3'd0;
        #1;
        if (ReadData_rs == 16'h0000) $display("Write to $0 blocked: PASS");
        else $display("Write to $0 blocked: FAIL (Got %h)", ReadData_rs);

        $stop;
    end
endmodule