property prop_check_one_clock_pulse(i_clock, enable_assertion, signal);
    @(posedge i_clock)
    disable iff (!enable_assertion)
    signal |=> !signal;
endproperty

property prop_check_signal_reset(i_clock, enable_assertion, reset, expected_signal, signal);
    @(posedge i_clock)
    disable iff (!enable_assertion)
    reset |=> (signal == expected_signal);
endproperty

property prop_check_data_equal_with_trigger(i_clock, enable_assertion, trigger, data_1, data_2);
    @(posedge i_clock)
    disable iff (!enable_assertion)
    if (trigger) (data_1 == data_2);
endproperty

