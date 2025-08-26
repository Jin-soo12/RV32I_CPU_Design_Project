`timescale 1ns / 1ps
`include "defines.sv"

module DataPath (
    // global signals
    input  logic        clk,
    input  logic        reset,
    // instruction memory side port
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    // control unit side port
    input  logic        PCEn,
    input  logic        regFileWe,
    input  logic        ALUSrcMuxSel,
    input  logic [ 3:0] ALUControl,
    input  logic [ 2:0] RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    // data memory side port
    input  logic [31:0] busRData,
    output logic [31:0] busAddr,
    output logic [31:0] busWData
);

    logic [31:0] ALUResult, ExeReg_ALUResult, RFData1, RFData2;
    logic [31:0] DecReg_RFData1, DecReg_RFData2, ExeReg_RFData2;
    logic [31:0] PCSrcData, PCOutData;
    logic [31:0] ALUSrcMuxOut, immExt, DecReg_immExt;
    logic [31:0] RFWDSrcMuxOut;
    logic [31:0]
        PC_4_AdderResult, PC_Imm_AdderResult, PCSrcMuxOut, ExeReg_PCSrcMuxOut;
    logic [31:0] PC_Imm_AdderSrcMuxOut;
    logic [31:0] MemAccReg_busRData;
    logic btaken;
    logic PCSrcMuxSel;

    assign instrMemAddr = PCOutData;
    assign busAddr = ExeReg_ALUResult;
    assign busWData = ExeReg_RFData2;


    RegisterFile U_RegisterFile (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (RFWDSrcMuxOut),
        .RD1(RFData1),
        .RD2(RFData2)
    );

    register U_DecReg_RFRD1 (
        .clk  (clk),
        .reset(reset),
        .d    (RFData1),
        .q    (DecReg_RFData1)
    );

    register U_DecReg_RFRD2 (
        .clk  (clk),
        .reset(reset),
        .d    (RFData2),
        .q    (DecReg_RFData2)
    );
    /*
    RFdata2Extend U_DecReg_RFData2Ext (
        .instrCode (instrCode),
        .RFData2   (DecReg_RFData2),
        .RFData2Ext(DecReg_RFData2Ext)
    );
*/
    register U_ExeReg_RFRD2 (
        .clk  (clk),
        .reset(reset),
        .d    (DecReg_RFData2),
        .q    (ExeReg_RFData2)
    );

    mux_2x1 U_ALUSrcMux (
        .sel(ALUSrcMuxSel),
        .x0 (DecReg_RFData2),
        .x1 (DecReg_immExt),
        .y  (ALUSrcMuxOut)
    );

    register U_MemAccReg_ReadData (
        .clk  (clk),
        .reset(reset),
        .d    (busRData),
        .q    (MemAccReg_busRData)
    );
    /*
    rDataExtend U_MemAccReg_busRDataExt (
        .instrCode  (instrCode),
        .busRData   (MemAccReg_busRData),
        .busRDataExt(MemAccReg_busRDataExt)
    );
*/
    mux_5x1 U_RFWDSrcMux (
        .sel(RFWDSrcMuxSel),
        .x0 (ALUResult),
        .x1 (MemAccReg_busRData),
        .x2 (DecReg_immExt),
        .x3 (PC_Imm_AdderResult),
        .x4 (PC_4_AdderResult),
        .y  (RFWDSrcMuxOut)
    );

    immExtend U_ImmExtend (
        .instrCode(instrCode),
        .immExt   (immExt)
    );

    register U_DecReg_ImmExtend (
        .clk  (clk),
        .reset(reset),
        .d    (immExt),
        .q    (DecReg_immExt)
    );

    ALU U_ALU (
        .ALUControl(ALUControl),
        .a         (DecReg_RFData1),
        .b         (ALUSrcMuxOut),
        .result    (ALUResult),
        .btaken    (btaken)
    );

    register U_ExeReg_ALU (
        .clk  (clk),
        .reset(reset),
        .d    (ALUResult),
        .q    (ExeReg_ALUResult)
    );

    mux_2x1 U_PC_IMM_AdderSrcMux (
        .sel(jalr),
        .x0 (PCOutData),
        .x1 (DecReg_RFData1),
        .y  (PC_Imm_AdderSrcMuxOut)
    );

    adder U_PC_Imm_Adder (
        .a(DecReg_immExt),
        .b(PC_Imm_AdderSrcMuxOut),
        .y(PC_Imm_AdderResult)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

    assign PCSrcMuxSel = jal | (branch & btaken);

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (PCSrcMuxOut)
    );

    register U_ExeReg_PCSrcMux (
        .clk  (clk),
        .reset(reset),
        .d    (PCSrcMuxOut),
        .q    (ExeReg_PCSrcMuxOut)
    );

    registerEn U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (PCEn),
        .d    (ExeReg_PCSrcMuxOut),
        .q    (PCOutData)
    );


