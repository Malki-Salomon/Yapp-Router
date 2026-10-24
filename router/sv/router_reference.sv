class router_reference extends uvm_component;
    `uvm_component_utils(router_reference)
    `uvm_analysis_imp_decl(_yapp)
    `uvm_analysis_imp_decl(_hbus)

    uvm_analysis_imp_yapp #(yapp_packet, router_reference) yapp_in;
    uvm_analysis_imp_hbus #(hbus_transaction, router_reference) hbus_in;
    uvm_analysis_port#(yapp_packet) vld_yapp_out;

    bit [5:0] maxpktsize;
    bit router_en;

    int num_drop_unen;
    int num_bigger_pkt;
    int num_n_vld_addr_pkt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        yapp_in = new("yapp_in", this);
        hbus_in = new("hbus_in", this);
        vld_yapp_out = new("vld_yapp_out", this);
    endfunction : new

    function void write_hbus(input hbus_transaction hbus);
        case(hbus.haddr)
            16'h1000: maxpktsize = hbus.hdata[5:0];
            16'h1001: router_en = hbus.hdata[0];
        endcase
    endfunction : write_hbus

    function void write_yapp(input yapp_packet yp);
        if(router_en && yp.length <= maxpktsize && yp.addr >= 0 && yp.addr < 3)
            vld_yapp_out.write(yp);
        else begin
            if(!router_en)
                num_drop_unen++;
            if(yp.addr < 0 || yp.addr > 2)
                num_n_vld_addr_pkt++;
            if(yp.length > maxpktsize)
                num_bigger_pkt++;
        end
    endfunction : write_yapp
endclass