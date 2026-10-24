class router_simple_mcseq extends uvm_sequence;
    `uvm_object_utils(router_simple_mcseq)
    `uvm_declare_p_sequencer(router_mcsequencer)

    hbus_small_packet_seq small_pkt;
    hbus_read_max_pkt_seq rd_max_pkt;
    yapp_012_seq addr_012;
    hbus_set_default_regs_seq large_pkt;
    six_yapp_seq six_yapp;

    function new(string name = "router_simple_mcseq");
        super.new(name);
    endfunction : new

    virtual task pre_body();
        if(starting_phase != null)
            starting_phase.raise_objection(this, get_type_name());
    endtask : pre_body

    virtual task body();
        `uvm_do_on(small_pkt, p_sequencer.hbus_seqr)
        `uvm_do_on(rd_max_pkt, p_sequencer.hbus_seqr)
        `uvm_do_on(addr_012, p_sequencer.yapp_seqr)
        `uvm_do_on(addr_012, p_sequencer.yapp_seqr)
        `uvm_do_on(large_pkt, p_sequencer.hbus_seqr)
        `uvm_do_on(rd_max_pkt, p_sequencer.hbus_seqr)
        `uvm_do_on(six_yapp, p_sequencer.yapp_seqr)
    endtask : body

    virtual task post_body();
        if (starting_phase != null)
        starting_phase.drop_objection(this, get_type_name());
    endtask : post_body
endclass
