/*
 * Module: register_file 
 * Chức năng: Lưu trữ 8 thanh ghi đa dụng ($0-$7).
 * Dùng mảng [0:7] chuẩn.
 */
module register_file(
    input clk,
    input rst,
    
    // ----- Cổng đọc GPR (General Purpose Reg) -----
    input [2:0] ReadAddr_rs,
    input [2:0] ReadAddr_rt,
    output [15:0] ReadData_rs,
    output [15:0] ReadData_rt,
    
    // ----- Cổng ghi GPR (cho Write-Back) -----
    input WriteEn_Gen,
    input [2:0] WriteAddr_Gen,
    input [15:0] WriteData_Gen,
    
    // ----- Cổng cho Thanh ghi Đặc thù (Special Reg) -----
    input [15:0] PC_in,
    input HILO_WriteEn,
    input [15:0] HI_in,
    input [15:0] LO_in,
    input WriteEn_Spec,
    input [2:0] Funct_MTSR,
    input [15:0] Data_MTSR,
    input [2:0] Funct_MFSR,
    output reg [15:0] ReadData_MFSR
);

    // KHAI BÁO CHUẨN: 8 thanh ghi, [0:7]
    reg [15:0] gen_registers [0:7]; 
    
    // 4 thanh ghi đặc thù
    reg [15:0] reg_RA;
    reg [15:0] reg_AT;
    reg [15:0] reg_HI;
    reg [15:0] reg_LO;

    // --- Logic ĐỌC GPR (Tổ hợp - Combinational) ---
    // Thanh ghi $0 (index 0) luôn trả về 0
    assign ReadData_rs = gen_registers[ReadAddr_rs];
    assign ReadData_rt = gen_registers[ReadAddr_rt];

    
    // --- Logic GHI (Tuần tự - Sequential) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset tất cả, bao gồm $0 (sẽ bị ghi đè)
            gen_registers[0] <= 16'h0000;
            gen_registers[1] <= 16'h0000;
            gen_registers[2] <= 16'h0000;
            gen_registers[3] <= 16'h0000;
            gen_registers[4] <= 16'h0000;
            gen_registers[5] <= 16'h0000;
            gen_registers[6] <= 16'h0000;
            gen_registers[7] <= 16'h0000;
            
            reg_RA <= 16'h0000;
            reg_AT <= 16'h0000;
            reg_HI <= 16'h0000;
            reg_LO <= 16'h0000;
        end else begin
            // 1. Ghi GPR
            if (WriteEn_Gen) begin
                // Ghi dữ liệu, NHƯNG BỎ QUA nếu địa chỉ là 0
                if (WriteAddr_Gen != 3'b000) begin
                    gen_registers[WriteAddr_Gen] <= WriteData_Gen;
                end
            end
            
            // 2. Ghi HI/LO
            if (HILO_WriteEn) begin
                reg_HI <= HI_in;
                reg_LO <= LO_in;
            end
            
            // 3. Ghi Special Reg (MTSR)
            if (WriteEn_Spec) begin
                case (Funct_MTSR)
                    3'b010: reg_RA <= Data_MTSR; // mtra $rt
                    3'b011: reg_AT <= Data_MTSR; // mtat $rt
                    3'b100: reg_HI <= Data_MTSR; // mthi $rt
                    3'b101: reg_LO <= Data_MTSR; // mtlo $rt
                    default: ;
                endcase
            end

            // 4. (QUAN TRỌNG) Luôn ép $0 về 0
            // Đảm bảo $0 luôn là 0, ngay cả khi có lỗi
            gen_registers[0] <= 16'h0000;
        end
    end
    
    // --- Logic ĐỌC Special Reg (MFSR) ---
    always @(*) begin
        case (Funct_MFSR)
            3'b000: ReadData_MFSR = 16'h0000; // mfz
            3'b001: ReadData_MFSR = PC_in;    // mfpc
            3'b010: ReadData_MFSR = reg_RA;   // mfra
            3'b011: ReadData_MFSR = reg_AT;   // mfat
            3'b100: ReadData_MFSR = reg_HI;   // mfhi
            3'b101: ReadData_MFSR = reg_LO;   // mflo
            default: ReadData_MFSR = 16'h0000;
        endcase
    end

endmodule