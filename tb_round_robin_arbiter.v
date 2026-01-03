`timescale 1ns/1ps

module tb_round_robin_arbiter;


    parameter N = 5;
    
    reg          clk;
    reg          rst_n;
    reg  [N-1:0] req;
    wire [N-1:0] gnt;


    round_robin_arbiter #(.N(N)) u_dut (
        .clk   (clk),
        .rst_n (rst_n),
        .req   (req),
        .gnt   (gnt)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    always @(negedge clk) begin
        if (rst_n) begin
            $display("Time: %0t | Req: %b | Gnt: %b | Mask: %b | LastGnt_Ptr: %b", 
                     $time, req, gnt, u_dut.mask, u_dut.last_gnt);
        end
    end

  
  initial begin
        $dumpfile("waves.vcd");              
        $dumpvars(0, tb_round_robin_arbiter);
    end

    initial begin
        // 1. Initialization
        $display("\n=== START SIMULATION ===");
        rst_n = 0;
        req   = 0;
        @(negedge clk);
        rst_n = 1;
        $display("Reset Released. Checking Default State...");

        // 2. Single Request Test (Basic Functionality)
        // Request bit 0. Expect Grant 0.
        @(negedge clk) req = 4'b0001;
        @(negedge clk); // Wait for grant cycle

        // 3. Multi-Request Test (Priority Logic)
        $display("\n--- Test: Priority Rotation (0 was last, now Req 1 & 2) ---");
        req = 4'b0110; 
        @(negedge clk); // Expect Grant 1 (4'b0010)
        
        
        $display("--- Test: Holding Req (Expect Grant to move to 2) ---");
        @(negedge clk);

        // 4. Wrap-Around Test
        $display("\n--- Test: Wrap Around (Last was 2, Req 0 & 1) ---");
        req = 4'b0011;
        @(negedge clk); // Expect Grant 0 (4'b0001)

        // 5. Saturation / Starvation Freedom Test
        $display("\n--- Test: Starvation Freedom (All Req High) ---");
        req = 4'b1111;
        repeat (6) @(negedge clk);

        // 6. Idle Test
        $display("\n--- Test: Idle (No Req) ---");
        req = 4'b0000;
        repeat (2) @(negedge clk);
        
        // 7. Re-activation
        // Request 3. Should grant immediately.
        req = 4'b1000;
        @(negedge clk);

        $display("\n=== TEST COMPLETE ===");
        $finish;
    end
endmodule

endmodule


