`timescale 1ns/1ps

module displaySecretKey_tb;
    logic clk, reset, key_found_finish_inst1, key_found_finish_inst2, key_found_finish_inst3, key_found_finish_inst4, stop_search;
    logic [23:0] secretKey_inst1, secretKey_inst2, secretKey_inst3, secretKey_inst4;

    //Simualtor counter
    logic [7:0] counterTb = '0;

    Display_SecretKey dut (
        .clk(clk),
        .reset(reset),
        .secretKey_inst1(secretKey_inst1),
        .secretKey_inst2(secretKey_inst2),
        .secretKey_inst3(secretKey_inst3),
        .secretKey_inst4(secretKey_inst4),
        .key_found_finish_inst1(key_found_finish_inst1),
        .key_found_finish_inst2(key_found_finish_inst2),
        .key_found_finish_inst3(key_found_finish_inst3),
        .key_found_finish_inst4(key_found_finish_inst4),
        .secretKey_out(secretKey_out),
        .stop_search(stop_search)
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
        key_found_finish_inst1 = 0;
        key_found_finish_inst2 = 0;
        key_found_finish_inst3 = 0;
        key_found_finish_inst4 = 0;
        secretKey_inst1 = 24'h0;
        secretKey_inst2 = 24'h0;
        secretKey_inst3 = 24'h0;
        secretKey_inst4 = 24'h0;
    end

    always @(posedge clk) begin
        if(counterTb == 8'd70) begin
            key_found_finish_inst4 <= 1;
            secretKey_inst4 <= 24'haabbcc;
        end
        else begin
            counterTb <= counterTb + 1;
        end
    end


endmodule