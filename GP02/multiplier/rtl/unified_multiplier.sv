module unified_multiplier
#(
    // * -------------------------------------------------------------------------------------
    // * Parameters
    // * -------------------------------------------------------------------------------------
    parameter                               NB_DATA_IN_1   = 16                              ,
    parameter                               NBF_DATA_IN_1  = 15                              ,
    parameter                               NB_DATA_IN_2   = 16                              ,
    parameter                               NBF_DATA_IN_2  = 15                              ,
    parameter                               NB_DATA_OUT    = 32                              ,
    parameter                               NBF_DATA_OUT   = 30                              ,
    parameter                               ADD_PIPE_IN    =  0                              ,
    parameter                               ADD_PIPE_OUT   =  1
)
(
    // * -------------------------------------------------------------------------------------
    // * Output
    // * -------------------------------------------------------------------------------------
    output logic [ NB_DATA_OUT    - 1 : 0 ] o_data                                           ,
    output logic                            o_overflow                                       ,

    // * -------------------------------------------------------------------------------------
    // * Inputs
    // * -------------------------------------------------------------------------------------
    input  logic [ NB_DATA_IN_1   - 1 : 0 ] i_data_1                                         ,
    input  logic                            i_data_1_is_signed                               ,

    input  logic [ NB_DATA_IN_2   - 1 : 0 ] i_data_2                                         ,
    input  logic                            i_data_2_is_signed                               ,

    input  logic                            i_data_are_fractional                            ,
    input  logic                            i_round_result                                   ,

    // * -------------------------------------------------------------------------------------
    // * Reset and system clock
    // * -------------------------------------------------------------------------------------
    input  logic                            i_reset                                          ,
    input  logic                            i_clock
) ;
    // * -------------------------------------------------------------------------------------
    // * Localparams
    // * -------------------------------------------------------------------------------------
    localparam                              NBI_DATA_IN_1   = NB_DATA_IN_1 - NBF_DATA_IN_1    ;
    localparam                              NBI_DATA_IN_2   = NB_DATA_IN_2 - NBF_DATA_IN_2    ;
    localparam                              NBI_DATA_OUT    = NB_DATA_OUT  - NBF_DATA_OUT     ;
    localparam                              NB_MULT_RESULT  = NB_DATA_IN_1 + NB_DATA_IN_2 + 2 ;
    localparam                              NBF_MULT_RESULT = NBF_DATA_IN_1 + NBF_DATA_IN_2   ;

    // * -------------------------------------------------------------------------------------
    // * Internal logics
    // * -------------------------------------------------------------------------------------
    logic signed [ NB_DATA_IN_1       : 0 ] expanded_data_1                                  ;
    logic signed [ NB_DATA_IN_2       : 0 ] expanded_data_2                                  ;
    logic signed [ NB_MULT_RESULT - 1 : 0 ] multiplication_result                            ;

    logic signed [ NB_DATA_OUT    - 1 : 0 ] truncator_both_frac_data                         ;
    logic signed [ NB_DATA_OUT    - 1 : 0 ] truncator_data_1_frac_data                       ;
    logic signed [ NB_DATA_OUT    - 1 : 0 ] truncator_data_2_frac_data                       ;
    logic signed [ NB_DATA_OUT    - 1 : 0 ] truncated_data                                   ;

    // * -------------------------------------------------------------------------------------
    // * Pipe in
    // * -------------------------------------------------------------------------------------
    pipe_handler
    #(
        .NB_DATA   ( NB_DATA_IN_1 + NB_DATA_IN_2      ) ,
        .ADD_PIPE  ( ADD_PIPE_IN                      )
    )
    pipe_handler_in
    (
        .o_data    ( { piped_data_1, piped_data_2 }   ) ,
        .i_data    ( { i_data_1    , i_data_2     }   ) ,
        .i_reset   ( i_reset                          ) ,
        .i_clock   ( i_clock                          )
    ) ;

    // * -------------------------------------------------------------------------------------
    // * Multiplication
    // * -------------------------------------------------------------------------------------
    assign expanded_data_1       = (i_data_1_is_signed) ? {piped_data_1[NB_DATA_IN_1-1], piped_data_1} : {1'b0, piped_data_1} ;
    assign expanded_data_2       = (i_data_2_is_signed) ? {piped_data_2[NB_DATA_IN_2-1], piped_data_2} : {1'b0, piped_data_2} ;
    assign multiplication_result = expanded_data_1*expanded_data_2                                                            ;

    // * -------------------------------------------------------------------------------------
    // * Rounding
    // * -------------------------------------------------------------------------------------
    generate
        if (NBF_OUT < NBF_MULT_RESULT)
        begin : gen_rounding
            assign rounded_data = multiplication_result + ( {{NB_MULT_RESULT-1{1'b0}}, 1'b1} << (NBF_MULT_RESULT - NBF_OUT) );
        end else
        begin : gen_not_rounding
            assign rounded_data = multiplication_result;
        end
    endgenerate

    assign data_to_truncators = (i_round_result && i_data_are_fractional) ? rounded_data : multiplication_result;
 no es un or, se hace redondeo y desp se trunca cuando es fractional
    // * -------------------------------------------------------------------------------------
    // * Truncation
    // * -------------------------------------------------------------------------------------
    truncator
    #(
        .NB_IN       ( NB_MULT_RESULT              ) ,
        .NBF_IN      ( NBF_MULT_RESULT             ) ,
        .NB_OUT      ( NB_DATA_OUT                 ) ,
        .NBF_OUT     ( NBF_DATA_OUT                )
    )
    u_truncator_fractional
    (
        .o_data      ( truncator_frac_data         ) ,
        .o_saturated ( truncator_frac_saturated    ) ,
        .i_data      ( data_to_truncators          )
    ) ;

    truncator
    #(
        .NB_IN       ( NB_MULT_RESULT              ) ,
        .NBF_IN      ( 0                           ) ,
        .NB_OUT      ( NB_DATA_OUT                 ) ,
        .NBF_OUT     ( 0                           )
    )
    u_truncator_integer
    (
        .o_data      ( truncator_integer_data      ) ,
        .o_saturated ( truncator_integer_saturated ) ,
        .i_data      ( multiplication_result       )
    ) ;

    assign truncated_data     = (i_data_are_fractional) ? truncator_frac_data    : truncator_integer_data    ;
    assign truncation_satured = (i_data_are_fractional) ? truncator_frac_satured : truncator_integer_satured ;

    // * -------------------------------------------------------------------------------------
    // * Result handling
    // * -------------------------------------------------------------------------------------
    assign pre_mux_data                       = (i_round_result) ? rounded_data : truncated_data                                            ;
    assign data_is_fractional_and_both_signed = (i_data_are_fractional && i_data_1_is_signed && i_data_2_is_signed)                         ;
    assign data_muxed                         = (data_is_fractional_and_both_signed) ? {pre_mux_data[NB_DATA_OUT-2:0], 1'b0} : pre_mux_data ;

    // * -------------------------------------------------------------------------------------
    // * Corner case analysis
    // * -------------------------------------------------------------------------------------




    // * -------------------------------------------------------------------------------------
    // * Pipe out
    // * -------------------------------------------------------------------------------------
    pipe_handler
    #(
        .NB_DATA   ( NB_DATA_OUT + 1                  ) ,
        .ADD_PIPE  ( ADD_PIPE_OUT                     )
    )
    pipe_handler_out
    (
        .o_data    ( { piped_result, piped_overflow } ) ,
        .i_data    ( { data_result , overflow       } ) ,
        .i_reset   ( i_reset                          ) ,
        .i_clock   ( i_clock                          )
    ) ;

    // * -------------------------------------------------------------------------------------
    // * Output assignment
    // * -------------------------------------------------------------------------------------
    assign o_data     = (corner_case && data_is_fractional_and_both_signed) ? piped_result : {1'b0, {NB_DATA_OUT-1{1'b1}}} ;
    assign o_overflow = piped_overflow ;

endmodule
