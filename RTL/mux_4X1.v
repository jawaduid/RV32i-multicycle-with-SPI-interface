module mux_4X1 ( input [31:0] A,                 
                         input [31:0] B,                 
                         input [31:0] C,     
						 input [31:0] D,             
                         input [1:0] Sel,               // input sel used to select between a,b,c,d
                         output [31:0] mux);             // 4-bit output based on input sel
   assign mux = Sel[1] ? (Sel[0] ? D : C) : (Sel[0] ? B : A);
endmodule