module Encrypted_MemInterface(
        //Clock and reset
        input logic clk, reset,


        //Start-finish protocol
        input logic start,
        output logic finish,
        

        //------------------------------------------- 4 signals to memory in total --------------------------------------------------

        //Signals for interfacing with RAM
        input logic [7:0] FSM_Adr, //address we want to read from passed in FSM
        output logic [7:0] Encrypt_Adr, //address we want to read from passed to memory


        //Data read from memory (read operation)
        input logic [7:0] DataIn_from_Encrypt, //data from memory
        output logic [7:0] DataOut_toFSM //data to FSM
);

    //state encoding: {state}_{finish}
    typedef enum logic [3:0] { 
        IDLE = 4'b000_0,
        SetAdrRead = 4'b001_0,
        WaitRead = 4'b010_0,
        GetRead = 4'b011_0,
        Finished = 4'b100_1
    } statetype;

    /*
    | **State Name** | **Hex (2-digit)** |
    | -------------- | ----------------- |
    | `IDLE`         | 0x00              |
    | `SetAdrRead`   | 0x02              |
    | `WaitRead`     | 0x04              |
    | `GetRead`      | 0x06              |
    | `Finished`     | 0x09              |
    */

    
    //Initialize state
    statetype state = IDLE;

    //Assign outputs (finish)
    assign finish = state[0];


    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            Encrypt_Adr <= 8'b0;
            DataOut_toFSM <= 8'b0;
        end
        else begin
            case(state)
                IDLE: begin
                    if (start) begin
                        state <= SetAdrRead;
                    end
                end
                SetAdrRead: begin //set address to read from
                    Encrypt_Adr <= FSM_Adr;
                    state <= WaitRead;
                end
                WaitRead: begin //wait for data to arrive from memory
                    state <= GetRead;
                end
                GetRead: begin //wait for data to arrive from memory
                    state <= Finished;
                    DataOut_toFSM <= DataIn_from_Encrypt;
                end
                Finished: begin //finished, sends signal to calling FSM that this module is finished processing the memory operation
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule