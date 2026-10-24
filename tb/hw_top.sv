/*-----------------------------------------------------------------
File name     : hw_top.sv
Developers    : Kathleen Meade, Brian Dickinson
Created       : 01/04/11
Description   : lab06_vif hardware top module for acceleration
              : Instantiates clock generator and YAPP interface only for testing - no DUT
Notes         : From the Cadence "SystemVerilog Accelerated Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

module hw_top;

  // Clock and reset signals
  logic [31:0]  clock_period;
  logic         run_clock;
  logic         clock;
  logic         reset;

  // YAPP Interface to the DUT
  yapp_if in0(clock, reset);

  clock_and_reset_if clk_and_rst_inst(clock, reset, run_clock, clock_period);

  channel_if chan0_inst(clock, reset);
  channel_if chan1_inst(clock, reset);
  channel_if chan2_inst(clock, reset);

  hbus_if hbus_inst(clock, reset);

  // CLKGEN module generates clock
  clkgen clkgen (
    .clock(clock),
    .run_clock(run_clock),
    .clock_period(clock_period)
  );

  yapp_router dut(
    .reset(reset),
    .clock(clock),
    .error(),

    // YAPP interface
    .in_data(in0.in_data),
    .in_data_vld(in0.in_data_vld),
    .in_suspend(in0.in_suspend),

    // Output Channels
    //Channel 0
    .data_0(chan0_inst.data),
    .data_vld_0(chan0_inst.data_vld),
    .suspend_0(chan0_inst.suspend),
    //Channel 1
    .data_1(chan1_inst.data),
    .data_vld_1(chan1_inst.data_vld),
    .suspend_1(chan1_inst.suspend),
    //Channel 2
    .data_2(chan2_inst.data),
    .data_vld_2(chan2_inst.data_vld),
    .suspend_2(chan2_inst.suspend),

    // HBUS Interface 
    .haddr(hbus_inst.haddr),
    .hdata(hbus_inst.hdata_w),
    .hen(hbus_inst.hen),
    .hwr_rd(hbus_inst.hwr_rd));

endmodule
