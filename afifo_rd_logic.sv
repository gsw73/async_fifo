module afifo_rd_logic
    #(
        parameter DW=38,
        parameter AW=27,
        parameter PW=AW+1
    )
    (
        input logic rclk,
        input logic rst_n,

        input logic pop,
        input logic [PW-1:0] wr_gray_ptr,

        output logic [AW-1:0] rd_addr,
        output logic [PW-1:0] rd_gray_ptr,
        output logic empty,
        output logic vld
    );

// =======================================================================
// Declarations

    logic [PW-1:0] rd_ptr_q_plus_one;
    logic [PW-1:0] next_rd_ptr_q;
    logic [PW-1:0] rd_ptr_q;
    logic [PW-1:0] next_rd_gray_ptr;
    logic [PW-1:0] wr_ptr;
    logic [PW-1:0] next_wr_ptr;

// =======================================================================
// Combinational Logic

    assign rd_ptr_q_plus_one = rd_ptr_q+'d1;
    assign next_rd_ptr_q = (pop && !empty) ? rd_ptr_q_plus_one:rd_ptr_q;

// note the ptr carries one extra bit than the address to aid in calculating
// emtpy and full conditions; the "next" signal goes to the memory and the
// g2b logic too allow immediate increment on a read enable (popp & !empty)
    assign rd_addr = next_rd_ptr_q[AW-1:0];

// Empty condition occurs when read pointer catches up to synchronized
// write pointer.
    assign empty = wr_ptr == rd_ptr_q;

// for user simplicity
    assign vld = ~empty;

// =======================================================================
// Registered Logic

// Register:  rd_ptr_q
//
// Logic required for determining read address.  This flop increments on
// each read enable.

    always_ff @(posedge rclk)
        if (!rst_n)
            rd_ptr_q <= {PW{1'b0}};

        else
            rd_ptr_q <= next_rd_ptr_q;

// Register:  rd_gray_ptr
//
// Flop the combinationally generated gray pointer before synchronizing
// it to the write clock domain.

    always_ff @(posedge rclk)
        if (!rst_n)
            rd_gray_ptr <= {PW{1'b0}};

        else
            rd_gray_ptr <= next_rd_gray_ptr;

// Register:  wr_ptr
//
// After converting gray write pointer to binary, flop it before using
// it in empty calc logic.

    always_ff @(posedge rclk)
        if (!rst_n)
            wr_ptr <= {PW{1'b0}};

        else
            wr_ptr <= next_wr_ptr;

// =======================================================================
// Module Instantiations

    bin2gray#(.WIDTH(PW)) u_bin2gray_rd(.bin(next_rd_ptr_q), .gray(next_rd_gray_ptr));
    gray2bin#(.WIDTH(PW)) u_gray2bin_wr(.gray(wr_gray_ptr), .bin(next_wr_ptr));

endmodule
