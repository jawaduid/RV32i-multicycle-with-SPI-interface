
///////////////////////////////////////////////////////////////////////////////
// Description: Top level module for SPI (Serial Peripheral Interface) Memory controller
//				With single chip-select (AKA Slave Select) capability
//
//              Supports arbitrary length byte transfers.
// 
//              Instantiates a SPI Master and adds single CS.
//              If multiple CS signals are needed, will need to use different
//              module, OR multiplex the CS from this at a higher level.
//
//              Instantiates a SPI Slave which will reveive the signals from Master and drive the 
//				data_memory_wrapper declared in the testbench
//
//              If multiple CS signals are needed, will need to use different
//              module, OR multiplex the CS from this at a higher level.
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
//				Mode 0 is selected for our purpose
//
//              CLKS_PER_HALF_BIT - Sets frequency of o_SPI_Clk.  o_SPI_Clk is
//              derived from i_Clk.  Set to integer number of clocks for each
//              half-bit of SPI data.  E.g. 100 MHz i_Clk, CLKS_PER_HALF_BIT = 2
//              would create o_SPI_CLK of 25 MHz.  Must be >= 2
//
// 
//              CS_INACTIVE_CLKS - Sets the amount of time in clock cycles to
//              hold the state of Chip-Selct high (inactive) before next 
//              command is allowed on the line.  Useful if chip requires some
//              time when CS is high between trasnfers.
///////////////////////////////////////////////////////////////////////////////

module peripheral_top
  #(parameter SPI_MODE = 0,
    parameter CLKS_PER_HALF_BIT = 2,
    parameter CS_INACTIVE_CLKS = 1,
    parameter DATA_LENGTH = 32,  
    parameter ADDRESS_LENGTH = 32)
  (
   // Control/Data Signals,
   input        i_Rst_L,     // Reset
   input        i_Clk,       // Clock
   
   // TX (MOSI) Signals
   input [31:0]  i_TX_Word,       // Byte to transmit on MOSI
   input         i_TX_DV,         // Data Valid Pulse with i_TX_Byte
   output        o_TX_Ready,      // Transmit Ready for next byte
   
    
   // Core select
   input core_select,
   
   // Output Wires for SPI Interface
   output wire o_SPI_Clk,
   output wire o_SPI_MOSI,
   output wire o_SPI_CS_n
   );
  
  
  
  /////////////// Master definition and its control////////////////////////
  // Output wires from master which will be connected to Slave
  //
  //


  localparam IDLE        = 2'b00;
  localparam TRANSFER    = 2'b01;
  localparam CS_INACTIVE = 2'b10;

  reg [1:0] r_SM_CS;
  reg r_CS_n;
  reg [$clog2(CS_INACTIVE_CLKS)-1:0] r_CS_Inactive_Count;
  wire w_Master_Ready;

  // Instantiate Master
  SPI_Master 
    #(.SPI_MODE(SPI_MODE),
      .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
      ) SPI_Master_Inst
   (
   // Control/Data Signals,
   .i_Rst_L(i_Rst_L),     // Reset
   .i_Clk(i_Clk),         // Clock
   
   // TX (MOSI) Signals
   .i_TX_Word(i_TX_Word),         // Byte to transmit
   .i_TX_DV(i_TX_DV),             // Data Valid Pulse 
   .o_TX_Ready(w_Master_Ready),   // Transmit Ready for Byte
   
   // SPI Interface
   .o_SPI_Clk(o_SPI_Clk),
   .o_SPI_MOSI(o_SPI_MOSI)
   );

  // Purpose: Control CS line using State Machine
  always @(posedge i_Clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      r_SM_CS <= IDLE;
      r_CS_n  <= 1'b1;   // Resets to high
      r_CS_Inactive_Count <= CS_INACTIVE_CLKS;
    end
    else
    begin

      case (r_SM_CS)      
      IDLE:
        begin
          if (r_CS_n & i_TX_DV) // Start of transmission
          begin
            r_CS_n     <= 1'b0;       // Drive CS low
            r_SM_CS    <= TRANSFER;   // Transfer bytes
          end
        end

      TRANSFER:
        begin
          // Wait until SPI is done transferring do next thing
          if (w_Master_Ready)
            begin
              r_CS_n  <= 1'b1; // we done, so set CS high
              r_CS_Inactive_Count <= CS_INACTIVE_CLKS;
              r_SM_CS             <= CS_INACTIVE;
          	end // if (w_Master_Ready)
        end // case: TRANSFER

      CS_INACTIVE:
        begin
          if (r_CS_Inactive_Count > 0)
          begin
            r_CS_Inactive_Count <= r_CS_Inactive_Count - 1'b1;
          end
          else
          begin
            r_SM_CS <= IDLE;
          end
        end

      default:
        begin
          r_CS_n  <= 1'b1; // we done, so set CS high
          r_SM_CS <= IDLE;
        end
      endcase // case (r_SM_CS)
    end
  end // always @ (posedge i_Clk or negedge i_Rst_L)

  assign o_SPI_CS_n = r_CS_n;
  assign o_TX_Ready  = (r_SM_CS == IDLE) & ~i_TX_DV;
  
  
endmodule // SPI_Master_With_Single_CS

