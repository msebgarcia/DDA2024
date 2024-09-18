module sum_accumulator
#(
    // * -------------------------------------------------
    // * Parameters
    // * -------------------------------------------------
    parameter                            NB_DATA_IN  = 3 ,
    parameter                            NB_SEL      = 2 ,
    parameter                            NB_DATA_OUT = 6
)
(
    // * -------------------------------------------------
    // * Outputs
    // * -------------------------------------------------
    output logic [ NB_DATA_OUT - 1 : 0 ] o_data          ,
    output logic                         o_overflow      ,

    // * -------------------------------------------------
    // * Inputs
    // * -------------------------------------------------
    input  logic [ NB_DATA_IN  - 1 : 0 ] i_data1         ,
    input  logic [ NB_DATA_IN  - 1 : 0 ] i_data2         ,
    input  logic [ NB_SEL      - 1 : 0 ] i_sel           ,

    // * -------------------------------------------------
    // * Clock and reset
    // * -------------------------------------------------
    input  logic                         i_rst_n         ,
    input  logic                         i_clk
) ;

    // * -------------------------------------------------
    // * Internal logics
    // * -------------------------------------------------
    logic        [ NB_DATA_IN      : 0 ] expanded_data1  ;
    logic        [ NB_DATA_IN      : 0 ] expanded_data2  ;
    logic        [ NB_DATA_IN      : 0 ] in_data_sum     ;
    logic        [ NB_DATA_IN      : 0 ] data_sel        ;
    logic        [ NB_DATA_OUT     : 0 ] sum             ;
    logic        [ NB_DATA_OUT - 1 : 0 ] sum_d           ;
    logic                                overflow        ;

    // * -------------------------------------------------
    // * Expansion and sum
    // * -------------------------------------------------
    assign expanded_data1 = {1'b0, i_data1}                 ;
    assign expanded_data2 = {1'b0, i_data2}                 ;
    assign in_data_sum    = expanded_data1 + expanded_data2 ;

    // * -------------------------------------------------
    // * Data selection
    // * -------------------------------------------------
    typedef enum logic [NB_SEL-1:0] {
        SELECT_DATA_1   = 2'b10 ,
        SELECT_DATA_2   = 2'b00 ,
        SELECT_DATA_SUM = 2'b01
    } selector_e;

    always_comb
    begin : proc_muxing
        unique case (i_sel)
            SELECT_DATA_1   : data_sel = expanded_data1 ;
            SELECT_DATA_2   : data_sel = expanded_data2 ;
            SELECT_DATA_SUM : data_sel = in_data_sum    ;
        endcase
    end

    // * -------------------------------------------------
    // * Accumulation
    // * -------------------------------------------------
    assign sum = {1'b0, sum_d} + {{NB_DATA_OUT-NB_DATA_IN{1'b0}}, data_sel};

    always_ff @(posedge i_clk or negedge i_rst_n)
    begin : proc_accum
        if (~i_rst_n) begin
            sum_d    <= '0               ;
            overflow <= '0               ;
        end else begin
            sum_d    <= sum              ;
            overflow <= sum[NB_DATA_OUT] ;
        end
    end

    // * -------------------------------------------------
    // * Output assignment
    // * -------------------------------------------------
    assign o_data     = sum_d [ NB_DATA_OUT - 1 : 0 ] ;
    assign o_overflow = overflow                      ;

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
