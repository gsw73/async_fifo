module afifo
    #(
        parameter DW=24,
        parameter AW=14,
        parameter PW=AW+1,
        parameter HEADROOM=6
    )
    (
        input logic wclk,
        input logic rst_wclk_n,
        input logic push,
        input logic [DW-1:0] data_in,
        output logic full,
        output logic alFull,

        input logic rclk,
        input logic rst_rclk_n,
        input logic pop,
        output logic vld,
        output logic [DW-1:0] data_out,
        output logic empty
    );

// =======================================================================
// Declarations

    logic [AW-1:0] wr_addr;
    logic [DW-1:0] wr_data;
    logic wen;

    logic [AW-1:0] rd_addr;
    logic [DW-1:0] rd_data;

    logic [PW-1:0] wr_gray_ptr_wclk;
    logic [PW-1:0] wr_gray_ptr_rclk;
    logic [PW-1:0] rd_gray_ptr_wclk;
    logic [PW-1:0] rd_gray_ptr_rclk;

// =======================================================================
// Combination & Registered Logic

    assign data_out = rd_data;

// =======================================================================
// Module Instantiations

// Module:  sync_dff
//
// The gray-encoded write pointer needs to be double floped and passed
// to the read side.  The gray-encoded read pointer needs to be double
// flopped and passed to the write side.

    sync_dff#(.WIDTH(PW)) u_sync_dff_w2r
                          (
                              .clk(rclk),
                              .rst_n(rst_rclk_n),

                              .in_data(wr_gray_ptr_wclk),
                              .out_data(wr_gray_ptr_rclk)
                          );

    sync_dff#(.WIDTH(PW)) u_sync_dff_r2w
                          (
                              .clk(wclk),
                              .rst_n(rst_wclk_n),

                              .in_data(rd_gray_ptr_rclk),
                              .out_data(rd_gray_ptr_wclk)
                          );

// Module:  afifo_rd_logic
//
// Logic for generating read address and gray-encoded read pointer.

    afifo_rd_logic#(.DW(DW), .AW(AW)) u_afifo_rd_logic
                                      (
                                          .rclk(rclk),
                                          .rst_n(rst_rclk_n),

                                          .pop(pop),
                                          .wr_gray_ptr(wr_gray_ptr_rclk),

                                          .rd_addr(rd_addr),
                                          .rd_gray_ptr(rd_gray_ptr_rclk),
                                          .empty(empty),
                                          .vld(vld)
                                      );

// Module:  afifo_wr_logic
//
// Logic for generating write address and gray-encoded write pointer.

    afifo_wr_logic#(.DW(DW), .AW(AW), .HEADROOM(HEADROOM)) u_afifo_wr_logic
                                                           (
                                                               .wclk(wclk),
                                                               .rst_n(rst_wclk_n),

                                                               .push(push),
                                                               .data_in(data_in),
                                                               .wr_data(wr_data),
                                                               .rd_gray_ptr(rd_gray_ptr_wclk),

                                                               .wen(wen),
                                                               .wr_addr(wr_addr),
                                                               .wr_gray_ptr(wr_gray_ptr_wclk),
                                                               .full(full),
                                                               .alFull(alFull)
                                                           );

// Module:  ram2p
//
// Two-port RAM with one-clock read latency.

    ram2p#(.DW(DW), .AW(AW)) u_ram2p(.*);

endmodule
