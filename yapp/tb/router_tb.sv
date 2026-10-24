class router_tb extends  uvm_env;
    `uvm_component_utils(router_tb)

    yapp_env uvc;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("ROUTER_TB", "The build phase of the testbench is being executed.", UVM_HIGH);
        uvc = yapp_env::type_id::create("yapp_env", this);
    endfunction : build_phase

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Program in %s", get_type_name()), UVM_HIGH);
    endfunction : start_of_simulation_phase
endclass