/*-----------------------------------------------------------------
File name     : top.sv
Description   : lab01_data top module template file
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

module tb_top;
// import the UVM library
    import uvm_pkg::*;
// include the UVM macros
    `include "uvm_macros.svh"

    import yapp_router_reg_pkg::*;
    typedef yapp_router_regs_vendor_Cadence_Design_Systems_library_Yapp_Registers_version_1_5 yapp_router_regs_t;

    import router_module::*;
    import channel_pkg::*;
    import hbus_pkg::*;
    import clock_and_reset_pkg::*;

// import the YAPP package
    import yapp_pkg::*;
    `include "router_mcsequencer.sv"
    `include "router_mcseqs_lib.sv"
    `include "router_tb.sv"
    `include "router_test_lib.sv"

// generate 5 random packets and use the print method
// to display the results
    initial begin
        yapp_vif_config::set(null, "uvm_test_top.tb.yapp_env.agent.*", "vif", hw_top.in0);
        channel_vif_config::set(null, "uvm_test_top.tb.chan0.*", "vif", hw_top.chan0_inst);
        channel_vif_config::set(null, "uvm_test_top.tb.chan1.*", "vif", hw_top.chan1_inst);
        channel_vif_config::set(null, "uvm_test_top.tb.chan2.*", "vif", hw_top.chan2_inst);
        clock_and_reset_vif_config::set(null, "uvm_test_top.tb.clk_and_rst.agent.*", "vif", hw_top.clk_and_rst_inst);
        hbus_vif_config::set(null, "uvm_test_top.tb.hbus.*", "vif", hw_top.hbus_inst);

        run_test("base_test");
    end

// experiment with the copy, clone and compare UVM method
endmodule : tb_top
