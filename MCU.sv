`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic reset
);
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;
    logic [31:0] busAddr;
    logic [31:0] busWData;
    logic        busWe;
    logic [31:0] busRData;
    logic [ 2:0] func3;

    ROM U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    CPU_RV32I U_RV32I (.*);

    RAM U_RAM (
        .clk  (clk),
        .we   (busWe),
        .addr (busAddr),
        .wData(busWData),
        .func3(func3),
        .rData(busRData)
    );
endmodule
