`timescale 1ns/1ps

module encrypt_tb;
    logic clk, reset, start, finish;
    logic [7:0] FSM_Adr, Encrypt_Adr, DataIn_from_Encrypt, DataOut_toFSM;

    Encrypted_MemInterface Encrypted_MemInterface_inst (
        //Clock and reset
        .clk(clk),
        .reset(reset),

        //Start-finish protocol
        .start(start),
        .finish(finish),
        
        //------------------------------------------- 4 signals to memory in total --------------------------------------------------

        //Signals for interfacing with RAM
        .FSM_Adr(FSM_Adr), //address we want to read from passed in FSM
        .Encrypt_Adr(Encrypt_Adr), //address we want to read from passed to memory


        //Data read from memory (read operation)
        .DataIn_from_Encrypt(DataIn_from_Encrypt), //data from memory
        .DataOut_toFSM(DataOut_toFSM) //data to FSM
    );


    //Clock signal
    initial begin
        clk = 0;
        forever #20 clk = ~clk;
    end

    initial begin
        reset = 1;
        #20;
        reset = 0;
    end

    initial begin
        start = 1;
        FSM_Adr = 8'h15;
        DataIn_from_Encrypt = 8'hBB;
    end
endmodule