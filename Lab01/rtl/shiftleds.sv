module shiftleds
#(
    // * ---------------------------------------------------
    // * Parameters
    // * ---------------------------------------------------
    parameter                        N_LEDS     =  4       ,
    parameter                        NB_COUNTER = 32       ,
    parameter                        NB_SW      =  4)
(
    // * ---------------------------------------------------
    // * Outputs
    // * ---------------------------------------------------
    output logic [ N_LEDS  - 1 : 0 ] o_led                 ,
    output logic [ N_LEDS  - 1 : 0 ] o_led_b               ,
    output logic [ N_LEDS  - 1 : 0 ] o_led_g               ,

    // * ---------------------------------------------------
    // * Inputs
    // * ---------------------------------------------------
    input  logic [ NB_SW   - 1 : 0 ] i_sw                  ,

    // * ---------------------------------------------------
    // * Clock and reset
    // * ---------------------------------------------------
    input  logic                     i_reset               ,
    input  logic                     i_clock
) ;
    // * ---------------------------------------------------
    // * Internal logics
    // * ---------------------------------------------------
    logic                            counter_count_reached ;
    logic        [ N_LEDS  - 1 : 0 ] shiftreg_led          ;

    // * ---------------------------------------------------
    // * Counter instantiation
    // * ---------------------------------------------------
    counter
    #(
        .NB_COUNTER      ( NB_COUNTER            ) ,
        .NB_SW           ( NB_SW - 1             )
    )
    u_counter
    (
        .o_count_reached ( counter_count_reached ) ,
        .i_sw            ( i_sw      [NB_SW-2:0] ) ,
        .i_reset         ( ~i_reset              ) ,
        .i_clock         ( i_clock               )
    );

    // * ---------------------------------------------------
    // * Shift register instantiation
    // * ---------------------------------------------------
    shiftreg
    #(
        .NB_DATA         ( N_LEDS                )
    )
    u_shiftreg
    (
        .o_led           ( shiftreg_led          ) ,
        .i_valid         ( counter_count_reached ) ,
        .i_reset         ( ~i_reset              ) ,
        .i_clock         ( i_clock               )
    ) ;

    // * ---------------------------------------------------
    // * Output assignment
    // * ---------------------------------------------------
    assign o_led   = shiftreg_led                            ;
    assign o_led_b = (i_sw[3]) ? shiftreg_led : '0           ;
    assign o_led_g = (i_sw[3]) ? '0           : shiftreg_led ;

    // * ---------------------------------------------------
    // * Assertions
    // * ---------------------------------------------------
    `ifdef ENABLE_SVA
        logic enable_sva = 1'b1;

        assert property (
            @(posedge i_clock)
            disable iff (!enable_sva)
            counter_count_reached |=> !counter_count_reached
        ) else $error("Valid signal for shift register lasted more than one clock");

        assert property (
            @(posedge i_clock)
            disable iff (!enable_sva)
            $rose(counter_count_reached) |=> (u_counter.count == 0)
        ) else $error("Counter limit reached but count register didnt go back to zero. Count value: %0d", u_counter.count);

        assert property (
            @(posedge i_clock)
            disable iff (!enable_sva)
            (u_counter.count == u_counter.limit_count) |-> $rose(counter_count_reached)
        ) else $error("Limit count reached but count reached never rose");

        assert property (
            @(posedge i_clock)
            disable iff (!enable_sva)
            $fell(i_reset) |=> (u_counter.count == 0)
        ) else $error("Reset negedge happened but counter didnt set to default value. Count value: %0d", u_counter.count);

        assert property (
            @(posedge i_clock)
            disable iff (!enable_sva)
            $fell(i_reset) |=> (u_shiftreg.shift_register == {{N_LEDS-1{1'b0}}, 1'b1})
        ) else $error("Reset negedge happened but shift register didnt set to default value. Value found: %0b", u_shiftreg.shift_register);

        assert property (
            @(posedge i_clock)
            disable iff (!enable_sva)
            !i_sw[0] |=> $stable(u_counter.count)
        ) else $error("Count is not stable during disable");
    `endif
endmodule
