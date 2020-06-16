interface afifo_if
    #(
        parameter DW=64
    )
    (
        input bit rclk, input bit wclk
    );
    timeunit 1ns;
    timeprecision 100ps;

    logic rst_wclk_n = 0;
    logic rst_rclk_n = 0;

    logic push = 0;
    logic [DW-1:0] data_in = 'd0;
    logic full;
    logic alFull;

    logic pop = 0;
    logic vld;
    logic [DW-1:0] data_out;
    logic empty;

    clocking cb_wr @(posedge wclk);
        output #1 rst_wclk_n;
        output #1 push;
        output #1 data_in;

        input full;
        input alFull;
    endclocking : cb_wr

    clocking cb_rd @(posedge rclk);
        output #1 rst_rclk_n;
        inout pop;

        input vld;
        input data_out;
        input empty;
    endclocking : cb_rd

    modport TB_WR(clocking cb_wr);
    modport TB_RD(clocking cb_rd);
endinterface : afifo_if

// ========================================================================

module tb;
    timeunit 1ns;
    timeprecision 100ps;

    parameter TBDW=16;
    parameter TBAW=5;
    parameter HEADROOM=5;

    logic wclk;
    logic rclk;

    afifo_if#(.DW(TBDW)) u_afifo_if(.rclk(rclk), .wclk(wclk));

// instantiate the test  
    main_prg#(.DW(TBDW)) u_main_prg(.sigw_h(u_afifo_if.TB_WR), .sigr_h(u_afifo_if.TB_RD));

    initial
        begin
            $dumpfile("dump.vcd");
            $dumpvars(0);
        end

    initial
        begin
            $timeformat(-9, 1, "ns", 8);

            fork
                begin
                    rclk = 1'b0;
                    forever #5 rclk = ~rclk;
                end

                begin
                    wclk = 1'b0;
                    forever #6 wclk = ~wclk;
                end
            join_none
        end

    afifo
    #(
        .DW(TBDW),
        .AW(TBAW),
        .HEADROOM(HEADROOM)
    )
    u_afifo
    (
        .wclk(wclk),
        .rst_wclk_n(u_afifo_if.rst_wclk_n),
        .push(u_afifo_if.push),
        .data_in(u_afifo_if.data_in),
        .full(u_afifo_if.full),
        .alFull(u_afifo_if.alFull),

        .rclk(rclk),
        .rst_rclk_n(u_afifo_if.rst_rclk_n),
        .pop(u_afifo_if.pop),
        .vld(u_afifo_if.vld),
        .data_out(u_afifo_if.data_out),
        .empty(u_afifo_if.empty)
    );

endmodule : tb

// ========================================================================

program automatic main_prg
    #(parameter DW=12)
    (afifo_if.TB_WR sigw_h, afifo_if.TB_RD sigr_h);

    MyEnv#(.DW(DW)) env;

    initial
        begin
            env = new (sigw_h, sigr_h);

            fork
                begin
                    sigw_h.cb_wr.rst_wclk_n <= 1'b0;
                    #50 sigw_h.cb_wr.rst_wclk_n <= 1'b1;
                end

                begin
                    sigr_h.cb_rd.rst_rclk_n <= 1'b0;
                    #50 sigr_h.cb_rd.rst_rclk_n <= 1'b1;
                end
            join

            repeat (20) @(sigw_h.cb_wr);

            env.run();

            repeat (2000) @(sigw_h.cb_wr);
        end

endprogram  
