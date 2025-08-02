`timescale 1ns/1ns //`timescale <time_unit>/<time_precision>

module Arbitrary_Clock_Divider_My_Version_tb;
    logic sim_in_clk;
    logic sim_out_clk;
    logic [29:0] sim_freq_counter;
    logic sim_on_off;

    //Error signal
    logic error;

    Arbitrary_Clock_Divider_My_Version #(.duty_cycle(2), .N(30)) DUT (.in_clk(sim_in_clk), .out_clk(sim_out_clk), .freq_counter(sim_freq_counter), .on_off(sim_on_off));


    //Simulate the clk signal for sim_in_clk, 50MHz
    initial sim_in_clk = 0;
    always #10 sim_in_clk = ~sim_in_clk;


    initial begin
        //Initialize the signals
        error = 1'b0;
        sim_freq_counter = 30'd0;
        sim_on_off = 1'b0;


        //Need to wait for sim_in_clk to set high, so values are initialized (not unknown)
        #10;

        //========================== Case 1: Generate a 25MHz clock with a 50% duty cycle =========================
        sim_freq_counter = 30'd2; //25MHz, period is 40ns, half period is 20ns
        sim_on_off = 1'b1; //on_off = 1'b1 if audio is on (SW[0] is in on position)

        //Test 1 - Initial clock starts at 0
        #10; //wait for 10ns to stabilize
        assert (sim_out_clk === 1'b0) $display("Test 1 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
        else begin
            $display("Fail: Test 1, sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
            error = 1'b1;
        end

        //Test 2 - After half a period, the clock should be 1
        #20;
        assert (sim_out_clk === 1'b1) $display("Test 2 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
        else begin
            $display("Fail: Test 2, sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
            error = 1'b1;
        end

        //Test 3 - After 1 full period, clock should be 0
        #20;
        assert (sim_out_clk === 1'b0) $display("Test 3 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
        else begin
            $display("Fail: Test 3, sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
            error = 1'b1;
        end

        //Test 4 - After half a period, the clock should be 1
        #20;
        assert (sim_out_clk === 1'b1) $display("Test 4 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
        else begin
            $display("Fail: Test 4, sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
            error = 1'b1;
        end

        #30; //wait for 30ns to complete the cycle


        //========================== Case 2: Generate a 5MHz clock with a 50% duty cycle =========================
        sim_freq_counter = 30'd10; //5MHz, period is 200ns, half period is 100ns
        sim_on_off = 1'b1; //on_off = 1'b1 if audio is on (SW[0] is in on position)

        //Test 5 - Initial clock starts at 0
        #50; //need to wait for 50ns to stabilize to new value
        assert (sim_out_clk === 1'b0) $display("Test 5 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
        else begin
            $display("Fail: Test 5, sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
            error = 1'b1;
        end

        //Test 6 - After half a period, the clock should be 1
        #100;
        assert (sim_out_clk === 1'b1) $display("Test 6 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
        else begin
            $display("Fail: Test 6, sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
            error = 1'b1;
        end

        //Test 7 - After 1 full period, clock should be 0
        #100;
        assert (sim_out_clk === 1'b0) $display("Test 7 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
        else begin
            $display("Fail: Test 7, sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
            error = 1'b1;
        end

        //Test 8 - After half a period, the clock should be 1
        #100;
        assert (sim_out_clk === 1'b1) $display("Test 8 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
        else begin
            $display("Fail: Test 8, sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
            error = 1'b1;
        end

        #130; //wait for 50ns to complete the cycle


        //========================== Case 3: Check the on_off signal using a 25MHz clock with a 50% duty cycle =========================
        sim_freq_counter = 30'd2; //25MHz, period is 40ns, half period is 20ns
        sim_on_off = 1'b1; //on_off = 1'b1 if audio is on (SW[0] is in on position)

        //Test 9 - Initial clock starts at 0
        #20; //wait for 10ns to stabilize
        assert (sim_out_clk === 1'b1) $display("Test 9 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
        else begin
            $display("Fail: Test 9, sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
            error = 1'b1;
        end

        //Test 10 - After half a period, the clock should be 1
        #40;
        assert (sim_out_clk === 1'b1) $display("Test 10 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
        else begin
            $display("Fail: Test 10, sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
            error = 1'b1;
        end


        //Now turn off the clock
        sim_on_off = 1'b0; //on_off = 1'b0 if audio is off (SW[0] is in off position)

        //Test 11 - Audio is off, so sim_out_clk should be immediately off
        #10;
        assert (sim_out_clk === 1'b0) $display("Test 11 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
        else begin
            $display("Fail: Test 11, sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
            error = 1'b1;
        end

        //Test 12 - Audio is off, so sim_out_clk should remain off
        #20;
        assert (sim_out_clk === 1'b0) $display("Test 12 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
        else begin
            $display("Fail: Test 12, sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
            error = 1'b1;
        end


        //Now turn on clock again
        sim_on_off = 1'b1; //on_off = 1'b1 if audio is on (SW[0] is in on position)

        //Test 13 - Audio is on, so sim_out_clk can now start again
        #30;
        assert (sim_out_clk === 1'b0) $display("Test 13 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
        else begin
            $display("Fail: Test 13, sim_out_clk is %b, expected %b", sim_out_clk, 1'b0);
            error = 1'b1;
        end

        //Test 14 - After half a period, the clock should be 1
        #20;
        assert (sim_out_clk === 1'b1) $display("Test 14 SUCCESS ** sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
        else begin
            $display("Fail: Test 14, sim_out_clk is %b, expected %b", sim_out_clk, 1'b1);
            error = 1'b1;
        end


        if (~error) begin
            $display("PASSED: All Arbitrary_Clock_Divider tests passed!");
        end else begin
            $display("FAILED: One or more Arbitrary_Clock_Divider tests failed.");
        end

        //End the simulation
        $finish;
    end
endmodule