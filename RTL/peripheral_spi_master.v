///////////////////////////////////////////////////////////////////////////////
// Description: SPI (Serial Peripheral Interface) Master
//              Creates master based on input configuration.
//              Sends a 8-byet word one bit at a time on MOSI
//              Will also receive byte data one bit at a time on MISO.
//              Any data on input byte will be shipped out on MOSI.
//
//              To kick-off transaction, user must pulse i_TX_DV.
//              This module supports multi-byte transmissions by pulsing
//              i_TX_DV and loading up i_TX_Byte when o_TX_Ready is high.
//
//              This module is only responsible for controlling Clk, MOSI, 
//              and MISO.  If the SPI peripheral requires a chip-select, 
//              this must be done at a higher level.
//
// Note:        i_Clk must be at least 2x faster than i_SPI_Clk
//
// Parameters:  SPI_MODE, can be 0, 1, 2, or 3.  See above.
//              Can be configured in one of 4 modes:
//              Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//               0   |             0             |        0
//               1   |             0             |        1
//               2   |             1             |        0
//               3   |             1             |        1
//              More: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_numbers
//              CLKS_PER_HALF_BIT - Sets frequency of o_SPI_Clk.  o_SPI_Clk is
//              derived from i_Clk.  Set to integer number of clocks for each
//              half-bit of SPI data.  E.g. 100 MHz i_Clk, CLKS_PER_HALF_BIT = 2
//              would create o_SPI_CLK of 25 MHz.  Must be >= 2
//
///////////////////////////////////////////////////////////////////////////////

module SPI_Master
  #(parameter SPI_MODE = 0,
    parameter CLKS_PER_HALF_BIT = 2)
  (
   // Control/Data Signals,
   input        i_Rst_L,     // FPGA Reset
   input        i_Clk,       // FPGA Clock
   
   // TX (MOSI) Signals
   input [31:0]   i_TX_Word,        // Byte to transmit on MOSI
   input          i_TX_DV,          // Data Valid Pulse with i_TX_Byte
   output reg     o_TX_Ready,       // Transmit Ready for next byte
  

   // SPI Interface
   output reg o_SPI_Clk,
   output reg o_SPI_MOSI
   );

  // SPI Interface (All Runs at SPI Clock Domain)
  wire w_CPOL;     // Clock polarity
  wire w_CPHA;     // Clock phase

  reg [$clog2(CLKS_PER_HALF_BIT*2)-1:0] r_SPI_Clk_Count;
  reg r_SPI_Clk;
  
  
  reg [19:0] r_SPI_Clk_Edges;
  reg r_Leading_Edge;
  reg r_Trailing_Edge;
  
  reg        r_TX_DV;
  reg [31:0] r_TX_Word;
  
  reg [4:0] r_TX_Bit_Count;

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



  // Purpose: Generate SPI Clock correct number of times when DV pulse comes
  always @(posedge i_Clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      o_TX_Ready      <= 1'b0;
      r_SPI_Clk_Edges <= 0;
      r_Leading_Edge  <= 1'b0;
      r_Trailing_Edge <= 1'b0;
      r_SPI_Clk       <= w_CPOL; // assign default state to idle state
      r_SPI_Clk_Count <= 0;
    end
    else
    begin

      // Default assignments
      r_Leading_Edge  <= 1'b0;
      r_Trailing_Edge <= 1'b0;
      
      if (i_TX_DV)
      begin
        o_TX_Ready      <= 1'b0;
        r_SPI_Clk_Edges = 64;  // Total # edges in one word ALWAYS 64
      end
      else if (r_SPI_Clk_Edges > 0)
      begin
        o_TX_Ready <= 1'b0;
        
        if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT*2-1)
        begin
          r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
          r_Trailing_Edge <= 1'b1;
          r_SPI_Clk_Count <= 0;
          r_SPI_Clk       <= ~r_SPI_Clk;
        end
        else if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT-1)
        begin
          r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
          r_Leading_Edge  <= 1'b1;
          r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
          r_SPI_Clk       <= ~r_SPI_Clk;
        end
        else
        begin
          r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
        end
      end  
      else
      begin
        o_TX_Ready <= 1'b1;
      end
      
      
    end // else: !if(~i_Rst_L)
  end // always @ (posedge i_Clk or negedge i_Rst_L)

  
  
  

  // Purpose: Register i_TX_Word when Data Valid is pulsed.
  // Keeps local storage of word in case higher level module changes the data
  always @(posedge i_Clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      r_TX_Word <= 32'h00;
      r_TX_DV   <= 1'b0;
    end
    else
      begin
        r_TX_DV <= i_TX_DV; // 1 clock cycle delay
        if (i_TX_DV)
        begin
          r_TX_Word <= i_TX_Word;
        end
      end // else: !if(~i_Rst_L)
  end // always @ (posedge i_Clk or negedge i_Rst_L)

  
  
  

  // Purpose: Generate MOSI data
  // Works with both CPHA=0 and CPHA=1
  always @(posedge i_Clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      o_SPI_MOSI     <= 1'b0;
      r_TX_Bit_Count <= 5'b11111; // send MSb first
    end
    else
    begin
      // If ready is high, reset bit counts to default
      if (o_TX_Ready)
      begin
        r_TX_Bit_Count <= 5'b11111;
      end
      // Catch the case where we start transaction and CPHA = 0
      else if (r_TX_DV & ~w_CPHA)
      begin
        o_SPI_MOSI     <= i_TX_Word[5'b11111];
        r_TX_Bit_Count <= 5'b11110;
      end
      else if ((r_Leading_Edge & w_CPHA) | (r_Trailing_Edge & ~w_CPHA))
      begin
        r_TX_Bit_Count <= r_TX_Bit_Count - 1;
        o_SPI_MOSI     <= i_TX_Word[r_TX_Bit_Count];
      end
    end
  end


  
  
  // Purpose: Add clock delay to signals for alignment.
  always @(posedge i_Clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      o_SPI_Clk  <= w_CPOL;
    end
    else
      begin
        o_SPI_Clk <= r_SPI_Clk;
      end // else: !if(~i_Rst_L)
  end // always @ (posedge i_Clk or negedge i_Rst_L)
  

endmodule // SPI_Master

