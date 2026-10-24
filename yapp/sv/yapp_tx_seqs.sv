/*-----------------------------------------------------------------
File name     : yapp_tx_seqs.sv
Developers    : Kathleen Meade, Brian Dickinson
Created       : 01/04/11
Description   : YAPP UVC simple TX test sequence for labs 2 to 4
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

//------------------------------------------------------------------------------
//
// SEQUENCE: base yapp sequence - base sequence with objections from which 
// all sequences can be derived
//
//------------------------------------------------------------------------------
class yapp_base_seq extends uvm_sequence #(yapp_packet);
  
  // Required macro for sequences automation
  `uvm_object_utils(yapp_base_seq)

  // Constructor
  function new(string name="yapp_base_seq");
    super.new(name);
  endfunction

  task pre_body();
    uvm_phase phase;
    `ifdef UVM_VERSION_1_2
      // in UVM1.2, get starting phase from method
      phase = get_starting_phase();
    `else
      phase = starting_phase;
    `endif
    if (phase != null) begin
      phase.raise_objection(this, get_type_name());
      `uvm_info(get_type_name(), "raise objection", UVM_MEDIUM)
    end
  endtask : pre_body

  task post_body();
    uvm_phase phase;
    `ifdef UVM_VERSION_1_2
      // in UVM1.2, get starting phase from method
      phase = get_starting_phase();
    `else
      phase = starting_phase;
    `endif
    if (phase != null) begin
      phase.drop_objection(this, get_type_name());
      `uvm_info(get_type_name(), "drop objection", UVM_MEDIUM)
    end
  endtask : post_body

endclass : yapp_base_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_5_packets
//
//  Configuration setting for this sequence
//    - update <path> to be hierarchial path to sequencer 
//
//  uvm_config_wrapper::set(this, "<path>.run_phase",
//                                 "default_sequence",
//                                 yapp_5_packets::get_type());
//
//------------------------------------------------------------------------------
class yapp_5_packets extends yapp_base_seq;
  
  // Required macro for sequences automation
  `uvm_object_utils(yapp_5_packets)

  // Constructor
  function new(string name="yapp_5_packets");
    super.new(name);
  endfunction

  // Sequence body definition
  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_5_packets sequence", UVM_LOW)
     repeat(5)
      `uvm_do(req)
  endtask
  
endclass : yapp_5_packets

class yapp_1_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_1_seq)

  function new(string name = "yapp_1_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_1_seq sequence", UVM_LOW)
    `uvm_do_with(req, {addr == 1;})
  endtask : body
endclass

class yapp_012_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_012_seq)

  function new(string name = "yapp_012_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_012_seq sequence", UVM_LOW)
    for(int i = 0; i < 3; i++)
      `uvm_do_with(req, {addr == i;})
  endtask : body
endclass

class yapp_111_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_111_seq)    
  yapp_1_seq y_1_seq;

  function new(string name = "yapp_111_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_111_seq sequence", UVM_LOW)
    repeat(3)
      `uvm_do(y_1_seq)
  endtask : body
endclass

class yapp_repeat_addr_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_repeat_addr_seq)    
  rand bit [1:0] seqaddr;
  constraint valid_seqaddr {seqaddr >= 0; seqaddr < 3;}

  function new(string name = "yapp_repeat_addr_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_repeat_addr_seq sequence", UVM_LOW)
    repeat(2)
      `uvm_do_with(req, {addr == seqaddr;})
  endtask : body
endclass

class yapp_incr_payload_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_incr_payload_seq)
  int ok;

  function new(string name = "yapp_incr_payload_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_incr_payload_seq sequence", UVM_LOW)
    `uvm_create(req)
    ok = req.randomize();
    for(int i = 0; i < req.length; i++)
      req.payload[i] = i;
    req.set_parity();
    `uvm_send(req)
  endtask : body
endclass

class yapp_rnd_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_rnd_seq)
  rand int count;
  constraint valid_cnt{count > 0; count <= 10;}

  function new(string name = "yapp_rnd_seq");
    super.new(name);
  endfunction :new

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_rnd_seq sequence", UVM_LOW)
    repeat(count)
      `uvm_do(req)
    `uvm_info(get_type_name(), $sformatf("Randomized local var value: %0d", count), UVM_MEDIUM)
  endtask : body
endclass

class six_yapp_seq extends yapp_base_seq;
  `uvm_object_utils(six_yapp_seq)
  rand int count;
  yapp_rnd_seq y_rnd;
  constraint valid_cnt{count > 0; count <= 6;}

  function new(string name = "six_yapp_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing six_yapp_seq sequence", UVM_LOW)
    repeat(count)
      `uvm_do(y_rnd)
    `uvm_info(get_type_name(), $sformatf("Randomized local var value: %0d", count), UVM_MEDIUM)
  endtask : body
endclass

class yapp_exhausetive_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_exhausetive_seq)
  yapp_1_seq yapp_1;
  yapp_012_seq yapp_012;
  yapp_111_seq yapp_111;
  yapp_repeat_addr_seq yapp_repeat_addr;
  yapp_rnd_seq yapp_rnd;
  six_yapp_seq six_yapp;

  function new(string name = "yapp_exhausetive_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_do(yapp_1)
    `uvm_do(yapp_012)
    `uvm_do(yapp_111)
    `uvm_do(yapp_repeat_addr)
    `uvm_do(yapp_rnd)
    `uvm_do(six_yapp)
  endtask : body
endclass

class seq_with_err extends yapp_base_seq;
  `uvm_object_utils(seq_with_err)

  function new(string name = "seq_with_err");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_integration_seq", UVM_LOW)
    for (int i = 0; i <= 3; i++) begin
      for (int len = 1; len <= 22; len++) begin
        `uvm_create(req)                 
        req.valid_addr.constraint_mode(0);
        req.correct_parity.constraint_mode(0);
        if (!req.randomize() with { addr == i; length == len; payload.size() == len;
                            parity_type dist {BAD_PARITY := 1, GOOD_PARITY := 4}; })
          `uvm_error(get_type_name(), "randomize failed")
        `uvm_send(req)
      end
    end
  endtask : body
endclass

class yapp_cross_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_cross_seq)
  int ok;

  function new(string name = "yapp_cross_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_cross_seq", UVM_LOW)
    for (int len = 1; len <= 63; len++) begin
      for (int a = 0; a <= 3; a++) begin
        for (int p = 0; p < 2; p++) begin
          `uvm_create(req)
          req.valid_addr.constraint_mode(0);
          req.payload_size.constraint_mode(0);
          req.default_length.constraint_mode(0);
          req.correct_parity.constraint_mode(0);
          if (!req.randomize() with { addr == a; length == len; payload.size() == len;
                                      parity_type == (p ? BAD_PARITY : GOOD_PARITY); })
            `uvm_error(get_type_name(), "randomize failed")
          req.set_parity();
          `uvm_send(req)
        end
      end
    end
endtask : body
endclass


