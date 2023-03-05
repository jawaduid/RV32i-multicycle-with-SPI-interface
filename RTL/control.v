module control(
input clk,rst,core_select,
input [3:0]flags,
input [6:0]op,funct7,
input [2:0]funct3,
output reg AdrSrc,IRWrite,MemWrite, RegWrite, 
output PCWrite,
output reg [1:0]ALUSrcA,ALUSrcB,ResultSrc,
output reg[2:0]ImmSrc,
output reg[3:0]ALUControl 
    );

reg [1:0]ALUOp;
/////////////////////////////////////// FSM START /////////////////////////////////////////////////
reg PCUpdate,Branch;
reg [4:0]present_state;
reg [4:0]next_state;
parameter idle = 4'b1111,state_0 = 4'b0000,state_1 = 4'b0001,state_2 = 4'b0010,state_3 = 4'b0011,
       state_4 = 4'b0100,state_5 = 4'b0101,state_6 = 4'b0110,state_7 = 4'b0111,state_8 = 4'b1000,
	   state_9 = 4'b1001,state_10 = 4'b1010,state_11 = 4'b1011,state_12 = 4'b1100, state_13 = 4'b1101;


always @ (*)
begin
   	if (!rst)
    		next_state <= idle;
	else if(!core_select)
			next_state <= present_state;
	else
	begin
		case (present_state)
     			idle :     next_state <= state_0;
     			state_0 :  next_state <= state_1;
				state_1 :  case(op)
								7'b0100011 : next_state <= state_2;		//sw
								7'b0000011 : next_state <= state_2;		//lw
								7'b0110011 : next_state <= state_6;  	//R
								7'b0010011 : next_state <= state_8;		//itypeALU
								7'b1101111 : next_state <= state_9;   	//jal
								7'b1100011 : next_state <= state_10;  	//B - type
								7'b1100111 : next_state <= state_11;  	//jalr
								7'b0010111	:next_state<= state_13; 	//uimm ops
								default : next_state <= next_state;            
							endcase
				state_2 :  case(op)   
							   7'b0000011 : next_state <= state_3;// load
							   7'b0100011 : next_state <= state_5;// store
							   default : next_state <= next_state; 
						   endcase
				state_3 :  next_state <= state_4;
				state_4 :  next_state <= state_0;         
				state_5 :  next_state <= state_0;  
				state_6 :  next_state <= state_7;  
				state_8 :  next_state <= state_7;  
				state_9 :  next_state <= state_7;  
				state_7 :  next_state <= state_0;
				state_10 :  next_state <= state_0;  
				state_11:	next_state <= state_12;
				state_12:	next_state <= state_0;
				state_13:	next_state <= state_7;
 	
		endcase
	end

end

 always @ (posedge clk or negedge rst) begin  //state register
  if (!rst)
     present_state <= idle;
  else
     present_state <= next_state;  
 end
 
 always @ (present_state,core_select) //output block
  begin
	if (!core_select) begin IRWrite <= 0; PCUpdate <= 0; Branch <=0; RegWrite <= 0; end
	else
	   case (present_state)
		   state_0 : begin AdrSrc <= 0; IRWrite <= 1; ALUSrcA <= 2'b00; ALUSrcB <= 2'b10; ALUOp <= 2'b00; ResultSrc <= 2'b10; PCUpdate <= 1; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
		   state_1 : begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b01; ALUSrcB <= 2'b01; ALUOp <= 2'b00; ResultSrc <= 2'b10; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
		   state_2 : begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b10; ALUSrcB <= 2'b01; ALUOp <= 2'b00; ResultSrc <= 2'b10; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
		   state_3 : begin AdrSrc <= 1; IRWrite <= 0; ALUSrcA <= 2'b10; ALUSrcB <= 2'b00; ALUOp <= 2'b00; ResultSrc <= 2'b00; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
		   state_4 : begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b00; ALUSrcB <= 2'b00; ALUOp <= 2'b00; ResultSrc <= 2'b01; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 1; end
		   state_5 : begin AdrSrc <= 1; IRWrite <= 0; ALUSrcA <= 2'b10; ALUSrcB <= 2'b00; ALUOp <= 2'b00; ResultSrc <= 2'b00; PCUpdate <= 0; Branch <=0; MemWrite <= 1; RegWrite <= 0; end
		   state_6 : begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b10; ALUSrcB <= 2'b00; ALUOp <= 2'b10; ResultSrc <= 2'b10; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
		   state_7 : begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b10; ALUSrcB <= 2'b00; ALUOp <= 2'b00; ResultSrc <= 2'b00; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 1; end
		   state_8 : begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b10; ALUSrcB <= 2'b01; ALUOp <= 2'b10; ResultSrc <= 2'b10; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
		   state_9 : begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b01; ALUSrcB <= 2'b10; ALUOp <= 2'b00; ResultSrc <= 2'b00; PCUpdate <= 1; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
		   state_10: begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b10; ALUSrcB <= 2'b00; ALUOp <= 2'b01; ResultSrc <= 2'b00; PCUpdate <= 0; Branch <=1; MemWrite <= 0; RegWrite <= 0; end
		   state_11: begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b01; ALUSrcB <= 2'b10; ALUOp <= 2'b00; ResultSrc <= 2'b10; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 1; end
		   state_12: begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b10; ALUSrcB <= 2'b01; ALUOp <= 2'b00; ResultSrc <= 2'b10; PCUpdate <= 1; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
		   state_13: begin AdrSrc <= 0; IRWrite <= 0; ALUSrcA <= 2'b01; ALUSrcB <= 2'b01; ALUOp <= 2'b00; ResultSrc <= 2'b00; PCUpdate <= 0; Branch <=0; MemWrite <= 0; RegWrite <= 0; end
	   endcase  
  end
