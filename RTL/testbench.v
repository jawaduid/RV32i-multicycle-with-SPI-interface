`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Description:       SPI_Slave_Controller Testbench
///////////////////////////////////////////////////////////////////////////////

`include "peripheral_spi_master.v"
`include "peripheral_top.v"
`include "DFFRAM_RTL_2048.v"
`include "data_memory_wrapper.v"

module SPI_Memory_Controller_TB ();
  
  //========================Top =======================//
  
  // parameter related to SPI interface
  parameter SPI_MODE = 0;           // CPOL = 1, CPHA = 1
  parameter CLKS_PER_HALF_BIT = 1;  // 50 MHz
  parameter MAIN_CLK_DELAY = 5;     // 100 MHz
  parameter CS_INACTIVE_CLKS = 3;   // Adds 4 SPI_clk amount of deay between words
  
  
  // Parameter related to Wrapper
  parameter DATA_LENGTH = 32;       
  parameter ADDRESS_LENGTH = 32;
  
  
  // Core Specific
  logic rst_n     = 1'b0;  
  logic clk       = 1'b0;
  logic core_select = 1'b1;

  
  // Peripheral Specific Signals, used only for testbench purpose
  logic [31:0] r_Master_TX_Word = 0;
  logic r_Master_TX_DV = 1'b0;
  logic w_Master_TX_Ready;
  //logic r_Master_TX_Count = 1'b1;
  
  
  // SPI signals fed into our system 
  logic SPI_Clk;
  logic SPI_MOSI;
  logic SPI_CS_n;
  
  
  // SPI_Slave_Controller outputs
  logic from_spi_mem_en;
  logic from_spi_mem_wr_en;
  logic from_spi_mem_rd_en;
  logic [ADDRESS_LENGTH-1:0] from_spi_mem_address;
  logic [DATA_LENGTH-1:0] from_spi_mem_data_in;
  logic [1:0] from_spi_mem_data_length;
  
  logic RX_DV;  	// Data Valid pulse (1 clock cycle)
  logic RX_Word;  	// Word received on MOSI

  
  // Wrapper Specific Signals
  logic [DATA_LENGTH-1:0] to_spi_mem_data_out;
  

  // Clock Generators:
  always #(MAIN_CLK_DELAY) clk = ~clk;
 
  // Instantiate Peripheral
  peripheral_top
  #(.SPI_MODE(SPI_MODE),
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
    .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS),
    .DATA_LENGTH(DATA_LENGTH),
    .ADDRESS_LENGTH(ADDRESS_LENGTH)
   ) peripheral_top_Inst
  (
   // Control/Data Signals,
   .i_Rst_L(rst_n),     // Reset
   .i_Clk(clk),         // Clock
   
   // TX (MOSI) Signals
   .i_TX_Word(r_Master_TX_Word),     // Byte to transmit on MOSI
   .i_TX_DV(r_Master_TX_DV),         // Data Valid Pulse with i_TX_Byte
   .o_TX_Ready(w_Master_TX_Ready),   // Transmit Ready for Byte
   
   // Core select
    .core_select(core_select),
    
   // Output Wires for SPI Interface
    .o_SPI_Clk(SPI_Clk),
    .o_SPI_MOSI(SPI_MOSI),
    .o_SPI_CS_n(SPI_CS_n)
   );
  
  
  // Slave will receive the SPI data, its output will connect to   
  // data_memory_wrapper 
  // Instantiate SPI_Slave_Controller
  SPI_Slave_Controller
  #(.SPI_MODE(SPI_MODE),
    .DATA_LENGTH(DATA_LENGTH),
    .ADDRESS_LENGTH(ADDRESS_LENGTH)
   ) SPI_Slave_Controller_Inst
  (
   // Control/Data Signals,
    .i_rst_n(rst_n),      // Reset
    .i_clk(!clk),          // Clock
    
    .o_RX_DV(o_RX_DV),  // Data Valid pulse (1 clock cycle)
    .o_RX_Word(o_RX_Word),  // Word received on MOSI

   // SPI Interface
    .i_SPI_Clk(SPI_Clk),
    .i_SPI_MOSI(SPI_MOSI),
    .i_SPI_CS_n(SPI_CS_n),
    
    // Core select
    .core_select(core_select),
    
    //Outputs for wrapper
    .o_from_spi_mem_en(from_spi_mem_en),
    .o_from_spi_mem_wr_en(from_spi_mem_wr_en),
    .o_from_spi_mem_rd_en(from_spi_mem_rd_en),
    .o_from_spi_mem_address(from_spi_mem_address),
    .o_from_spi_mem_data_in(from_spi_mem_data_in),
    .o_from_spi_mem_data_length(from_spi_mem_data_length)
   );
  
  	wire [31:0]Adr, ReadData, WriteData;
	wire MemWrite;
  
  // Instantiate Core
	RV32i_core core(
	clk,rst_n,core_select, ReadData, Adr, WriteData, MemWrite
	);


	
  // Instantiate data_memory_wrapper_Ints
  data_memory_wrapper 
  #(.DATA_LENGTH(DATA_LENGTH),
    .ADDRESS_LENGTH(ADDRESS_LENGTH)
   ) data_memory_wrapper_Ints 
  (.clk(!clk), 
   .core_select(core_select),  
   //mem2core
   .from_core_mem_en(core_select),
   .from_core_mem_wr_en(MemWrite), 
   .from_core_mem_rd_en(core_select), 
   .from_core_mem_address(Adr),
   .from_core_mem_data_in(WriteData), 
   .from_core_mem_data_length(2'b00), 
   .to_core_mem_data_out(ReadData),
   // mem 2 spi
   .from_intf_mem_ctrl_mem_en(from_spi_mem_en), 
   .from_intf_mem_ctrl_mem_wr_en(from_spi_mem_wr_en), 
   .from_intf_mem_ctrl_mem_rd_en(from_spi_mem_rd_en), 
   .from_intf_mem_ctrl_mem_address(from_spi_mem_address), 
   .from_intf_mem_ctrl_mem_data_in(from_spi_mem_data_in), 
   .from_intf_mem_ctrl_mem_data_length(from_spi_mem_data_length), 
   .to_intf_mem_ctrl_mem_data_out(to_spi_mem_data_out)   
  );
  
  
  // Sends a single Word from master.  Will drive CS on its own.
  task SendSingleWord(input [31:0] data);
    @(posedge clk);
    r_Master_TX_Word <= data;
    r_Master_TX_DV   <= 1'b1;
    @(posedge clk);
    r_Master_TX_DV <= 1'b0;
    @(posedge clk);
    @(posedge w_Master_TX_Ready);
  endtask // SendSingleByte

  reg [31:0] Mem [0:127];
  initial $readmemh("ins2.mem", Mem);
  integer k;
  
  initial
    begin
      // Required for EDA Playground
      $dumpfile("dump.vcd"); 
      $dumpvars;
      
      rst_n  = 1'b0;
      core_select = 1'b0;
      repeat(2) @(posedge clk);
      rst_n  = 1'b1;
      core_select = 1'b0;

      // Sending the data from file to RAM through SPI
      begin
        for (k=0; k<68; k=k+1) begin
      		SendSingleWord(Mem[k]);
      		$display("Inst No %d : Sent out %h, Received %h", k,Mem[k],to_spi_mem_data_out); 
      		#10;
           //core_select = 1'b1;
        end
      end

     
      //$finish();      
    end // initial begin

initial begin
	#49403	core_select = 1;
	end

endmodule // SPI_Slave

