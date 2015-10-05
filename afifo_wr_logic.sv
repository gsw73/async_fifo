module afifo_wr_logic
#(
    parameter DW = 64,
    parameter AW = 15,
    parameter PW = AW + 1,
    parameter HEADROOM = 4
)
(
    input logic wclk,
    input logic rst_n,

    input logic push,
    input logic [ DW - 1:0 ] data_in,
    input logic [ PW - 1:0 ] rd_gray_ptr,

  	output logic wen,
    output logic [ DW - 1:0 ] wr_data,
    output logic [ AW - 1:0 ] wr_addr,
    output logic [ PW - 1:0 ] wr_gray_ptr,
    output logic full,
    output logic alFull
);

// =======================================================================
// Declarations
  
localparam MAX_DEPTH = 2**AW;  

logic [ PW - 1:0 ] wr_ptr;
logic [ PW - 1:0 ] next_wr_ptr;
logic [ PW - 1:0 ] next_wr_gray_ptr;
logic [ PW - 1:0 ] rd_ptr;
logic [ PW - 1:0 ] next_rd_ptr;
logic [ PW - 1:0 ] current_depth;

// =======================================================================
// Combinational Logic

assign next_wr_ptr = wen ? wr_ptr + 'd1 : wr_ptr;
assign wr_addr = wr_ptr[ AW - 1:0 ];

always_comb
  alFull = ( MAX_DEPTH - current_depth ) < HEADROOM;

// =======================================================================
// Registered Logic

// Register:  wen
// Register:  wr_data
// Allow data to be written into the memory only when the memory is not full.
// Outside logic should never push into full FIFO, but this just protects
// data that is already there.

always @( posedge wclk )

    if ( !rst_n )
    begin
        wen <= 1'b0;
        wr_data <= {DW{1'b0}};
    end

    else
    begin
        wen <= push && !full;
        wr_data <= data_in;
    end

// Register:  wr_ptr
// One bit larger than the addr, used for both addressing memory and for
// gray encoding.  The "d" input is used for gray coding so incrmenet
// is combinational.

always @( posedge wclk )

    if ( !rst_n )
        wr_ptr <= {PW{1'b0}};

    else
        wr_ptr <= next_wr_ptr;

// Register:  wr_gray_ptr
// Gray encoded version of wr_ptr that can be synced to read clock domain.

always @( posedge wclk )

    if ( !rst_n )
        wr_gray_ptr <= {PW{1'b0}};

    else
        wr_gray_ptr <= next_wr_gray_ptr;

// Register:  rd_ptr
// After converting gray-encoded read pointer to bin, flop it before comparing
// with write pointer

always @( posedge wclk )

    if ( !rst_n )
        rd_ptr <= {PW{1'b0}};

    else
        rd_ptr <= next_rd_ptr;

// Register:  full
// full when the write pointer wraps and catches up with the read pointer
  
always @( posedge wclk )
    
    if ( !rst_n )
        full <= 1'b0;
  
    else
        full <= next_wr_ptr[ PW - 1 ] == ~rd_ptr[ PW - 1 ] &&
                next_wr_ptr[ PW - 2:0 ] == rd_ptr[ PW - 2:0 ];
  
// Register:  alFull
// "Almost Full"... note that the flop eases timing here, but does add
// the extra clock delay.  One should be conservative in setting the
// HEADROOM parameter.
  
always @( posedge wclk )  
  
  if ( !rst_n )
    current_depth <= {PW{1'b0}};
  
  else if ( wr_ptr[ PW - 1 ] == rd_ptr[ PW - 1 ] )
    current_depth <= wr_ptr[ AW - 1:0 ] - rd_ptr[ AW - 1:0 ];
  
  else
    current_depth <= MAX_DEPTH - rd_ptr[ AW - 1:0 ] + wr_ptr[ AW - 1:0 ]; 
  
// =======================================================================
// Module Instantiations

bin2gray #( .WIDTH( PW ) ) u_bin2gray_wr( .bin( next_wr_ptr ), .gray( next_wr_gray_ptr ) );
gray2bin #( .WIDTH( PW ) ) u_gray2bin_rd( .gray( rd_gray_ptr ), .bin( next_rd_ptr ) );

endmodule
