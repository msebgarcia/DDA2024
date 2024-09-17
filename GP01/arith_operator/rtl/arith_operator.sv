module arith_operator
#(
    // * ------------------------------------------------------------------
    // * Parameters
    // * ------------------------------------------------------------------
    parameter                               NB_DATA        = 16 ,
    parameter                               NB_SEL         =  2
)
(
    // * ------------------------------------------------------------------
    // * Output
    // * ------------------------------------------------------------------
    output logic signed [ NB_DATA - 1 : 0 ] o_data_c            ,

    // * ------------------------------------------------------------------
    // * Inputs
    // * ------------------------------------------------------------------
    input  logic signed [ NB_DATA - 1 : 0 ] i_data_a            ,
    input  logic signed [ NB_DATA - 1 : 0 ] i_data_b            ,
    input  logic        [ NB_SEL  - 1 : 0 ] i_sel
);
    // * ------------------------------------------------------------------
    // * Vars
    // * ------------------------------------------------------------------
    logic        signed [ NB_DATA - 1 : 0 ] result              ;

    // * ------------------------------------------------------------------
    // * Muxing
    // * ------------------------------------------------------------------
    typedef enum logic [NB_SEL-1:0] {
        OP_ADDITION     = 2'b00 ,
        OP_SUBSTRACTION = 2'b01 ,
        OP_AND          = 2'b10 ,
        OP_OR           = 2'b11
    } op_options_e;

    always_comb
    begin : proc_op_selection
        case (i_sel)
            OP_ADDITION     : result = i_data_a + i_data_b ;
            OP_SUBSTRACTION : result = i_data_a - i_data_b ;
            OP_AND          : result = i_data_a & i_data_b ;
            OP_OR           : result = i_data_a | i_data_b ;
        endcase
    end

    // * ------------------------------------------------------------------
    // * Output assignment
    // * ------------------------------------------------------------------
    assign o_data_c = result;

    // * -------------------------------------------------
    // * Simulation define
    // * -------------------------------------------------
    `ifdef COCOTB_SIM
        initial begin
            $dumpfile ("dump.vcd");
            $dumpvars ();
            #1;
        end
    `endif
 endmodule

