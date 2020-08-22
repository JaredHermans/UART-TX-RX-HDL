/////////////////////////////////////////////////////////////////////////////////////////
// Jared Hermans
/////////////////////////////////////////////////////////////////////////////////////////
// Description: This testbench will exercise the UART RX
//
// Parameters:  it sends out byte 0x37, and ensures the TX recieves it correctly.
////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module UART_TB ();

    //Testbench uses a 26 MHZ clock
    //Waht to interface to 115200 baus UART
    //25000000 / 115200 = 217 Clocks per bit
    parameter c_CLOCK_PERIOD_NS     = 40;
    parameter c_CLKS_PER_BIT        = 217;
    parameter c_BIT_PERIOD          = 8600;

    reg r_Clock = 0;
    reg r_TX_DV = 0;
    wire w_TX_Active, w_UART_Line;
    wire w_TX_Serial;
    reg [7:0] r_TX_Byte = 0;
    wire [7:0] w_RX_Byte;

    UART_RX #(
        .CLKS_PER_BIT(c_CLKS_PER_BIT)
    )
    UART_RX_Inst (
        .i_Rst_L(),
        .i_Clk(r_Clock),
        .i_RX_Serial(w_UART_Line),
        .o_RX_DV(w_RX_DV),
        .o_RX_Byte(w_RX_Byte)
    );

    UART_TX #(
        .CLKS_PER_BIT(c_CLKS_PER_BIT)
        )
    UART_TX_Inst (
        .i_Clock(r_Clock),
        .i_TX_DV(r_TX_DV),
        .i_TX_Byte(r_TX_Byte),
        .o_TX_Active(w_TX_Active),
        .o_TX_Serial(w_TX_Serial),
        .o_TX_Done()
    );

    //Keeps the UART Recieve input high (default) when
    //UART transmitter is not active
    assign w_UART_Line = w_TX_Active ? w_TX_Serial : 1'b1;      //? conditional assignment

    always #(c_CLOCK_PERIOD_NS / 2) r_Clock <= !r_Clock;

    //Main Testing:
    initial begin
        //Tell UART to send a command (exercise TX)
        @(posedge r_Clock);
        @(posedge r_Clock);
        r_TX_DV <= 1'b1;
        r_TX_Byte <= 8'h3F;
        @(posedge r_Clock);
        r_TX_DV <= 1'b0;

        //Check that the correct command was recieved
        @(posedge w_RX_DV);
        if (w_RX_Byte == 8'hF)
            $display("Test passed - Correct byte received");
        else
            $display("Test Failed - Incorrect byte received"); 
        $finish();
    end
endmodule