//////////////////////////////////////////////////////////////////////////////////
// RV32i RTL
// Create Date: 09/01/2023
// Module Name: RISCV_ALU
// Project Name: EEE 468
// Dept of EEE, BUET
// Team 01
// Developed by: Diganta & Co.
//////////////////////////////////////////////////////////////////////////////////
module Data_register(
input rst,clk,[31:0]ReadData,
output reg [31:0]Data
    );
    
    always @ (posedge clk or negedge rst) begin
     if (!rst)
      Data <= 32'h00000000;
      else
      Data <= ReadData; 
    end
    
endmodule
