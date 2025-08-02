`define INIT_STAGE 3'b000
`define TASK2a_STAGE 3'b001
`define TASK2b_STAGE 3'b010
`define TASK3_STAGE 3'b011
`define FINISH 3'b100


module FSM_Controller(
                        input logic clk, reset,
                        input logic [3:0] buttons,

                        //Secret key (range of keys to check)
                        input logic [23:0] lower_key_index, //lower bound
                        input logic [23:0] upper_key_index, //upper bound
                        output logic [23:0] current_key, //current key to check
                        
                        input logic key_found_Task3, //if key was found in check
                        output logic successful_key, //output key is found, output to top module (0 if not found, 1 if found)
                        input logic stop_search, //if key found, we stop the search

                        //Init
                        output logic start_INIT,
                        input logic finish_INIT,

                        //Task2a
                        output logic start_Task2a,
                        input logic finish_Task2a,

                        //Task2b
                        output logic start_Task2b,
                        input logic finish_Task2b,

                        //Task3
                        output logic start_Task3,
                        input logic finish_Task3,

                        output logic [2:0] operation_num
);

    //Which stage are we on in the algorithm
    logic [2:0] op_num;
    assign operation_num = op_num;

    //State definitions
    typedef enum logic [3:0] {
        IDLE    = 4'b0000,
        StartInit = 4'b0001,
        Init    = 4'b0010,
        Task2a  = 4'b0011,
        Task2b  = 4'b0100,
        Task3   = 4'b0101,
        WaitValid = 4'b0110,
        WaitValid2 = 4'b0111,
        Finish  = 4'b1000
    } statetype;

    /*
    | State      | Hex  |
    | ---------- | ---- |
    | IDLE       | 0x00 |
    | StartInit  | 0x01 |
    | Init       | 0x02 |
    | Task2a     | 0x03 |
    | Task2b     | 0x04 |
    | Task3      | 0x05 |
    | WaitValid  | 0x06 |
    | WaitValid2 | 0x07 |
    | Finish     | 0x08 |
    */

    //Initialize state
    statetype state = IDLE;

    logic [23:0] counterI;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            op_num <= `FINISH;
            state <= IDLE;
            successful_key <= 0;

            start_INIT <= 0;
            start_Task2a <= 0;
            start_Task2b <= 0;
            start_Task3 <= 0;

            counterI <= 0;
            current_key <= lower_key_index;
        end else begin
            case(state)
                IDLE: begin
                    op_num <= `FINISH;
                    successful_key <= 0;

                    start_INIT <= 0;
                    start_Task2a <= 0;
                    start_Task2b <= 0;
                    start_Task3 <= 0;

                    counterI <= 0;

                    if (!buttons[0]) begin
                        state <= StartInit;
                    end
                end
                StartInit: begin //start init task
                    op_num <= `INIT_STAGE;
                    state <= Init;
                    
                    start_INIT <= 1;
                    start_Task2a <= 0;
                    start_Task2b <= 0;
                    start_Task3 <= 0;

                    current_key <= lower_key_index + counterI;
                end
                Init: begin
                    if (finish_INIT) begin //if finished, start task2a task
                        op_num <= `TASK2a_STAGE;
                        state <= Task2a;

                        start_INIT <= 0;
                        start_Task2a <= 1;
                        start_Task2b <= 0;
                        start_Task3 <= 0;
                    end
                end
                Task2a: begin
                    if (finish_Task2a) begin //if finished, start task2b task
                        op_num <= `TASK2b_STAGE;
                        state <= Task2b;

                        start_INIT <= 0;
                        start_Task2a <= 0;
                        start_Task2b <= 1;
                        start_Task3 <= 0;
                    end
                end
                Task2b: begin //if finished, start task3 task
                    if (finish_Task2b) begin
                        op_num <= `TASK3_STAGE;
                        state <= Task3;

                        start_INIT <= 0;
                        start_Task2a <= 0;
                        start_Task2b <= 0;
                        start_Task3 <= 1;
                    end
                end
                Task3: begin //if finished, check if key was valid
                    if (finish_Task3) begin
                        start_INIT <= 0;
                        start_Task2a <= 0;
                        start_Task2b <= 0;
                        start_Task3 <= 0;
                        
                        state <= WaitValid;
                    end
                end
                WaitValid: begin //wait for key to be sent
                    state <= WaitValid2;
                end
                WaitValid2: begin
                    if (stop_search) begin
                        state <= Finish;
                        successful_key <= 0;
                    end else begin
                        if (key_found_Task3) begin //if key found, finish execution
                            op_num <= `FINISH;
                            state <= Finish;
                            successful_key <= 1;
                        end
                        else begin
                            op_num <= `FINISH;
                            successful_key <= 0;

                            if ((lower_key_index + counterI) <= upper_key_index) begin //if we have not reached top limit, check next key
                                state <= StartInit;
                                counterI <= counterI + 24'd1;
                            end else begin //if upper bound for keys reached, stop
                                state <= Finish;
                            end
                        end
                    end
                end
                Finish: begin
                    op_num <= `FINISH;
                    state <= Finish;

                    start_INIT <= 0;
                    start_Task2a <= 0;
                    start_Task2b <= 0;
                    start_Task3 <= 0;
                end
            endcase
        end
    end
endmodule