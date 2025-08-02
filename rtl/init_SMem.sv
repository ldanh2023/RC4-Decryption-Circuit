module init_SMem (
    input clk, reset,

    //Memory signals
    output logic [7:0] address,
    output logic [7:0] data_out,
    output logic readWrite,

    //Signals from memory interface
    input logic finish_readWrite_op,
    output logic start_readWrite_op,

    //Start-finish protocol
    input logic start_init, 
    output logic finish_init
);

    logic [7:0] counter;

    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        Init      = 3'b001,
        WaitInit  = 3'b010,
        Increment = 3'b011,
        Finish    = 3'b100
    } statetype;

    /*
    | **State Name** | **Hex (2-digit)** |
    | -------------- | ----------------- |
    | `IDLE`         | 0x00              |
    | `Init`         | 0x01              |
    | `WaitInit`     | 0x02              |
    | `Increment`    | 0x03              |
    | `Finish`       | 0x04              |
    */

    statetype state = IDLE;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            address <= 0;
            data_out <= 0;
            readWrite <= 0;
            start_readWrite_op <= 0;
            finish_init <= 0;
            counter <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    address <= 0;
                    data_out <= 0;
                    readWrite <= 0;
                    start_readWrite_op <= 0;
                    finish_init <= 0;
                    counter <= 0;

                    if (start_init) begin //if start signal passed to this FSM
                        state <= Init;
                    end
                end

                Init: begin //initialize by passing arguments to S_memory
                    address <= counter;
                    data_out <= counter;
                    readWrite <= 1;
                    start_readWrite_op <= 1;
                    state <= WaitInit;
                end

                WaitInit: begin //wait for changes to take effect
                    start_readWrite_op <= 0;

                    if (finish_readWrite_op) begin
                        state <= Increment;
                    end
                end

                Increment: begin //increment counter and check if we have written 256 characters
                    if (counter == 8'd255) begin
                        state <= Finish;
                    end else begin
                        counter <= counter + 8'b1;
                        state <= Init;
                    end
                end

                Finish: begin //finish and exit, send finish signal
                    address <= 0;
                    data_out <= 0;
                    readWrite <= 0;
                    start_readWrite_op <= 0;
                    finish_init <= 1;
                    counter <= 0;

                    state <= IDLE;
                end
            endcase
        end
    end
endmodule