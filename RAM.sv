`timescale 1ns / 1ps

module RAM (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    input  logic [ 2:0] func3,
    output logic [31:0] rData
);
    logic [31:0] mem[0:2**6-1];  // 0x00 ~ 0x0f => 0x40 * 4 => 0x100

    always_ff @(posedge clk) begin
        if (we) begin
            case (func3[1:0])
                2'b00: begin  // Byte
                    case (addr[1:0])
                        2'b00: mem[addr[31:2]][7:0] <= wData[7:0];
                        2'b01: mem[addr[31:2]][15:8] <= wData[7:0];
                        2'b10: mem[addr[31:2]][23:16] <= wData[7:0];
                        2'b11: mem[addr[31:2]][31:24] <= wData[7:0];
                    endcase
                end
                2'b01: begin  // Half
                    case (addr[1])
                        1'b0: mem[addr[31:2]][15:0] <= wData[15:0];
                        1'b1: mem[addr[31:2]][31:16] <= wData[15:0];
                    endcase
                end
                default: begin  // Word
                    mem[addr[31:2]] <= wData;
                end
            endcase
        end
    end
            /*
            mem[addr[31:2]] <= (mem[addr[31:2]]&~(data_shift_value<<(addr[1:0]<<4'b1000)))| 
            (wData<<(addr[1:0]<<4'b1000))&~(data_shift_value<<(addr[1:0]<<4'b1000));
            */
            /*
    always_ff @(posedge clk) begin
        if (we) begin
            mem[addr[31:2]] <= (mem[addr[31:2]]&(~(32'b0)<<data_shift_value)) | wData;
            end
            end
         */

    always_comb begin
        rData = mem[addr[31:2]];
        case (func3)
            3'b000: begin  //Byte Signed
                case (addr[1:0])
                    2'b00:
                    rData = {{24{mem[addr[31:2]][7]}}, mem[addr[31:2]][7:0]};
                    2'b01:
                    rData = {{24{mem[addr[31:2]][15]}}, mem[addr[31:2]][15:8]};
                    2'b10:
                    rData = {{24{mem[addr[31:2]][23]}}, mem[addr[31:2]][23:16]};
                    2'b11:
                    rData = {{24{mem[addr[31:2]][31]}}, mem[addr[31:2]][31:24]};
                endcase
            end
            3'b100: begin  //Byte Unsiged
                case (addr[1:0])
                    2'b00: rData = {24'b0, mem[addr[31:2]][7:0]};
                    2'b01: rData = {24'b0, mem[addr[31:2]][15:8]};
                    2'b10: rData = {24'b0, mem[addr[31:2]][23:16]};
                    2'b11: rData = {24'b0, mem[addr[31:2]][31:24]};
                endcase
            end
            3'b001: begin  //Half Signed
                case (addr[1])
                    0:
                    rData = {{16{mem[addr[31:2]][15]}}, mem[addr[31:2]][15:0]};
                    1:
                    rData = {{16{mem[addr[31:2]][31]}}, mem[addr[31:2]][31:16]};
                endcase
            end
            3'b101: begin  //Half Unsigned
                case (addr[1])
                    0: rData = {16'b0, mem[addr[31:2]][15:0]};
                    1: rData = {16'b0, mem[addr[31:2]][31:16]};
                endcase
            end

        endcase
    end
endmodule
