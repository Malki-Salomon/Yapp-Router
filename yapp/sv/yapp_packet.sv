/*-----------------------------------------------------------------
File name     : yapp_packet.sv
Description   : lab01_data YAPP UVC packet template file
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

// Define your enumerated type(s) here
typedef enum bit{BAD_PARITY, GOOD_PARITY} parity_type_e;

class yapp_packet extends uvm_sequence_item;

// Follow the lab instructions to create the packet.
// Place the packet declarations in the following order:

  // Define protocol data
  rand bit [1:0] addr;
  rand bit [5:0] length;
  rand bit [7:0] payload [];
       bit [7:0] parity;

  // Define control knobs
  rand parity_type_e parity_type;
  rand int packet_delay;

  // Enable automation of the packet's fields
  `uvm_object_utils_begin(yapp_packet)
    `uvm_field_int (addr, UVM_ALL_ON);
    `uvm_field_int (length, UVM_ALL_ON);
    `uvm_field_array_int (payload, UVM_ALL_ON);
    `uvm_field_int (parity, UVM_ALL_ON);
  `uvm_object_utils_end

  // Define packet constraints
  constraint valid_addr {addr >= 0; addr < 3;}
  constraint payload_size { length == payload.size(); }
  constraint default_length { length > 0; length < 64; }
  constraint correct_parity {parity_type dist {GOOD_PARITY := 5, BAD_PARITY := 1};}
  constraint default_packet_delay {packet_delay inside {[1:20]};}

  function new(string name = "yapp_packet");
    super.new(name);
  endfunction

  // Add methods for parity calculation and class construction
  function bit [7:0] calc_parity();
    calc_parity = {length, addr};
    foreach (payload[i]) begin
      calc_parity = calc_parity ^ payload[i];
    end
  endfunction

  function void set_parity();
    parity = calc_parity();
    if (parity_type == BAD_PARITY)
      parity = ~parity;
  endfunction

  function void post_randomize();
    set_parity();
  endfunction

endclass: yapp_packet


class short_yapp_packet extends yapp_packet;
  `uvm_object_utils(short_yapp_packet)

  constraint default_length {length > 0; length < 15; }
  //constraint valid_addr { addr >= 0; addr < 2; }

  function new(string name = "short_yapp_packet");
    super.new(name);
  endfunction : new
endclass
