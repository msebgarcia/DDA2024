module pipe_handler
#(
    // * --------------------------------------------
    // * Parameters
    // * --------------------------------------------
    parameter                        NB_DATA   = 16 ,
    parameter                        ADD_PIPE  =  1 ,
    parameter                        ADD_RESET =  1
)
(
    // * --------------------------------------------
    // * Output
    // * --------------------------------------------
    output logic [ NB_DATA - 1 : 0 ] o_data         ,

    // * --------------------------------------------
    // * Input
    // * --------------------------------------------
    input  logic [ NB_DATA - 1 : 0 ] i_data         ,

    // * --------------------------------------------
    // * Reset and system clock
    // * --------------------------------------------
    input  logic                     i_reset        ,
    input  logic                     i_clock
) ;
    // * --------------------------------------------
    // * Internal logics
    // * --------------------------------------------
    logic        [ NB_DATA - 1 : 0 ] piped_data     ;

    // * --------------------------------------------
    // * Pipe handling
    // * --------------------------------------------
    generate
        if (ADD_PIPE)
        begin : gen_enabled_pipe
            if (ADD_RESET)
            begin : gen_pipe_with_reset
                always_ff @(posedge i_clock)
                begin : proc_data_pipe_w_reset
                    if (i_reset)
                        piped_data <= '0     ;
                    else
                        piped_data <= i_data ;
                end
            end else
            begin : gen_pipe_without_reset
                always_ff @(posedge i_clock)
                begin : proc_data_pipe_wo_reset
                    piped_data <= i_data ;
                end
            end
        end else
        begin : gen_disabled_pipe
            assign piped_data = i_data;
        end
    endgenerate

    // * --------------------------------------------
    // * Output assignment
    // * --------------------------------------------
    assign o_data = piped_data;
endmodule
