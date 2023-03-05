module Instruction_register(
input rst,clk,IRWrite,
input [31:0]mem_data,PC,
output reg [31:0]OldPC,Instr
    );
    
    always @ (posedge clk or negedge rst) begin
     if (!rst) 
		begin
			Instr <= 0;
			OldPC <= 0;
		end 
      else if (IRWrite) 
		begin
			OldPC <= PC;
			Instr <= mem_data;
		end
    end
     
endmodule
