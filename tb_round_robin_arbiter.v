`timescale 1ns/1ps

module tb_round_robin_arbiter;

    parameter N = 32;

    reg clk;
    reg rst_n;
    reg  [N-1:0] req;
    wire [N-1:0] gnt;

    integer cycle;
    integer i;
    integer ones;

    round_robin_arbiter #(N) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .gnt(gnt)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        req = 0;

        #20 rst_n = 1;

        $display("\n--- Round-Robin Arbiter Test ---\n");

        for (cycle = 1; cycle <= 10; cycle = cycle + 1) begin
            @(negedge clk);
            req = $random;

            @(posedge clk);

            // Count grants
            ones = 0;
            for (i = 0; i < N; i = i + 1)
                ones = ones + gnt[i];

            $display("C%0d | Req=%b | Gnt=%b", cycle, req, gnt);

            if (req != 0 && ones != 1)
                $display("ERROR: Invalid grant count!");
        end

        // Wrap-around test
        $display("\n[Wrap-Around Test]");
        req = 0;
        req[0] = 1;
        dut.last_granted_index = N-1;

        @(posedge clk);
        $display("Req[0]=1 -> Gnt=%b", gnt);

        $display("\nTEST COMPLETE\n");
        $finish;
    end

endmodule
