`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2022 01:42:40 AM
// Design Name: 
// Module Name: Imm_gen
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


module Extend(input rst,
              input reg [31:0]Instr,
              input wire [2:0]ImmSrc,
              output reg[31:0]ImmExt);
  always@(*)
    begin
      if(!rst)
        ImmExt <= 32'h00000000;
      else
        case(ImmSrc)
          3'b000:	ImmExt <= {{20{Instr[31]}}, Instr[31:20]};
          3'b001:	ImmExt <={{20{Instr[31]}}, Instr[31:25],Instr[11:7]};
          3'b010:	ImmExt <={{20{Instr[31]}}, Instr[7], 
                              Instr[30:25], Instr[11:8], 1'b0}; 
          3'b011:	ImmExt <={{12{Instr[31]}}, Instr[19:12], 
                              Instr[20], Instr[30:21], 1'b0};
		  3'b100:	ImmExt <= {Instr[31:12],12'h000};
        endcase  
    end
endmodule             