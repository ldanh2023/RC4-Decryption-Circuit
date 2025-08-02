module Display_SecretKey(
                            input logic clk, reset,

                            //Secret Key from Cores
                            input logic [23:0] secretKey_inst1,
                            input logic [23:0] secretKey_inst2,
                            input logic [23:0] secretKey_inst3, 
                            input logic [23:0] secretKey_inst4,

                            //If key was successfully found
                            input logic key_found_finish_inst1, //if key was found in check
                            input logic key_found_finish_inst2, 
                            input logic key_found_finish_inst3,
                            input logic key_found_finish_inst4,

                            //Secret Key out to Display
                            output logic [23:0] secretKey_out, //correct key
                            output logic stop_search //stop search sent to all cores 
);

    //State definitions
    typedef enum logic [2:0] {
        INST1 = 3'b000,
        INST2 = 3'b001,
        INST3 = 3'b010,
        INST4 = 3'b011,
        Finish = 3'b100
    } statetype;

    /*
    | State Name | Hex Value |
    |------------|-----------|
    | INST1 | 0x0 |
    | INST2 | 0x1 |
    | INST3 | 0x2 |
    | INST4 | 0x3 |
    | Finish | 0x4 |
    */

    //Initialize state
    statetype state = INST1;
    
    logic key_found_finish;
    assign key_found_finish = key_found_finish_inst1 | key_found_finish_inst2 | key_found_finish_inst3 | key_found_finish_inst4;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin //if reset
            state <= INST1;
            secretKey_out <= 24'h000000;
            stop_search <= 0;
        end else begin
            if (key_found_finish) begin
                stop_search <= 1; //stop_search when any core finds key
                state <= Finish;

                //Get the correct key, the key found by the successful core
                if (key_found_finish_inst1) begin
                    secretKey_out <= secretKey_inst1;
                end
                else if (key_found_finish_inst2) begin
                    secretKey_out <= secretKey_inst2;
                end
                else if (key_found_finish_inst3) begin
                    secretKey_out <= secretKey_inst3;
                end
                else if (key_found_finish_inst4) begin
                    secretKey_out <= secretKey_inst4;
                end
            end else begin
                stop_search <= 0; //key not found

                case (state) //cycle through states until key is found, print current key used by each core on HEX displays
                    INST1: begin
                        secretKey_out <= secretKey_inst1;
                        state <= INST2;
                    end
                    INST2: begin
                        secretKey_out <= secretKey_inst2;
                        state <= INST3;
                    end
                    INST3: begin
                        secretKey_out <= secretKey_inst3;
                        state <= INST4;
                    end
                    INST4: begin
                        secretKey_out <= secretKey_inst4;
                        state <= INST1;
                    end
                    Finish: begin
                        state <= Finish;  //Remain in Finish, keep displaying correct key
                    end
                endcase
            end
        end
    end
endmodule