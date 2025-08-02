`timescale 1ns/1ps

module task2_tb;
    logic clk, reset;
    logic [23:0] secretKey;
    logic [7:0] data_in, address, data_out;
    logic readWrite, finish_readWrite_op, start_readWrite_op;
    logic start_Task2a, finish_Task2a;

    swapAlgo swapAlgo_inst (
        .clk(clk),
        .reset(reset),

        //Secret key
        .secretKey(secretKey),

        //Memory data signals
        .address(address),
        .data_out(data_out),
        .readWrite(readWrite),
        .data_in(data_in),

        //Start-finish signals from memory interface
        .finish_readWrite_op(finish_readWrite_op),
        .start_readWrite_op(start_readWrite_op),
        
        //Start-finish protocol
        .start_Task2a(start_Task2a),
        .finish_Task2a(finish_Task2a)
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
        start_Task2a = 1;
        finish_readWrite_op = 1; //Always set at True
        data_in = 8'h2;
        secretKey = 24'h000249;
    end

endmodule