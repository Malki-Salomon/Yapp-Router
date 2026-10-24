class yapp_tx_monitor extends uvm_monitor;
    `uvm_component_utils(yapp_tx_monitor)
    virtual interface yapp_if vif;
    yapp_packet pkt;
    int num_pkt_col;
    uvm_analysis_port#(yapp_packet) item_send_port;
    bit parity_sampled;

    covergroup collect_packet_cg;
        option.per_instance = 1;
        pkt_size : coverpoint pkt.length{
            bins MIN = {1};
            bins MAX = {63};
            bins SMALL = {[2:10]};
            bins MEDIUM = {[11:40]};
            bins LARGE = {[41:62]};
        }

        pkt_addr : coverpoint pkt.addr{
            bins legal = {[0:2]};
            bins illegal = {3};
        }

        pkt_parity : coverpoint pkt.parity_type{
            bins good_parity = {GOOD_PARITY};
            bins bad_parity = {BAD_PARITY};
        }

        req3_cross : cross pkt_size, pkt_addr, pkt_parity{
            ignore_bins illegal_addr_cross = binsof(pkt_addr) intersect {3};
        }
    endgroup : collect_packet_cg

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_send_port = new("item_send_port", this);
        collect_packet_cg = new();
    endfunction : new

    task run_phase(uvm_phase phase);
        @(posedge vif.reset)
        @(negedge vif.reset)
        `uvm_info(get_type_name(), "program in the monitor.", UVM_LOW);
        forever begin 
            // Create collected packet instance
            pkt = yapp_packet::type_id::create("pkt", this);

            // concurrent blocks for packet collection and transaction recording
            fork
                // collect packet
                vif.collect_packet(pkt.length, pkt.addr, pkt.payload, pkt.parity);
                // trigger transaction at start of packet
                @(posedge vif.monstart) void'(begin_tr(pkt, "Monitor_YAPP_Packet"));
            join

            pkt.parity_type = (pkt.parity == pkt.calc_parity()) ? GOOD_PARITY : BAD_PARITY;
            // End transaction recording
            end_tr(pkt);
            `uvm_info(get_type_name(), $sformatf("Packet Collected :\n%s", pkt.sprint()), UVM_LOW)
            item_send_port.write(pkt);
            num_pkt_col++;
            collect_packet_cg.sample();
        end
    endtask : run_phase

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Program in %s", get_type_name()), UVM_HIGH);
    endfunction : start_of_simulation_phase

    function void connect_phase(uvm_phase phase);
        if(!yapp_vif_config::get(this, "", "vif", vif))
            `uvm_error("NOVIF", "vif not set")
    endfunction : connect_phase

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Report: YAPP Monitor Collected %0d Packets", num_pkt_col), UVM_LOW)
    endfunction : report_phase
endclass