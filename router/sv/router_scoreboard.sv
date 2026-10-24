class router_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(router_scoreboard)
    `uvm_analysis_imp_decl(_yapp)
    `uvm_analysis_imp_decl(_chan0)
    `uvm_analysis_imp_decl(_chan1)
    `uvm_analysis_imp_decl(_chan2)

    uvm_analysis_imp_yapp #(yapp_packet, router_scoreboard) yapp_in;
    uvm_analysis_imp_chan0 #(channel_packet, router_scoreboard) chan0_in;
    uvm_analysis_imp_chan1 #(channel_packet, router_scoreboard) chan1_in;
    uvm_analysis_imp_chan2 #(channel_packet, router_scoreboard) chan2_in;

    yapp_packet chan0_q[$];
    yapp_packet chan1_q[$];
    yapp_packet chan2_q[$];

    int received_pkt;
    int incorrect_pkt;
    int correct_pkt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        yapp_in = new("yapp_in", this);
        chan0_in = new("chan0_in", this);
        chan1_in = new("chan1_in", this);
        chan2_in = new("chan2_in", this);
    endfunction : new

    function void write_yapp(input yapp_packet yp);
        yapp_packet pkt_cln;
        if(!$cast(pkt_cln, yp.clone()))
            `uvm_fatal("NET", "Failed to cast cloned packet in write_yapp")
        case(pkt_cln.addr)
            2'b00: begin
              chan0_q.push_back(pkt_cln);
              received_pkt++;
            end
            2'b01: begin
              chan1_q.push_back(pkt_cln);
              received_pkt++;
            end
            2'b10: begin
              chan2_q.push_back(pkt_cln);
              received_pkt++;
            end
            default: `uvm_warning("NET", $sformatf("Received packet with invalid address: %0d", pkt_cln.addr))
        endcase
    endfunction : write_yapp

    function bit comp_equal (input yapp_packet yp, input channel_packet cp);
        
      uvm_comparer comparer = new();
      bit status = 1;
      if(yp == null)
            return 0;

      status &= comparer.compare_field("addr", yp.addr, cp.addr, 2);
      status &= comparer.compare_field("length", yp.length, cp.length, 6);
      status &= comparer.compare_field("parity", yp.parity, cp.parity, 8);

      if (yp.payload.size() != cp.payload.size()) begin
          `uvm_error("PKT_COMPARE", $sformatf("Payload size mismatch YAPP %0d Chan %0d", yp.payload.size(), cp.payload.size()))
          status = 0;
      end else begin
          foreach (yp.payload[i]) begin
              status &= comparer.compare_field($sformatf("payload[%0d]", i), yp.payload[i], cp.payload[i], 8);
          end
      end

      if (!status) begin
          `uvm_error("PKT_COMPARE", "Packet comparison failed using uvm_comparer")
          return 0;
      end

      return 1;
    endfunction : comp_equal

    function void write_chan0(input channel_packet cp);
        yapp_packet yp;
        yp = chan0_q.pop_front();
        if(!comp_equal(yp, cp))
            incorrect_pkt++;
        else
            correct_pkt++;
    endfunction : write_chan0

    function void write_chan1(input channel_packet cp);
        yapp_packet yp;
        yp = chan1_q.pop_front();
        if(!comp_equal(yp, cp))
            incorrect_pkt++;
        else
            correct_pkt++;
    endfunction : write_chan1

    function void write_chan2(input channel_packet cp);
        yapp_packet yp;
        yp = chan2_q.pop_front();
        if(!comp_equal(yp, cp))
            incorrect_pkt++;
        else
            correct_pkt++;
    endfunction : write_chan2

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Report: scoreboard received %0d packets", received_pkt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Report: scoreboard received %0d incorrect packets", incorrect_pkt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Report: scoreboard received %0d correct packets", correct_pkt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Report: in queue left %0d packets", chan0_q.size()+chan1_q.size()+chan2_q.size()), UVM_LOW)
    endfunction : report_phase
endclass