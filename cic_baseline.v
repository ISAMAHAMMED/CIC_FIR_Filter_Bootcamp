
module cic_n2_r2048_m1 (
    input  wire              clk,
    input  wire              reset,
    input  wire signed [1:0] in_sample,

    output reg signed [19:0] out_sample,
    output reg               out_valid
);

    // CIC parameters: N=2, R=2048, M=1
    // Required internal width = 2 + 2*log2(2048) = 24 bits(bit growth formula)

    reg signed [23:0] int1, int2;
    reg signed [23:0] comb1_delay, comb2_delay;

    reg [10:0] count;

    wire signed [23:0] input_value;
    wire signed [23:0] int1_next, int2_next;
    wire signed [23:0] comb1_next, comb2_next;

    // Extend the signed input to the internal register width.
    assign input_value = {{22{in_sample[1]}}, in_sample};

    // Integrator stages run on every clock cycle.(2 integrator stages)
    assign int1_next = int1 + input_value;
    assign int2_next = int2 + int1_next;

    // Comb stages calculate differences between delayed samples.
    assign comb1_next = int2_next - comb1_delay;
    assign comb2_next = comb1_next - comb2_delay;

    always @(posedge clk) begin
        if (reset) begin
            int1        <= 24'sd0;
            int2        <= 24'sd0;
            comb1_delay <= 24'sd0;
            comb2_delay <= 24'sd0;

            count       <= 11'd0;
            out_sample  <= 20'sd0;
            out_valid   <= 1'b0;
        end
        else begin
            int1 <= int1_next;
            int2 <= int2_next;

            // Output is valid only when a new decimated sample is ready.
            out_valid <= 1'b0;

            if (count == 11'd2047) begin
                count <= 11'd0;

                // Update the comb delays at the decimated rate.
                comb1_delay <= int2_next;
                comb2_delay <= comb1_next;

                // Reduce the result to 20 bits by scaling it down.
                out_sample <= comb2_next >>> 4;
                out_valid  <= 1'b1;
            end
            else begin
                count <= count + 1'b1;
            end
        end
    end

endmodule