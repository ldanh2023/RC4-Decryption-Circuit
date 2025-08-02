`timescale 1ns/1ps

module task3_tb;
    logic clk, reset, D_readWrite, D_finish_readWrite_op, D_start_readWrite_op, key_Valid;
    logic start_Task3, finish_Task3;
    logic [7:0] D_data_in, D_address, D_data_out;

    Task3_Check Task3_Check_inst (
        .clk(clk),
        .reset(reset),

        //Memory data signals for decrypted memory
        .D_data_in(D_data_in),
        .D_address(D_address),
        .D_data_out(D_data_out),
        .D_readWrite(D_readWrite),

        //Start-finish signals from decrypted memory interface
        .D_finish_readWrite_op(D_finish_readWrite_op),
        .D_start_readWrite_op(D_start_readWrite_op),

        //Key is valid
        .key_Valid(key_Valid),
        
        //Start-finish protocol
        .start_Task3(start_Task3),
        .finish_Task3(finish_Task3)
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
        D_data_in = 8'd210;//Valid character
        D_finish_readWrite_op = 1;
        start_Task3 = 1;
    end
        
endmodule