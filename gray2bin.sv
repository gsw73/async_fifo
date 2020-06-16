module gray2bin#(parameter WIDTH=8)
    (
        input logic [WIDTH-1:0] gray,
        output logic [WIDTH-1:0] bin
    );

    assign bin[WIDTH-1] = gray[WIDTH-1];

    always_comb
        for (int i = WIDTH-2; i >= 0; i--)
            bin[i] = gray[i] ^ bin[i+1];

endmodule
