//////////////////////////////////////////////////////////////////////////////////
// RV32i RTL
// Create Date: 09/01/2023
// Module Name: RISCV_ALU
// Project Name: EEE 468
// Dept of EEE, BUET
// Team 01
// Developed by: Diganta & Co.
//////////////////////////////////////////////////////////////////////////////////


// ALU is incomplete, must add more instructions later.
module ALU(input rst,
		   input reg[31:0]a,b,
           input reg[3:0]ALUControl,
           output reg[3:0] flags,
           output reg[31:0]ALUResult
          );

  reg [31:0] b_not;
  
  always@(*)begin
	if(!rst) ALUResult <= 0;
	else
		case(ALUControl)
		  4'b0000:	{flags[1],ALUResult} <= a+b;

		  4'b0001:	begin
				b_not = ~b + 1;
				{flags[1],ALUResult} <= a+b_not;
				end

		  4'b0101:  ALUResult <= (a[31]^b[31])? a[31] : (a < b);
							//slt, slti, signed comparison
		  4'b1101:	ALUResult <= a<b; //sltu, sltiu, unsigned comparison
		  4'b0011:	ALUResult <= a|b; //or
		  4'b0010:	ALUResult <= a&b; //and
		  4'b0100:	ALUResult <= a^b; //xor
		  4'b0110:  ALUResult <= a << b[4:0]; //sll, slli
		  4'b0111:  ALUResult <= a >> b[4:0]; //srl, srli
		  4'b1111:  ALUResult <= $signed(a) >>> b[4:0]; //sra, srai
		default: 	ALUResult <= ALUResult;
		endcase

    flags[2] = !(|ALUResult);
    flags[3] = ALUResult[31];
    if(ALUControl == 1)	flags[0] = a[31]&(!b[31])&(!ALUResult[31])|
						(!a[31])&(b[31])&ALUResult[31]; ///for negative numbers, b sign is inverted beforehand
		else flags[0] = a[31]&b[31]&(!ALUResult[31])|
		(!a[31])&(!b[31])&ALUResult[31];
  end
endmodule
