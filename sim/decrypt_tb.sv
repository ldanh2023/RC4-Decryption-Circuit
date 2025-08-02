`timescale 1ns/1ps

module decrypt_tb;
    logic clk, reset, start, finish, readWrite, Decrypt_WriteEn;
    logic [7:0] FSM_Adr, Decrypt_Adr, DataIn_fromFSM, DataOut_to_Decrypt, DataIn_from_Decrypt, DataOut_toFSM;

     Decrypted_MemInterface Decrypted_MemInterface_inst (
        //Clock and reset
        .clk(clk),
        .reset(reset),


        //Start-finish protocol
        .start(start),
        .finish(finish),


        //readWrite signal indicates if we are doing a read or write operation, read = 0, write = 1
        .readWrite(readWrite),
        

        //------------------------------------------- 4 signals to memory in total --------------------------------------------------

        //Signals for interfacing with RAM
        .FSM_Adr(FSM_Adr), //address we want to read from passed in FSM
        .Decrypt_Adr(Decrypt_Adr), //address we want to read from passed to memory
        

        //Write enable signal to memory
        .Decrypt_WriteEn(Decrypt_WriteEn),

        
        //Data passed to memory (write operation)
        .DataIn_fromFSM(DataIn_fromFSM), //data from FSM
        .DataOut_to_Decrypt(DataOut_to_Decrypt), //data to memory


        //Data read from memory (read operation)
        .DataIn_from_Decrypt(DataIn_from_Decrypt), //data from memory
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
        readWrite = 0;//Read
        FSM_Adr = 8'h15;
        DataIn_fromFSM = 8'h00;
        DataIn_from_Decrypt = 8'hBB;
    end

    always @(posedge finish) begin
        // Write operation
        start = 1;
        readWrite = 1;
        FSM_Adr = 8'h15;
        DataIn_fromFSM = 8'hAA;
        DataIn_from_Decrypt = 8'h00;
    end

endmodule