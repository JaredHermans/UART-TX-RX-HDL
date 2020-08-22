-----------------------------------------------------------------------------------------
-- Jared Hermans
-----------------------------------------------------------------------------------------
-- Description: This file contains the UART Reciever. This Reciever is able to
--              recieve 8 bits of serial data, one start bit, one stop bit, and no parity
--              bit. Ater all 8 bits are recieved, o_Rx_done will be driven high for one 
--              clock cycle.
--  
-- Parameters: Set Parameter CLKS_PER_BIT as follows:
--              CLKS_PER_BIT = (Frequency of i_Clock) / (Frequency of UART)
--              25 MHz Clock, 115200 baud UART
--              (25000000) / (115200) = 217
-----------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_RX is
    generic (
        g_CLKS_PER_BIT : integer := 217          --Needs to be set correctly
    );
    port (
        i_Clk               : in  std_logic;
        i_RX_Serial         : in  std_logic;        --Serial data stream recieved from computer
        o_RX_DV             : out std_logic;        --Data valid pulse
        o_RX_Byte           : out std_logic_vector(7 downto 0)
    );
end UART_RX;

architecture RTL of UART_RX is
    type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits,      --enumerated type
                        s_RX_STOP_BIT, s_Cleanup);
    signal r_SM_Main : t_SM_Main := s_Idle;
    signal w_SM_Main : std_logic_vector(2 downto 0);    --For sumulation only

    signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT - 1 := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0;         --8 bits total
    signal r_RX_Byte : std_logic_vector(7 downto 0) := (others => '0');
    signal r_RX_DV : std_logic := '0';

begin

    --Purpose: Contro RX state machine
    p_UART_RX : process (i_Clk)
    begin
        if rising_edge(i_Clk) then

            case r_SM_Main is

                when s_Idle =>
                    r_RX_Dv     <= '0';
                    r_Clk_Count <= 0;
                    r_Bit_Index <= 0;

                    if i_RX_Serial = '0' then           --Start bit detected
                        r_Sm_Main <= s_RX_Start_Bit;
                    else
                        r_SM_Main <= s_Idle;
                    end if;

                --Check middlw of start bit to make sure it is still low
                when s_RX_Start_Bit => 
                    if r_Clk_Count = (g_CLKS_PER_BIT - 1) / 2 then
                        if i_RX_Serial = '0' then
                            r_CLK_Count <= 0;               --Reset counter since we found the middle
                            r_SM_Main   <= s_RX_Data_Bits;
                        else
                            r_SM_Main   <= s_Idle;
                        end if;
                    else
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main   <= s_RX_Start_Bit;
                    end if;

                --Wait g_CLKS_PER_BIT - 1 clock cycles to sample serial data
                when s_RX_Data_Bits =>
                    if r_Clk_Count < g_CLKS_PER_BIT - 1 then
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_RX_Data_Bits;
                    else r_Clk_Count            <= 0;
                    r_RX_Byte(r_Bit_Index)      <= i_RX_Serial;

                    --Check if we have recieved out all bits
                        if r_Bit_Index < 7 then
                            r_Bit_Index <= r_Bit_Index + 1;
                            r_SM_Main <= s_RX_Data_Bits;
                        else r_Bit_Index <= 0;
                        r_SM_Main <= s_RX_Stop_Bit;
                        end if;
                    end if;
                --Recieve Stop bit. Stop bit = 1
                when s_RX_Stop_Bit =>
                            --Wait g_CLKS_PER_BIT - 1 clock cycles for stop bit to finish
                    if r_Clk_Count < g_CLKS_PER_BIT - 1 then
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_RX_Stop_Bit;
                    else 
                        r_RX_DV         <= '1';
                        r_Clk_Count     <= 0;
                        r_SM_Main       <= s_Cleanup;
                    end if;

                --Stay here 1 clock
                when s_Cleanup => 
                    r_SM_Main <= s_Idle;
                    r_RX_DV   <= '0';
                    
                when others =>
                        r_SM_Main <= s_Idle;

            end case;
        end if;
    end process p_UART_RX;

    o_RX_DV <= r_RX_DV;
    o_RX_Byte <= r_RX_Byte;

    --Create a signal for simulation purposes (allows waveform display)
    w_SM_Main <=    "000" when r_Sm_Main = s_Idle else
                    "001" when r_SM_Main = s_RX_Start_Bit else
                    "010" when r_Sm_Main = s_RX_Data_Bits else
                    "011" when r_SM_Main = s_RX_Stop_Bit else
                    "100" when r_Sm_Main = s_Cleanup else
                    "101"; --should never get here
end RTL;
                