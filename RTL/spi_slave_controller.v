///////////////////////////////////////////////////////////////////////////////
// Description: SPI (Serial Peripheral Interface) Slave
//              Creates slave based on input configuration.
//              Receives a 8-byte word one bit at a time on MOSI

//				MISO is deactivated**

//              Supports multiple bytes per transaction when CS_n is kept 
//              low during the transaction.
//
// Note:        i_Clk must be at least 4x faster than i_SPI_Clk
//              MISO is tri-stated when not communicating.  Allows for multiple
//              SPI Slaves on the same interface.
//
// Parameters:  SPI_MODE, can be 0, 1, 2, or 3.  See above.
//              Can be configured in one of 4 modes:
//              Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//               0   |             0             |        0
//               1   |             0             |        1
//               2   |             1             |        0
//               3   |             1             |        1
//              More info: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_numbers
///////////////////////////////////////////////////////////////////////////////

module SPI_Slave_Controller
  #(parameter SPI_MODE = 0,
    parameter DATA_LENGTH = 32,  
    parameter ADDRESS_LENGTH = 32)
  (
   // Control/Data Signals,
   input             i_rst_n,    // Reset, active low
   input             i_clk,      // Clock
   output reg        o_RX_DV,    // Data Valid pulse (1 clock cycle)
   output reg [31:0] o_RX_Word,  // Word received on MOSI

   // SPI Interface
   input      i_SPI_Clk,
   input      i_SPI_MOSI,
   input      i_SPI_CS_n,        // active low
    
   // Core select
   input core_select,
    
   // Output signals for wrapper
   output wire o_from_spi_mem_en,
   output wire o_from_spi_mem_wr_en, // EDITED BY DIGANTA, (REG > wire)
   output wire o_from_spi_mem_rd_en, // EDITED BY DIGANTA, (REG > wire)
   output reg [ADDRESS_LENGTH-1:0] o_from_spi_mem_address,
   output wire [DATA_LENGTH-1:0] o_from_spi_mem_data_in,
   output wire [1:0] o_from_spi_mem_data_length
   );

  
  // SPI Interface (All Runs at SPI Clock Domain)
  wire w_CPOL;     // Clock polarity
  wire w_CPHA;     // Clock phase
  wire w_SPI_Clk;  // Inverted/non-inverted depending on settings
  
  reg [4:0] r_RX_Bit_Count;
  reg [31:0] r_RX_Word;
  reg [31:0] r_Temp_RX_Word;
  reg r_RX_Done, r2_RX_Done, r3_RX_Done;

  // CPOL: Clock Polarity
  // CPOL=0 means clock idles at 0, leading edge is rising edge.
  // CPOL=1 means clock idles at 1, leading edge is falling edge.
  assign w_CPOL  = (SPI_MODE == 2) | (SPI_MODE == 3);

  // CPHA: Clock Phase
  // CPHA=0 means the "out" side changes the data on trailing edge of clock
  //              the "in" side captures data on leading edge of clock
  // CPHA=1 means the "out" side changes the data on leading edge of clock
  //              the "in" side captures data on the trailing edge of clock
  assign w_CPHA  = (SPI_MODE == 1) | (SPI_MODE == 3);
  assign w_SPI_Clk = w_CPHA ? ~i_SPI_Clk : i_SPI_Clk;


  // Purpose: Recover SPI Word in SPI Clock Domain
  // Samples MOSI line on correct edge of SPI Clock
  always @(posedge w_SPI_Clk or posedge i_SPI_CS_n)
  begin
    if (i_SPI_CS_n)
    begin
      r_RX_Bit_Count <= 0;
      r_RX_Done      <= 1'b0;
    end
    else
    begin
      r_RX_Bit_Count <= r_RX_Bit_Count + 1;

      // Receive in LSB, shift up to MSB
      r_Temp_RX_Word <= {r_Temp_RX_Word[30:0], i_SPI_MOSI};
    
      if (r_RX_Bit_Count == 5'b11111)
      begin
        r_RX_Done <= 1'b1;
        r_RX_Word <= {r_Temp_RX_Word[30:0], i_SPI_MOSI};
      end
      else if (r_RX_Bit_Count == 5'b00000)
      begin
        r_RX_Done <= 1'b0;        
      end

    end // else: !if(i_SPI_CS_n)
  end // always @ (posedge w_SPI_Clk or posedge i_SPI_CS_n)



  // Purpose: Cross from SPI Clock Domain to main core clock domain
  // Assert o_RX_DV for 2 clock cycle when o_RX_Word has valid data.
  always @(posedge i_clk or negedge i_rst_n)
  begin
    if (~i_rst_n)
    begin
      r2_RX_Done <= 1'b0;
      r3_RX_Done <= 1'b0;
      o_RX_DV    <= 1'b0;
      o_RX_Word  <= 32'h00;
    end
    else
    begin
      // Here is where clock domains are crossed.
      // This will require timing constraint created, can set up long path.
      r2_RX_Done <= r_RX_Done;
      r3_RX_Done <= r2_RX_Done;

      // setting o_RX_DV to 1'b1 for 2 Clock cycle 
      if ((r2_RX_Done == 1'b0 && r_RX_Done == 1'b1) || (r3_RX_Done == 1'b0 && r2_RX_Done == 1'b1)) 
      begin
        o_RX_DV   <= 1'b1;  // Pulse Data Valid 2 clock cycle
        o_RX_Word <= r_RX_Word;
      end
      else
      begin
        o_RX_DV <= 1'b0;
      end
    end // else: !if(~i_Rst_L)
  end // always @ (posedge i_Bus_Clk)
  
  
  
  
  //=============== Wrapper Control and data signals ============//
  
   //write and read enable follows o_RX_DV
   assign o_from_spi_mem_en = ~core_select;
   assign o_from_spi_mem_wr_en = core_select ? 1'b0 : o_RX_DV;
   assign o_from_spi_mem_rd_en = core_select ? 1'b1 : ~o_RX_DV;
  
   // Receiving data from SPI
   assign o_from_spi_mem_data_in = o_RX_Word; 
   assign o_from_spi_mem_data_length = 2'b11;
  
  
  // address will reset only when i_rst_n is imposed
  always @(negedge i_rst_n)
    begin
      if (~i_rst_n)
      begin
        o_from_spi_mem_address <= 32'hffffffff;
      end
    end
  
  // If core_select is 1'b1, address will retain its formal value, otherwise will increment 
  // after receiving a word
  always @(posedge o_RX_DV)
    begin
      if(~core_select)
        begin
        	o_from_spi_mem_address <= o_from_spi_mem_address + 1;
        end
    end

endmodule // SPI_Slave
