module swapAlgo (
                    input logic clk,
                    input logic reset,

                    //Secret key
                    input logic [23:0] secretKey,

                    //Memory data signals
                    input logic [7:0] data_in,
                    output logic [7:0] address,
                    output logic [7:0] data_out,
                    output logic readWrite,

                    //Start-finish signals from memory interface
                    input logic finish_readWrite_op,
                    output logic start_readWrite_op,
                    
                    //Start-finish protocol
                    input logic start_Task2a,
                    output logic finish_Task2a
);

    //State encoding stateNum_{readWrite, finish_Task2a}
    typedef enum logic [6:0] {
        Idle = 7'b0000_00,

        ReadMemSi = 7'b0001_00,
        Read_Wait_ResSi = 7'b0010_00,

        ComputeJ = 7'b0011_00,

        ReadMemSj = 7'b0100_00,
        Read_Wait_ResSj = 7'b0101_00,

        SwapValSi = 7'b0110_10,
        Write_Wait_ResSi = 7'b0111_10,

        SwapValSj = 7'b1000_10,
        Write_Wait_ResSj = 7'b1001_10,

        IncrementI = 7'b1010_00,
        Finished = 7'b1011_01
    } statetype;

    /*
    | State Name | Hex Value |
    |------------|-----------|
    | Idle | 0x00 |
    | ReadMemSi | 0x04 |
    | Read_Wait_ResSi | 0x08 |
    | ComputeJ | 0x0C |
    | ReadMemSj | 0x10 |
    | Read_Wait_ResSj | 0x14 |
    | SwapValSi | 0x1A |
    | Write_Wait_ResSi | 0x1E |
    | SwapValSj | 0x22 |
    | Write_Wait_ResSj | 0x26 |
    | IncrementI | 0x28 |
    | Finished | 0x2D |
    */


    //Initial state
    statetype state = Idle;


    logic [7:0] counterI, counterJ, tempVal, datafromRAM;
    logic [7:0] key_byte;


    //Output logic
    assign finish_Task2a = state[0];
    assign readWrite = state[1];


    //Get secret key value, use modulo operation
    always_comb begin
        case (counterI % 3)
            0: key_byte = secretKey[23:16];
            1: key_byte = secretKey[15:8];
            2: key_byte = secretKey[7:0];
            default: key_byte = 8'b0;
        endcase
    end


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= Idle;
            counterI <= 0;
            counterJ <= 0;
            tempVal <= 0;
            datafromRAM <= 0;

            address <= 0;
            data_out <= 0;
        end
        else begin
            case(state)
                Idle: begin
                    if (start_Task2a) begin //if start signal passed to FSM
                        counterI <= 0;
                        counterJ <= 0;

                        state <= ReadMemSi;
                    end
                end
                ReadMemSi: begin //read S[i]
                    start_readWrite_op <= 1;
                    address <= counterI;
                    state <= Read_Wait_ResSi;
                end
                Read_Wait_ResSi: begin //wait for data to come
                    if(finish_readWrite_op) begin
                        start_readWrite_op <= 0;
                        datafromRAM <= data_in;
                        state <= ComputeJ;
                    end
                end
                ComputeJ: begin
                    counterJ <= counterJ + datafromRAM + key_byte; //j = j + S[i] + secret_key[i % key_length (3)]
                    state <= ReadMemSj;
                    tempVal <= datafromRAM; //store S[i] in temporary variable
                end
                ReadMemSj: begin //read S[j]
                    start_readWrite_op <= 1;
                    address <= counterJ;
                    state <= Read_Wait_ResSj;
                end
                Read_Wait_ResSj: begin //get S[j]
                    if(finish_readWrite_op) begin
                        start_readWrite_op <= 0;
                        state <= SwapValSi;
                        datafromRAM <= data_in;
                    end
                end
                SwapValSi: begin //write S[j] into S[i]
                    start_readWrite_op <= 1;
                    address <= counterI;
                    data_out <= datafromRAM;
                    state <= Write_Wait_ResSi;
                end
                Write_Wait_ResSi: begin //wait for data to be written
                    if(finish_readWrite_op) begin
                        start_readWrite_op <= 0;
                        state <= SwapValSj;
                    end
                end
                SwapValSj: begin //write S[i] into S[j]
                    start_readWrite_op <= 1;
                    address <= counterJ;
                    data_out <= tempVal;
                    state <= Write_Wait_ResSj;
                end
                Write_Wait_ResSj: begin //wait for data to be written
                    if(finish_readWrite_op) begin
                        start_readWrite_op <= 0;
                        state <= IncrementI;
                    end
                end
                IncrementI: begin //increment i counter (loop variable: i = 0 to 255), if we reach 255 then finish
                    if (counterI == 8'd255) begin
                        state <= Finished;
                    end else begin
                        counterI <= counterI + 8'b1;
                        state <= ReadMemSi;
                    end
                end
                Finished: begin
                    state <= Idle;
                end
                
                default: state <= Idle;
            endcase
        end
    end

endmodule