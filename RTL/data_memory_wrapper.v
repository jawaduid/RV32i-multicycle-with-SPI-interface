module data_memory_wrapper #( parameter DATA_LENGTH, ADDRESS_LENGTH) (clk, core_select,
from_core_mem_en, from_core_mem_wr_en, from_core_mem_rd_en, from_core_mem_address,
from_core_mem_data_in, from_core_mem_data_length, to_core_mem_data_out,
from_intf_mem_ctrl_mem_en, from_intf_mem_ctrl_mem_wr_en, from_intf_mem_ctrl_mem_rd_en,
from_intf_mem_ctrl_mem_address, from_intf_mem_ctrl_mem_data_in,
from_intf_mem_ctrl_mem_data_length, to_intf_mem_ctrl_mem_data_out);
	
	input clk;
	input core_select;
	//core
	input from_core_mem_en;
	input from_core_mem_wr_en;
	input from_core_mem_rd_en;
	input [DATA_LENGTH-1:0] from_core_mem_address;
	input [DATA_LENGTH-1:0] from_core_mem_data_in;
	input [1:0] from_core_mem_data_length;
	output wire [DATA_LENGTH-1:0] to_core_mem_data_out;
	//top
	input from_intf_mem_ctrl_mem_en;
	input from_intf_mem_ctrl_mem_wr_en;
	input from_intf_mem_ctrl_mem_rd_en;
	input [DATA_LENGTH-1:0] from_intf_mem_ctrl_mem_address;
	input [DATA_LENGTH-1:0] from_intf_mem_ctrl_mem_data_in;
	input [1:0] from_intf_mem_ctrl_mem_data_length;
	output wire [DATA_LENGTH-1:0] to_intf_mem_ctrl_mem_data_out;
	wire mem_wr_en, mem_en, mem_rd_en;
	wire [DATA_LENGTH-1:0] mem_data;
	wire [ADDRESS_LENGTH-1:0] mem_address;
	
	assign mem_en = core_select ? from_core_mem_en: from_intf_mem_ctrl_mem_en;
	assign mem_wr_en = core_select ? from_core_mem_wr_en: from_intf_mem_ctrl_mem_wr_en;
	assign mem_rd_en = core_select ? from_core_mem_rd_en: from_intf_mem_ctrl_mem_rd_en;
	assign mem_data = core_select ? from_core_mem_data_in : from_intf_mem_ctrl_mem_data_in;
	assign mem_address = core_select ? from_core_mem_address[ADDRESS_LENGTH-1:2]:
	from_intf_mem_ctrl_mem_address[ADDRESS_LENGTH-1:0];
	
	wire [3:0] mem_we_out;
	wire [3:0] spi_mem_we_out;
	wire [3:0] core_mem_we_out;
	wire [DATA_LENGTH-1:0] mem_data_out_wire;
	
	assign spi_mem_we_out = (from_intf_mem_ctrl_mem_data_length==2'b00) ? 4'b0000 :
	(from_intf_mem_ctrl_mem_data_length==2'b01) ? 4'b0001 :
      (from_intf_mem_ctrl_mem_data_length==2'b10) ? 4'b0011 : 4'b1111; //data_length signal is stuck 2'b11 from spi interface
	
	assign core_mem_we_out = (from_core_mem_data_length==2'b00) ? 4'b1111 :
	(from_core_mem_data_length==2'b01) ? 4'b0011 : (from_core_mem_data_length==2'b10) ? 4'b0001 :
	4'b0000; // data_length 2'b00 means full word write; why tf ;-
	
	assign mem_we_out = mem_wr_en ?core_select?core_mem_we_out : spi_mem_we_out: 4'b0000;
	
	assign to_core_mem_data_out = (core_select & mem_rd_en) ? mem_data_out_wire :
	to_core_mem_data_out;
	
	assign to_intf_mem_ctrl_mem_data_out = (~core_select & mem_rd_en) ? mem_data_out_wire :
	to_intf_mem_ctrl_mem_data_out;

	DFFRAM_RTL_2048 #(ADDRESS_LENGTH,DATA_LENGTH) memory_from_DFFRAM (
		.CLK(clk),
		.WE(mem_we_out),
		.EN(mem_en),
		.Di(mem_data),
		.Do(mem_data_out_wire),
		.A(mem_address)
	);
endmodule
