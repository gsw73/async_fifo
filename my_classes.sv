package asfifo_pkg;
    timeunit 1ns;
    timeprecision 100ps;

    typedef enum {FAIL, PASS} pf_e;

// =======================================================================

    class DataPkt#(parameter DW=7);
        rand bit [DW-1:0] fifo_data;
    endclass : DataPkt

// =======================================================================

    class pshAgnt#(parameter DW=3);
        mailbox mbxPsh;
        mailbox mbxSB;
        DataPkt#(DW) d;

        function new(mailbox mbxPsh, mailbox mbxSB);
            this.mbxPsh = mbxPsh;
            this.mbxSB = mbxSB;
        endfunction

        task run();
            repeat (500)
                begin
                    d = new ();
                    d.randomize();
                    mbxPsh.put(d);
                    mbxSB.put(d);
                end
        endtask
    endclass

// =======================================================================

    class pshXactor#(parameter DW=4);
        mailbox mbxPsh;

        virtual afifo_if#(DW).TB_WR sigw_h;

        function new(mailbox mbxPsh, virtual afifo_if#(DW).TB_WR s);
            this.mbxPsh = mbxPsh;
            sigw_h = s;
        endfunction

        task run();
            DataPkt#(DW) data;
            int pshCnt;

            forever
                begin
                    mbxPsh.get(data);

                    repeat ($urandom & 3) @(sigw_h.cb_wr);
                    wait (~sigw_h.cb_wr.alFull);
                    sigw_h.cb_wr.push <= 1;
                    sigw_h.cb_wr.data_in <= data.fifo_data;

                    @(sigw_h.cb_wr)
                        sigw_h.cb_wr.push <= 0;
                    sigw_h.cb_wr.data_in <= 0;
                    pshCnt++;
                end
        endtask ;
    endclass

// =======================================================================

    class popXactor#(parameter DW=5);
        mailbox mbxPop;

        virtual afifo_if#(DW).TB_RD sigr_h;

        function new(mailbox m, virtual afifo_if#(DW).TB_RD s);
            this.mbxPop = m;
            sigr_h = s;
        endfunction

        task run();

            DataPkt#(DW) data;

            fork
                forever
                    begin
                        repeat ($urandom & 3) @(sigr_h.cb_rd);
                        sigr_h.cb_rd.pop <= 0;
                        repeat ($urandom & 'h3) @(sigr_h.cb_rd);
                        sigr_h.cb_rd.pop <= 1;
                    end
            join_none

            forever
                begin
                    wait (sigr_h.cb_rd.pop && sigr_h.cb_rd.vld);
                    data = new;
                    data.fifo_data = sigr_h.cb_rd.data_out;
                    mbxPop.put(data);
                    @(sigr_h.cb_rd);
                end
        endtask
    endclass

// =======================================================================

    class popAgnt#(parameter DW=13);
        mailbox mbxPop;
        mailbox mbxSB;
        virtual afifo_if#(DW).TB_RD sigr_h;

        function new(mailbox m_pop, mailbox m_sb, virtual afifo_if#(DW).TB_RD sr);
            mbxPop = m_pop;
            mbxSB = m_sb;
            sigr_h = sr;
        endfunction

        task run();
            DataPkt#(DW) d_out;
            DataPkt#(DW) d_sb;
            int cnt_total;
            pf_e chk;

            forever
                begin
                    mbxPop.get(d_out);
                    mbxSB.get(d_sb);

                    chk = pf_e'(d_out.fifo_data == d_sb.fifo_data);
                    cnt_total++;

                    $display("@%t d_out = %h d_sb = %h chk = %0s cnt = %0d", $realtime, d_out.fifo_data, d_sb.fifo_data, chk.name, cnt_total);

                    if (chk == FAIL)
                        begin
                            $display("@%t ERROR DETECTED; exiting", $realtime);
                            repeat (10) @(sigr_h.cb_rd);
                            $finish;
                        end
                end
        endtask
    endclass

// =======================================================================

    class MyEnv#(parameter DW=2);

        pshXactor#(DW) pshX;
        popXactor#(DW) popX;
        mailbox mbxPsh;
        mailbox mbxPop;
        mailbox mbxSB;
        pshAgnt#(DW) pshA;
        popAgnt#(DW) popA;

        function new(virtual afifo_if#(DW).TB_WR sw, virtual afifo_if#(DW).TB_RD sr);
            mbxPsh = new ();
            mbxPop = new ();
            mbxSB = new ();

            pshX = new (mbxPsh, sw);
            pshA = new (mbxPsh, mbxSB);
            popX = new (mbxPop, sr);
            popA = new (mbxPop, mbxSB, sr);
        endfunction

// =======================================================================

        task run();
            fork
                pshX.run();
                pshA.run();
                popX.run();
                popA.run();
            join_none
        endtask

    endclass : MyEnv

endpackage : asfifo_pkg
