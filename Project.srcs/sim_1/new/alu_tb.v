`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2025 10:06:56 AM
// Design Name: 
// Module Name: alu_tb
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

module alu_tb;
    // Inputs
    reg [15:0] A;
    reg [15:0] B;
    reg [4:0] ALUOp;

    // Outputs
    wire [15:0] Result;
    wire [15:0] HI_Out;
    wire [15:0] LO_Out;
    wire Zero;

    // Instantiate the Unit Under Test (UUT)
    alu uut (
        .A(A), 
        .B(B), 
        .ALUOp(ALUOp), 
        .Result(Result), 
        .HI_Out(HI_Out), 
        .LO_Out(LO_Out), 
        .Zero(Zero)
    );

    initial begin
        // Initialize Inputs
        A = 0; B = 0; ALUOp = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        $display("=== BAT DAU TEST ALU ===");

        // Test 1: ADD (5 + 7 = 12)
        A = 16'd5; B = 16'd7; ALUOp = 5'b00001; // OP_ADD
        #10;
        if (Result == 16'd12) $display("ADD: PASS");
        else $display("ADD: FAIL (Result=%d)", Result);

        // Test 2: SUB (10 - 3 = 7)
        A = 16'd10; B = 16'd3; ALUOp = 5'b00011; // OP_SUB
        #10;
        if (Result == 16'd7) $display("SUB: PASS");
        else $display("SUB: FAIL (Result=%d)", Result);

        // Test 3: AND (0F0F & 00FF = 000F)
        A = 16'h0F0F; B = 16'h00FF; ALUOp = 5'b00101; // OP_AND
        #10;
        if (Result == 16'h000F) $display("AND: PASS");
        else $display("AND: FAIL (Result=%h)", Result);

        // Test 4: SHIFT LEFT (1 << 2 = 4)
        // Lưu ý: Shift amount lấy từ 4 bit thấp của A theo thiết kế của bạn
        B = 16'd1; A = 16'd2; ALUOp = 5'b01101; // OP_SHL
        #10;
        if (Result == 16'd4) $display("SHL: PASS");
        else $display("SHL: FAIL (Result=%d)", Result);
        
        // Test 5: Check Zero Flag (5 - 5 = 0)
        A = 16'd5; B = 16'd5; ALUOp = 5'b00100; // OP_SUBU
        #10;
        if (Zero == 1) $display("Zero Flag: PASS");
        else $display("Zero Flag: FAIL");

        $display("=== END TEST ALU ===");
        $stop;
    end
endmodule