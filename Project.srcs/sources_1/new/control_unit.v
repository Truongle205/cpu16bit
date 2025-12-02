/*
 * Module: control_unit (Single-Cycle Combinational)
 * Chức năng: "Bộ não" của CPU.
 * Giải mã opcode và funct để tạo ra TẤT CẢ tín hiệu điều khiển
 * trong CÙNG MỘT chu kỳ clock.
 */
`timescale 1ns / 1ps
module control_unit(
    // --- Inputs ---
    input [3:0] opcode,
    input [2:0] funct,
    input Zero,            // Từ ALU, 1 nếu (A-B == 0) for bneq
    input GTZ,             // Từ Datapath, 1 nếu ($rs > 0) for bgtz
    
    // --- Outputs (cho Datapath) ---
    output reg PCWrite,         // 1 = Cho phép ghi PC (tắt khi HLT)
    output reg RegWrite,        // 1 = Cho phép ghi vào Register File
    output reg MemRead,         // 1 = Đọc Data Memory (cho 'lh')
    output reg MemWrite,        // 1 = Ghi Data Memory (cho 'sh')
    output reg ALUSrc,          // 0 = ALU_B từ $rt, 1 = ALU_B từ Imm_16bit
    output reg RegDst,          // 0 = Ghi vào $rt, 1 = Ghi vào $rd
    output reg [1:0] MemtoReg,  // 00 = ALU_Result, 01 = Mem_Data, 10 = MFSR_Data
    output reg [1:0] PCSource,  // 00 = PC+2, 01 = Branch, 10 = Jump, 11 = Jr
    output reg HILO_WriteEn,    // 1 = Ghi HI/LO (cho mult/div)
    output reg MTSR_WriteEn,    // 1 = Ghi (mtra, mtat, mthi, mtlo)
    output reg MFSR_ReadEn,     // 1 = Đọc (mf...)
    
    // --- Output (cho ALU) ---
    output reg [4:0] ALUOp      // Mã hoạt động cho ALU
);

    // --- 1. ALUOp Definitions (Phải khớp với alu.v) ---
    parameter OP_ADD  = 5'b00001;
    parameter OP_ADDU = 5'b00010;
    parameter OP_SUB  = 5'b00011;
    parameter OP_SUBU = 5'b00100;
    parameter OP_AND  = 5'b00101;
    parameter OP_OR   = 5'b00110;
    parameter OP_NOR  = 5'b00111;
    parameter OP_XOR  = 5'b01000;
    parameter OP_SLT  = 5'b01001;
    parameter OP_SLTU = 5'b01010;
    parameter OP_SEQ  = 5'b01011;
    parameter OP_SHR  = 5'b01100;
    parameter OP_SHL  = 5'b01101;
    parameter OP_ROR  = 5'b01110;
    parameter OP_ROL  = 5'b01111;
    parameter OP_MULT  = 5'b10000;
    parameter OP_MULTU = 5'b10001;
    parameter OP_DIV   = 5'b10010;
    parameter OP_DIVU  = 5'b10011;
    
    // --- 2. ALU Decoder (Tổ hợp) ---
    // Giải mã 'funct' cho các lệnh R-Type
    // Đồng thời giải mã 'opcode' cho các lệnh cần ALU
    always @(*) begin
        case (opcode)
            'b0000: // ALUO
                case (funct)
                    3'b000: ALUOp = OP_ADDU;
                    3'b001: ALUOp = OP_SUBU;
                    3'b010: ALUOp = OP_MULTU;
                    3'b011: ALUOp = OP_DIVU;
                    3'b100: ALUOp = OP_AND;
                    3'b101: ALUOp = OP_OR;
                    3'b110: ALUOp = OP_NOR;
                    3'b111: ALUOp = OP_XOR;
                    default: ALUOp = 5'b00000;
                endcase
            'b0001: // ALU1
                case (funct)
                    3'b000: ALUOp = OP_ADD;
                    3'b001: ALUOp = OP_SUB;
                    3'b010: ALUOp = OP_MULT;
                    3'b011: ALUOp = OP_DIV;
                    3'b100: ALUOp = OP_SLT;
                    3'b101: ALUOp = OP_SEQ;
                    3'b110: ALUOp = OP_SLTU;
                    3'b111: ALUOp = 5'b00000; // 'jr' không dùng ALU chính
                    default: ALUOp = 5'b00000;
                endcase
            'b0010: // ALU2 (Shift)
                case (funct)
                    3'b000: ALUOp = OP_SHR;
                    3'b001: ALUOp = OP_SHL;
                    3'b010: ALUOp = OP_ROR;
                    3'b011: ALUOp = OP_ROL;
                    default: ALUOp = 5'b00000;
                endcase
            'b0011: // ADDI
                ALUOp = OP_ADDU; // Dùng ADDU cho addi
            'b0100: // SLTI
                ALUOp = OP_SLT;  // Dùng SLT cho slti
            'b0101: // BNEQ (dùng A-B để check cờ Zero)
                ALUOp = OP_SUBU; 
            'b1000: // LH (ALU cộng $rs + imm)
                ALUOp = OP_ADDU; 
            'b1001: // SH (ALU cộng $rs + imm)
                ALUOp = OP_ADDU; 
            default: ALUOp = 5'b00000;
        endcase
    end

    // --- 3. Main Decoder (Tổ hợp) ---
    // Giải mã 'opcode' cho tất cả tín hiệu điều khiển chính
    always @(*) begin
        // Gán giá trị mặc định (cho lệnh NO-OP hoặc lỗi)
        PCWrite      = 1'b1;  // Mặc định là cho chạy
        RegWrite     = 1'b0;  // Mặc định là không ghi
        MemRead      = 1'b0;
        MemWrite     = 1'b0;
        ALUSrc       = 1'b0;  // Mặc định B = $rt
        RegDst       = 1'b0;  // Mặc định ghi vào $rt
        MemtoReg     = 2'b00; // Mặc định ghi kết quả ALU
        PCSource     = 2'b00; // Mặc định PC = PC + 2
        HILO_WriteEn = 1'b0;
        MTSR_WriteEn = 1'b0;
        MFSR_ReadEn  = 1'b0;

        case (opcode)
            'b0000: begin // ALUO (R-Type)
                RegWrite = 1'b1;
                ALUSrc   = 1'b0; // B = $rt
                RegDst   = 1'b1; // Ghi $rd
                MemtoReg = 2'b00;
                HILO_WriteEn = (funct == 3'b010 || funct == 3'b011); // multu/divu
            end
            'b0001: begin // ALU1 (R-Type)
                RegWrite = (funct != 3'b111); // Không ghi GPR nếu là 'jr'
                ALUSrc   = 1'b0; // B = $rt
                RegDst   = 1'b1; // Ghi $rd
                MemtoReg = 2'b00;
                PCSource = (funct == 3'b111) ? 2'b11 : 2'b00; // PC = $rs nếu là 'jr'
                HILO_WriteEn = (funct == 3'b010 || funct == 3'b011); // mult/div
            end
            'b0010: begin // ALU2 (Shift, R-Type)
                RegWrite = 1'b1;
                ALUSrc   = 1'b0; // B = $rt (shift)
                RegDst   = 1'b1; // Ghi $rd
                MemtoReg = 2'b00;
            end
            'b0011: begin // ADDI (I-Type)
                RegWrite = 1'b1;
                ALUSrc   = 1'b1; // B = Imm
                RegDst   = 1'b0; // Ghi $rt
                MemtoReg = 2'b00;
            end
            'b0100: begin // SLTI (I-Type)
                RegWrite = 1'b1;
                ALUSrc   = 1'b1; // B = Imm
                RegDst   = 1'b0; // Ghi $rt
                MemtoReg = 2'b00;
            end
            'b0101: begin // BNEQ (I-Type)
                // ALU tính (A-B), nếu Zero=0 (not equal) thì branch
                PCSource = (~Zero) ? 2'b01 : 2'b00;
                ALUSrc   = 1'b0; // B = $rt
            end
            'b0110: begin // BGTZ (I-Type)
                // Check cờ GTZ (rs > 0)
                PCSource = (GTZ) ? 2'b01 : 2'b00;
            end
            'b0111: begin // JUMP (J-Type)
                PCSource = 2'b10;
            end
            'b1000: begin // LH (I-Type)
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                ALUSrc   = 1'b1; // B = Imm (để tính addr)
                RegDst   = 1'b0; // Ghi $rt
                MemtoReg = 2'b01; // Ghi từ Memory
            end
            'b1001: begin // SH (I-Type)
                MemWrite = 1'b1;
                ALUSrc   = 1'b1; // B = Imm (để tính addr)
            end
            'b1010: begin // MFSR (R-Type)
                RegWrite    = 1'b1;
                RegDst      = 1'b1; // Ghi $rd
                MemtoReg    = 2'b10; // Ghi từ MFSR
                MFSR_ReadEn = 1'b1;
            end
            'b1011: begin // MTSR (R-Type)
                MTSR_WriteEn = 1'b1;
            end
            'b1111: begin // HLT (J-Type)
                PCWrite = 1'b0; // Dừng PC
            end
            default: ; // Giữ giá trị mặc định
        endcase
    end
    
endmodule