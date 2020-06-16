module sync_dff#(parameter WIDTH=8)
    (
        input logic clk,
        input logic rst_n,

        input logic [WIDTH-1:0] in_data,
        output logic [WIDTH-1:0] out_data
    );

// =======================================================================
// Declarations

    logic [WIDTH-1:0] in_data_q;
    logic [WIDTH-1:0] in_data_qq;

// =======================================================================
// Combinational Logic

    assign out_data = in_data_qq;

// =======================================================================
// Registered Logic

    always_ff @(posedge clk)
        if (!rst_n)
            begin
                in_data_q <= {WIDTH{1'd0}};
                in_data_qq <= {WIDTH{1'd0}};
            end

        else
            begin
                in_data_q <= in_data;
                in_data_qq <= in_data_q;
            end

endmodule
