module Registers(
input rst,clk,RegWrite,
input [4:0]read_reg1,read_reg2,write_address,
input [31:0]write_data,
output [31:0]read_data_1,read_data_2
);
reg [31:0]registers[0:31];

assign read_data_1 = registers[read_reg1];
assign read_data_2 = registers[read_reg2];

integer i;
always @ (posedge clk  or negedge rst)begin
	if (!rst) begin
		for (i=0;i<32;i=i+1)
		  registers[i] <= 0;
		end 
	else if (RegWrite)
		registers[write_address] <= write_data;
	registers[0] <= 32'h00000000;
end 
endmodule