module round_robin_arbiter #(
    parameter N = 32 // Scalable to large N 
)(
    input  wire         clk,
    input  wire         rst_n,
  input  wire [N-1:0] req,         // N independent requesters
  output reg  [N-1:0] gnt          // at most one grant per cycle
);

    reg  [N-1:0] last_gnt;      // Pointer to the last granted requester
    wire [N-1:0] mask;          // Mask to block lower-priority indices
    wire [N-1:0] masked_req;    // Requests strictly > last_gnt
    wire [N-1:0] arb_req;       // The actual request vector used for arbitration
    wire [N-1:0] next_gnt;      // The resolved grant for the current cycle
    
    // 1. Mask Generation (Priority Rotation)
    assign mask = ~((last_gnt - 1'b1) | last_gnt);

    // 2. Wrap-Around Logic (Starvation Freedom)
    assign masked_req = req & mask;
    assign arb_req    = (|masked_req) ? masked_req : req;

    // 3. Selection Logic (The "Find First Set" Arithmetic)
    wire [N-1:0] arb_req_2s_comp = -arb_req; // 2's complement
    assign next_gnt = arb_req & arb_req_2s_comp;

    // 4. State Update (Deterministic & Cycle-Accurate)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset State: Point to MSB so the first priority check starts at 0.
            // This ensures fairness from the very first cycle.
            last_gnt <= {1'b1, {(N-1){1'b0}}};
            gnt      <= {N{1'b0}};
        end else begin
            // if no requests, no grant issued
            if (|req) begin
                gnt      <= next_gnt;
                last_gnt <= next_gnt; // Move the pointer to the newly granted requester
            end else begin
                gnt      <= {N{1'b0}};
            end
        end
    end

endmodule
