`timescale  1ns/1ps

module AUG_System_tb ();

reg                      Transfer_tb;
reg                      PCLK_tb;
reg                      PRESETn_tb; 
reg                      RW_tb;       
reg          [31:0]      APB_Address_tb;    
reg          [31:0]      APB_Wr_Data_tb;  
reg          [3:0]       APB_Strobe_tb;
wire         [31:0]      APB_Rd_Data_tb;     
wire                     APB_Error_tb;

wire                     RX_IN_tb;

wire                     TX_OUT_tb;
wire                     Busy_tb;

wire         [7:0]       PORTA;
wire         [7:0]       PORTB;
wire         [7:0]       PORTC;
wire         [7:0]       PORTD;


reg     Manual_Input;
reg     Manual_Mode;

//Using the Tx to send the data frames and using Manual Mode to introduce errors.
assign RX_IN_tb = Manual_Mode ? Manual_Input : TX_OUT_tb;

//Constants for readability

localparam      BR_Divisor        =   32'd139;  //16MHz -> 115200 
localparam      SYS_CLK_PER       =   62.5;
localparam      H_SYS_CLK_PER     =   31.25;
localparam      TX_CLK_PER        =   BR_Divisor * SYS_CLK_PER;
localparam      H_TX_CLK_PER      =   0.5 * TX_CLK_PER; 
localparam      RX_CLK_PER        =   TX_CLK_PER / 8; 

localparam      UART        =   32'b0000_0000_0000_0001_0000_0000_0000_0000,
                GPIO        =   32'b0000_0000_0000_0010_0000_0000_0000_0000;

localparam      TXRX          =       0,
                BRD           =       1,
                Prescale      =       2,
                UARTCTRL      =       3,
                UARTFLAGS     =       4;

localparam      A_MODE            =   0,
                A_DIRECTION       =   1,
                A_OUTPUT          =   2,
                A_INPUT           =   3,
                B_MODE            =   4,
                B_DIRECTION       =   5,
                B_OUTPUT          =   6,
                B_INPUT           =   7,
                C_MODE            =   8,
                C_DIRECTION       =   9,
                C_OUTPUT          =   10,
                C_INPUT           =   11,
                D_MODE            =   12,
                D_DIRECTION       =   13,
                D_OUTPUT          =   14,
                D_INPUT           =   15;

localparam      IDLE      =   2'b00,
                SETUP     =   2'b01,
                ACCESS    =   2'b10;

integer I;

initial 
    begin
        $dumpfile("AUG_System.vcd");
        $dumpvars;

        //Initial Values
        PCLK_tb = 0;
        Transfer_tb = 0;
        Manual_Mode = 0;
        Manual_Input = 0;
        
        //Reset System
        PRESETn_tb = 0;
        #SYS_CLK_PER
        PRESETn_tb = 1;
        #SYS_CLK_PER

        

        $display("-----INITIALIZE UART REGISTERS WITH APB-----");
        $display("\n\n-----BAUD RATE DIVISOR REGISTER-----");
        Transfer_tb = 1;
        APB_Address_tb = UART | BRD;
        APB_Wr_Data_tb = BR_Divisor;
        RW_tb = 1;
        APB_Strobe_tb = 4'b0001;
        #SYS_CLK_PER;

        $display("TEST CASE 1 : ENTERED SETUP PHASE.");
        if (DUT.APB_Master.current_state == SETUP)
            $display("TEST CASE 1 PASSED.");
        else
            $display("TEST CASE 1 FAILED.");
            
        #SYS_CLK_PER;

        $display("TEST CASE 2 : ENTERED ACCESS PHASE.");
        if (DUT.APB_Master.current_state == ACCESS && DUT.PENABLE == 1)
            $display("TEST CASE 2 PASSED.");
        else
            $display("TEST CASE 2 FAILED.");

        #SYS_CLK_PER;

        $display("TEST CASE 3 : WROTE TO BAUD RATE REGISTER.");
        if (DUT.UART.BRD_R == BR_Divisor)
            $display("TEST CASE 3 PASSED.");
        else
            $display("TEST CASE 3 FAILED.");


        $display("\n\n-----PRESCALE REGISTER-----");
        APB_Address_tb = UART | Prescale;
        APB_Wr_Data_tb = 32'b0000_1000_0000_0000;
        RW_tb = 1;
        APB_Strobe_tb = 4'b0010;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;

        $display("TEST CASE 4 : WROTE TO PRESCALE REGISTER WITH DIFFERENT STROBE.");
        if (DUT.UART.Prescale_R == 8)
            $display("TEST CASE 4 PASSED.");
        else
            $display("TEST CASE 4 FAILED.");


        $display("\n\n-----CONTROL REGISTER-----");
        APB_Address_tb = UART | UARTCTRL;
        APB_Wr_Data_tb = 32'b1000;
        APB_Strobe_tb = 4'b0001;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;

        $display("TEST CASE 5 : ENABLED EVEN PARITY.");
        if (DUT.UART.UARTCTRL_R == 32'b1000 && DUT.UART.PAR_EN_TOP == 1 && DUT.UART.PAR_TYP_TOP == 0)
            $display("TEST CASE 5 PASSED.");
        else
            $display("TEST CASE 5 FAILED.");


        $display("\n\n-----FLAGS REGISTER-----");
        APB_Address_tb = UART | UARTFLAGS;
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 6 : READ FROM UART (TxEmpty = 1, RxEmpty = 1, Other Flags = 0).");
        if (APB_Rd_Data_tb == 32'b01100)
            $display("TEST CASE 6 PASSED.");
        else
            $display("TEST CASE 6 FAILED.");



        $display("-----TRANSMIT AND RECEIVE WITH UART-----");
        $display("\n\n-----WRITE TO TX'S FIFO-----");
        APB_Address_tb = UART | TXRX;
        RW_tb = 1;

        //Filling Tx FIFO 
        APB_Wr_Data_tb = 32'b0101_1001;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b0100_0010;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b0010_1010;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b1101_0110;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b1010_1010;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b0001_0001;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b1111_1111;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b0000_0000;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b1111_0000;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b0001_1011;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b1001_0110;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b0110_1001;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b1111_0010;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b1000_0100;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b0101_1110;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        APB_Wr_Data_tb = 32'b0010_0000;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;    
        #SYS_CLK_PER;

        $display("TEST CASE 7 : FIFO[0] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[0] == 8'b0101_1001)
            $display("TEST CASE 7 PASSED.");
        else
            $display("TEST CASE 7 FAILED.");

        $display("TEST CASE 8 : FIFO[1] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[1] == 8'b0100_0010)
            $display("TEST CASE 8 PASSED.");
        else
            $display("TEST CASE 8 FAILED.");

        $display("TEST CASE 9 : FIFO[2] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[2] == 8'b0010_1010)
            $display("TEST CASE 9 PASSED.");
        else
            $display("TEST CASE 9 FAILED.");

        $display("TEST CASE 10 : FIFO[3] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[3] == 8'b1101_0110)
            $display("TEST CASE 10 PASSED.");
        else
            $display("TEST CASE 10 FAILED.");

        $display("TEST CASE 11 : FIFO[4] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[4] == 8'b1010_1010)
            $display("TEST CASE 11 PASSED.");
        else
            $display("TEST CASE 11 FAILED.");

        $display("TEST CASE 12 : FIFO[5] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[5] == 8'b0001_0001)
            $display("TEST CASE 12 PASSED.");
        else
            $display("TEST CASE 12 FAILED.");

        $display("TEST CASE 13 : FIFO[6] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[6] == 8'b1111_1111)
            $display("TEST CASE 13 PASSED.");
        else
            $display("TEST CASE 13 FAILED.");

        $display("TEST CASE 14 : FIFO[7] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[7] == 8'b0000_0000)
            $display("TEST CASE 14 PASSED.");
        else
            $display("TEST CASE 14 FAILED.");

        $display("TEST CASE 15 : FIFO[8] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[8] == 8'b1111_0000)
            $display("TEST CASE 15 PASSED.");
        else
            $display("TEST CASE 15 FAILED.");

        $display("TEST CASE 16 : FIFO[9] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[9] == 8'b0001_1011)
            $display("TEST CASE 16 PASSED.");
        else
            $display("TEST CASE 16 FAILED.");

        $display("TEST CASE 17 : FIFO[10] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[10] == 8'b1001_0110)
            $display("TEST CASE 17 PASSED.");
        else
            $display("TEST CASE 17 FAILED.");

        $display("TEST CASE 18 : FIFO[11] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[11] == 8'b0110_1001)
            $display("TEST CASE 18 PASSED.");
        else
            $display("TEST CASE 18 FAILED.");

        $display("TEST CASE 19 : FIFO[12] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[12] == 8'b1111_0010)
            $display("TEST CASE 19 PASSED.");
        else
            $display("TEST CASE 19 FAILED.");

        $display("TEST CASE 20 : FIFO[13] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[13] == 8'b1000_0100)
            $display("TEST CASE 21 PASSED.");
        else
            $display("TEST CASE 21 FAILED.");

        $display("TEST CASE 22 : FIFO[14] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[14] == 8'b0101_1110)
            $display("TEST CASE 22 PASSED.");
        else
            $display("TEST CASE 22 FAILED.");

        $display("TEST CASE 23 : FIFO[15] HAS CORRECT DATA.");
        if (DUT.UART.Tx_FIFO.FIFO[15] == 8'b0010_0000)
            $display("TEST CASE 23 PASSED.");
        else
            $display("TEST CASE 23 FAILED.");

        #SYS_CLK_PER
        $display("TEST CASE 24 : PSLVERR ASSERTED WHEN TRYING TO WRITE TO FULL TX.");
        if (DUT.UART.PSLVERR == 1)
            $display("TEST CASE 24 PASSED.");
        else
            $display("TEST CASE 24 FAILED.");

        #SYS_CLK_PER
        $display("TEST CASE 25 : APB_Error ASSERTED BY APB.");
        if (APB_Error_tb == 1)
            $display("TEST CASE 25 PASSED.");
        else
            $display("TEST CASE 25 FAILED.");


        APB_Address_tb = UART | UARTFLAGS;
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 26 : READ FROM UART (TxFull = 1, RxEmpty = 1, Other Flags = 0).");
        if (APB_Rd_Data_tb == 32'b01010)
            $display("TEST CASE 26 PASSED.");
        else
            $display("TEST CASE 26 FAILED.");

        //Delay to Start of Transmission
        Transfer_tb = 0;
        #TX_CLK_PER;
        
        for (I = 0; I < 22; I = I + 1)
            #SYS_CLK_PER;
        #H_SYS_CLK_PER
        

        $display("\n\n-----BEGIN TRANSMITTING AND RECEIVING CORRECT FRAME WITH EVEN PARITY-----");
        
        #H_TX_CLK_PER; //To reach Falling Edge of Tx CLK

        $display("TEST CASE 27 : Start Bit Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 27 PASSED.");
        else
            $display("TEST CASE 27 FAILED.");

        #RX_CLK_PER
        #RX_CLK_PER // To reach Edge 6  (When Receiver finishes oversampling)
        $display("TEST CASE 28 : Start Bit Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 28 PASSED.");
        else
            $display("TEST CASE 28 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 29 : Bit 0 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 29 PASSED.");
        else
            $display("TEST CASE 29 FAILED.");

        $display("TEST CASE 30 : Bit 0 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 30 PASSED.");
        else
            $display("TEST CASE 30 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 31 : Bit 1 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 31 PASSED.");
        else
            $display("TEST CASE 31 FAILED.");

        $display("TEST CASE 32 : Bit 1 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 32 PASSED.");
        else
            $display("TEST CASE 32 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 33 : Bit 2 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 33 PASSED.");
        else
            $display("TEST CASE 33 FAILED.");

        $display("TEST CASE 34 : Bit 2 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 34 PASSED.");
        else
            $display("TEST CASE 34 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 35 : Bit 3 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 35 PASSED.");
        else
            $display("TEST CASE 35 FAILED.");

        $display("TEST CASE 36 : Bit 3 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 36 PASSED.");
        else
            $display("TEST CASE 36 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 37 : Bit 4 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 37 PASSED.");
        else
            $display("TEST CASE 37 FAILED.");

        $display("TEST CASE 38 : Bit 4 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 38 PASSED.");
        else
            $display("TEST CASE 38 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 39 : Bit 5 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 39 PASSED.");
        else
            $display("TEST CASE 39 FAILED.");

        $display("TEST CASE 40 : Bit 5 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 40 PASSED.");
        else
            $display("TEST CASE 40 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 41 : Bit 6 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 41 PASSED.");
        else
            $display("TEST CASE 41 FAILED.");

        $display("TEST CASE 42 : Bit 6 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 42 PASSED.");
        else
            $display("TEST CASE 42 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 43 : Bit 7 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 43 PASSED.");
        else
            $display("TEST CASE 43 FAILED.");

        $display("TEST CASE 44 : Bit 7 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 44 PASSED.");
        else
            $display("TEST CASE 44 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 45 : Correct Parity Bit Transmitted. (Even Parity)");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 45 PASSED.");
        else
            $display("TEST CASE 45 FAILED.");

        $display("TEST CASE 46 : Correct Parity Bit Received. (Even Parity)");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 46 PASSED.");
        else
            $display("TEST CASE 46 FAILED.");


        Transfer_tb = 1;
        APB_Address_tb = UART | TXRX;
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 47 : TRYING TO READ FROM RX WHEN IT HASN'T FINISHED RECEIVING.");
        if (APB_Error_tb == 1)
            $display("TEST CASE 47 PASSED.");
        else
            $display("TEST CASE 47 FAILED.");

        APB_Address_tb = UART | UARTFLAGS;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 48 : READ FROM UART (Busy = 1, RxEmpty = 1, Other Flags = 0).");
        if (DUT.UART.UARTFLAGS_R == 8'b1001)
            $display("TEST CASE 48 PASSED.");
        else
            $display("TEST CASE 48 FAILED.");

        #SYS_CLK_PER;

        #TX_CLK_PER
        $display("TEST CASE 49 : Stop Bit Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 49 PASSED.");
        else
            $display("TEST CASE 49 FAILED.");

        $display("TEST CASE 50 : Stop Bit Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 50 PASSED.");
        else
            $display("TEST CASE 50 FAILED.");

        $display("TEST CASE 51 : FRAME RECEIVED WITH NO ERRORS.");
        if (DUT.UART.Rx_FIFO.FIFO[0] == 8'b0101_1001)
            $display("TEST CASE 51 PASSED.");
        else
            $display("TEST CASE 51 FAILED.");

        #H_TX_CLK_PER

        #SYS_CLK_PER;
        APB_Address_tb = UART | UARTFLAGS;
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 52 : READ FROM UART (RxFull,RxEmpty,TxFull,TxEmpty,Busy = 0).");
        if (DUT.UART.UARTFLAGS_R == 8'b0)
            $display("TEST CASE 52 PASSED.");
        else
            $display("TEST CASE 52 FAILED.");

        APB_Address_tb = UART | TXRX;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        Transfer_tb = 0;

        $display("TEST CASE 53 : READING RECEIVED FRAME.");
        if (APB_Rd_Data_tb == 8'b0101_1001)
            $display("TEST CASE 53 PASSED.");
        else
            $display("TEST CASE 53 FAILED.");

        #SYS_CLK_PER;
        Transfer_tb = 1;
        APB_Address_tb = UART | UARTCTRL;
        APB_Wr_Data_tb = 32'b0000_1100; //Enable Odd Parity
        RW_tb = 1;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        Transfer_tb = 0;
        #TX_CLK_PER
        #TX_CLK_PER

        $display("\n\n-----BEGIN TRANSMITTING AND RECEIVING CORRECT FRAME WITH ODD PARITY-----");
        
        #H_TX_CLK_PER; 

        $display("TEST CASE 54 : Start Bit Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 54 PASSED.");
        else
            $display("TEST CASE 54 FAILED.");

        RW_tb = 1;
        $display("TEST CASE 54 : Start Bit Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 54 PASSED.");
        else
            $display("TEST CASE 54 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 55 : Bit 0 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 55 PASSED.");
        else
            $display("TEST CASE 55 FAILED.");

        $display("TEST CASE 56 : Bit 0 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 56 PASSED.");
        else
            $display("TEST CASE 56 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 57 : Bit 1 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 57 PASSED.");
        else
            $display("TEST CASE 57 FAILED.");

        $display("TEST CASE 58 : Bit 1 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 58 PASSED.");
        else
            $display("TEST CASE 58 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 59 : Bit 2 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 59 PASSED.");
        else
            $display("TEST CASE 59 FAILED.");

        $display("TEST CASE 60 : Bit 2 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 60 PASSED.");
        else
            $display("TEST CASE 1 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 61 : Bit 3 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 61 PASSED.");
        else
            $display("TEST CASE 61 FAILED.");

        $display("TEST CASE 62 : Bit 3 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 62 PASSED.");
        else
            $display("TEST CASE 62 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 63 : Bit 4 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 63 PASSED.");
        else
            $display("TEST CASE 63 FAILED.");

        $display("TEST CASE 64 : Bit 4 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 64 PASSED.");
        else
            $display("TEST CASE 64 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 65 : Bit 5 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 65 PASSED.");
        else
            $display("TEST CASE 65 FAILED.");

        $display("TEST CASE 66 : Bit 5 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 66 PASSED.");
        else
            $display("TEST CASE 66 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 67 : Bit 6 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 67 PASSED.");
        else
            $display("TEST CASE 67 FAILED.");

        $display("TEST CASE 68 : Bit 6 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 68 PASSED.");
        else
            $display("TEST CASE 68 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 69 : Bit 7 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 69 PASSED.");
        else
            $display("TEST CASE 69 FAILED.");

        $display("TEST CASE  70: Bit 7 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 70 PASSED.");
        else
            $display("TEST CASE 70 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 71 : Correct Parity Bit Transmitted. (Odd Parity)");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 71 PASSED.");
        else
            $display("TEST CASE 71 FAILED.");

        $display("TEST CASE 72 : Correct Parity Bit Received. (Odd Parity)");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 72 PASSED.");
        else
            $display("TEST CASE 72 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 73 : Stop Bit Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 73 PASSED.");
        else
            $display("TEST CASE 73 FAILED.");

        $display("TEST CASE 74 : Stop Bit Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 74 PASSED.");
        else
            $display("TEST CASE 74 FAILED.");

        $display("TEST CASE 75 : FRAME RECEIVED WITH NO ERRORS.");
        if (DUT.UART.Rx_FIFO.FIFO[1] == 8'b0100_0010)
            $display("TEST CASE 75 PASSED.");
        else
            $display("TEST CASE 75 FAILED.");

        #H_TX_CLK_PER

        Transfer_tb = 1;
        RW_tb = 0;
        APB_Address_tb = UART | TXRX;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        Transfer_tb = 0;
        $display("TEST CASE 76 : READING RECEIVED FRAME.");
        if (APB_Rd_Data_tb == 8'b0100_0010)
            $display("TEST CASE 76 PASSED.");
        else
            $display("TEST CASE 76 FAILED.");

        #SYS_CLK_PER;
        Transfer_tb = 1;
        APB_Address_tb = UART | UARTCTRL;
        APB_Wr_Data_tb = 32'b0000_0000; //Disable Parity
        RW_tb = 1;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        Transfer_tb = 0;
        #TX_CLK_PER
        #TX_CLK_PER

        $display("\n\n-----BEGIN TRANSMITTING AND RECEIVING CORRECT FRAME WITH PARITY DISABLED-----");
        
        #H_TX_CLK_PER; 

        $display("TEST CASE 77 : Start Bit Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 77 PASSED.");
        else
            $display("TEST CASE 77 FAILED.");

        RW_tb = 1;
        $display("TEST CASE 78 : Start Bit Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 78 PASSED.");
        else
            $display("TEST CASE 78 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 79 : Bit 0 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 79 PASSED.");
        else
            $display("TEST CASE 79 FAILED.");

        $display("TEST CASE 79 : Bit 0 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 79 PASSED.");
        else
            $display("TEST CASE 79 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 80 : Bit 1 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 80 PASSED.");
        else
            $display("TEST CASE 80 FAILED.");

        $display("TEST CASE 81 : Bit 1 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 81 PASSED.");
        else
            $display("TEST CASE 81 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 82 : Bit 2 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 82 PASSED.");
        else
            $display("TEST CASE 82 FAILED.");

        $display("TEST CASE 83 : Bit 2 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 83 PASSED.");
        else
            $display("TEST CASE 83 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 84 : Bit 3 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 84 PASSED.");
        else
            $display("TEST CASE 84 FAILED.");

        $display("TEST CASE 84 : Bit 3 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 84 PASSED.");
        else
            $display("TEST CASE 84 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 85 : Bit 4 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 85 PASSED.");
        else
            $display("TEST CASE 85 FAILED.");

        $display("TEST CASE 86 : Bit 4 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 86 PASSED.");
        else
            $display("TEST CASE 86 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 87 : Bit 5 Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 87 PASSED.");
        else
            $display("TEST CASE 87 FAILED.");

        $display("TEST CASE 88 : Bit 5 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 88 PASSED.");
        else
            $display("TEST CASE 88 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 89 : Bit 6 Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 89 PASSED.");
        else
            $display("TEST CASE 89 FAILED.");

        $display("TEST CASE 1 : Bit 90 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 90 PASSED.");
        else
            $display("TEST CASE 90 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 91 : Bit  Transmitted.");
        if (TX_OUT_tb == 0 && Busy_tb == 1)
            $display("TEST CASE 91 PASSED.");
        else
            $display("TEST CASE 91 FAILED.");

        $display("TEST CASE 92 : Bit 7 Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 0)
            $display("TEST CASE 92 PASSED.");
        else
            $display("TEST CASE 92 FAILED.");

        #TX_CLK_PER
        $display("TEST CASE 93 : Stop Bit Transmitted.");
        if (TX_OUT_tb == 1 && Busy_tb == 1)
            $display("TEST CASE 93 PASSED.");
        else
            $display("TEST CASE 93 FAILED.");

        $display("TEST CASE 94 : Stop Bit Received.");
        if (DUT.UART.Rx.Sampled_Bit_TOP == 1)
            $display("TEST CASE 94 PASSED.");
        else
            $display("TEST CASE 94 FAILED.");

        $display("TEST CASE 95 : FRAME RECEIVED WITH NO ERRORS.");
        if (DUT.UART.Rx_FIFO.FIFO[2] == 8'b0010_1010)
            $display("TEST CASE 95 PASSED.");
        else
            $display("TEST CASE 95 FAILED.");

        #H_TX_CLK_PER

        Transfer_tb = 1;
        RW_tb = 0;
        APB_Address_tb = UART | TXRX;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        Transfer_tb = 0;
        $display("TEST CASE 96 : READING RECEIVED FRAME.");
        if (APB_Rd_Data_tb == 8'b0010_1010)
            $display("TEST CASE 96 PASSED.");
        else
            $display("TEST CASE 96 FAILED.");

        #SYS_CLK_PER;
        Transfer_tb = 1;
        APB_Address_tb = UART | UARTCTRL;
        APB_Wr_Data_tb = 32'b0000_1000; //Disable Parity
        RW_tb = 1;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        Transfer_tb = 0;

        $display("\n\n-----RECEIVING FRAME WITH PARITY ERROR (Using Manual Mode)-----");

        for (I = 0; I < 10; I = I + 1)
            #TX_CLK_PER;
        
        //Turn on Manual Mode to Transmit a 0 instead of a 1 (Incorrect Parity)
        Manual_Mode = 1;
        Manual_Input = 0;   
        #TX_CLK_PER;

        Manual_Mode = 0;
        #TX_CLK_PER;
        #TX_CLK_PER;

        $display("TEST CASE 97 : DISREGARDED FRAME WITH INCORRECT PARITY.");
        if (DUT.UART.Rx_FIFO.FIFO[3] == 0)
            $display("TEST CASE 97 PASSED.");
        else
            $display("TEST CASE 97 FAILED.");


        $display("TEST CASE 98 : RX'S PARITY ERROR SIGNAL ASSERTED.");
        if (DUT.UART.Rx.Par_Err_TOP == 1)
            $display("TEST CASE 98 PASSED.");
        else
            $display("TEST CASE 98 FAILED.");

        #H_TX_CLK_PER

        Transfer_tb = 1;
        RW_tb = 0;
        APB_Address_tb = UART | UARTFLAGS;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        Transfer_tb = 0;
        $display("TEST CASE 99 : READING UART FLAGS (ParityError, RxEmpty = 1).");
        if (APB_Rd_Data_tb == 8'b0100_1000)
            $display("TEST CASE 99 PASSED.");
        else
            $display("TEST CASE 99 FAILED.");



        $display("\n\n-----RECEIVING FRAME WITH STOP ERROR (Using Manual Mode)-----");

        for (I = 0; I < 11; I = I + 1)
            #TX_CLK_PER;
        
        //Turn on Manual Mode to Transmit a 0 instead of a 1 (Incorrect Stop Bit)
        Manual_Mode = 1;
        Manual_Input = 0;   
        #H_TX_CLK_PER;
        Manual_Mode = 0;
        #H_TX_CLK_PER
        #TX_CLK_PER;

        $display("TEST CASE 100 : DISREGARDED FRAME WITH STOP ERROR.");
        if (DUT.UART.Rx_FIFO.FIFO[3] == 0)
            $display("TEST CASE 100 PASSED.");
        else
            $display("TEST CASE 100 FAILED.");

        $display("TEST CASE 101 : RX'S STOP ERROR SIGNAL ASSERTED.");
        if (DUT.UART.Rx.Stp_Err_TOP == 1)
            $display("TEST CASE 101 PASSED.");
        else
            $display("TEST CASE 101 FAILED.");

        #H_TX_CLK_PER

        Transfer_tb = 1;
        RW_tb = 0;
        APB_Address_tb = UART | UARTFLAGS;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        Transfer_tb = 0;
        $display("TEST CASE 102 : READING UART FLAGS (StopError, RxEmpty = 1).");
        if (APB_Rd_Data_tb == 8'b0010_1000)
            $display("TEST CASE 102 PASSED.");
        else
            $display("TEST CASE 102 FAILED.");
        


        $display("\n\n-----RECEIVING FALSE START (Start Glitch)-----");
        
        #H_TX_CLK_PER

        //Rx just started to receive a 0 (Start Bit) from Tx, Turning manual mode on so it receives a 1 instead. 
        Manual_Mode = 1;
        Manual_Input = 1;
        
        #TX_CLK_PER;
        #TX_CLK_PER;

        $display("TEST CASE 103 : RX'S START GLITCH SIGNAL ASSERTED, WENT BACK TO IDLE STATE.");
        if (DUT.UART.Rx.Strt_Glitch_TOP == 1 && DUT.UART.Rx.FSM.current_state == 0)
            $display("TEST CASE 103 PASSED.");
        else
            $display("TEST CASE 103 FAILED.");

        Manual_Mode = 0;

        #TX_CLK_PER;
        #TX_CLK_PER;


        $display("\n\n\n-----TESTING GPIO WITH APB-----");
        $display("\n\n-----PORT A-----");
        $display("\n\n-----PORTA MODE REGISTER-----");
        
        Transfer_tb = 1;
        APB_Address_tb = GPIO | A_MODE;
        APB_Wr_Data_tb = 8'b0000_1111;
        RW_tb = 1;
        APB_Strobe_tb = 4'b0001;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 104 : WROTE TO PORTA MODE REGISTER.");
        if (DUT.GPIO.PORTA_MODE_R == 8'b0000_1111)
            $display("TEST CASE 104 PASSED.");
        else
            $display("TEST CASE 104 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 105 : READING PORTA MODE REGISTER.");
        if (APB_Rd_Data_tb == 8'b0000_1111)
            $display("TEST CASE 105 PASSED.");
        else
            $display("TEST CASE 105 FAILED.");


        $display("\n\n-----PORTA DIRECTION REGISTER-----");
        APB_Address_tb = GPIO | A_DIRECTION;
        APB_Wr_Data_tb = 8'b1100_1100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 106 : WROTE TO PORTA DIRECTION REGISTER.");
        if (DUT.GPIO.PORTA_DIRECTION_R == 8'b1100_1100)
            $display("TEST CASE 106 PASSED.");
        else
            $display("TEST CASE 106 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 107 : READING PORTA DIRECTION REGISTER.");
        if (APB_Rd_Data_tb == 8'b1100_1100)
            $display("TEST CASE 107 PASSED.");
        else
            $display("TEST CASE 107 FAILED.");


        $display("\n\n-----PORTA OUTPUT REGISTER-----");
        APB_Address_tb = GPIO | A_OUTPUT;
        APB_Wr_Data_tb = 8'b0100_0100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 108 : WROTE TO PORTA OUTPUT REGISTER.");
        if (DUT.GPIO.PORTA_OUTPUT_R == 8'b0100_0100)
            $display("TEST CASE 108 PASSED.");
        else
            $display("TEST CASE 108 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 109 : READING PORTA OUTPUT REGISTER.");
        if (APB_Rd_Data_tb == 8'b0100_0100)
            $display("TEST CASE 109 PASSED.");
        else
            $display("TEST CASE 109 FAILED.");


        $display("\n\n-----PORTA INPUT REGISTER-----");
        APB_Address_tb = GPIO | A_INPUT;
        APB_Wr_Data_tb = 8'b0100_0100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 110 : PSLVERR ASSERTED WHEN WRITING TO PORTA INPUT REGISTER.");
        if (DUT.GPIO.PSLVERR == 1)
            $display("TEST CASE 110 PASSED.");
        else
            $display("TEST CASE 110 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 111 : READING PORTA INPUT REGISTER.");
        if (APB_Rd_Data_tb === 32'b01zz_0zzz) 
            $display("TEST CASE 111 PASSED.");
        else
            $display("TEST CASE 111 FAILED.");

        $display("\n-----PORTA GPIO PINS-----");

        $display("TEST CASE 112 : PORTA GPIO PINS.");
        if (PORTA === 8'b01zz_0zzz) 
            $display("TEST CASE 112 PASSED.");
        else
            $display("TEST CASE 112 FAILED.");



        $display("\n\n-----PORT B-----");
        $display("\n\n-----PORTB MODE REGISTER-----");
        
        Transfer_tb = 1;
        APB_Address_tb = GPIO | B_MODE;
        APB_Wr_Data_tb = 8'b0000_1111;
        RW_tb = 1;
        APB_Strobe_tb = 4'b0001;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 113 : WROTE TO PORTB MODE REGISTER.");
        if (DUT.GPIO.PORTB_MODE_R == 8'b0000_1111)
            $display("TEST CASE 113 PASSED.");
        else
            $display("TEST CASE 113 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 114 : READING PORTB MODE REGISTER.");
        if (APB_Rd_Data_tb == 8'b0000_1111)
            $display("TEST CASE 114 PASSED.");
        else
            $display("TEST CASE 114 FAILED.");


        $display("\n\n-----PORTB DIRECTION REGISTER-----");
        APB_Address_tb = GPIO | B_DIRECTION;
        APB_Wr_Data_tb = 8'b1100_1100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 115 : WROTE TO PORTB DIRECTION REGISTER.");
        if (DUT.GPIO.PORTB_DIRECTION_R == 8'b1100_1100)
            $display("TEST CASE 115 PASSED.");
        else
            $display("TEST CASE 115 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 116 : READING PORTB DIRECTION REGISTER.");
        if (APB_Rd_Data_tb == 8'b1100_1100)
            $display("TEST CASE 116 PASSED.");
        else
            $display("TEST CASE 116 FAILED.");


        $display("\n\n-----PORTB OUTPUT REGISTER-----");
        APB_Address_tb = GPIO | B_OUTPUT;
        APB_Wr_Data_tb = 8'b0100_0100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 117 : WROTE TO PORTB OUTPUT REGISTER.");
        if (DUT.GPIO.PORTA_OUTPUT_R == 8'b0100_0100)
            $display("TEST CASE 117 PASSED.");
        else
            $display("TEST CASE 117 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 118 : READING PORTB OUTPUT REGISTER.");
        if (APB_Rd_Data_tb == 8'b0100_0100)
            $display("TEST CASE 118 PASSED.");
        else
            $display("TEST CASE 118 FAILED.");


        $display("\n\n-----PORTB INPUT REGISTER-----");
        APB_Address_tb = GPIO | B_INPUT;
        APB_Wr_Data_tb = 8'b0100_0100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 119 : PSLVERR ASSERTED WHEN WRITING TO PORTB INPUT REGISTER.");
        if (DUT.GPIO.PSLVERR == 1)
            $display("TEST CASE 119 PASSED.");
        else
            $display("TEST CASE 119 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 120 : READING PORTB INPUT REGISTER.");
        if (APB_Rd_Data_tb === 32'b01zz_0zzz) 
            $display("TEST CASE 120 PASSED.");
        else
            $display("TEST CASE 120 FAILED.");

        $display("\n-----PORTB GPIO PINS-----");

        $display("TEST CASE 121 : PORTB GPIO PINS.");
        if (PORTB === 8'b01zz_0zzz) 
            $display("TEST CASE 121 PASSED.");
        else
            $display("TEST CASE 121 FAILED.");



        $display("\n\n-----PORT C-----");
        $display("\n\n-----PORTC MODE REGISTER-----");
        
        Transfer_tb = 1;
        APB_Address_tb = GPIO | C_MODE;
        APB_Wr_Data_tb = 8'b0000_1111;
        RW_tb = 1;
        APB_Strobe_tb = 4'b0001;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 122 : WROTE TO PORTC MODE REGISTER.");
        if (DUT.GPIO.PORTC_MODE_R == 8'b0000_1111)
            $display("TEST CASE 122 PASSED.");
        else
            $display("TEST CASE 122 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 123 : READING PORTC MODE REGISTER.");
        if (APB_Rd_Data_tb == 8'b0000_1111)
            $display("TEST CASE 123 PASSED.");
        else
            $display("TEST CASE 123 FAILED.");


        $display("\n\n-----PORTC DIRECTION REGISTER-----");
        APB_Address_tb = GPIO | C_DIRECTION;
        APB_Wr_Data_tb = 8'b1100_1100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 124 : WROTE TO PORTC DIRECTION REGISTER.");
        if (DUT.GPIO.PORTC_DIRECTION_R == 8'b1100_1100)
            $display("TEST CASE 124 PASSED.");
        else
            $display("TEST CASE 124 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 125 : READING PORTC DIRECTION REGISTER.");
        if (APB_Rd_Data_tb == 8'b1100_1100)
            $display("TEST CASE 125 PASSED.");
        else
            $display("TEST CASE 125 FAILED.");


        $display("\n\n-----PORTC OUTPUT REGISTER-----");
        APB_Address_tb = GPIO | C_OUTPUT;
        APB_Wr_Data_tb = 8'b0100_0100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 126 : WROTE TO PORTC OUTPUT REGISTER.");
        if (DUT.GPIO.PORTC_OUTPUT_R == 8'b0100_0100)
            $display("TEST CASE 126 PASSED.");
        else
            $display("TEST CASE 126 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 127 : READING PORTC OUTPUT REGISTER.");
        if (APB_Rd_Data_tb == 8'b0100_0100)
            $display("TEST CASE 127 PASSED.");
        else
            $display("TEST CASE 127 FAILED.");


        $display("\n\n-----PORTC INPUT REGISTER-----");
        APB_Address_tb = GPIO | C_INPUT;
        APB_Wr_Data_tb = 8'b0100_0100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 128 : PSLVERR ASSERTED WHEN WRITING TO PORTC INPUT REGISTER.");
        if (DUT.GPIO.PSLVERR == 1)
            $display("TEST CASE 128 PASSED.");
        else
            $display("TEST CASE 128 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 129 : READING PORTC INPUT REGISTER.");
        if (APB_Rd_Data_tb === 32'b01zz_0zzz) 
            $display("TEST CASE 129 PASSED.");
        else
            $display("TEST CASE 129 FAILED.");

        $display("\n-----PORTC GPIO PINS-----");

        $display("TEST CASE 130 : PORTC GPIO PINS.");
        if (PORTC === 8'b01zz_0zzz) 
            $display("TEST CASE 130 PASSED.");
        else
            $display("TEST CASE 130 FAILED.");

        
        $display("\n\n-----PORT D-----");
        $display("\n\n-----PORTD MODE REGISTER-----");
        
        Transfer_tb = 1;
        APB_Address_tb = GPIO | D_MODE;
        APB_Wr_Data_tb = 8'b0000_1111;
        RW_tb = 1;
        APB_Strobe_tb = 4'b0001;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 131 : WROTE TO PORTD MODE REGISTER.");
        if (DUT.GPIO.PORTD_MODE_R == 8'b0000_1111)
            $display("TEST CASE 131 PASSED.");
        else
            $display("TEST CASE 131 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 132 : READING PORTD MODE REGISTER.");
        if (APB_Rd_Data_tb == 8'b0000_1111)
            $display("TEST CASE 132 PASSED.");
        else
            $display("TEST CASE 132 FAILED.");


        $display("\n\n-----PORTD DIRECTION REGISTER-----");
        APB_Address_tb = GPIO | D_DIRECTION;
        APB_Wr_Data_tb = 8'b1100_1100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 133 : WROTE TO PORTD DIRECTION REGISTER.");
        if (DUT.GPIO.PORTD_DIRECTION_R == 8'b1100_1100)
            $display("TEST CASE 133 PASSED.");
        else
            $display("TEST CASE 133 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 134 : READING PORTD DIRECTION REGISTER.");
        if (APB_Rd_Data_tb == 8'b1100_1100)
            $display("TEST CASE 134 PASSED.");
        else
            $display("TEST CASE 134 FAILED.");


        $display("\n\n-----PORTD OUTPUT REGISTER-----");
        APB_Address_tb = GPIO | D_OUTPUT;
        APB_Wr_Data_tb = 8'b0100_0100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 135 : WROTE TO PORTD OUTPUT REGISTER.");
        if (DUT.GPIO.PORTD_OUTPUT_R == 8'b0100_0100)
            $display("TEST CASE 135 PASSED.");
        else
            $display("TEST CASE 135 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 136 : READING PORTD OUTPUT REGISTER.");
        if (APB_Rd_Data_tb == 8'b0100_0100)
            $display("TEST CASE 136 PASSED.");
        else
            $display("TEST CASE 136 FAILED.");


        $display("\n\n-----PORTD INPUT REGISTER-----");
        APB_Address_tb = GPIO | D_INPUT;
        APB_Wr_Data_tb = 8'b0100_0100;
        RW_tb = 1;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        
        $display("TEST CASE 137 : PSLVERR ASSERTED WHEN WRITING TO PORTD INPUT REGISTER.");
        if (DUT.GPIO.PSLVERR == 1)
            $display("TEST CASE 137 PASSED.");
        else
            $display("TEST CASE 137 FAILED.");
      
        RW_tb = 0;
        
        #SYS_CLK_PER;    
        #SYS_CLK_PER;
        #SYS_CLK_PER;
        #SYS_CLK_PER;

        $display("TEST CASE 138 : READING PORTD INPUT REGISTER.");
        if (APB_Rd_Data_tb === 32'b01zz_0zzz) 
            $display("TEST CASE 138 PASSED.");
        else
            $display("TEST CASE 138 FAILED.");

        $display("\n-----PORTD GPIO PINS-----");

        $display("TEST CASE 139 : PORTD GPIO PINS.");
        if (PORTD === 8'b01zz_0zzz) 
            $display("TEST CASE 139 PASSED.");
        else
            $display("TEST CASE 139 FAILED.");

        Transfer_tb = 0;

        #TX_CLK_PER;
        $stop;
    end


always #31.25 PCLK_tb = ~PCLK_tb;    //16MHz System

AUG_System DUT (
    .Transfer(Transfer_tb),
    .PCLK(PCLK_tb),    
    .PRESETn(PRESETn_tb), 
    .RW(RW_tb),
    .APB_Address(APB_Address_tb),
    .APB_Wr_Data(APB_Wr_Data_tb),
    .APB_Strobe(APB_Strobe_tb),
    .APB_Rd_Data(APB_Rd_Data_tb),
    .APB_Error(APB_Error_tb),

    .RX_IN(RX_IN_tb),
    .TX_OUT(TX_OUT_tb),
    .Busy(Busy_tb),

    .PORTA(PORTA),
    .PORTB(PORTB),
    .PORTC(PORTC),
    .PORTD(PORTD)
);


endmodule