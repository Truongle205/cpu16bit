/*
 * Module: cpu_top (Module cấp cao nhất)
 * Chức năng: Kết nối Control Unit và Datapath.
 * Nhận clock và reset.
 */
 `timescale 1ns / 1ps
module cpu_top(
    input clk,
    input rst
    );

    // --- Dây (Wires) kết nối giữa Control và Datapath ---

    // Tín hiệu TỪ Datapath (status) GỬI TỚI Control Unit
    wire [3:0] opcode;
    wire [2:0] funct;
    wire Zero;
    wire GTZ;

    // Tín hiệu TỪ Control Unit (control) GỬI TỚI Datapath
    wire PCWrite;
    wire RegWrite;
    wire MemRead;
    wire MemWrite;
    wire ALUSrc;
    wire RegDst;
    wire [1:0] MemtoReg;
    wire [1:0] PCSource;
    wire HILO_WriteEn;
    wire MTSR_WriteEn;
    wire MFSR_ReadEn;
    wire [4:0] ALUOp;

    // --- 1. Hiện thực "Cơ thể" (Datapath) ---
    datapath datapath_inst (
        .clk(clk),
        .rst(rst),
        
        // Control Inputs (nhận từ Control Unit)
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUOp(ALUOp),
        .ALUSrc(ALUSrc),
        .RegDst(RegDst),
        .MemtoReg(MemtoReg),
        .PCSource(PCSource),
        .HILO_WriteEn(HILO_WriteEn),
        .MTSR_WriteEn(MTSR_WriteEn),
        .MFSR_ReadEn(MFSR_ReadEn),
        
        // Status Outputs (gửi tới Control Unit)
        .opcode(opcode),
        .funct(funct),
        .Zero(Zero),
        .GTZ(GTZ)
    );

    // --- 2. Hiện thực "Bộ não" (Control Unit) ---
    control_unit control_unit_inst (
        // Status Inputs (nhận từ Datapath)
        .opcode(opcode),
        .funct(funct),
        .Zero(Zero),
        .GTZ(GTZ),
        
        // Control Outputs (gửi tới Datapath)
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegDst(RegDst),
        .MemtoReg(MemtoReg),
        .PCSource(PCSource),
        .HILO_WriteEn(HILO_WriteEn),
        .MTSR_WriteEn(MTSR_WriteEn),
        .MFSR_ReadEn(MFSR_ReadEn),
        .ALUOp(ALUOp)
    );

endmodule