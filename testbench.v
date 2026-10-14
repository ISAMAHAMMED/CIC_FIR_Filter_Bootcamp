
`timescale 1ns / 1ps

module cic_tb;

    reg data [0:4096025];
    reg clk, clk2, clk3, clk4, reset, enable;
    reg signed [1:0] bits;

    wire outready, outready2, firvalid;
    wire signed [19:0] cicout, firout;

    integer i = 0;
    integer fd1, fd2, fd3, fd4;

    initial begin
        $readmemh("/Users/isamahammed/Downloads/hz500.mem", data);

        clk = 0;
        clk2 = 0;
        clk3 = 0;
        clk4 = 0;
        bits = 0;
        reset = 1;
        enable = 0;

        #51 reset = 0;
        enable = 1;
    end

    always #50 clk = ~clk;
    always #25600 clk2 = ~clk2;
    always #102400 clk3 = ~clk3;

    initial begin
        fd1 = $fopen("bits.txt", "w");
        fd2 = $fopen("cic_n2_500.txt", "w");
        fd3 = $fopen("fir_baseline_500_rtl.txt", "w");
        fd4 = $fopen("cic512_500_by4.txt", "w");

        if (!fd1 || !fd2 || !fd3 || !fd4) begin
            $display("Error opening output files.");
            $finish;
        end
    end

    always @(posedge clk) begin
        if (!reset && i < 4096026) begin
            if (i % 2 == 0)
                bits <= {1'b0, data[i]};
            else
                bits <= {2{data[i]}};

            i <= i + 1;
        end
        else if (i >= 4096026) begin
            $fclose(fd1);
            $fclose(fd2);
            $fclose(fd3);
            $fclose(fd4);
            $finish;
        end
    end

    always @(posedge clk) begin
        if (!reset)
            $fwrite(fd1, "%0d\n", $signed(bits));

        if (!reset && outready)
            $fwrite(fd2, "%0d\n", $signed(cicout));

        if (!reset && firvalid)
            $fwrite(fd3, "%0d\n", $signed(firout));
    end

    always @(posedge clk3) begin
        if (!reset)
            $fwrite(fd4, "%0d\n", $signed(cicout));
    end

    cic_n2_r2048_m1 cic (
        .clk(clk),
        .reset(reset),
        .in_sample(bits),
        .out_sample(cicout),
        .out_valid(outready)
    );

    fir_baseline fir (
        .clk(clk),
        .reset(reset),
        .in_valid(outready),
        .in_sample(cicout),
        .out_sample(firout),
        .out_valid(firvalid)
    );

endmodule