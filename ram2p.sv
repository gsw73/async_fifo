module ram2p
    #(
        parameter DW=18,
        parameter AW=7
    )
    (
        input logic wclk,
        input logic wen,
        input logic [AW-1:0] wr_addr,
        input logic [DW-1:0] wr_data,

        input logic rclk,
        input logic [AW-1:0] rd_addr,
        output logic [DW-1:0] rd_data
    );

// =======================================================================
// Declarations

    localparam DEPTH=2**AW;
    logic [DW-1:0] mem [DEPTH];

// =======================================================================
// Registered Logic

    always_ff @(posedge wclk)
        if (wen)
            mem[wr_addr] <= wr_data;

    always_ff @(posedge rclk)
        rd_data <= mem[rd_addr];

endmodule
