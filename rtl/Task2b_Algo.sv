module Task2b_Algo(
                    input logic clk,
                    input logic reset,

                    //Memory data signals for S memory
                    input logic [7:0] S_data_in,
                    output logic [7:0] S_address,
                    output logic [7:0] S_data_out,
                    output logic S_readWrite,

                    //Memory data signals for encrypted memory
                    input logic [7:0] E_data_in,
                    output logic [7:0] E_address,

                    //Memory data signals for decrypted memory
                    input logic [7:0] D_data_in,
                    output logic [7:0] D_address,
                    output logic [7:0] D_data_out,
                    output logic D_readWrite,

                    //Start-finish signals from S memory interface
                    input logic S_finish_readWrite_op,
                    output logic S_start_readWrite_op,

                    //Start-finish signals from encrypted memory interface
                    input logic E_finish_readWrite_op,
                    output logic E_start_readWrite_op,

                    //Start-finish signals from decrypted memory interface
                    input logic D_finish_readWrite_op,
                    output logic D_start_readWrite_op,
                    
                    //Start-finish protocol
                    input logic start_Task2b,
                    output logic finish_Task2b
);

    parameter message_length = 8'd32; //message_length is 32 in our implementation

    //State encoding stateNum_{D_readWrite, S_readWrite, finish_Task2b}
    typedef enum logic [7:0] {
        Idle = 8'b00000_000,
        IncrementI = 8'b00001_000,

        ReadMemSi = 8'b00010_000,
        Read_Wait_ResSi = 8'b0011_000,

        ComputeJ = 8'b00100_000,

        ReadMemSj = 8'b00101_000,
        Read_Wait_ResSj = 8'b00110_000,

        SwapValSi = 8'b00111_010,
        Write_Wait_ResSi = 8'b01000_010,

        SwapValSj = 8'b01001_010,
        Write_Wait_ResSj = 8'b01010_010,

        ReadMemS_SiSj = 8'b01011_000,
        Read_Wait_ResSiSj = 8'b01100_000,

        Read_encryptedMem_K = 8'b01101_000,
        Read_Wait_encryptedMem_K = 8'b01110_000,

        Write_decryptedMem_K = 8'b01111_100,
        Write_Wait_decryptedMem_K = 8'b10000_100,

        IncrementK = 8'b10001_000,
        Finished = 8'b10010_001
    } statetype;

    /*
    | **State Name**              | **Hex (2-digit)** |
    | --------------------------- | ----------------- |
    | `Idle`                      | 0x00              |
    | `IncrementI`                | 0x08              |
    | `ReadMemSi`                 | 0x10              |
    | `Read_Wait_ResSi`           | 0x18              |
    | `ComputeJ`                  | 0x20              |
    | `ReadMemSj`                 | 0x28              |
    | `Read_Wait_ResSj`           | 0x30              |
    | `SwapValSi`                 | 0x3A              |
    | `Write_Wait_ResSi`          | 0x42              |
    | `SwapValSj`                 | 0x4A              |
    | `Write_Wait_ResSj`          | 0x52              |
    | `ReadMemS_SiSj`             | 0x58              |
    | `Read_Wait_ResSiSj`         | 0x60              |
    | `Read_encryptedMem_K`       | 0x68              |
    | `Read_Wait_encryptedMem_K`  | 0x70              |
    | `Write_decryptedMem_K`      | 0x7C              |
    | `Write_Wait_decryptedMem_K` | 0x84              |
    | `IncrementK`                | 0x88              |
    | `Finished`                  | 0x91              |
    */


    //Initial state
    statetype state = Idle;

    logic [7:0] counterI, counterJ, counterK, datafromRAM, f, S_i, S_j;

    //Output logic
    assign finish_Task2b = state[0];
    assign S_readWrite = state[1];
    assign D_readWrite = state[2];


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= Idle;
            
            counterI <= 0;
            counterJ <= 0;
            counterK <= 0;
            datafromRAM <= 0;
            f <= 0;
            S_i <= 0;
            S_j <= 0;

            S_address <= 0;
            S_data_out <= 0;
            E_address <= 0;
            D_address <= 0;
            D_data_out <= 0;

            S_start_readWrite_op <= 0;
            E_start_readWrite_op <= 0;
            D_start_readWrite_op <= 0;
        end
        else begin
            case(state)
                Idle: begin
                    if (start_Task2b) begin //if start signal passed to FSM
                        counterI <= 0;
                        counterJ <= 0;
                        counterK <= 0;
                        datafromRAM <= 0;
                        f <= 0;
                        S_i <= 0;
                        S_j <= 0;

                        S_address <= 0;
                        S_data_out <= 0;
                        E_address <= 0;
                        D_address <= 0;
                        D_data_out <= 0;

                        S_start_readWrite_op <= 0;
                        E_start_readWrite_op <= 0;
                        D_start_readWrite_op <= 0;

                        state <= IncrementI;
                    end
                end
                IncrementI: begin //increment I
                    counterI <= counterI + 8'b1;

                    state <= ReadMemSi;
                end
                ReadMemSi: begin //read S[i]
                    S_start_readWrite_op <= 1;
                    S_address <= counterI;

                    state <= Read_Wait_ResSi;
                end
                Read_Wait_ResSi: begin //wait for data to come
                    if (S_finish_readWrite_op) begin
                        S_start_readWrite_op <= 0;
                        S_i <= S_data_in;
                        
                        state <= ComputeJ;
                    end
                end
                ComputeJ: begin
                    counterJ <= counterJ + S_i; //j = j + S[i]

                    state <= ReadMemSj;
                end
                ReadMemSj: begin //read S[j]
                    S_start_readWrite_op <= 1;
                    S_address <= counterJ;

                    state <= Read_Wait_ResSj;
                end
                Read_Wait_ResSj: begin //get S[j]
                    if (S_finish_readWrite_op) begin
                        S_start_readWrite_op <= 0;
                        S_j <= S_data_in;

                        state <= SwapValSi;
                    end
                end
                SwapValSi: begin //write S[j] into S[i]
                    S_start_readWrite_op <= 1;
                    S_address <= counterI;
                    S_data_out <= S_j;

                    state <= Write_Wait_ResSi;
                end
                Write_Wait_ResSi: begin //wait for data to be written
                    if(S_finish_readWrite_op) begin
                        S_start_readWrite_op <= 0;

                        state <= SwapValSj;
                    end
                end
                SwapValSj: begin //write S[i] into S[j]
                    S_start_readWrite_op <= 1;
                    S_address <= counterJ;
                    S_data_out <= S_i;

                    state <= Write_Wait_ResSj;
                end
                Write_Wait_ResSj: begin //wait for data to be written
                    if(S_finish_readWrite_op) begin
                        S_start_readWrite_op <= 0;

                        state <= ReadMemS_SiSj;
                    end
                end
                ReadMemS_SiSj: begin //read S[S[i] + S[j]]
                    S_start_readWrite_op <= 1;
                    S_address <= S_i + S_j;

                    state <= Read_Wait_ResSiSj;
                end
                Read_Wait_ResSiSj: begin //get S[S[i] + S[j]]
                    if (S_finish_readWrite_op) begin
                        S_start_readWrite_op <= 0;
                        f <= S_data_in;

                        state <= Read_encryptedMem_K;
                    end
                end
                Read_encryptedMem_K: begin //read encrypted_input[k]
                    E_start_readWrite_op <= 1;
                    E_address <= counterK;

                    state <= Read_Wait_encryptedMem_K;
                end
                Read_Wait_encryptedMem_K: begin //get encrypted_input[k]
                    if (E_finish_readWrite_op) begin
                        E_start_readWrite_op <= 0;
                        datafromRAM <= E_data_in;

                        state <= Write_decryptedMem_K;
                    end
                end
                Write_decryptedMem_K: begin //write decrypted_output[k] = f xor encrypted_input[k]
                    D_start_readWrite_op <= 1;
                    D_address <= counterK;
                    D_data_out <= datafromRAM ^ f;

                    state <= Write_Wait_decryptedMem_K;
                end
                Write_Wait_decryptedMem_K: begin //wait for data to be written
                    if(D_finish_readWrite_op) begin
                        D_start_readWrite_op <= 0;

                        state <= IncrementK;
                    end
                end
                IncrementK: begin //increment i counter (loop variable: i = 0 to 255), if we reach 255 then finish
                    if (counterK == message_length-1) begin //for k = 0 to message_length-1
                        state <= Finished;
                    end else begin
                        counterK <= counterK + 8'b1;
                        state <= IncrementI;
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