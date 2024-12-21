module truncator
#(
    // * -------------------------------------------------------------------------------------
    // * Parameters
    // * -------------------------------------------------------------------------------------
    parameter                        NB_IN         = 34                   ,
    parameter                        NBF_IN        = 30                   ,
    parameter                        NB_OUT        = 32                   ,
    parameter                        NBF_OUT       = 30
)
(
    // * -------------------------------------------------------------------------------------
    // * Output
    // * -------------------------------------------------------------------------------------
    output logic [ NB_OUT  - 1 : 0 ] o_data                               ,
    output logic                     o_saturated                          ,

    // * -------------------------------------------------------------------------------------
    // * Inputs
    // * -------------------------------------------------------------------------------------
    input  logic [ NB_IN   - 1 : 0 ] i_data
) ;
    // * -------------------------------------------------------------------------------------
    // * Localparams
    // * -------------------------------------------------------------------------------------
    localparam                       NBI_IN        = NB_IN  - NBF_IN      ;
    localparam                       NBI_OUT       = NB_OUT - NBF_OUT     ;
    localparam                       NB_SIGN_CHECK = NBI_IN - NBI_OUT + 1 ;

    // * -------------------------------------------------------------------------------------
    // * Internal logics
    // * -------------------------------------------------------------------------------------
    logic        [ NBI_OUT - 1 : 0 ] integer_data                         ;
    logic        [ NB_OUT  - 1 : 0 ] truncated_data                       ;
    logic                            saturated_data                       ;
    logic                            saturation_when_positive             ;
    logic                            saturation_when_negative             ;
    logic                            saturated_result                     ;

    // * -------------------------------------------------------------------------------------
    // * Internal assigns
    // * -------------------------------------------------------------------------------------
    generate
        if (NBF_OUT > 0)
        begin : gen_out_w_frac
            logic  [ NBF_OUT - 1 : 0 ] fractionary_data;
            assign truncated_data = {integer_data, fractionary_data};
        end else
        begin : gen_out_wo_frac
            assign truncated_data = integer_data                    ;
        end

        if (NBF_IN < NBF_OUT)
        begin : gen_frac_with_zero_padding
            assign fractionary_data = {i_data[NBF_IN-1:0], {NBF_OUT-NBF_IN{1'b0}}} ;
        end else if (NBF_OUT > 0)
        begin : gen_frac_truncated
            assign fractionary_data = i_data[NBF_IN - 1 -: NBF_OUT]                ;
        end

        if (NBI_IN < NBI_OUT)
        begin : gen_int_with_padding
            assign integer_data = {{NBI_OUT-NBI_IN{i_data[NB_IN-1]}}, i_data[NB_IN -: NBI_IN]} ;
        end else
        begin : gen_int_without_padding
            assign integer_data = i_data[NB_IN - (NBI_IN - NBI_OUT) - 1 -: NBI_OUT]            ;
        end
    endgenerate

    assign saturated_data           = {i_data[NB_IN-1], {NB_OUT-1{~i_data[NB_IN-1]}}}       ;

    assign saturation_when_positive =  |i_data[NB_IN - 1 -: NB_SIGN_CHECK]                  ;
    assign saturation_when_negative = ~&i_data[NB_IN - 1 -: NB_SIGN_CHECK]                  ;
    assign saturated_result         =  saturation_when_positive || saturation_when_negative ;

    // * -------------------------------------------------------------------------------------
    // * Internal logics
    // * -------------------------------------------------------------------------------------
    assign o_data      = (saturated_result) ? saturated_data : truncated_data ;
    assign o_saturated =  saturated_result                                    ;
endmodule
