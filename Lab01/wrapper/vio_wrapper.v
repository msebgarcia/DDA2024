//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Sat Sep 28 23:19:27 2024
//Host        : dsktp running 64-bit Fedora Linux 40 (KDE Plasma)
//Command     : generate_target vio_wrapper.bd
//Design      : vio_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module vio_wrapper
   (clk_0,
    probe_in0_0,
    probe_in1_0,
    probe_in2_0,
    probe_out0_0,
    probe_out1_0,
    probe_out2_0);
  input clk_0;
  input [3:0]probe_in0_0;
  input [3:0]probe_in1_0;
  input [3:0]probe_in2_0;
  output [0:0]probe_out0_0;
  output [0:0]probe_out1_0;
  output [3:0]probe_out2_0;

  wire clk_0;
  wire [3:0]probe_in0_0;
  wire [3:0]probe_in1_0;
  wire [3:0]probe_in2_0;
  wire [0:0]probe_out0_0;
  wire [0:0]probe_out1_0;
  wire [3:0]probe_out2_0;

  vio vio_i
       (.clk_0(clk_0),
        .probe_in0_0(probe_in0_0),
        .probe_in1_0(probe_in1_0),
        .probe_in2_0(probe_in2_0),
        .probe_out0_0(probe_out0_0),
        .probe_out1_0(probe_out1_0),
        .probe_out2_0(probe_out2_0));
endmodule

