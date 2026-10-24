class router_tb extends  uvm_env;
    yapp_router_regs_t  yapp_rm;
    hbus_reg_adapter    reg2hbus;

    `uvm_component_utils_begin(router_tb)
        `uvm_field_object(yapp_rm, UVM_ALL_ON)
    `uvm_component_utils_end

    yapp_env uvc;
    channel_env chan0;
    channel_env chan1;
    channel_env chan2;
    hbus_env hbus;
    clock_and_reset_env clk_and_rst;
    router_mcsequencer mcseqr;
    router_module_env router_env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        uvm_config_int::set(this, "chan0", "channel_id", 0);
        uvm_config_int::set(this, "chan1", "channel_id", 1);
        uvm_config_int::set(this, "chan2", "channel_id", 2);
        uvm_config_int::set(this, "hbus", "num_masters", 1);
        uvm_config_int::set(this, "hbus", "num_slaves", 0);

        super.build_phase(phase);
        `uvm_info("ROUTER_TB", "The build phase of the testbench is being executed.", UVM_HIGH);

        uvc = yapp_env::type_id::create("yapp_env", this);
        chan0 = channel_env::type_id::create("chan0", this);
        chan1 = channel_env::type_id::create("chan1", this);
        chan2 = channel_env::type_id::create("chan2", this);
        hbus = hbus_env::type_id::create("hbus", this);
        clk_and_rst = clock_and_reset_env::type_id::create("clk_and_rst", this);
        mcseqr = router_mcsequencer::type_id::create("mcseqr", this);
        router_env = router_module_env::type_id::create("router_env", this);

        yapp_rm = yapp_router_regs_t::type_id::create("yapp_rm",this);
        yapp_rm.build();
        yapp_rm.lock_model();
        yapp_rm.set_hdl_path_root("hw_top.dut");
        yapp_rm.default_map.set_auto_predict(1);
        reg2hbus= hbus_reg_adapter::type_id::create("reg2bus",this);
    endfunction : build_phase

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Program in %s", get_type_name()), UVM_HIGH)
    endfunction : start_of_simulation_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mcseqr.hbus_seqr = hbus.masters[0].sequencer;
        mcseqr.yapp_seqr = uvc.agent.sequencer;
        uvc.agent.monitor.item_send_port.connect(router_env.router_ref.yapp_in);
        chan0.rx_agent.monitor.item_collected_port.connect(router_env.router_sb.chan0_in);
        chan1.rx_agent.monitor.item_collected_port.connect(router_env.router_sb.chan1_in);
        chan2.rx_agent.monitor.item_collected_port.connect(router_env.router_sb.chan2_in);
        hbus.bus_monitor.item_collected_port.connect(router_env.router_ref.hbus_in);
        yapp_rm.default_map.set_sequencer(hbus.masters[0].sequencer, reg2hbus);
    endfunction : connect_phase
endclass