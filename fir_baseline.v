
`timescale 1ns / 1ps

module fir_baseline (
    input wire clk,
    input wire reset,
    input wire in_valid,
    input wire signed [19:0] in_sample,
    output reg signed [19:0] out_sample,
    output reg out_valid
);

    // Q3.13 coefficients
    localparam signed [15:0] C0 = 16'sd954;
    localparam signed [15:0] C1 = -16'sd2867;
    localparam signed [15:0] C2 = 16'sd12018;
    localparam signed [15:0] C3 = -16'sd2867;
    localparam signed [15:0] C4 = 16'sd954;

    reg signed [19:0] d1, d2, d3, d4;

    wire signed [35:0] p0 = in_sample * C0;
    wire signed [35:0] p1 = d1 * C1;
    wire signed [35:0] p2 = d2 * C2;
    wire signed [35:0] p3 = d3 * C3;
    wire signed [35:0] p4 = d4 * C4;

    wire signed [39:0] acc =
          {{4{p0[35]}}, p0}
        + {{4{p1[35]}}, p1}
        + {{4{p2[35]}}, p2}
        + {{4{p3[35]}}, p3}
        + {{4{p4[35]}}, p4};

    wire signed [39:0] rounded_result =
        (acc >= 0) ? ((acc + 40'sd4096) >>> 13)
                   : -(((-acc + 40'sd4096) >>> 13));

    always @(posedge clk) begin
        if (reset) begin
            d1 <= 0;
            d2 <= 0;
            d3 <= 0;
            d4 <= 0;
            out_sample <= 0;
            out_valid <= 0;
        end
        else begin
            out_valid <= 0;

            if (in_valid) begin
                out_sample <= rounded_result;
                out_valid <= 1;

                d4 <= d3;
                d3 <= d2;
                d2 <= d1;
                d1 <= in_sample;
            end
        end
    end

endmodule