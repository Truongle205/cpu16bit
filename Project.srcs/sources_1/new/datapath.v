/*
 * Module: datapath
 * Chức năng: Kết nối tất cả các thành phần phần cứng (PC, Muxes,
 * ALU, Register File, Memories) lại với nhau.
 * Được điều khiển bởi các tín hiệu từ Control Unit.
 */
module datapath(
    input clk,
    input rst,
    
    // --- Tín hiệu điều khiển TỪ Control Unit ---
    input PCWrite,         // 1 = Cho phép ghi giá trị mới vào PC
    input RegWrite,        // 1 = Cho phép ghi vào GPR (ALUout/Mem/MFSR)
    input MemRead,         // 1 = Đọc Data Memory
    input MemWrite,        // 1 = Ghi Data Memory
    input [4:0] ALUOp,     // Mã hoạt động cho ALU
    input ALUSrc,          // 0 = ALU_B lấy từ $rt, 1 = ALU_B lấy từ Imm_16bit
    input RegDst,          // 0 = Ghi vào $rt, 1 = Ghi vào $rd
    input [1:0] MemtoReg,  // 00 = Ghi ALU_Result, 01 = Ghi Mem_DataOut
                           // 10 = Ghi MFSR_DataOut
    input [1:0] PCSource,  // 00 = PC+2, 01 = BranchAddr, 10 = JumpAddr, 11 = JrAddr
    
    // Tín hiệu cho Special Registers
    input HILO_WriteEn,    // 1 = Ghi HI/LO (từ kết quả mult/div)
    input MTSR_WriteEn,    // 1 = Ghi (mtra, mtat, mthi, mtlo)
    input MFSR_ReadEn,     // 1 = Bật cờ (đang đọc MFSR)
    
    // --- Tín hiệu trạng thái CHO Control Unit ---
    output [3:0] opcode,
    output [2:0] funct,
    output Zero,           // Cờ Zero từ ALU (dùng cho bneq)
    output GTZ             // Cờ > 0 (dùng cho bgtz)
);

    // --- 1. PC và Instruction Fetch ---
    reg [15:0] pc;
    wire [15:0] pc_next, pc_plus_2;
    wire [15:0] instruction;

    // Bộ đếm chương trình (PC)
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 16'h0000; // Địa chỉ bắt đầu
        else if (PCWrite)
            pc <= pc_next;
    end
    
    assign pc_plus_2 = pc + 16'd2; // PC luôn trỏ đến lệnh 16-bit
    
    // Khối Instruction Memory
    instruction_memory imem(
        .Address(pc),
        .Instruction(instruction)
    );
    
    // --- 2. Instruction Decode (Trích xuất các trường) ---
    assign opcode = instruction[15:12];
    assign funct = instruction[2:0];
    
    wire [2:0] rs_addr = instruction[11:9];
    wire [2:0] rt_addr = instruction[8:6];
    wire [2:0] rd_addr = instruction[5:3];
    wire [5:0] imm_6bit = instruction[5:0];
    wire [11:0] addr_12bit = instruction[11:0];

    // --- 3. Sign Extender ---
    wire [15:0] imm_16bit;
    sign_extend se(
        .Imm_6bit(imm_6bit),
        .Imm_16bit(imm_16bit)
    );

    // --- 4. Register File ---
    wire [15:0] rs_data, rt_data;
    wire [15:0] wb_data; // Dữ liệu write-back
    wire [2:0] wb_addr;  // Địa chỉ write-back
    wire [15:0] alu_hi, alu_lo;
    wire [15:0] mfsr_data_out;
    
    register_file reg_file(
        .clk(clk),
        .rst(rst),
        .ReadAddr_rs(rs_addr),
        .ReadAddr_rt(rt_addr),
        .ReadData_rs(rs_data),
        .ReadData_rt(rt_data),
        
        .WriteEn_Gen(RegWrite),
        .WriteAddr_Gen(wb_addr),
        .WriteData_Gen(wb_data),
        
        .PC_in(pc_plus_2), // Gửi PC+2 cho lệnh mfpc
        
        // Cổng MTSR (mthi, mtlo, mtra, mtat)
        .WriteEn_Spec(MTSR_WriteEn),
        .Funct_MTSR(funct),
        .Data_MTSR(rt_data), // Lệnh MTSR lấy data từ $rt
        
        // Cổng GHI HI/LO (từ alu)
        .HILO_WriteEn(HILO_WriteEn),
        .HI_in(alu_hi),
        .LO_in(alu_lo),
        
        // Cổng MFSR (mf...)
        .Funct_MFSR(MFSR_ReadEn ? funct : 3'b000), // Chỉ đọc khi có lệnh
        .ReadData_MFSR(mfsr_data_out)
    );

    // --- 5. ALU ---
    wire [15:0] alu_in_A;
    wire [15:0] alu_in_B;
    wire [15:0] alu_result;
    wire zero_flag;
    
    // ALU Input A luôn là $rs
    assign alu_in_A = rs_data; 
    
    // Mux chọn ALU Input B:
    // 0 = $rt (R-type), 1 = Imm_16bit (I-type)
    assign alu_in_B = (ALUSrc == 0) ? rt_data : imm_16bit;
    
    alu alu_unit(
        .A(alu_in_A),
        .B(alu_in_B),
        .ALUOp(ALUOp),
        .Result(alu_result),
        .HI_Out(alu_hi),
        .LO_Out(alu_lo),
        .Zero(zero_flag)
    );
    
    assign Zero = zero_flag;
    assign GTZ = $signed(rs_data) > 0; // Cờ cho bgtz

    // --- 6. Data Memory ---
    wire [15:0] mem_data_out;
    
    data_memory dmem(
        .clk(clk),
        .Address(alu_result), // Địa chỉ tính từ ALU
        .DataIn(rt_data),     // Dữ liệu ghi là từ $rt
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .DataOut(mem_data_out)
    );
    
    // --- 7. Write-Back Muxes ---
    
    // Mux chọn ĐỊA CHỈ ghi:
    // 0 = $rt (cho addi, lh), 1 = $rd (cho R-type)
    assign wb_addr = (RegDst == 0) ? rt_addr : rd_addr;
    
    // Mux chọn DỮ LIỆU ghi:
    // 00 = Kết quả ALU
    // 01 = Dữ liệu từ Memory
    // 10 = Dữ liệu từ Special Reg (MFSR)
    assign wb_data = (MemtoReg == 2'b00) ? alu_result :
                     (MemtoReg == 2'b01) ? mem_data_out :
                     (MemtoReg == 2'b10) ? mfsr_data_out :
                     16'hXXXX; // Mặc định (lỗi)

    // --- 8. PC Next Logic Mux ---
    
    wire [15:0] branch_addr = pc + (imm_16bit << 1); // PC + offset*2
    wire [15:0] jump_addr = {pc[15:13], addr_12bit, 1'b0};
    wire [15:0] jr_addr = rs_data; // Địa chỉ từ $rs
    
    assign pc_next = (PCSource == 2'b00) ? pc_plus_2 :
                     (PCSource == 2'b01) ? branch_addr :
                     (PCSource == 2'b10) ? jump_addr :
                     (PCSource == 2'b11) ? jr_addr :
                     pc_plus_2; // Mặc định

endmodule