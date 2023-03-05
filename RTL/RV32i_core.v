
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2022 03:24:53 AM
// Design Name: 
// Module Name: RV32i_multi
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


module RV32i_core(
input clk,rst,core_select,
input [31:0]ReadData,
output [31:0]Adr, WriteData,
output MemWrite
);

wire AdrSrc,IRWrite,RegWrite, PCWrite;
wire [1:0]ALUSrcA,ALUSrcB, ResultSrc;
wire [2:0]ImmSrc;
wire [3:0] ALUControl;
wire [31:0]Instr;
wire [3:0]flags;

control control_unit(
.clk(clk),.rst(rst),.core_select(core_select),.flags(flags),.op(Instr[6:0]),.funct7(Instr[31:25]),.funct3(Instr[14:12]),.AdrSrc(AdrSrc),.IRWrite(IRWrite),
.MemWrite(MemWrite), .RegWrite(RegWrite), .PCWrite(PCWrite),.ALUSrcA(ALUSrcA),.ALUSrcB(ALUSrcB), .ResultSrc(ResultSrc),.ImmSrc(ImmSrc),.ALUControl(ALUControl) 
);
    
Datapath datapath(
 .clk(clk),.rst(rst),.PCWrite(PCWrite),.AdrSrc(AdrSrc),.MemWrite(MemWrite),
 .IRWrite(IRWrite),.RegWrite(RegWrite),.core_select(core_select),.ALUSrcA(ALUSrcA),.ALUSrcB(ALUSrcB),
 .ResultSrc(ResultSrc),.ImmSrc(ImmSrc),.ALUControl(ALUControl),.ReadData(ReadData),.flags(flags),
 .Instr(Instr),.Adr(Adr),.WriteData(WriteData)
);
       
endmodule
