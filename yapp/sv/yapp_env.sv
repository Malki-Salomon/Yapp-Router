class yapp_env extends uvm_env;
    `uvm_component_utils(yapp_env)

    yapp_tx_agent agent;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = yapp_tx_agent::type_id::create("agent", this);
    endfunction : build_phase

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Program in %s", get_type_name()), UVM_HIGH);
    endfunction : start_of_simulation_phase
endclass