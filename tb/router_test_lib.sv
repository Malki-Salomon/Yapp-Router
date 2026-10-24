class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    router_tb tb;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_int::set(this, "*", "recording_detail", 1);
        tb = router_tb::type_id::create("tb", this);
        `uvm_info("BASE_TEST", "The build phase of the test is being executed.", UVM_HIGH);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        uvm_objection obj = phase.get_objection();
        obj.set_drain_time(this, 200ns);
    endtask : run_phase

    function void check_phase(uvm_phase phase);
        check_config_usage();
    endfunction : check_phase

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase
endclass

class active_agent_test extends base_test;
    `uvm_component_utils(active_agent_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.yapp_env.agent.sequencer.run_phase",
                        "default_sequence",
                        yapp_5_packets::get_type());
        super.build_phase(phase);
    endfunction : build_phase
endclass



class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        yapp_packet::type_id::set_type_override(short_yapp_packet::get_type());
        uvm_config_wrapper::set(this, "tb.yapp_env.agent.sequencer.run_phase",
                                "default_sequence",
                                yapp_012_seq::get_type());
        uvm_config_wrapper::set(this, "tb.chan?.rx_agent.sequencer.run_phase",
                                "default_sequence",
                                channel_rx_resp_seq::get_type());
        uvm_config_wrapper::set(this, "tb.clk_and_rst.agent.sequencer.run_phase",
                                "default_sequence",
                                clk10_rst5_seq::get_type());
        super.build_phase(phase);
    endfunction : build_phase
endclass

