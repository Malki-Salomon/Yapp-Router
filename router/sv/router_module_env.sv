class router_module_env extends uvm_env;
    `uvm_component_utils(router_module_env)

    router_scoreboard router_sb;
    router_reference router_ref;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        router_sb = router_scoreboard::type_id::create("router_sb", this);
        router_ref = router_reference::type_id::create("router_ref", this);
    endfunction : new

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        router_ref.vld_yapp_out.connect(router_sb.yapp_in);
    endfunction : connect_phase
endclass