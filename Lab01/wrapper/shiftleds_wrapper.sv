module shiftleds_wrapper (
    // * ---------------------------------------------------
    // * Outputs
    // * ---------------------------------------------------
    output logic [4-1:0] o_led           ,
    output logic [4-1:0] o_led_b         ,
    output logic [4-1:0] o_led_g         ,

    // * ---------------------------------------------------
    // * Inputs
    // * ---------------------------------------------------
    input logic  [4-1:0] i_sw            ,

    // * ---------------------------------------------------
    // * Clock and reset
    // * ---------------------------------------------------
    input logic          i_reset_n       ,
    input logic          i_clock
) ;
    // * ---------------------------------------------------
    // * Internal logics
    // * ---------------------------------------------------
    logic        [4-1:0] shiftleds_led   ;
    logic        [4-1:0] shiftleds_led_b ;
    logic        [4-1:0] shiftleds_led_g ;
    logic        [4-1:0] vio_sw          ;
    logic                vio_reset       ;
    logic                vio_enable      ;
    logic        [4-1:0] sw_to_device    ;
    logic                reset_to_device ;

    // * ---------------------------------------------------
    // * VIO instantion
    // * ---------------------------------------------------
    vio_wrapper
    u_vio_wrapper
    (
        .clk_0        ( i_clock         ) ,
        .probe_in0_0  ( shiftleds_led   ) ,
        .probe_in1_0  ( shiftleds_led_b ) ,
        .probe_in2_0  ( shiftleds_led_g ) ,
        .probe_out0_0 ( vio_enable      ) ,
        .probe_out1_0 ( vio_reset       ) ,
        .probe_out2_0 ( vio_sw          )
    );

    // * ---------------------------------------------------
    // * ILA instantion
    // * ---------------------------------------------------
    ila_wrapper
    u_ila_wrapper
    (
        .clk_0        ( i_clock         ) ,
        .probe0_0     ( shiftleds_led   ) ,
        .probe1_0     ( shiftleds_led_b ) ,
        .probe2_0     ( shiftleds_led_g )
    );

    // * ---------------------------------------------------
    // * Muxing shiftleds input
    // * ---------------------------------------------------
    assign sw_to_device    = (vio_enable) ? vio_sw     : i_sw      ;
    assign reset_to_device = (vio_enable) ? ~vio_reset : i_reset_n ;

    // * ---------------------------------------------------
    // * Main device
    // * ---------------------------------------------------
    shiftleds
    u_shiftleds
    (
        .o_led        ( shiftleds_led   ) ,
        .o_led_b      ( shiftleds_led_b ) ,
        .o_led_g      ( shiftleds_led_g ) ,
        .i_sw         ( sw_to_device    ) ,
        .i_reset      ( reset_to_device ) ,
        .i_clock      ( i_clock         )
    ) ;

    // * ---------------------------------------------------
    // * Output assign
    // * ---------------------------------------------------
    assign o_led   = shiftleds_led   ;
    assign o_led_b = shiftleds_led_b ;
    assign o_led_g = shiftleds_led_g ;
endmodule
