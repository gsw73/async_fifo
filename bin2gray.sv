module bin2gray #( parameter WIDTH = 8 )
(
    input logic [ WIDTH - 1:0 ] bin,
    output logic [ WIDTH - 1:0 ] gray
);

assign gray = bin[ WIDTH - 1:0 ] ^ { 1'b0, bin[ WIDTH - 1:1 ] };

endmodule
