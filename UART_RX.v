//////////////////////////////////////////////////////////////////////
// Author:      Jared Hermans Project from NANDLAND
//////////////////////////////////////////////////////////////////////
// Description: This file contains the UART Receiver.  This receiver is 
//              able to receive 8 bits of serial data, one start bit, one 
//              stop bit, and no parity bit.  When receive is complete 
//              o_RX_DV will be driven high for one clock cycle.
// 
// Parameters:  Set Parameter CLKS_PER_BIT as follows:
//              CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
//              Example: 25 MHz Clock, 115200 baud UART
//              (25000000)/(115200) = 217
//////////////////////////////////////////////////////////////////////////////

module UART_RX #(
    parameter         CLKS_PER_BIT      = 217
)
(
    input             i_Rst_L,
    input             i_Clk,
    input             i_RX_Serial,          //Serial data stream coming from computer  
    output reg        o_RX_DV,              //single pulse
    output reg [7:0]  o_RX_Byte             //single byte recieved form computer
);

    localparam   IDLE                    = 3'b000;               //State machine
    localparam   RX_START_BIT            = 3'b001;
    localparam   RX_DATA_BITS            = 3'b010;
    localparam   RX_STOP_BIT             = 3'b011;
    localparam   CLEANUP                 = 3'b100;

    //reg [7:0]   r_Clock_Count           = 0;
    //reg [2:0]   r_BIT_INDEX             = 0;
    //reg [7:0]   r_RX_Byte               = 0;
    //reg         r_RX_DV                 = 0;
    //reg [2:0]   r_SM_Main               = 0;

    reg [$clog2(CLKS_PER_BIT) - 1: 0] r_Clock_Count;
    reg [2:0] r_BIT_INDEX;
    reg [2:0] r_SM_Main;

    //Purpose: Control RX State machine
    always @ (posedge i_Clk) begin
        
        if (i_Rst_L) begin
            r_SM_Main <= 3'b000;
            o_RX_DV <= 1'b0;
        end
        else begin
            case (r_SM_Main)
                IDLE : begin
                    o_RX_DV         <= 1'b0;
                    r_Clock_Count   <= 0;
                    r_BIT_INDEX     <= 0;

                    if (i_RX_Serial == 1'b0)                    //Start bit detected
                        r_SM_Main <= RX_START_BIT;
                    else
                        r_SM_Main <= IDLE;
                end

                ////Check middle of start bit to make sure it is still low
                RX_START_BIT : begin
                    if (r_Clock_Count == (CLKS_PER_BIT - 1) / 2) begin                      //Finding the middle of the bit
                        if (i_RX_Serial == 1'b0) begin
                            r_Clock_Count <= 0;                                             //reset counter, found the middle
                            r_SM_Main       <= RX_DATA_BITS;
                        end                     
                        else
                            r_SM_Main <= IDLE;
                    
                    end
                    else begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        r_SM_Main <= RX_START_BIT;
                    end

                end //case: RX_START_BIT

                //Wait CLKS_PER_BIT - 1 clock cycles to sample serial data
                RX_DATA_BITS : begin
                    if (r_Clock_Count < CLKS_PER_BIT - 1) begin                             
                        r_Clock_Count <= r_Clock_Count + 1;
                        r_SM_Main <= RX_DATA_BITS;
                    end
                    else begin
                        r_Clock_Count <= 0;                                     //Clear the counter
                        o_RX_Byte[r_BIT_INDEX] <= i_RX_Serial;                  //Sample the line

                        //Check if we have recieved all bits
                        if (r_BIT_INDEX < 7) begin
                            r_BIT_INDEX <= r_BIT_INDEX + 1;
                            r_SM_Main <= RX_DATA_BITS;
                        end
                        else begin
                            r_BIT_INDEX <= 0;
                            r_SM_Main <= RX_STOP_BIT;                           //recieve stop bit
                        end
                    end
                end // case : RX_DATA_BITS

                //Recieve Stop bit. stop bit = 1
                RX_STOP_BIT : begin
                    //wait CLKS_PER_BIT - 1 clock cycles for stop bit to finish
                    if (r_Clock_Count < CLKS_PER_BIT - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        r_SM_Main <= RX_STOP_BIT;
                    end
                    else begin
                        o_RX_DV <= 1'b1;                                        //Data in byte is valid
                        r_Clock_Count <= 0;
                        r_SM_Main <= CLEANUP;
                    end

                end // case: RX_STOP_BIT

                //Stay here 1 clock
                CLEANUP : begin
                    r_SM_Main <= IDLE;
                    o_RX_DV <= 1'b0;
                end

                default : 
                    r_SM_Main <= IDLE;

            endcase
        end
    end

    //assign o_RX_DV = r_RX_DV;
    //assign o_RX_Byte = r_RX_Byte;

endmodule // UART_RX