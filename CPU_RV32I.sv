module CPU_RV32I (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    input  logic [31:0] busRData,
    output logic [31:0] instrMemAddr,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    output logic        busWe,
    output logic [ 2:0] func3
);

    logic       regFileWe;
    logic [3:0] ALUControl;
    logic       ALUSrcMuxSel;
    logic [2:0] RFWDSrcMuxSel;
    logic       branch;
    logic       jal;
    logic       jalr;
    logic       PCEn;

    ControlUnit U_Control (.*);

    DataPath U_DataPath (.*);
endmodule
