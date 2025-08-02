`default_nettype none

`define INIT_STAGE 3'b000
`define TASK2a_STAGE 3'b001
`define TASK2b_STAGE 3'b010
`define TASK3_STAGE 3'b011
`define FINISH 3'b100

//This module constitutes the single decryption algorithm core and signals to interface with the memory
module rc4_solution(
                    input logic clock,
                    input logic [3:0] buttons,

                    input logic [23:0] lower_key_index, //lower bound
                    input logic [23:0] upper_key_index, //upper bound
                    output logic [23:0] current_key, //current key to be checked
                    output logic successful_key, //output key is found, output to top module (0 if not found, 1 if found)
                    input logic stop_search,
            

                    //S memory interface controls
                    output logic [7:0] S_address,
                    output logic [7:0] DataIn_toS,
                    input logic [7:0] S_DataOut_toFSM,
                    output logic S_write_en,


                    //Encrypted memory controls
                    output logic [7:0] Encrypted_mem_address,
                    input logic [7:0] Encrypted_mem_DataOut_toFSM,


                    //Decrypted memory controls
                    output logic [7:0] Decrypted_mem_address,
                    output logic [7:0] DataIn_to_decrypted_mem,
                    input logic [7:0] Decrypted_mem_DataOut_toFSM,
                    output logic Decrypted_mem_write_en
);


    //Create FSM module that handles writing/reading the data to S memory
    logic start_SMemInterface;
    logic finish_SMemInterface;
    logic readWrite_SMemInterface;

    logic [7:0] FSM_Adr_SMemInterface;
    logic [7:0] DataIn_fromFSM_toS;
    logic [7:0] DataOut_toFSM_SMemInterface;


    S_MemInterface S_MemInterface_inst (
        //Clock and reset
        .clk(clock),
        .reset(1'b0),

        //Start-finish protocol
        .start(start_SMemInterface),
        .finish(finish_SMemInterface),

        //readWrite signal indicates if we are doing a read or write operation, read = 0, write = 1
        .readWrite(readWrite_SMemInterface),

        //------------------------------------------- 4 signals to memory in total --------------------------------------------------

        //Signals for interfacing with RAM
        .FSM_Adr(FSM_Adr_SMemInterface), //address we want to read from passed in FSM
        .sAdr(S_address), //address we want to read from passed to memory
        

        //Write enable signal to memory
        .sWriteEn(S_write_en),

        
        //Data passed to memory (write operation)
        .DataIn_fromFSM(DataIn_fromFSM_toS), //data from FSM
        .DataOut_to_s(DataIn_toS), //data to memory


        //Data read from memory (read operation)
        .DataIn_from_s(S_DataOut_toFSM), //data from memory
        .DataOut_toFSM(DataOut_toFSM_SMemInterface) //data to FSM
    );


    //Create FSM module that handles writing/reading the data to encrypted memory
    logic start_encrypted_MemInterface;
    logic finish_encrypted_MemInterface;

    logic [7:0] FSM_Adr_encrypt_MemInterface;
    logic [7:0] DataOut_toFSM_EncryptMemInterface;


    Encrypted_MemInterface Encrypted_MemInterface_inst (
        //Clock and reset
        .clk(clock),
        .reset(1'b0),


        //Start-finish protocol
        .start(start_encrypted_MemInterface),
        .finish(finish_encrypted_MemInterface),
        

        //------------------------------------------- 4 signals to memory in total --------------------------------------------------

        //Signals for interfacing with RAM
        .FSM_Adr(FSM_Adr_encrypt_MemInterface), //address we want to read from passed in FSM
        .Encrypt_Adr(Encrypted_mem_address), //address we want to read from passed to memory


        //Data read from memory (read operation)
        .DataIn_from_Encrypt(Encrypted_mem_DataOut_toFSM), //data from memory
        .DataOut_toFSM(DataOut_toFSM_EncryptMemInterface) //data to FSM
);

    


    //Create FSM module that handles writing/reading the data to decrypted memory
    logic start_decrypted_MemInterface;
    logic finish_decrypted_MemInterface;
    logic readWrite_decrypted_MemInterface;

    logic [7:0] FSM_Adr_decrypt_MemInterface;
    logic [7:0] DataIn_fromFSM_to_DecryptedMem;
    logic [7:0] DataOut_toFSM_DecryptMemInterface;


    Decrypted_MemInterface Decrypted_MemInterface_inst (
        //Clock and reset
        .clk(clock),
        .reset(1'b0),


        //Start-finish protocol 
        .start(start_decrypted_MemInterface),
        .finish(finish_decrypted_MemInterface),


        //readWrite signal indicates if we are doing a read or write operation, read = 0, write = 1
        .readWrite(readWrite_decrypted_MemInterface),
        

        //------------------------------------------- 4 signals to memory in total --------------------------------------------------

        //Signals for interfacing with RAM
        .FSM_Adr(FSM_Adr_decrypt_MemInterface), //address we want to read from passed in FSM
        .Decrypt_Adr(Decrypted_mem_address), //address we want to read from passed to memory
        

        //Write enable signal to memory
        .Decrypt_WriteEn(Decrypted_mem_write_en),

        
        //Data passed to memory (write operation)
        .DataIn_fromFSM(DataIn_fromFSM_to_DecryptedMem), //data from FSM
        .DataOut_to_Decrypt(DataIn_to_decrypted_mem), //data to memory


        //Data read from memory (read operation)
        .DataIn_from_Decrypt(Decrypted_mem_DataOut_toFSM), //data from memory
        .DataOut_toFSM(DataOut_toFSM_DecryptMemInterface) //data to FSM
    );


    //Create FSM module that handles controlling the FSMs
    logic [23:0] test_key;
    logic [2:0] operation_num;

    assign current_key = test_key;

    FSM_Controller CONTROLLER(
        .clk(clock),
        .reset(1'b0),
        .buttons(buttons),

        //Secret key (range of keys to check)
        .lower_key_index(lower_key_index), //lower bound
        .upper_key_index(upper_key_index), //upper bound
        .current_key(test_key), //current key to check
        
        .key_found_Task3(key_Valid), //if key was found in check
        .successful_key(successful_key), //output key is found, output to top module (0 if not found, 1 if found)
        .stop_search(stop_search),

        //----------------- Start-finish protocols -----------------------------------
        //Init
        .start_INIT(start_INIT),
        .finish_INIT(finish_INIT),

        //Task2a
        .start_Task2a(start_Task2a),
        .finish_Task2a(finish_Task2a),

        //Task2b
        .start_Task2b(start_Task2b),
        .finish_Task2b(finish_Task2b),

        //Task3
        .start_Task3(start_Task3),
        .finish_Task3(finish_Task3),

        .operation_num(operation_num)            
    );


    //--------------------------------------------------- S memory signals -----------------------------------------------------
    //Inputs to S Memory
    always_comb begin
        case(operation_num)
            `INIT_STAGE: begin
                start_SMemInterface = start_SMemInterface_INIT;
                readWrite_SMemInterface = readWrite_SMemInterface_INIT;
                FSM_Adr_SMemInterface = FSM_Adr_SMemInterface_INIT;
                DataIn_fromFSM_toS = DataIn_fromFSM_toS_INIT;
            end
            `TASK2a_STAGE: begin
                start_SMemInterface = start_SMemInterface_TASK2a;
                readWrite_SMemInterface = readWrite_SMemInterface_TASK2a;
                FSM_Adr_SMemInterface = FSM_Adr_SMemInterface_TASK2a;
                DataIn_fromFSM_toS = DataIn_fromFSM_toS_TASK2a;
            end
            `TASK2b_STAGE: begin
                start_SMemInterface = start_SMemInterface_TASK2b;
                readWrite_SMemInterface = readWrite_SMemInterface_TASK2b;
                FSM_Adr_SMemInterface = FSM_Adr_SMemInterface_TASK2b;
                DataIn_fromFSM_toS = DataIn_fromFSM_toS_TASK2b;
            end
            default: begin
                start_SMemInterface = 1'b0;
                readWrite_SMemInterface = 1'b0;
                FSM_Adr_SMemInterface = 8'b0;
                DataIn_fromFSM_toS = 8'b0;
            end
        endcase
    end

    //Outputs
    assign finish_SMemInterface_INIT = finish_SMemInterface; //Init

    assign finish_SMemInterface_TASK2a = finish_SMemInterface; //Task 2a
    assign DataOut_toFSM_SMemInterface_TASK2a = DataOut_toFSM_SMemInterface;

    assign finish_SMemInterface_TASK2b = finish_SMemInterface;
    assign DataOut_toFSM_SMemInterface_TASK2b = DataOut_toFSM_SMemInterface;


    //--------------------------------------------------- Encrypted memory signals -------------------------------------------------
    //Inputs to Encrypted Memory
    assign start_encrypted_MemInterface = start_EMemInterface_TASK2b;
    assign FSM_Adr_encrypt_MemInterface = FSM_Adr_EMemInterface_TASK2b;

    //Outputs
    assign finish_EMemInterface_TASK2b = finish_encrypted_MemInterface;
    assign DataOut_toFSM_EMemInterface_TASK2b = DataOut_toFSM_EncryptMemInterface;


    //--------------------------------------------------- Decrypted memory signals --------------------------------------------------
    //Inputs to Decrypted Memory
    always_comb begin
        case (operation_num)
            `TASK2b_STAGE: begin
                start_decrypted_MemInterface = start_DMemInterface_TASK2b;
                readWrite_decrypted_MemInterface = readWrite_DMemInterface_TASK2b;
                FSM_Adr_decrypt_MemInterface = FSM_Adr_DMemInterface_TASK2b;
                DataIn_fromFSM_to_DecryptedMem = DataIn_fromFSM_toD_TASK2b;
            end
            `TASK3_STAGE: begin
                start_decrypted_MemInterface = start_DMemInterface_TASK3;
                readWrite_decrypted_MemInterface = readWrite_DMemInterface_TASK3;
                FSM_Adr_decrypt_MemInterface = FSM_Adr_DMemInterface_TASK3;
                DataIn_fromFSM_to_DecryptedMem = DataIn_fromFSM_toD_TASK3;
            end
            default: begin
                start_decrypted_MemInterface = 1'b0;
                readWrite_decrypted_MemInterface = 1'b0;
                FSM_Adr_decrypt_MemInterface = 8'b0;
                DataIn_fromFSM_to_DecryptedMem = 8'b0;
            end
        endcase
    end

    //Outputs
    assign finish_DMemInterface_TASK2b = finish_decrypted_MemInterface;
    assign DataOut_toFSM_DMemInterface_TASK2b = DataOut_toFSM_DecryptMemInterface;

    assign finish_DMemInterface_TASK3 = finish_decrypted_MemInterface;
    assign DataOut_toFSM_DMemInterface_TASK3 = DataOut_toFSM_DecryptMemInterface;


    //----------------------------------- Instantiate the modules that do the operations ----------------------------------------

    //-------------------------------------------- Step 1: Initialize ------------------------------------------------------
    logic [7:0] FSM_Adr_SMemInterface_INIT;
    logic readWrite_SMemInterface_INIT;
    logic finish_SMemInterface_INIT;
    logic start_SMemInterface_INIT;
    logic [7:0] DataIn_fromFSM_toS_INIT;

    logic start_INIT;
    logic finish_INIT;

    init_SMem init_SMem_inst (
                                .clk(clock),
                                .reset(1'b0),

                                //Memory data signals
                                .address(FSM_Adr_SMemInterface_INIT),
                                .data_out(DataIn_fromFSM_toS_INIT),
                                .readWrite(readWrite_SMemInterface_INIT),

                                //Start-finish signals from memory interface
                                .finish_readWrite_op(finish_SMemInterface_INIT),
                                .start_readWrite_op(start_SMemInterface_INIT),

                                //Start-finish protocol
                                .start_init(start_INIT),
                                .finish_init(finish_INIT)
    );



    //---------------------------------------------- Task_2a -------------------------------------------------------------------
    logic start_SMemInterface_TASK2a;
    logic finish_SMemInterface_TASK2a;
    logic readWrite_SMemInterface_TASK2a;

    logic [7:0] FSM_Adr_SMemInterface_TASK2a;
    logic [7:0] DataIn_fromFSM_toS_TASK2a;
    logic [7:0] DataOut_toFSM_SMemInterface_TASK2a;
    
    logic start_Task2a;
    logic finish_Task2a;

    swapAlgo swapAlgo_inst (
                                .clk(clock),
                                .reset(1'b0),

                                //Secret key
                                .secretKey(test_key),

                                //Memory data signals
                                .address(FSM_Adr_SMemInterface_TASK2a),
                                .data_out(DataIn_fromFSM_toS_TASK2a),
                                .readWrite(readWrite_SMemInterface_TASK2a),
                                .data_in(DataOut_toFSM_SMemInterface_TASK2a),

                                //Start-finish signals from memory interface
                                .finish_readWrite_op(finish_SMemInterface_TASK2a),
                                .start_readWrite_op(start_SMemInterface_TASK2a),
                                
                                //Start-finish protocol
                                .start_Task2a(start_Task2a),
                                .finish_Task2a(finish_Task2a)
    );



    //---------------------------------------------- Task 2b ---------------------------------------------------------------------
    logic start_Task2b;
    logic finish_Task2b;

    //S Memory signals
    logic start_SMemInterface_TASK2b;
    logic finish_SMemInterface_TASK2b;
    logic readWrite_SMemInterface_TASK2b;

    logic [7:0] FSM_Adr_SMemInterface_TASK2b;
    logic [7:0] DataIn_fromFSM_toS_TASK2b;
    logic [7:0] DataOut_toFSM_SMemInterface_TASK2b;


    //Encrypted Memory signals
    logic start_EMemInterface_TASK2b;
    logic finish_EMemInterface_TASK2b;

    logic [7:0] FSM_Adr_EMemInterface_TASK2b;
    logic [7:0] DataOut_toFSM_EMemInterface_TASK2b;


    //Decrypted Memory signals
    logic start_DMemInterface_TASK2b;
    logic finish_DMemInterface_TASK2b;
    logic readWrite_DMemInterface_TASK2b;

    logic [7:0] FSM_Adr_DMemInterface_TASK2b;
    logic [7:0] DataIn_fromFSM_toD_TASK2b;
    logic [7:0] DataOut_toFSM_DMemInterface_TASK2b;

    Task2b_Algo Task2b_Algo_inst(
                                    .clk(clock),
                                    .reset(1'b0),


                                    //Memory data signals for S memory
                                    .S_data_in(DataOut_toFSM_SMemInterface_TASK2b),
                                    .S_address(FSM_Adr_SMemInterface_TASK2b),
                                    .S_data_out(DataIn_fromFSM_toS_TASK2b),
                                    .S_readWrite(readWrite_SMemInterface_TASK2b),

                                    //Memory data signals for encrypted memory
                                    .E_data_in(DataOut_toFSM_EMemInterface_TASK2b),
                                    .E_address(FSM_Adr_EMemInterface_TASK2b),

                                    //Memory data signals for decrypted memory
                                    .D_data_in(DataOut_toFSM_DMemInterface_TASK2b),
                                    .D_address(FSM_Adr_DMemInterface_TASK2b),
                                    .D_data_out(DataIn_fromFSM_toD_TASK2b),
                                    .D_readWrite(readWrite_DMemInterface_TASK2b),


                                    //Start-finish signals from S memory interface
                                    .S_finish_readWrite_op(finish_SMemInterface_TASK2b),
                                    .S_start_readWrite_op(start_SMemInterface_TASK2b),

                                    //Start-finish signals from encrypted memory interface
                                    .E_finish_readWrite_op(finish_EMemInterface_TASK2b),
                                    .E_start_readWrite_op(start_EMemInterface_TASK2b),

                                    //Start-finish signals from decrypted memory interface
                                    .D_finish_readWrite_op(finish_DMemInterface_TASK2b),
                                    .D_start_readWrite_op(start_DMemInterface_TASK2b),
                                    
                                    //Start-finish protocol
                                    .start_Task2b(start_Task2b),
                                    .finish_Task2b(finish_Task2b)
    );



    //---------------------------------------------- Task 3 ------------------------------------------------------------------
    logic start_Task3;
    logic finish_Task3;

    //Key valid signal
    logic key_Valid;

    //Decrypted Memory signals
    logic start_DMemInterface_TASK3;
    logic finish_DMemInterface_TASK3;
    logic readWrite_DMemInterface_TASK3;

    logic [7:0] FSM_Adr_DMemInterface_TASK3;
    logic [7:0] DataIn_fromFSM_toD_TASK3;
    logic [7:0] DataOut_toFSM_DMemInterface_TASK3;


    Task3_Check Task3_Check_inst (
                    .clk(clock),
                    .reset(1'b0),

                    //Memory data signals for decrypted memory
                    .D_data_in(DataOut_toFSM_DMemInterface_TASK3),
                    .D_address(FSM_Adr_DMemInterface_TASK3),
                    .D_data_out(DataIn_fromFSM_toD_TASK3),
                    .D_readWrite(readWrite_DMemInterface_TASK3),

                    //Start-finish signals from decrypted memory interface
                    .D_finish_readWrite_op(finish_DMemInterface_TASK3),
                    .D_start_readWrite_op(start_DMemInterface_TASK3),

                    //Key is valid
                    .key_Valid(key_Valid),
                    
                    //Start-finish protocol
                    .start_Task3(start_Task3),
                    .finish_Task3(finish_Task3)
    );
endmodule