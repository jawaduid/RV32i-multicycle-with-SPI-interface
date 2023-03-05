
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2022 06:55:18 AM
// Design Name: 
// Module Name: mux2X1
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


module mux_2X1(
input [31:0]A,B,
input Sel,
output [31:0]mux
    );
    
    assign mux = Sel ? B : A;
endmodule
