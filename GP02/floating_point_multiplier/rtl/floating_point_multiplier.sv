module floating_point_multiplier
#(
    // * -------------------------------------------------------------------------
    // * Parameters
    // * -------------------------------------------------------------------------
    parameter                            NB_MANTISSA = 8                         ,
    parameter                            NB_EXPONENT = 4                         ,
    parameter                            NB_DATA     = NB_MANTISSA+NB_EXPONENT+1 ,
    parameter                            N_BIAS      = 2**(NB_EXPONENT-1)-1
)
(
    // * -------------------------------------------------------------------------
    // * Output
    // * -------------------------------------------------------------------------
    output logic [ NB_DATA     - 1 : 0 ] o_data                                  ,
    output logic                         o_overflow                              ,
    output logic                         o_underflow                             ,

    // * -------------------------------------------------------------------------
    // * Inputs
    // * -------------------------------------------------------------------------
    input  logic [ NB_DATA     - 1 : 0 ] i_data_1                                ,
    input  logic [ NB_DATA     - 1 : 0 ] i_data_2                                ,

    // * -------------------------------------------------------------------------
    // * Reset and system clock
    // * -------------------------------------------------------------------------
    input  logic                         i_reset                                 ,
    input  logic                         i_clock
)                                                                                ;
    // * -------------------------------------------------------------------------
    // * Logics
    // * -------------------------------------------------------------------------
    logic        [ NB_MANTISSA - 1 : 0 ] mantissa_data_1                         ;
    logic        [ NB_MANTISSA - 1 : 0 ] mantissa_data_2                         ;
    logic        [ NB_EXPONENT - 1 : 0 ] exponent_data_1                         ;
    logic        [ NB_EXPONENT - 1 : 0 ] exponent_data_2                         ;
    logic                                sign_data_1                             ;
    logic                                sign_data_2                             ;

    logic                                data_is_nan                             ;

    logic        [ 2*NB_MANTISSA+1 : 0 ] mantissa_product                        ;
    logic        [ NB_EXPONENT     : 0 ] exp_operation                           ;
    logic                                sign_result                             ;

    logic        [ NB_MANTISSA - 1 : 0 ] mantissa_normalized                     ;
    logic        [ NB_MANTISSA - 1 : 0 ] mantissa_normalized_d                   ;
    logic        [ NB_EXPONENT     : 0 ] exp_normalized                          ;
    logic        [ NB_EXPONENT - 1 : 0 ] exp_normalized_d                        ;

    logic                                overflow                                ;
    logic                                underflow                               ;
    logic        [ NB_DATA     - 1 : 0 ] data_result                             ;

    // * -------------------------------------------------------------------------
    // * Data split
    // * -------------------------------------------------------------------------
    assign {sign_data_1, exponent_data_1, mantissa_data_1} = i_data_1;
    assign {sign_data_2, exponent_data_2, mantissa_data_2} = i_data_2;

    // * -------------------------------------------------------------------------
    // * Data basic operation
    // * -------------------------------------------------------------------------
    assign data_is_nan      = (&exponent_data_1) || (&exponent_data_2)                                  ;
    assign exp_operation    = exponent_data_1 + exponent_data_2 - N_BIAS[NB_EXPONENT-1:0]               ;
    assign mantissa_product = {|exponent_data_1, mantissa_data_1} * {|exponent_data_2, mantissa_data_2} ;

    always_ff @(posedge i_clock)
    begin : proc_sign_record
        if (i_reset)
            sign_result <= '0;
        else
            sign_result <= sign_data_1 ^ sign_data_2;
    end

    // * -------------------------------------------------------------------------
    // * Data normalization
    // * -------------------------------------------------------------------------
    always_comb
    begin : proc_data_normalize
        if (mantissa_product[2*NB_MANTISSA+1]) begin
            mantissa_normalized = mantissa_product[2*NB_MANTISSA   -: NB_MANTISSA];
            exp_normalized      = exp_operation + {{NB_EXPONENT-1{1'b0}}, 1'b1};
        end else begin
            mantissa_normalized = mantissa_product[2*NB_MANTISSA-1 -: NB_MANTISSA];
            exp_normalized      = exp_operation;
        end
    end

    always_ff @(posedge i_clock)
    begin : proc_normalization_record
        mantissa_normalized_d <= mantissa_normalized;
        exp_normalized_d <= exp_normalized;
    end

    // * -------------------------------------------------------------------------
    // * Overflow/Underflow detection
    // * -------------------------------------------------------------------------
    always_ff @(posedge i_clock)
    begin : proc_overflow_underflow
        overflow  <= (exp_normalized[NB_EXPONENT] && ~exp_normalized[NB_EXPONENT-1]) ||  &exp_normalized[NB_EXPONENT-1:0];
        underflow <= (exp_normalized[NB_EXPONENT] &&  exp_normalized[NB_EXPONENT-1]) || ~|exp_normalized                 ;
    end

    always_comb
    begin : proc_exception_catch
        case ({overflow, underflow, data_is_nan}) inside
            3'b??1  : data_result = {sign_result, {NB_EXPONENT{1'b1}}, {NB_MANTISSA{1'b0}}};
            3'b100  : data_result = {sign_result, {NB_EXPONENT{1'b1}}, {NB_MANTISSA{1'b0}}};
            3'b010  : data_result = {sign_result, {NB_EXPONENT{1'b0}}, {NB_MANTISSA{1'b0}}};
            default : data_result = {sign_result, exp_normalized_d, mantissa_normalized_d};
        endcase
    end

    // * -------------------------------------------------------------------------
    // * Output assignment
    // * -------------------------------------------------------------------------
    assign o_data      = data_result ;
    assign o_overflow  = overflow    ;
    assign o_underflow = underflow   ;

    // * -------------------------------------------------------------------------------------------
    // * Simulation define
    // * -------------------------------------------------------------------------------------------
    `ifdef COCOTB_SIM
        initial begin
            $dumpfile ("dump.vcd");
            $dumpvars ();
            #1;
        end
    `endif
endmodule