endmodule

module ALU (
    input  logic [ 3:0] ALUControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        btaken
);
    always_comb begin
        result = 32'bx;
        case (ALUControl)
            `ADD:  result = a + b;
            `SUB:  result = a - b;
            `SLL:  result = a << b;
            `SLR:  result = a >> b;
            `SRA:  result = $signed(a) >>> b;
            `SLT:  result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: result = (a < b) ? 1 : 0;
            `XOR:  result = a ^ b;
            `OR:   result = a | b;
            `AND:  result = a & b;
        endcase
    end

    always_comb begin
        btaken = 1'b0;
        case (ALUControl[2:0])
            `BEQ:  btaken = (a == b);
            `BNE:  btaken = (a != b);
            `BLT:  btaken = ($signed(a) < $signed(b));
            `BGE:  btaken = ($signed(a) >= $signed(b));
            `BLTU: btaken = (a < b);
            `BGEU: btaken = (a >= b);
        endcase
    end
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);
    logic [31:0] mem[0:31];
    
    initial begin  //Simulation을 위한 임의의 값 할당
        for (int i = 0; i < 32; i++) begin
            mem[i] = 10 + i;
        end
   /*
    mem[1] = -100;
    mem[2] = 3;
    */
    end
    always_ff @(posedge clk) begin
        if (we) begin
            mem[WA] <= WD;
        end
    end

    assign RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
    assign RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;
endmodule

module registerEn (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (en) q <= d;
        end
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end
endmodule

module mux_5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            3'b000: y = x0;
            3'b001: y = x1;
            3'b010: y = x2;
            3'b011: y = x3;
            3'b100: y = x4;
        endcase
    end
endmodule

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;
            `OP_TYPE_S:
            immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_I: begin
                case (func3)
                    3'b001:  immExt = {27'b0, instrCode[24:20]};  //SLLI
                    3'b011:  immExt = {20'b0, instrCode[31:20]};  //SRLI, SRAI
                    3'b101:  immExt = {27'b0, instrCode[24:20]};  //SLTIU
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                endcase
            end
            `OP_TYPE_B:
            immExt = {
                {20{instrCode[31]}},
                instrCode[7],
                instrCode[30:25],
                instrCode[11:8],
                1'b0
            };
            `OP_TYPE_LU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_AU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_J:
            immExt = {
                instrCode[31],
                instrCode[19:12],
                instrCode[20],
                instrCode[30:21],
                1'b0
            };
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
        endcase
    end
endmodule
/*
module RFdata2Extend (
    input  logic [31:0] instrCode,
    input  logic [31:0] RFData2,
    output logic [31:0] RFData2Ext
);

    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];
    always_comb begin
        RFData2Ext = RFData2;
        case (opcode)
            `OP_TYPE_S: begin
                case (func3)
                    3'b000: RFData2Ext = {{24{1'b0}}, RFData2[7:0]};
                    3'b001: RFData2Ext = {{16{1'b0}}, RFData2[15:0]};
                endcase
            end
        endcase
    end
endmodule
*/
/*
module rDataExtend (
    input  logic [31:0] instrCode,
    input  logic [31:0] busRData,
    output logic [31:0] busRDataExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];
    always_comb begin
        busRDataExt = busRData;
        case (opcode)
            `OP_TYPE_R: busRDataExt = busRData;
            `OP_TYPE_L: begin
                case (func3)
                    3'b000: busRDataExt = {{24{busRData[7]}}, busRData[7:0]};
                    3'b001: busRDataExt = {{16{busRData[15]}}, busRData[15:0]};
                    3'b010: busRDataExt = busRData;
                    3'b100: busRDataExt = {24'b0, busRData[7:0]};
                    3'b101: busRDataExt = {16'b0, busRData[15:0]};
                endcase
            end
        endcase
    end
endmodule
*/
