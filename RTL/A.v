//////////////////////////////////////////////////////////////////////////////////
// RV32i RTL
// Create Date: 09/01/2023
// Module Name: RISCV_ALU
// Project Name: EEE 468
// Dept of EEE, BUET
// Team 01
// Developed by: Diganta & Co.
//////////////////////////////////////////////////////////////////////////////////
module A(
input rst,clk,
input [31:0]read_data_1,read_data_2,
output reg [31:0]Aread_data_1,Aread_data_2
    );
    
    always @ (posedge clk or negedge rst) begin
     if (!rst)
		begin
			Aread_data_1 <= 0;
			Aread_data_2 <= 0;
		end 
      else if (clk)
		begin 
			Aread_data_1 <= read_data_1; 
			Aread_data_2 <= read_data_2; 
		end
    end
    
endmodule
