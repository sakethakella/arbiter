module round_robin_arbiter #(parameter N = 8)(input  wire clk,input  wire rst_n,input  wire [N-1:0] req,output reg  [N-1:0] gnt);

    reg  [N-1:0] last_gnt;
    wire [N-1:0] mask;
    wire [N-1:0] masked_req;
    wire [N-1:0] next_gnt_masked;
    wire [N-1:0] next_gnt_raw;
    wire [N-1:0] next_gnt;

    assign mask = ~((last_gnt - {{N-1{1'b0}}, 1'b1}) | last_gnt);
    assign masked_req = req & mask;
    assign next_gnt_masked = masked_req & (~masked_req + 1'b1);
    assign next_gnt_raw    = req & (~req + 1'b1);
    assign next_gnt = (|masked_req) ? next_gnt_masked : next_gnt_raw;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_gnt <= {1'b1, {(N-1){1'b0}}};
            gnt      <= {N{1'b0}};
        end else begin
            if (|req) begin
                gnt <= next_gnt;
                last_gnt <= next_gnt; 
            end else begin
                gnt <= {N{1'b0}};
            end
        end
    end

endmodule
