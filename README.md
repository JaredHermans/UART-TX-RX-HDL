# UART-TX-RX-HDL
This project creates a loopback of data sent by the computer via a serial COM connection. The Go Board FPGA recieves data from the computer,
displays it on the two 7-segment displays and then transmits the recieved data back to the computer. The UART recievers operates at 115,200 baud.

**UART_Loopback_Top** is the top level module in the design. It instantiates modules UART_RX, UART_TX, and Binary_To_7Segment.

**UART_TX** and **UART_RX** modules set up a state machine where there is one state for idle where it stays until there is a data valid pulse, one state for a 
start bit, one state for the 8 data bits, one state for a stop bit, and one state for a cleanup where the data valid bit is set back to 0. 

**Binary_To_7Segment** module converts a 4 bit binary number to a hex number and displays it on a single
7-Segment display.

**VHDL** code with the same performance in **VHDL-Code**.
