`define a_ascii 8'd97
`define z_ascii 8'd122
`define space_ascii 8'd32

module Task3_Check (
                    input logic clk,
                    input logic reset,

                    //Memory data signals for decrypted memory
                    input logic [7:0] D_data_in,
                    output logic [7:0] D_address,
                    output logic [7:0] D_data_out,
                    output logic D_readWrite,

                    //Start-finish signals from decrypted memory interface
                    input logic D_finish_readWrite_op,
                    output logic D_start_readWrite_op,

                    //Key is valid
                    output logic key_Valid,
                    
                    //Start-finish protocol
                    input logic start_Task3,
                    output logic finish_Task3
);

    parameter message_length = 8'd32; //message_length is 32 in our implementation


    //State encoding stateNum_{D_readWrite, finish_Task3}
    typedef enum logic [4:0] {
        Idle = 5'b000_00,

        Read_decryptedMem = 5'b001_00,
        Read_Wait_decryptedMem = 5'b010_00,
        CheckValid = 5'b011_00,

        IncrementI = 5'b100_00,
        Finished = 5'b101_01
    } statetype;

    /*
    | State                    | Hex  |
    | ------------------------ | ---- |
    | Idle                     | 0x00 |
    | Read\_decryptedMem       | 0x04 |
    | Read\_Wait\_decryptedMem | 0x08 |
    | CheckValid               | 0x0C |
    | IncrementI               | 0x10 |
    | Finished                 | 0x15 |
    */


    //Initial state
    statetype state = Idle;

    logic [7:0] counterI, counter_NumCorrect, datafromRAM;

    //Output logic
    assign finish_Task3 = state[0];
    assign D_readWrite = state[1];


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= Idle;

            counterI <= 0;
            counter_NumCorrect <= 0;
            datafromRAM <= 0;

            D_address <= 0;
            D_data_out <= 0;
            D_start_readWrite_op <= 0;

            key_Valid <= 0;
        end else begin
            case (state)
                Idle: begin
                    if (start_Task3) begin
                        counterI <= 0;
                        counter_NumCorrect <= 0;
                        datafromRAM <= 0;

                        D_address <= 0;
                        D_data_out <= 0;
                        D_start_readWrite_op <= 0;

                        key_Valid <= 0;

                        state <= Read_decryptedMem;
                    end
                end
                Read_decryptedMem: begin //read decrypted_data
                    D_start_readWrite_op <= 1;
                    D_address <= counterI;

                    state <= Read_Wait_decryptedMem;
                end
                Read_Wait_decryptedMem: begin
                    if (D_finish_readWrite_op) begin
                        D_start_readWrite_op <= 0;
                        datafromRAM <= D_data_in; 

                        state <= CheckValid;
                    end
                end
                CheckValid: begin
                    if (((datafromRAM >= `a_ascii) && (datafromRAM <= `z_ascii)) || datafromRAM == `space_ascii) begin //if value is from the range[97, 122] or 32, then correct
                        counter_NumCorrect <= counter_NumCorrect + 8'b1;
                    end

                    state <= IncrementI;
                end
                IncrementI: begin
                   if (counterI == message_length-1) begin //for k = 0 to message_length-1
                        if (counter_NumCorrect == message_length) begin //if message length reached, stop checking
                            key_Valid <= 1;
                        end else begin
                            key_Valid <= 0;
                        end
                        state <= Finished;
                    end else begin
                        counterI <= counterI + 8'b1; //keep checking if message length not reached
                        state <= Read_decryptedMem;
                    end
                end
                Finished: begin
                    state <= Idle;
                end
            endcase
        end
    end
endmodule