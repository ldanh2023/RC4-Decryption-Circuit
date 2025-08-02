`timescale 1ns/1ps

module task1_tb;
    logic clk, reset, readWrite, finish_readWrite_op, start_readWrite_op, start_init, finish_init;

    //Memory signals
    logic [7:0] address, data_out;
    
    //S_mem signals
    logic start_SMem, finish_SMem, readWrite_SMem, sWriteEn;
    logic [7:0] FSM_Adr, sAdr, DataIn_fromFSM, DataOut_to_s, DataIn_from_s, DataOut_toFSM;
    

    //DUT
    init_SMem init_SMem_inst (
                                .clk(clk),
                                .reset(reset),

                                //Memory data signals
                                .address(address),
                                .data_out(data_out),
                                .readWrite(readWrite),

                                //Start-finish signals from memory interface
                                .finish_readWrite_op(finish_readWrite_op),
                                .start_readWrite_op(start_readWrite_op),

                                //Start-finish protocol
                                .start_init(start_init),
                                .finish_init(finish_init)
    );

    S_MemInterface S_MemInterface_inst (
        //Clock and reset
        .clk(clk),
        .reset(reset),

        //Start-finish protocol
        .start(start_SMem),
        .finish(finish_SMem),

        //readWrite signal indicates if we are doing a read or write operation, read = 0, write = 1
        .readWrite(readWrite_SMem),

        //------------------------------------------- 4 signals to memory in total --------------------------------------------------

        //Signals for interfacing with RAM
        .FSM_Adr(FSM_Adr), //address we want to read from passed in FSM
        .sAdr(sAdr), //address we want to read from passed to memory
        

        //Write enable signal to memory
        .sWriteEn(sWriteEn),

        
        //Data passed to memory (write operation)
        .DataIn_fromFSM(DataIn_fromFSM), //data from FSM
        .DataOut_to_s(DataOut_to_s), //data to memory


        //Data read from memory (read operation)
        .DataIn_from_s(DataIn_from_s), //data from memory
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
        start_init = 1;
        finish_readWrite_op = 1; //Always set at True
    end

    initial begin
    // Read operation
    start_SMem = 1;
    readWrite_SMem = 0;
    DataIn_fromFSM = 8'h00;
    DataIn_from_s = 8'hAA;
    FSM_Adr = 8'h12;

    end

    always @(posedge finish_SMem) begin
        // Write operation
        readWrite_SMem = 1;
        FSM_Adr = 8'h24;
        DataIn_fromFSM = 8'h75;
        DataIn_from_s = 8'h00;
    end

endmodule