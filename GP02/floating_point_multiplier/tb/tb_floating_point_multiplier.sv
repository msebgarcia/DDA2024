`define CLOCK_PERIOD_NS 10
`define ENABLE          1'b1
`define DISABLE         1'b0
`define HIGH            1'b1
`define LOW             1'b0

module tb_floating_point_multiplier();
    // * -------------------------------------------------
    // * Localparams
    // * -------------------------------------------------
    localparam                NB_MANTISSA    =  8 ;
    localparam                NB_EXPONENT    =  4 ;
    localparam                NB_DATA        = 13 ;
    localparam                N_BIAS         =  7 ;
    localparam                N_DATASET_SIZE =  4 ;

    // * -------------------------------------------------
    // * Declaration
    // * -------------------------------------------------
    logic [ NB_DATA - 1 : 0 ] o_data           ;
    logic                     o_overflow       ;
    logic                     o_underflow      ;
    logic [ NB_DATA - 1 : 0 ] i_data_1         ;
    logic [ NB_DATA - 1 : 0 ] i_data_2         ;
    logic                     i_reset          ;
    logic                     i_clock          ;

    logic [ N_DATASET_SIZE - 1 : 0 ] [ NB_DATA - 1 : 0 ] data_1_in_range     ;
    logic [ N_DATASET_SIZE - 1 : 0 ] [ NB_DATA - 1 : 0 ] data_2_in_range     ;
    logic [ N_DATASET_SIZE - 1 : 0 ] [ NB_DATA - 1 : 0 ] result_in_range     ;
    logic [ N_DATASET_SIZE - 1 : 0 ] [ NB_DATA - 1 : 0 ] data_1_overflow     ;
    logic [ N_DATASET_SIZE - 1 : 0 ] [ NB_DATA - 1 : 0 ] data_2_overflow     ;
    logic [ NB_DATA                            - 1 : 0 ] overflow_data       ;
    logic [ N_DATASET_SIZE - 1 : 0 ] [ NB_DATA - 1 : 0 ] data_1_underflow    ;
    logic [ N_DATASET_SIZE - 1 : 0 ] [ NB_DATA - 1 : 0 ] data_2_underflow    ;
    logic [ NB_DATA                            - 1 : 0 ] underflow_data      ;

    // * -------------------------------------------------
    // * Clock generation
    // * -------------------------------------------------
    initial
    begin : proc_clock_initializacion
        i_clock = '0;
    end
    always #(`CLOCK_PERIOD_NS/2) i_clock = ~i_clock;

    // * -------------------------------------------------
    // * Tasks
    // * -------------------------------------------------
    task automatic wait_for_n_clocks(input int n_clocks = 1, input bit safe_check = 1'b0);
        repeat(n_clocks) @(posedge i_clock);
        if (safe_check) #1ps;
    endtask : wait_for_n_clocks

    task automatic run_reset(input int clock_duration = 1);
        wait_for_n_clocks(.n_clocks(1), .safe_check(0));
        force i_reset = 1'b0;
        wait_for_n_clocks(.n_clocks(1), .safe_check(0));
        force i_reset = 1'b1;
        wait_for_n_clocks(.n_clocks(clock_duration), .safe_check(0));
        force i_reset = 1'b0;
    endtask : run_reset

    task automatic data_assertion(input logic [NB_DATA-1:0] expected_data, input logic expected_overflow, input logic expected_underflow);
        $display("Data expected: %13b - Data collected: %13b", expected_data, o_data);
        assert( o_data      == expected_data      ) ;
        assert( o_overflow  == expected_overflow  ) ;
        assert( o_underflow == expected_underflow ) ;
    endtask : data_assertion

    // * -------------------------------------------------
    // * Stimulus generation
    // * -------------------------------------------------
    initial
    begin : proc_stimulus
        i_data_1 = '0;
        i_data_2 = '0;
        i_reset  = 1'b1;
        run_reset();
        for (int i = 0 ; i < N_DATASET_SIZE ; i++) begin : testing_basic_data
            wait_for_n_clocks(.n_clocks(1), .safe_check(`DISABLE));

            i_data_1 = data_1_in_range[i];
            i_data_2 = data_2_in_range[i];
            wait_for_n_clocks(.n_clocks(1), .safe_check(`ENABLE));
            data_assertion(.expected_data(result_in_range[i]), .expected_overflow(`LOW), .expected_underflow(`LOW));

            wait_for_n_clocks(.n_clocks(1), .safe_check(`DISABLE));
            i_data_1 = data_1_overflow[i];
            i_data_2 = data_2_overflow[i];
            wait_for_n_clocks(.n_clocks(1), .safe_check(`ENABLE));
            data_assertion(.expected_data(overflow_data), .expected_overflow(`HIGH), .expected_underflow(`LOW));

            wait_for_n_clocks(.n_clocks(1), .safe_check(`DISABLE));
            i_data_1 = data_1_underflow[i];
            i_data_2 = data_2_underflow[i];
            wait_for_n_clocks(.n_clocks(1), .safe_check(`ENABLE));
            data_assertion(.expected_data(underflow_data), .expected_overflow(`LOW), .expected_underflow(`HIGH));
        end
        wait_for_n_clocks(.n_clocks(1), .safe_check(`DISABLE));

        // * NaN as input in data 1
        i_data_1 = {1'b0, 4'hf, 8'h8f};
        i_data_2 = '0;
        wait_for_n_clocks(.n_clocks(1), .safe_check(`ENABLE));
        data_assertion(.expected_data({1'b0, 4'hf, 8'h80}), .expected_overflow(`LOW), .expected_underflow(`LOW));
        wait_for_n_clocks(.n_clocks(1), .safe_check(`DISABLE));

        i_data_1 = {1'b1, 4'hf, 8'h0f};
        i_data_2 = data_2_in_range[1];
        wait_for_n_clocks(.n_clocks(1), .safe_check(`ENABLE));
        data_assertion(.expected_data({1'b1, 4'hf, 8'h00}), .expected_overflow(`LOW), .expected_underflow(`LOW));
        wait_for_n_clocks(.n_clocks(1), .safe_check(`DISABLE));

        // * NaN as input in data 2
        i_data_1 = '0;
        i_data_2 = {1'b1, 4'hf, 8'hff};
        wait_for_n_clocks(.n_clocks(1), .safe_check(`ENABLE));
        data_assertion(.expected_data({1'b1, 4'hf, 8'h80}), .expected_overflow(`LOW), .expected_underflow(`LOW));
        wait_for_n_clocks(.n_clocks(1), .safe_check(`DISABLE));

        i_data_1 = data_1_in_range[0];
        i_data_2 = {1'b1, 4'hf, 8'h7f};
        wait_for_n_clocks(.n_clocks(1), .safe_check(`ENABLE));
        data_assertion(.expected_data({1'b0, 4'hf, 8'h00}), .expected_overflow(`LOW), .expected_underflow(`LOW));
        wait_for_n_clocks(.n_clocks(1), .safe_check(`DISABLE));

        $finish;
    end

    // * -------------------------------------------------
    // * Datasets
    // * -------------------------------------------------
    `include "data_in_range.sv"
    `include "data_overflow.sv"
    `include "data_underflow.sv"

    // * -------------------------------------------------
    // * DUT instantiation
    // * -------------------------------------------------
    floating_point_multiplier
    #(
        .NB_MANTISSA (NB_MANTISSA) ,
        .NB_EXPONENT (NB_EXPONENT) ,
        .NB_DATA     (NB_DATA    ) ,
        .N_BIAS      (N_BIAS     )
    )
    u_floating_point_multiplier
    (
        .o_data      (o_data     ) ,
        .o_overflow  (o_overflow ) ,
        .o_underflow (o_underflow) ,
        .i_data_1    (i_data_1   ) ,
        .i_data_2    (i_data_2   ) ,
        .i_reset     (i_reset    ) ,
        .i_clock     (i_clock    )
    ) ;

endmodule
