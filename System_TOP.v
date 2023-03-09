module AUG_System (

    //APB Signals
    input       wire                   Transfer,        //Enable Entire APB
    input       wire                   PCLK,    
    input       wire                   PRESETn, 
    input       wire                   RW,              //RW Input from Processor
    input       wire        [31:0]     APB_Address,     //Address from Processor
    input       wire        [31:0]     APB_Wr_Data,     //Write Data from Processor
    input       wire        [3:0]      APB_Strobe,
    output      wire        [31:0]     APB_Rd_Data,     //Read Data from Processor
    output      wire                   APB_Error,       //Error Signal to Processor

    //Rx Signals
    input       wire                     RX_IN,

    //Tx Signals
    output      wire                     TX_OUT,
    output      wire                     Busy,

    //GPIO Pins
    output      wire         [7:0]    PORTA,
    output      wire         [7:0]    PORTB,
    output      wire         [7:0]    PORTC,
    output      wire         [7:0]    PORTD
);

wire        [15:0]       PREADY;
wire        [15:0]       PSEL;
wire                     PENABLE;
wire                     PWRITE;
wire        [31:0]       PADDR;
wire        [31:0]       PWDATA;
wire        [3:0]        PSTRB;
wire        [15:0]       PSLVERR;

wire        [31:0]       PRDATA     [15:0];
reg         [31:0]       Active_PRDATA;


wire                     PREADY_U;
wire                     PSLVERR_U;
wire                     PSEL_U   =   PSEL[0];
assign                   PREADY[0] = PREADY_U;
assign                   PSLVERR[0] = PSLVERR_U;


wire                     PSLVERR_G;
wire                     PREADY_G;
wire                     PSEL_G   =   PSEL[1];
assign                   PREADY[1] = PREADY_G;
assign                   PSLVERR[1] = PSLVERR_G;


//Decide which peripheral's PRDATA is being read by APB
always @ (posedge PCLK)
    begin   
        case (APB_Address[31:16])
                            16'b0000_0000_0000_0001   :     begin
                                                                Active_PRDATA <= PRDATA[0];
                                                            end
                            16'b0000_0000_0000_0010   :     begin
                                                                Active_PRDATA <= PRDATA[1];
                                                            end
                            16'b0000_0000_0000_0100   :     begin
                                                                Active_PRDATA <= PRDATA[2];
                                                            end
                            16'b0000_0000_0000_1000   :     begin
                                                                Active_PRDATA <= PRDATA[3];
                                                            end
                            16'b0000_0000_0001_0000   :     begin
                                                                Active_PRDATA <= PRDATA[4];
                                                            end
                            16'b0000_0000_0010_0000   :     begin
                                                                Active_PRDATA <= PRDATA[5];
                                                            end
                            16'b0000_0000_0100_0000   :     begin
                                                                Active_PRDATA <= PRDATA[6];
                                                            end
                            16'b0000_0000_1000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[7];
                                                            end
                            16'b0000_0001_0000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[8];
                                                            end
                            16'b0000_0010_0000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[9];
                                                            end
                            16'b0000_0100_0000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[10];
                                                            end
                            16'b0000_1000_0000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[11];
                                                            end
                            16'b0001_0000_0000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[12];
                                                            end
                            16'b0010_0000_0000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[13];
                                                            end
                            16'b0100_0000_0000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[14];
                                                            end
                            16'b1000_0000_0000_0000   :     begin
                                                                Active_PRDATA <= PRDATA[15];
                                                            end
                            default                   :     begin
                                                                Active_PRDATA <= 0;
                                                            end
                        endcase
    end


//Instantiations

APB_Controller APB_Master (
    .Transfer(Transfer),
    .PCLK(PCLK),    
    .PRESETn(PRESETn), 
    .PREADY(PREADY),
    .RW(RW),              
    .APB_Address(APB_Address),     
    .APB_Wr_Data(APB_Wr_Data),   
    .Strobe(APB_Strobe),  
    .PRDATA(Active_PRDATA),
    .PSLVERR(PSLVERR),
    .PWDATA(PWDATA),
    .APB_Rd_Data(APB_Rd_Data),     
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL),
    .PSTRB(PSTRB),
    .APB_Error(APB_Error)
);

UART_APB UART (
    .PCLK (PCLK),    
    .PRESETn (PRESETn), 
    .PSEL(PSEL_U),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PSTRB(PSTRB),
    .PRDATA(PRDATA[0]),
    .PREADY(PREADY_U),
    .PSLVERR(PSLVERR_U),
    .RX_IN_TOP(RX_IN),
    .TX_OUT_TOP(TX_OUT),
    .Busy_TOP(Busy)
);

GPIO_Controller GPIO (
    .PCLK (PCLK),    
    .PRESETn (PRESETn), 
    .PSEL(PSEL_G),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PSTRB(PSTRB),
    .PRDATA(PRDATA[1]),
    .PREADY(PREADY_G),
    .PSLVERR(PSLVERR_G),
    .PORTA(PORTA),
    .PORTB(PORTB),
    .PORTC(PORTC),
    .PORTD(PORTD)
);


endmodule
