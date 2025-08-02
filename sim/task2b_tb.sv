`timescale 1ns/1ps

module task2b_tb;
    logic clk, reset, S_readWrite, D_readWrite, S_finish_readWrite_op, S_start_readWrite_op, E_finish_readWrite_op, E_start_readWrite_op;
    logic D_finish_readWrite_op, D_start_readWrite_op, start_Task2b, finish_Task2b;

    logic [7:0] S_data_in, S_address, S_data_out, E_data_in, E_address, D_data_in, D_address, D_data_out;

    Task2b_Algo Task2b_Algo_inst(
        .clk(clk),
        .reset(reset),

        //Memory data signals for S memory
        .S_data_in(S_data_in),
        .S_address(S_address),
        .S_data_out(S_data_out),
        .S_readWrite(S_readWrite),

        //Memory data signals for encrypted memory
        .E_data_in(E_data_in),
        .E_address(E_address),

        //Memory data signals for decrypted memory
        .D_data_in(D_data_in),
        .D_address(D_address),
        .D_data_out(D_data_out),
        .D_readWrite(D_readWrite),


        //Start-finish signals from S memory interface
        .S_finish_readWrite_op(S_finish_readWrite_op),
        .S_start_readWrite_op(S_start_readWrite_op),

        //Start-finish signals from encrypted memory interface
        .E_finish_readWrite_op(E_finish_readWrite_op),
        .E_start_readWrite_op(E_start_readWrite_op),

        //Start-finish signals from decrypted memory interface
        .D_finish_readWrite_op(D_finish_readWrite_op),
        .D_start_readWrite_op(D_start_readWrite_op),
        
        //Start-finish protocol
        .start_Task2b(start_Task2b),
        .finish_Task2b(finish_Task2b)
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
        start_Task2b = 1;
        S_finish_readWrite_op = 1; //Always set at True
        S_data_in = 8'h1;
        E_data_in = 8'h2;
        D_data_in = 8'h3;
        D_finish_readWrite_op = 1;
        E_finish_readWrite_op = 1;
    end

endmodule