class test_uvc_integration extends base_test;
    `uvm_component_utils(test_uvc_integration)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.yapp_env.agent.sequencer.run_phase",
                                "default_sequence",
                                seq_with_err::get_type());
        uvm_config_wrapper::set(this, "tb.chan?.rx_agent.sequencer.run_phase",
                                "default_sequence",
                                channel_rx_resp_seq::get_type());
        uvm_config_wrapper::set(this, "tb.clk_and_rst.agent.sequencer.run_phase",
                                "default_sequence",
                                clk10_rst5_seq::get_type());
        uvm_config_wrapper::set(this, "tb.hbus.masters[0].sequencer.run_phase",
                                "default_sequence",
                                hbus_small_packet_seq::get_type());
        super.build_phase(phase);
    endfunction : build_phase
endclass

class test_mcsequncer extends base_test;
    `uvm_component_utils(test_mcsequncer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        yapp_packet::type_id::set_type_override(short_yapp_packet::get_type());
        uvm_config_wrapper::set(this, "tb.chan?.rx_agent.sequencer.run_phase",
                                "default_sequence",
                                channel_rx_resp_seq::get_type());
        uvm_config_wrapper::set(this, "tb.clk_and_rst.agent.sequencer.run_phase",
                                "default_sequence",
                                clk10_rst5_seq::get_type());
        uvm_config_wrapper::set(this, "tb.mcseqr.run_phase",
                                "default_sequence",
                                router_simple_mcseq::get_type());
        super.build_phase(phase);
    endfunction : build_phase
endclass

class cross_test extends base_test;
    `uvm_component_utils(cross_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.yapp_env.agent.sequencer.run_phase",
                                "default_sequence",
                                yapp_cross_seq::get_type());
        uvm_config_wrapper::set(this, "tb.chan?.rx_agent.sequencer.run_phase",
                                "default_sequence",
                                channel_rx_resp_seq::get_type());
        uvm_config_wrapper::set(this, "tb.clk_and_rst.agent.sequencer.run_phase",
                                "default_sequence",
                                clk10_rst5_seq::get_type());
        uvm_config_wrapper::set(this, "tb.hbus.masters[0].sequencer.run_phase",
                                "default_sequence",
                                hbus_small_packet_seq::get_type());
        super.build_phase(phase);
    endfunction : build_phase
endclass

class  uvm_reset_test extends base_test;

    uvm_reg_hw_reset_seq reset_seq;

  // component macro
  `uvm_component_utils(uvm_reset_test)

  // component constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
      uvm_reg::include_coverage("*", UVM_NO_COVERAGE);
      reset_seq = uvm_reg_hw_reset_seq::type_id::create("uvm_reset_seq");
      uvm_config_wrapper::set(this, "tb.clk_and_rst.agent.sequencer.run_phase",
                                "default_sequence",
                                clk10_rst5_seq::get_type());
      super.build_phase(phase);
  endfunction : build_phase

  virtual task run_phase (uvm_phase phase);
     phase.raise_objection(this, "Raising Objection to run uvm built in reset test");
     // Set the model property of the sequence to our Register Model instance
     // Update the RHS of this assignment to match your instance names. Syntax is:
     //  <testbench instance>.<register model instance>
     reset_seq.model = tb.yapp_rm;
     // Execute the sequence (sequencer is already set in the testbench)
     reset_seq.start(null);
     phase.drop_objection(this," Dropping Objection to uvm built reset test finished");
     
     
  endtask

endclass : uvm_reset_test

class  uvm_mem_walk_test extends base_test;

    uvm_mem_walk_seq mem_seq;

  // component macro
  `uvm_component_utils(uvm_mem_walk_test)

  // component constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
      uvm_reg::include_coverage("*", UVM_NO_COVERAGE);
      mem_seq = uvm_mem_walk_seq::type_id::create("uvm_reset_seq");
      uvm_config_wrapper::set(this, "tb.clk_and_rst.agent.sequencer.run_phase",
                                "default_sequence",
                                clk10_rst5_seq::get_type());
      super.build_phase(phase);
  endfunction : build_phase

  virtual task run_phase (uvm_phase phase);
     phase.raise_objection(this, "Raising Objection to run uvm built in reset test");
     // Set the model property of the sequence to our Register Model instance
     // Update the RHS of this assignment to match your instance names. Syntax is:
     //  <testbench instance>.<register model instance>
     mem_seq.model = tb.yapp_rm;
     // Execute the sequence (sequencer is already set in the testbench)
     mem_seq.start(null);
     phase.drop_objection(this," Dropping Objection to uvm built reset test finished");
     
     
  endtask

endclass : uvm_mem_walk_test

class  reg_access_test extends base_test;

    uvm_reg_access_seq access_seq;

    // component macro
    `uvm_component_utils(reg_access_test)

    yapp_regs_c yapp_regs;
    uvm_status_e status;
    bit [7:0] rdata;

    // component constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_reg::include_coverage("*", UVM_NO_COVERAGE);
        access_seq = uvm_reg_access_seq::type_id::create("uvm_access_seq");
        uvm_config_wrapper::set(this, "tb.clk_and_rst.agent.sequencer.run_phase",
                                    "default_sequence",
                                    clk10_rst5_seq::get_type());
        super.build_phase(phase);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        yapp_regs = tb.yapp_rm.router_yapp_regs;
    endfunction : connect_phase

    virtual task run_phase (uvm_phase phase);
        phase.raise_objection(this, "Raising Objection to run uvm built in reset test");
        // Set the model property of the sequence to our Register Model instance
        // Update the RHS of this assignment to match your instance names. Syntax is:
        //  <testbench instance>.<register model instance>
        access_seq.model = tb.yapp_rm;

        yapp_regs.addr0_cnt_reg.poke(status, 8'hA5);
        `uvm_info(get_type_name(), "poke to addr0_cnt_reg", UVM_NONE)
        yapp_regs.addr0_cnt_reg.read(status, rdata);
        `uvm_info(get_type_name(), "read from addr0_cnt_reg", UVM_NONE)
        yapp_regs.addr0_cnt_reg.write(status, 8'h5A);
        `uvm_info(get_type_name(), "write to addr0_cnt_reg", UVM_NONE)
        yapp_regs.addr0_cnt_reg.peek(status, rdata);
        `uvm_info(get_type_name(), "peek from addr0_cnt_reg", UVM_NONE)

        yapp_regs.en_reg.write(status, 8'hA5);
        `uvm_info(get_type_name(), "write to en_reg", UVM_NONE)
        yapp_regs.en_reg.peek(status, rdata);
        `uvm_info(get_type_name(), "peek from en_reg", UVM_NONE)
        yapp_regs.en_reg.poke(status, 8'h5A);
        `uvm_info(get_type_name(), "poke to en_reg", UVM_NONE)
        yapp_regs.en_reg.read(status, rdata);
        `uvm_info(get_type_name(), "read from en_reg", UVM_NONE)
        // Execute the sequence (sequencer is already set in the testbench)
        access_seq.start(null);
        phase.drop_objection(this," Dropping Objection to uvm built reset test finished");
    endtask

endclass : reg_access_test

class  reg_function_test extends base_test;


    // component macro
    `uvm_component_utils(reg_function_test)

    yapp_regs_c yapp_regs;
    uvm_status_e status;
    bit [7:0] rdata;
    yapp_tx_sequencer yapp_seqr;
    yapp_012_seq yapp_012_seq_inst;
    uvm_reg all_regs[$];
    uvm_reg range_q[$];

    // component constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_reg::include_coverage("*", UVM_NO_COVERAGE);
        uvm_config_wrapper::set(this, "tb.chan?.rx_agent.sequencer.run_phase",
                                "default_sequence",
                                channel_rx_resp_seq::get_type());
        uvm_config_wrapper::set(this, "tb.clk_and_rst.agent.sequencer.run_phase",
                                    "default_sequence",
                                    clk10_rst5_seq::get_type());
        yapp_012_seq_inst = yapp_012_seq::type_id::create("yapp_012_seq");
        super.build_phase(phase);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        yapp_regs = tb.yapp_rm.router_yapp_regs;
        yapp_seqr = tb.uvc.agent.sequencer;
    endfunction : connect_phase

    task check_cnt(uvm_reg r, bit [7:0] exp);
        uvm_reg_data_t val;
        r.read(status, val);
        if (val[7:0] !== exp)
            `uvm_error(get_type_name(), $sformatf("%s = %0d, expected %0d", r.get_name(), val[7:0], exp))
        else
            `uvm_info(get_type_name(), $sformatf("%s = %0d OK", r.get_name(), val[7:0]), UVM_NONE)
    endtask

    virtual task run_phase (uvm_phase phase);
        phase.raise_objection(this, "Raising Objection to run uvm built in reset test");
        tb.yapp_rm.default_map.set_check_on_read(1);
        tb.yapp_rm.default_map.get_registers(all_regs);
        range_q = all_regs.find(r) with (r.get_address() >= 'h1009 &&
                                        r.get_address() <= 'h100b);
        yapp_regs.en_reg.write(status, 8'h01);
        yapp_regs.en_reg.read(status, rdata);
        if (rdata[0] !== 1'b1)
            `uvm_error(get_type_name(), $sformatf("en_reg read %0h, router enable not set", rdata))
        yapp_012_seq_inst.start(yapp_seqr);
        foreach (range_q[i]) begin
            check_cnt(range_q[i], 0);
        end
        check_cnt(yapp_regs.addr3_cnt_reg, 0);
        yapp_regs.en_reg.write(status, 8'hFF);
        repeat(2)
            yapp_012_seq_inst.start(yapp_seqr);
        foreach (range_q[i]) begin
            range_q[i].predict(2);
            check_cnt(range_q[i], 2);
        end
        check_cnt(yapp_regs.addr3_cnt_reg, 0);
        yapp_regs.parity_err_cnt_reg.predict(1);
         yapp_regs.parity_err_cnt_reg.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("parity_err_cnt = %0d", rdata), UVM_NONE)
        yapp_regs.oversized_pkt_cnt_reg.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("oversized_pkt_cnt = %0d", rdata), UVM_NONE)
        
        phase.drop_objection(this," Dropping Objection to uvm built reset test finished");
    endtask

endclass : reg_function_test
