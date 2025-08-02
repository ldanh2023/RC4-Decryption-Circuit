module Arbitrary_Clock_Divider_My_Version(in_clk, out_clk, freq_counter, on_off);
    parameter duty_cycle = 2; //50% duty cycle (1/duty_cycle);
    parameter N = 32;

    //Inputs
    input logic in_clk, on_off;
    input logic [N-1:0] freq_counter;
    
    //Outputs
    output logic out_clk;

    logic [N-1:0] current_count = {N{1'b0}}; //20 bits, max count is 1 million

    always_ff @(posedge in_clk) begin
        if (!on_off) begin //on_off = 0: SW[0] is in off position
            current_count <= {N{1'b0}};
            out_clk <= 1'b0;
        end //Notes to self: When using <= Verilog assigns all values at the end of executions, therefore "if statements" get old value of values
        else begin //on_off: 1'b1 if audio is on (SW[0] is in on position)
            if (current_count < freq_counter-1) begin //Need < freq_counter-1 because we start at current_count = 1'b0 and we cannot double count (off by one error)
                current_count <= current_count + 1'b1;
            end
            else begin
                current_count <= {N{1'b0}};
            end

            if (current_count < (freq_counter/duty_cycle)) begin //Duty cycle: initial = 0, final = 1
                out_clk <= 1'b0;
            end
            else begin
                out_clk <= 1'b1;
            end
        end
    end
endmodule