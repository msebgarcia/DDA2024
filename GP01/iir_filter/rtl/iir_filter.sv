module iir_filter#(
    // * -------------------------------------------------------------------------------------------
    // * Parameters
    // * -------------------------------------------------------------------------------------------
    parameter                                                                NB_DATA_IN       =  8 ,
    parameter                                                                NB_DATA_OUT      = 12 ,
    parameter                                                                N_INPUT_SAMPLES  =  3 ,
    parameter                                                                N_OUTPUT_SAMPLES =  2 ,
    parameter                                                                ADD_OUTPUT_PIPE  =  0
)
(
    // * -------------------------------------------------------------------------------------------
    // * Outputs
    // * -------------------------------------------------------------------------------------------
    output logic signed [ NB_DATA_OUT                              - 1 : 0 ] o_data                ,

    // * -------------------------------------------------------------------------------------------
    // * Inputs
    // * -------------------------------------------------------------------------------------------
    input  logic signed [ NB_DATA_IN                               - 1 : 0 ] i_data                ,

    // * -------------------------------------------------------------------------------------------
    // * Clock and reset
    // * -------------------------------------------------------------------------------------------
    input  logic                                                             i_reset               ,
    input  logic                                                             i_clock
) ;
    // * -------------------------------------------------------------------------------------------
    // * Internal logics
    // * -------------------------------------------------------------------------------------------
    logic  signed       [ N_INPUT_SAMPLES  - 1 : 0 ] [ NB_DATA_IN  - 1 : 0 ] x_samples             ;
    logic  signed       [ N_INPUT_SAMPLES  - 1 : 0 ] [ NB_DATA_OUT - 1 : 0 ] partial_sums_x        ;
    logic  signed       [ N_OUTPUT_SAMPLES - 1 : 0 ] [ NB_DATA_OUT - 1 : 0 ] y_samples             ;
    logic  signed       [ N_OUTPUT_SAMPLES - 1 : 0 ] [ NB_DATA_OUT - 1 : 0 ] partial_sums_y        ;
    logic  signed       [ N_OUTPUT_SAMPLES - 1 : 0 ] [ NB_DATA_OUT - 1 : 0 ] y_samples_divided     ;
    logic  signed       [ NB_DATA_OUT                              - 1 : 0 ] ed_result             ;
    logic  signed       [ NB_DATA_OUT                              - 1 : 0 ] pipe_result           ;

    // * -------------------------------------------------------------------------------------------
    // * Output divisions
    // * -------------------------------------------------------------------------------------------
    generate
        for (genvar g_sample = 0 ; g_sample < N_OUTPUT_SAMPLES ; g_sample++)
        begin : gen_assigns_divisions
            assign y_samples_divided[g_sample] = y_samples[g_sample] >>> 1;
        end
    endgenerate

    // * -------------------------------------------------------------------------------------------
    // * Result calculation
    // * -------------------------------------------------------------------------------------------
    assign partial_sums_x[0] = i_data - x_samples[0];
    generate
        for (genvar g_sum_xi = 1 ; g_sum_xi < N_INPUT_SAMPLES ; g_sum_xi++)
        begin : gen_xi_partial_sums
            assign partial_sums_x[g_sum_xi] = partial_sums_x[g_sum_xi-1] + x_samples[g_sum_xi];
        end
    endgenerate

    assign partial_sums_y[0] = y_samples_divided[0];
    generate
        for (genvar g_sum_yi = 1 ; g_sum_yi < N_OUTPUT_SAMPLES ; g_sum_yi++)
        begin : gen_yi_partial_sums
            assign partial_sums_y[g_sum_yi] = partial_sums_y[g_sum_yi-1] + y_samples_divided[g_sum_yi];
        end
    endgenerate

    assign ed_result = partial_sums_x[N_INPUT_SAMPLES-1] + partial_sums_y[N_OUTPUT_SAMPLES-1];

    // * -------------------------------------------------------------------------------------------
    // * Sampling
    // * -------------------------------------------------------------------------------------------
    always_ff @(posedge i_clock)
    begin : proc_filtering
        if (i_reset) begin
            x_samples <= '0;
            y_samples <= '0;
        end else begin
            x_samples <= {x_samples        [N_INPUT_SAMPLES -2:0], i_data   };
            y_samples <= {y_samples_divided[N_OUTPUT_SAMPLES-2:0], ed_result};
        end
    end

    // * -------------------------------------------------------------------------------------------
    // * Optional pipe out
    // * -------------------------------------------------------------------------------------------
    if (ADD_OUTPUT_PIPE)
    begin : gen_pipe_out
        always_ff @(i_clock)
        begin : proc_pipe_out
            pipe_result <= ed_result;
        end
    end else
    begin : gen_direct_out
        assign pipe_result = ed_result;
    end

    // * -------------------------------------------------------------------------------------------
    // * Output assignment
    // * -------------------------------------------------------------------------------------------
    assign o_data = pipe_result;

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
