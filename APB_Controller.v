module APB_Controller (
    input       wire                   Transfer,        //Enable Entire APB
    input       wire                   PCLK,    
    input       wire                   PRESETn, 
    input       wire        [15:0]     PREADY,
    input       wire                   RW,              //RW Input from Processor
    input       wire        [31:0]     APB_Address,     //Address from Processor
    input       wire        [31:0]     APB_Wr_Data,     //Write Data from Processor
    input       wire        [3:0]      Strobe,          //Strobe Input from Processor
    input       wire        [31:0]     PRDATA,
    input       wire        [15:0]     PSLVERR, 

    output      reg         [31:0]     PWDATA,
    output      reg         [31:0]     APB_Rd_Data,     //Read Data from Processor
    output      reg         [31:0]     PADDR,
    output      reg                    PWRITE,
    output      reg                    PENABLE,
    output      reg         [15:0]     PSEL,
    output      reg         [3:0]      PSTRB,
    output      reg                    APB_Error        //Error Signal to Processor
);

//Higher 16 bits of APB_Address choose the peripheral in One Hot Encoding. 
//Lower  16 bits choose register inside the peripheral (if any).

reg     [1:0]       current_state, next_state;
reg                 Active_PREADY;
reg                 Active_PSLVERR;


localparam      IDLE      =   2'b00,
                SETUP     =   2'b01,
                ACCESS    =   2'b10;


//State Machine
always @ (posedge PCLK or negedge PRESETn)
    begin
        if (!PRESETn)
            begin
                current_state <= IDLE;
            end
        else
            begin
                current_state <= next_state;
            end
    end

//Output Logic
always @ (*)
    begin
        case (current_state)
                    IDLE    :       begin
                                        PENABLE = 0;
                                    end

                    SETUP    :      begin
                                        PENABLE = 0;
                                        PWRITE  = RW;
                                        PADDR   = APB_Address;
                                        PSTRB   = Strobe;
                                        if (RW)
                                            begin
                                                PWDATA = APB_Wr_Data;
                                            end
                                        else
                                            begin
                                                PWDATA = 0;
                                            end
                                    end

                    ACCESS    :     begin
                                        PENABLE = 1;
                                        APB_Error = Active_PSLVERR;
                                        if (RW)
                                            begin
                                                APB_Rd_Data = 0;
                                            end
                                        else
                                            begin
                                                APB_Rd_Data = PRDATA;
                                            end
                                        
                                    end

        endcase
    end

//Next State Logic
always @ (*)
    begin
        case (current_state)
            IDLE    :       begin
                                if (Transfer)
                                    begin
                                        next_state = SETUP;
                                    end
                                else
                                    begin
                                        next_state = IDLE;
                                    end
                            end

            SETUP    :      begin
                                if (Transfer)
                                    begin
                                        next_state = ACCESS;
                                    end
                                else
                                    begin
                                        next_state = IDLE;
                                    end
                            end

            ACCESS    :     begin
                                if (!Transfer)
                                    next_state = IDLE;
                                else if (Active_PREADY && Transfer)
                                    next_state = SETUP;
                                else    
                                    next_state = ACCESS;
                            end

        endcase
    end


//Controlling PSEL, PREADY, and PSLVERR depending on address
always @ (posedge PCLK or negedge PRESETn)
    begin
        if (!PRESETn)
            begin
                PSEL <= 0;
            end
        else
            begin
                if (Transfer && current_state != ACCESS)    
                    begin
                        case (APB_Address[31:16])
                            16'b0000_0000_0000_0001   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[0];
                                                                Active_PSLVERR <= PSLVERR[0];
                                                            end
                            16'b0000_0000_0000_0010   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[1];
                                                                Active_PSLVERR <= PSLVERR[1];
                                                            end
                            16'b0000_0000_0000_0100   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[2];
                                                                Active_PSLVERR <= PSLVERR[2];
                                                            end
                            16'b0000_0000_0000_1000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[3];
                                                                Active_PSLVERR <= PSLVERR[3];
                                                            end
                            16'b0000_0000_0001_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[4];
                                                                Active_PSLVERR <= PSLVERR[4];
                                                            end
                            16'b0000_0000_0010_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[5];
                                                                Active_PSLVERR <= PSLVERR[5];
                                                            end
                            16'b0000_0000_0100_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[6];
                                                                Active_PSLVERR <= PSLVERR[6];
                                                            end
                            16'b0000_0000_1000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[7];
                                                                Active_PSLVERR <= PSLVERR[7];
                                                            end
                            16'b0000_0001_0000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[8];
                                                                Active_PSLVERR <= PSLVERR[8];
                                                            end
                            16'b0000_0010_0000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[9];
                                                                Active_PSLVERR <= PSLVERR[9];
                                                            end
                            16'b0000_0100_0000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[10];
                                                                Active_PSLVERR <= PSLVERR[10];
                                                            end
                            16'b0000_1000_0000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[11];
                                                                Active_PSLVERR <= PSLVERR[11];
                                                            end
                            16'b0001_0000_0000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[12];
                                                                Active_PSLVERR <= PSLVERR[12];
                                                            end
                            16'b0010_0000_0000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[13];
                                                                Active_PSLVERR <= PSLVERR[13];
                                                            end
                            16'b0100_0000_0000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[14];
                                                                Active_PSLVERR <= PSLVERR[14];
                                                            end
                            16'b1000_0000_0000_0000   :     begin
                                                                PSEL <= APB_Address[31:16];
                                                                Active_PREADY <= PREADY[15];
                                                                Active_PSLVERR <= PSLVERR[15];
                                                            end
                            default     :       begin
                                                    PSEL <= 0;
                                                    Active_PREADY <= 0;
                                                    Active_PSLVERR <= 0;
                                                end
                        endcase
                    end
            end
    end


endmodule
