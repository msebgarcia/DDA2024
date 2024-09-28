module counter
#(
    // * --------------------------------------------------------------------
    // * Parameters
    // * --------------------------------------------------------------------
    parameter                           NB_COUNTER   = 32                   ,
    parameter                           NB_SW        =  3                   ,
    parameter                           ADD_PIPE_OUT =  0
)
(
    // * --------------------------------------------------------------------
    // * Outputs
    // * --------------------------------------------------------------------
    output logic                        o_count_reached                     ,

    // * --------------------------------------------------------------------
    // * Inputs
    // * --------------------------------------------------------------------
    input  logic [ NB_SW      - 1 : 0 ] i_sw                                ,

    // * --------------------------------------------------------------------
    // * Clock and reset
    // * --------------------------------------------------------------------
    input  logic                        i_reset                             ,
    input  logic                        i_clock
) ;
    // * --------------------------------------------------------------------
    // * Localparams
    // * --------------------------------------------------------------------
    localparam                          R0           = 2**(NB_COUNTER-10)-1 ;
    localparam                          R1           = 2**(NB_COUNTER-11)-1 ;
    localparam                          R2           = 2**(NB_COUNTER-12)-1 ;
    localparam                          R3           = 2**(NB_COUNTER-13)-1 ;

    // * --------------------------------------------------------------------
    // * Internal logics
    // * --------------------------------------------------------------------
    logic        [ NB_COUNTER - 1 : 0 ] count                               ;
    logic        [ NB_COUNTER - 1 : 0 ] next_count                          ;
    logic        [ NB_COUNTER - 1 : 0 ] limit_count                         ;
    logic                               limit_reached                       ;
    logic                               count_enable                        ;
    logic                               piped_limit_reached                 ;

    // * --------------------------------------------------------------------
    // * Max count decode
    // * --------------------------------------------------------------------
    always_comb
    begin : proc_limit_count_decode
        unique case (i_sw[2:1]) inside
            2'b00: limit_count = R0[NB_COUNTER-1:0];
            2'b01: limit_count = R1[NB_COUNTER-1:0];
            2'b10: limit_count = R2[NB_COUNTER-1:0];
            2'b11: limit_count = R3[NB_COUNTER-1:0];
        endcase
    end

    // * --------------------------------------------------------------------
    // * Count process
    // * --------------------------------------------------------------------
    assign next_count    = count + {{NB_COUNTER-1{1'b0}}, 1'b1}   ;
    assign count_enable  = i_sw[0]                                ;
    assign limit_reached = (count >= limit_count) && count_enable ;

    always_ff @(posedge i_clock)
    begin : proc_count
        if (i_reset || limit_reached)
            count <= '0;
        else if (count_enable)
            count <= next_count;
    end

    // * --------------------------------------------------------------------
    // * Piping output
    // * --------------------------------------------------------------------
    generate
        if (ADD_PIPE_OUT)
        begin : gen_out_piped
            always_ff @(posedge i_clock)
            begin : proc_pipe_out
                piped_limit_reached <= limit_reached;
            end
        end else
        begin : gen_out_unpiped
            assign piped_limit_reached = limit_reached;
        end
    endgenerate

    // * --------------------------------------------------------------------
    // * Output assignment
    // * --------------------------------------------------------------------
    assign o_count_reached = piped_limit_reached;
endmodule
