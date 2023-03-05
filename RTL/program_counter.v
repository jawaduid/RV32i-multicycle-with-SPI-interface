module program_counter(
input clk,rst,PCWrite,
input [31:0]PCNext,
output reg [31:0]PC
    );
     always @ (posedge clk  or negedge rst) //next instruction
    begin
    if(!rst)
		PC <= 0;  
    else if (PCWrite) 
		PC <= PCNext;
    else 
		PC <= PC; end
endmodule
