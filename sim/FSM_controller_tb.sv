`timescale 1ns/1ps

module fsm_control_tb;
    logic clk, reset, start_INIT, finish_INIT, start_Task2a, finish_Task2a, start_Task2b, finish_Task2b, start_Task3, finish_Task3, key_found_Task3, successful_key, stop_search;
    logic [23:0] lower_key_index, upper_key_index, current_key;
    logic [2:0] operation_num; 

    logic [7:0] counterTb = '0;

    FSM_Controller CONTROLLER(
        .clk(clk),
        .reset(reset),

        // Secret key (range of keys to check)
        .lower_key_index(lower_key_index),
        .upper_key_index(upper_key_index),
        .current_key(current_key),

        .key_found_Task3(key_found_Task3),
        .successful_key(successful_key),

        //----------------- Start-finish protocols -----------------------------------
        // Init
        .start_INIT(start_INIT),
        .finish_INIT(finish_INIT),

        // Task2a
        .start_Task2a(start_Task2a),
        .finish_Task2a(finish_Task2a),

        // Task2b
        .start_Task2b(start_Task2b),
        .finish_Task2b(finish_Task2b),

        // Task3
        .start_Task3(start_Task3),
        .finish_Task3(finish_Task3),

        .stop_search(stop_search),

        .operation_num(operation_num)
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
        lower_key_index = 24'h0;
        upper_key_index = 24'hFFFFFF;

        // Task 3 result signals
        key_found_Task3 = 0;
        stop_search = 0;

        // Finish signals for each task
        finish_INIT <= 1;
        finish_Task2a <= 1;
        finish_Task2b <= 1;
        finish_Task3 <= 1;
    end

    always @(posedge clk) begin
        if(counterTb == 8'd220) begin
            stop_search <= 1;
        end
        else begin
            counterTb <= counterTb + 1;
        end
    end
endmodule