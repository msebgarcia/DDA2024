`timescale 1ns/100ps

`define N_LEDS           4
`define NB_SEL           2
`define NB_COUNTER      32
`define NB_SW            4
`define CLOCK_PERIOD_NS 10

module tb_shiftleds();
    // * -------------------------------------------------
    // * Localparams
    // * -------------------------------------------------
    localparam                  N_LEDS     = `N_LEDS     ;
    localparam                  NB_SEL     = `NB_SEL     ;
    localparam                  NB_COUNTER = `NB_COUNTER ;
    localparam                  NB_SW      = `NB_SW      ;

    // * -------------------------------------------------
    // * Declaration
    // * -------------------------------------------------
    wire [ N_LEDS     - 1 : 0 ] o_led                    ;
    wire [ N_LEDS     - 1 : 0 ] o_led_b                  ;
    wire [ N_LEDS     - 1 : 0 ] o_led_g                  ;
    reg  [ NB_SW      - 1 : 0 ] i_sw                     ;
    reg                         i_reset                  ;
    reg                         i_clock                  ;

    wire [ NB_COUNTER - 1 : 0 ] active_count_limit       ;
    wire [ NB_COUNTER - 1 : 0 ] counter_limit [4]        ;

    reg  [ NB_COUNTER - 1 : 0 ] counter_record           ;

    // * -------------------------------------------------
    // * Observers assigns
    // * -------------------------------------------------
    assign counter_limit[0] = u_shiftleds.u_counter.R0;
    assign counter_limit[1] = u_shiftleds.u_counter.R1;
    assign counter_limit[2] = u_shiftleds.u_counter.R2;
    assign counter_limit[3] = u_shiftleds.u_counter.R3;

    assign active_count_limit = (i_sw[2:1] == 2'b00 ) ? counter_limit[0] :
                                (i_sw[2:1] == 2'b01 ) ? counter_limit[1] :
                                (i_sw[2:1] == 2'b10 ) ? counter_limit[2] :
                                                        counter_limit[3] ;

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
    task automatic wait_for_n_clocks(int n_clocks = 1, bit safe_check = 1'b1);
        repeat(n_clocks) @(posedge i_clock);
        if (safe_check) #1ns;
    endtask : wait_for_n_clocks

    task automatic run_reset(int clock_duration = 1);
        wait_for_n_clocks(.n_clocks(1), .safe_check(0));
        force i_reset = 1'b0;
        wait_for_n_clocks(.n_clocks(clock_duration), .safe_check(0));
        force i_reset = 1'b1;
    endtask : run_reset

    task automatic check_led_change(int n_changes = N_LEDS);
        logic [N_LEDS-1:0] led_record;
        repeat (n_changes) begin : proc_check_repeatedly
            led_record = u_shiftleds.o_led;
            wait_for_n_clocks(active_count_limit);
            assert(u_shiftleds.counter_count_reached == 1'b1);
            wait_for_n_clocks(1);
            assert(o_led == {led_record[N_LEDS-2:0], led_record[N_LEDS-1]});
            if (i_sw[3]) begin
                assert (o_led_b == o_led);
                assert (o_led_g == '0   );
            end else begin
                assert (o_led_b == '0   );
                assert (o_led_g == o_led);
            end
            $display("Led value: %4b - Led recorded: %4b - Expected value: %4b", o_led, led_record, {led_record[N_LEDS-2:0], led_record[N_LEDS-1]});
        end
    endtask : check_led_change

    // * -------------------------------------------------
    // * Assertion handling
    // * -------------------------------------------------
    initial
    begin : proc_bypass_sva_first_clock
        $assertoff(0,u_shiftleds);
        wait_for_n_clocks(.n_clocks(2), .safe_check(0));
        $asserton(0,u_shiftleds);
    end

    // * -------------------------------------------------
    // * Stimulus generation
    // * -------------------------------------------------
    initial
    begin : proc_stimulus
        i_sw    = '0;
        i_reset = 1'b0;
        run_reset(5);
        wait_for_n_clocks(20);

        i_sw[0] = 1'b1;
        check_led_change(8);
        wait_for_n_clocks(4);

        i_sw[2:1] = 2'b01;
        run_reset();
        check_led_change(8);

        i_sw[3]   = 1'b1 ;
        i_sw[2:1] = 2'b10;
        run_reset();
        check_led_change(8);

        i_sw[2:1] = 2'b11;
        run_reset();
        check_led_change(8);

        wait_for_n_clocks(.n_clocks(100), .safe_check(0));
        i_sw[0] = 1'b0;
        wait_for_n_clocks(.n_clocks(2000), .safe_check(0));

        counter_record = u_shiftleds.u_counter.count;
        i_sw[0] = 1'b1;
        wait_for_n_clocks(1);
        assert(u_shiftleds.u_counter.count == counter_record+1);

        $finish;
    end

    // * -------------------------------------------------
    // * DUT instantiation
    // * -------------------------------------------------
    shiftleds
    #(
        .N_LEDS     ( N_LEDS     ) ,
        .NB_COUNTER ( NB_COUNTER ) ,
        .NB_SW      ( NB_SW      )
    )
    u_shiftleds
    (
        .o_led      ( o_led      ) ,
        .o_led_b    ( o_led_b    ) ,
        .o_led_g    ( o_led_g    ) ,
        .i_sw       ( i_sw       ) ,
        .i_reset    ( i_reset    ) ,
        .i_clock    ( i_clock    )
    ) ;
endmodule
