//////////////////////////////////////////////////////////////////////////////////
// RV32i RTL
// Create Date: 09/01/2023
// Module Name: Datapath
// Project Name: EEE 468
// Dept of EEE, BUET
// Team 01
// Developed by: Diganta & Co.
//////////////////////////////////////////////////////////////////////////////////
module Datapath(
input clk,rst,PCWrite,AdrSrc,MemWrite,IRWrite,RegWrite,core_select,
input [1:0]ALUSrcA,ALUSrcB,ResultSrc,
input [2:0]ImmSrc,
input [3:0]ALUControl,
input [31:0] ReadData,
output [3:0]flags,
output [31:0]Instr,Adr,WriteData
);

parameter DATA_LENGTH = 32;
parameter ADDRESS_LENGTH = 32;
wire [31:0]PC,OldPC,read_data_2,read_data_1,ALUOut,Data,ALUResult,SrcA,SrcB,Result; //Areaddata1,2Immext declared below
////1
program_counter pc(
.clk(clk),.rst(rst),.PCWrite(PCWrite),
.PCNext(Result),
.PC(PC)
    );
    
mux_2X1 mux1(
.A(PC),.B(Result),
.Sel(AdrSrc),
.mux(Adr)
    );
    
/*  Memory mem(
.clk(clk),.rst(rst),.MemWrite(MemWrite),
.address(Adr),.data_in(WriteData),
.data_out(ReadData)
);    
  data_memory_wrapper  # (DATA_LENGTH,ADDRESS_LENGTH) wrapper(.clk(clk), .core_select(core_select),.from_core_mem_en(core_select), 
 .from_core_mem_wr_en(MemWrite), .from_core_mem_rd_en(core_select), .from_core_mem_address(Adr),
 .from_core_mem_data_in(WriteData), .from_core_mem_data_length(2'b00), .to_core_mem_data_out(ReadData)
);*/
   
    
 Instruction_register IR(
.rst(rst),.clk(clk),.IRWrite(IRWrite),.mem_data(ReadData),.PC(PC),
.OldPC(OldPC),.Instr(Instr)
    );
  
Data_register Data_register(
.rst(rst),.clk(clk),.ReadData(ReadData),
.Data(Data)
 );
        
mux_4X1 mux2(
.A(ALUOut),.B(Data),.C(ALUResult),.D(32'h00000000),
.Sel(ResultSrc),
.mux(Result)
    );
        
 wire [31:0] Aread_data_1,ImmExt; //Aread_data_2 not required, its same as WriteData  
Registers R(
.rst(rst),.clk(clk),.RegWrite(RegWrite),
.read_reg1(Instr[19:15]),.read_reg2(Instr[24:20]),.write_address(Instr[11:7]),
.write_data(Result),
.read_data_1(read_data_1),.read_data_2(read_data_2)
);    
        
Extend Extend(
.rst(rst),.Instr(Instr),.ImmSrc(ImmSrc),
.ImmExt(ImmExt)
);

A A(
.rst(rst),.clk(clk),.read_data_1(read_data_1),.read_data_2(read_data_2),
.Aread_data_1(Aread_data_1),.Aread_data_2(WriteData)
    );
       

mux_4X1 mux3(
.A(PC),.B(OldPC),.C(Aread_data_1),.D(32'h00000000),
.Sel(ALUSrcA),
.mux(SrcA)
    );
    
mux_4X1 mux4(
.A(WriteData),.B(ImmExt),.C(32'h00000004),.D(32'h00000000),
.Sel(ALUSrcB),
.mux(SrcB)
    );

ALU ALU(
.rst(rst),.a(SrcA),.b(SrcB),.ALUControl(ALUControl),
.flags(flags),
.ALUResult(ALUResult) 
    );
    
    
ALU_out_reg Alu_out_reg(
.rst(rst),
.clk(clk),
.ALUResult(ALUResult),
.ALUOut(ALUOut)
    );        

endmodule
