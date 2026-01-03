module round_robin_arbiter #(
    parameter N = 32
)(
    input              clk,
    input              rst_n,
    input  [N-1:0]     req,
    output reg [N-1:0] gnt
);

    integer i;
    integer last_granted_index;
    integer winner;
    reg found;

    always @(*) begin
        gnt   = {N{1'b0}};
        found = 1'b0;
        winner = last_granted_index;

        // Scan forward
        for (i = last_granted_index + 1; i < N; i = i + 1) begin
            if (!found && req[i]) begin
                winner = i;
                found  = 1'b1;
            end
        end

        // Wrap-around scan
        if (!found) begin
            for (i = 0; i <= last_granted_index; i = i + 1) begin
                if (!found && req[i]) begin
                    winner = i;
                    found  = 1'b1;
                end
            end
        end

        if (found)
            gnt[winner] = 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            last_granted_index <= N-1;
        else if (found)
            last_granted_index <= winner;
    end

endmodule
