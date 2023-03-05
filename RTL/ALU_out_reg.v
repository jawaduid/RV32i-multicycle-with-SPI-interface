//////////////////////////////////////////////////////////////////////////////////
// RV32i RTL
// Create Date: 09/01/2023
// Module Name: RISCV_ALU
// Project Name: EEE 468
// Dept of EEE, BUET
// Team 01
// Developed by: Diganta & Co.
//////////////////////////////////////////////////////////////////////////////////

module ALU_out_reg(
input rst,clk,
input [31:0]ALUResult,
output reg [31:0]ALUOut
    );
    
    always @ (posedge clk or negedge rst) begin
     if (!rst)
      ALUOut <= 32'h00000000;
      else
      ALUOut <= ALUResult; 
    end
    
endmodule
