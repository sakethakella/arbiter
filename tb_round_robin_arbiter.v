`timescale 1ns/1ps

module tb_round_robin_arbiter;

    parameter N = 8;

    reg          clk;
    reg          rst_n;
    reg  [N-1:0] req;
    wire [N-1:0] gnt;

    // Instantiate DUT
    round_robin_arbiter #(.N(N)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .gnt(gnt)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------
    // Helper: Convert One-Hot to Integer for the Status Column
    // -------------------------------------------------------------
    function integer onehot_to_int;
        input [N-1:0] vector;
        integer i;
        begin
            onehot_to_int = -1; 
            for (i = 0; i < N; i = i + 1) begin
                if (vector[i]) onehot_to_int = i;
            end
        end
    endfunction

    // -------------------------------------------------------------
    // Monitor
    // -------------------------------------------------------------
    initial begin
        $display("");
        $display("   Time |    Req     |    Gnt     |  LastGnt   | Status");
        $display("----------------------------------------------------------------------------");
        
        forever begin
            @(posedge clk);
            #1; // Allow signals to settle
            
            if (rst_n) begin
                $write("%7t |  %b  |  %b  |  %b  |", $time, req, gnt, dut.last_gnt);

                // Print Status explanation
                if (gnt == 0) begin
                     $write(" Idle / No Grant");
                end else begin
                     $write(" Grant -> Agent %0d", onehot_to_int(gnt));
                end
                
                $write("\n");
            end
        end
    end

    // -------------------------------------------------------------
    // Test Sequence
    // -------------------------------------------------------------
    initial begin
        rst_n = 0;
        req   = 0;
        #15; 
        
        $display("--- RESET RELEASED ---");
        rst_n = 1;

        // --- TEST 1: Rotation ---
        $display("\n[TEST 1] Req Agents 0 & 1");
        @(negedge clk); req = 8'b00000011; 
        @(negedge clk); 
        @(negedge clk); 

        // --- TEST 2: Skipping ---
        $display("\n[TEST 2] Req Agents 3 & 7");
        req = 8'b10001000; 
        @(negedge clk);
        @(negedge clk);

        // --- TEST 3: Wrap Around ---
        $display("\n[TEST 3] Req Agents 1 & 2 (Wrap from 7->0->1)");
        req = 8'b00000110; 
        @(negedge clk); 

        // --- TEST 4: Full Load ---
        $display("\n[TEST 4] All Agents Requesting");
        req = 8'b11111111; 
        repeat(8) @(negedge clk);

        // --- TEST 5: Idle State ---
        $display("\n[TEST 5] Idle (No Req)");
        req = 0;
        @(negedge clk);
        @(negedge clk);
        
        $display("\n[TEST 5b] Resume Full Load (Check Pointer Frozen)");
        req = 8'b11111111;
        @(negedge clk);
        @(negedge clk);

        $display("----------------------------------------------------------------------------");
        $finish;
    end

endmodule