/////////////////////////////////////// FSM END /////////////////////////////////////////////////


/////////////////////////////////////// Branch Control //////////////////////////////////////////
reg BranchCond;

always@(*)
	case(funct3)
		3'b000: BranchCond <= flags[2];			//beq, Z
		3'b001: BranchCond <= !flags[2];			//bne, ~Z
		3'b100: BranchCond <= flags[3]^flags[0];		//blt, N^V
		3'b101: BranchCond <= !(flags[3]^flags[0]);	//bge, ~(N^V)
		3'b110: BranchCond <= !(flags[1] | flags[2]);	//bltu, ~(Z or C)
		3'b111: BranchCond <= (flags[1] | flags[2]);	//bgeu, Z or C
	default:	BranchCond <=0;
	endcase
assign PCWrite = PCUpdate|(Branch&BranchCond);
/////////////////////////////////////// Branch Control End /////////////////////////////////////

/////////////////////////////////////// ALU Decoder ////////////////////////////////////////////
always@(*)
	case(ALUOp)
		2'b00:	ALUControl <= 4'b0000;
		2'b01:	ALUControl <= 4'b0001; //B - type
		2'b10:	case(funct3)
					3'b000:	case({op[5],funct7[5]})
								2'b00:	ALUControl <= 4'b0000; //addi
								2'b01:	ALUControl <= 4'b0000; //addi
								2'b10:	ALUControl <= 4'b0000; //add
								2'b11:	ALUControl <= 4'b0001; //sub
							endcase

					3'b001:     ALUControl <= 4'b0110;	//sll: shift left log.
											//I and R not seperated
					3'b010:	ALUControl <= 4'b0101;	//slt: set less than 												//signed
					3'b011:	ALUControl <= 4'b1101;	//sltu: set less than 												//unsigned
					3'b100:     ALUControl <= 4'b0100;	//xor

					3'b101:     case(funct7[5])
								1'b0: ALUControl <= 4'b0111;   //srl: shift 												//right log.
								1'b1: ALUControl <= 4'b1111;   //sra: shift 												//right arith.
							endcase
					3'b110:	ALUControl <= 4'b0011;	//or
					3'b111:	ALUControl <= 4'b0010;	//and
				endcase
	endcase
/////////////////////////////////////// ALU Decoder End ////////////////////////////////////////////

/////////////////////////////////////// Extend Control ////////////////////////////////////////////
always@(*)
	case(op)
		7'b0000011:	ImmSrc <= 3'b000;	//lw
		7'b0100011:	ImmSrc <= 3'b001;	//sw
		7'b0110011:	ImmSrc <= 3'b000;	//R type
		7'b1100011:	ImmSrc <= 3'b010;	//beq
		7'b0010011:	ImmSrc <= 3'b000;	//I-ALU
		7'b1101111:	ImmSrc <= 3'b011;	//jal
		7'b1100111:	ImmSrc <= 3'b000;	//jalr
		7'b0010111:	ImmSrc <= 3'b100;	//upper immediate
	endcase	
/////////////////////////////////////// Extend Control End ////////////////////////////////////////////	
 endmodule
 
//begin AdrSrc <= 0; IRWrite <= 1; ALUSrcA <= 2'b00; ALUSrcB <= 2'b10; ALUOp <= 2'b00; ResultSrc <= 2'b10; PCUpdate <= 1; Branch <=0; MemWrite <= 0; RegWrite <= 0; end