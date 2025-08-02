module Decrypted_MemInterface(
        //Clock and reset
        input logic clk, reset,


        //Start-finish protocol
        input logic start,
        output logic finish,


        //readWrite signal indicates if we are doing a read or write operation, read = 0, write = 1
        input logic readWrite,
        

        //------------------------------------------- 4 signals to memory in total --------------------------------------------------

        //Signals for interfacing with RAM
        input logic [7:0] FSM_Adr, //address we want to read from passed in FSM
        output logic [7:0] Decrypt_Adr, //address we want to read from passed to memory
        

        //Write enable signal to memory
        output logic Decrypt_WriteEn,

        
        //Data passed to memory (write operation)
        input logic [7:0] DataIn_fromFSM, //data from FSM
        output logic [7:0] DataOut_to_Decrypt, //data to memory


        //Data read from memory (read operation)
        input logic [7:0] DataIn_from_Decrypt, //data from memory
        output logic [7:0] DataOut_toFSM //data to FSM
);


    //state encoding: {state}_{finish}
    typedef enum logic [3:0] { 
        IDLE = 4'b000_0,
        SetAdrRead = 4'b001_0,
        WaitRead = 4'b010_0,
        GetRead = 4'b011_0,

        SetAdrWrite = 4'b100_0,
        WaitWrite = 4'b101_0,
        GetWrite = 4'b110_0,

        Finished = 4'b111_1
    } statetype;

    /*
    | **State Name** | **Hex (2-digit)** |
    | -------------- | ----------------- |
    | `IDLE`         | 0x00              |
    | `SetAdrRead`   | 0x02              |
    | `WaitRead`     | 0x04              |
    | `GetRead`      | 0x06              |
    | `SetAdrWrite`  | 0x08              |
    | `WaitWrite`    | 0x0A              |
    | `GetWrite`     | 0x0C              |
    | `Finished`     | 0x0F              |
    */
    
    //Initialize state
    statetype state = IDLE;

    //Assign outputs (finish)
    assign finish = state[0];


    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            Decrypt_Adr <= 8'b0;
            DataOut_to_Decrypt <= 8'b0;
            DataOut_toFSM <= 8'b0;
        end
        else begin
            case(state)
                IDLE: begin
                    Decrypt_WriteEn <= 0;

                    if (start) begin
                        if (readWrite) begin //if 1, then write operation
                            state <= SetAdrWrite;
                        end
                        else begin //if 0, then read operation
                            state <= SetAdrRead;
                        end
                    end
                end
                SetAdrRead: begin //set address to read from
                    Decrypt_WriteEn <= 0;
                    Decrypt_Adr <= FSM_Adr;
                    state <= WaitRead;
                end
                WaitRead: begin //wait for data to arrive from memory
                    state <= GetRead;
                end
                GetRead: begin //wait for data to arrive from memory
                    state <= Finished;
                    DataOut_toFSM <= DataIn_from_Decrypt;
                end
                SetAdrWrite: begin //set address and data to write to memory
                    Decrypt_WriteEn <= 1;
                    Decrypt_Adr <= FSM_Adr;
                    DataOut_to_Decrypt <= DataIn_fromFSM;
                    state <= WaitWrite;
                end
                WaitWrite: begin //wait for write data to take effect
                    state <= GetWrite;
                end
                GetWrite: begin //wait for write data to take effect
                    state <= Finished;
                end
                Finished: begin //finished, sends signal to calling FSM that this module is finished processing the memory operation
                    Decrypt_WriteEn <= 0;
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule