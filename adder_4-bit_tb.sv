// UVM Testbench for 4-bit Adder
// Complete UVM verification environment with all components

`include "uvm_macros.svh"
import uvm_pkg::*;

//----------------------------------------------------------------------
// Transaction Class
//----------------------------------------------------------------------
class adder_transaction extends uvm_sequence_item;
    // Input signals
    rand bit [3:0] a;
    rand bit [3:0] b;
    rand bit       cin;
    
    // Output signals
    bit [3:0] sum;
    bit       cout;
    
    `uvm_object_utils_begin(adder_transaction)
        `uvm_field_int(a, UVM_ALL_ON)
        `uvm_field_int(b, UVM_ALL_ON)
        `uvm_field_int(cin, UVM_ALL_ON)
        `uvm_field_int(sum, UVM_ALL_ON)
        `uvm_field_int(cout, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "adder_transaction");
        super.new(name);
    endfunction
endclass

//----------------------------------------------------------------------
// Sequence Class
//----------------------------------------------------------------------
class adder_sequence extends uvm_sequence#(adder_transaction);
    `uvm_object_utils(adder_sequence)
    
    // Number of random transactions to generate
    int count = 50;

    function new(string name = "adder_sequence");
        super.new(name);
    endfunction
    
    task body();
        adder_transaction tx;
        
        repeat(count) begin
            tx = adder_transaction::type_id::create("tx");
            start_item(tx);
            assert(tx.randomize());
            finish_item(tx);
        end
    endtask
endclass

//----------------------------------------------------------------------
// Directed Test Sequence - Corner Cases
//----------------------------------------------------------------------
class adder_directed_sequence extends uvm_sequence#(adder_transaction);
    `uvm_object_utils(adder_directed_sequence)
    
    function new(string name = "adder_directed_sequence");
        super.new(name);
    endfunction
    
    task body();
        adder_transaction tx;
        
        // Test case 1: All zeros
        tx = adder_transaction::type_id::create("tx");
        start_item(tx);
        tx.a = 4'b0000; tx.b = 4'b0000; tx.cin = 0;
        finish_item(tx);
        
        // Test case 2: All ones
        tx = adder_transaction::type_id::create("tx");
        start_item(tx);
        tx.a = 4'b1111; tx.b = 4'b1111; tx.cin = 1;
        finish_item(tx);
        
        // Test case 3: Maximum with no carry in
        tx = adder_transaction::type_id::create("tx");
        start_item(tx);
        tx.a = 4'b1111; tx.b = 4'b1111; tx.cin = 0;
        finish_item(tx);
        
        // Test case 4: Simple addition
        tx = adder_transaction::type_id::create("tx");
        start_item(tx);
        tx.a = 4'b0101; tx.b = 4'b0011; tx.cin = 0;
        finish_item(tx);
        
        // Test case 5: Carry propagation
        tx = adder_transaction::type_id::create("tx");
        start_item(tx);
        tx.a = 4'b1000; tx.b = 4'b1000; tx.cin = 0;
        finish_item(tx);
    endtask
endclass

//----------------------------------------------------------------------
// Sequencer
//----------------------------------------------------------------------
class adder_sequencer extends uvm_sequencer#(adder_transaction);
    `uvm_component_utils(adder_sequencer)
    
    function new(string name = "adder_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

//----------------------------------------------------------------------
// Driver
//----------------------------------------------------------------------
class adder_driver extends uvm_driver#(adder_transaction);
    `uvm_component_utils(adder_driver)
    
    virtual adder_if vif;
    
    function new(string name = "adder_driver", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual adder_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction
    
    task run_phase(uvm_phase phase);
        adder_transaction tx;
        
        forever begin
            seq_item_port.get_next_item(tx);
            drive_transaction(tx);
            seq_item_port.item_done();
        end
    endtask
    
    task drive_transaction(adder_transaction tx);
        @(posedge vif.clk);
        vif.a   <= tx.a;
        vif.b   <= tx.b;
        vif.cin <= tx.cin;
    endtask
endclass

//----------------------------------------------------------------------
// Monitor
//----------------------------------------------------------------------
class adder_monitor extends uvm_monitor;
    `uvm_component_utils(adder_monitor)
    
    virtual adder_if vif;
    uvm_analysis_port#(adder_transaction) ap;
    
    function new(string name = "adder_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if(!uvm_config_db#(virtual adder_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction
    
    task run_phase(uvm_phase phase);
        adder_transaction tx;
        
        forever begin
            @(posedge vif.clk);
            tx = adder_transaction::type_id::create("tx");
            tx.a    = vif.a;
            tx.b    = vif.b;
            tx.cin  = vif.cin;
            tx.sum  = vif.sum;
            tx.cout = vif.cout;
            ap.write(tx);
        end
    endtask
endclass

//----------------------------------------------------------------------
// Scoreboard
//----------------------------------------------------------------------
class adder_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(adder_scoreboard)
    
    uvm_analysis_imp#(adder_transaction, adder_scoreboard) ap_imp;
    
    int pass_count = 0;
    int fail_count = 0;
    
    function new(string name = "adder_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
    endfunction
    
    function void write(adder_transaction tx);
        bit [4:0] expected_result;
        bit [3:0] expected_sum;
        bit       expected_cout;
        
        // Calculate expected values
        expected_result = tx.a + tx.b + tx.cin;
        expected_sum    = expected_result[3:0];
        expected_cout   = expected_result[4];
        
        // Compare with actual values
        if(tx.sum === expected_sum && tx.cout === expected_cout) begin
            `uvm_info("SCOREBOARD", $sformatf("PASS: a=%0d, b=%0d, cin=%0d | sum=%0d, cout=%0d", 
                      tx.a, tx.b, tx.cin, tx.sum, tx.cout), UVM_MEDIUM)
            pass_count++;
        end else begin
            `uvm_error("SCOREBOARD", $sformatf("FAIL: a=%0d, b=%0d, cin=%0d | Expected: sum=%0d, cout=%0d | Got: sum=%0d, cout=%0d", 
                       tx.a, tx.b, tx.cin, expected_sum, expected_cout, tx.sum, tx.cout))
            fail_count++;
        end
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD", $sformatf("\n========== Test Results =========="), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Total Tests: %0d", pass_count + fail_count), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Passed:      %0d", pass_count), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Failed:      %0d", fail_count), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("==================================\n"), UVM_NONE)
        
        if(fail_count == 0)
            `uvm_info("SCOREBOARD", "*** TEST PASSED ***", UVM_NONE)
        else
            `uvm_error("SCOREBOARD", "*** TEST FAILED ***")
    endfunction
endclass

//----------------------------------------------------------------------
// Agent
//----------------------------------------------------------------------
class adder_agent extends uvm_agent;
    `uvm_component_utils(adder_agent)
    
    adder_driver    driver;
    adder_monitor   monitor;
    adder_sequencer sequencer;
    
    function new(string name = "adder_agent", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = adder_driver::type_id::create("driver", this);
        monitor   = adder_monitor::type_id::create("monitor", this);
        sequencer = adder_sequencer::type_id::create("sequencer", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_port);
    endfunction
endclass

//----------------------------------------------------------------------
// Environment
//----------------------------------------------------------------------
class adder_env extends uvm_env;
    `uvm_component_utils(adder_env)
    
    adder_agent      agent;
    adder_scoreboard scoreboard;
    
    function new(string name = "adder_env", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = adder_agent::type_id::create("agent", this);
        scoreboard = adder_scoreboard::type_id::create("scoreboard", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.ap_imp);
    endfunction
endclass

//----------------------------------------------------------------------
// Test Class
//----------------------------------------------------------------------
class adder_test extends uvm_test;
    `uvm_component_utils(adder_test)
    
    adder_env env;
    
    function new(string name = "adder_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = adder_env::type_id::create("env", this);
    endfunction
    
    task run_phase(uvm_phase phase);
        adder_sequence seq;
        
        phase.raise_objection(this);
        
        seq = adder_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        phase.drop_objection(this);
    endtask
endclass

//----------------------------------------------------------------------
// Directed Test Class
//----------------------------------------------------------------------
class adder_directed_test extends uvm_test;
    `uvm_component_utils(adder_directed_test)
    
    adder_env env;
    
    function new(string name = "adder_directed_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = adder_env::type_id::create("env", this);
    endfunction
    
    task run_phase(uvm_phase phase);
        adder_directed_sequence seq;
        
        phase.raise_objection(this);
        
        seq = adder_directed_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        phase.drop_objection(this);
    endtask
endclass

//----------------------------------------------------------------------
// Interface
//----------------------------------------------------------------------
interface adder_if;
    logic        clk;
    logic [3:0]  a;
    logic [3:0]  b;
    logic        cin;
    logic [3:0]  sum;
    logic        cout;
endinterface

//----------------------------------------------------------------------
// Top Module (Testbench Top)
//----------------------------------------------------------------------
module tb_top;
    
    // Clock generation
    bit clk;
    always #5 clk = ~clk;
    
    // Interface instantiation
    adder_if vif();
    assign vif.clk = clk;
    
    // DUT instantiation
    adder_4bit dut (
        .a(vif.a),
        .b(vif.b),
        .cin(vif.cin),
        .sum(vif.sum),
        .cout(vif.cout)
    );
    
    // UVM configuration and test execution
    initial begin
        uvm_config_db#(virtual adder_if)::set(null, "*", "vif", vif);
        
        // Run the test
        run_test("adder_test");
        // To run directed test, use: run_test("adder_directed_test");
    end
    
    // Waveform dumping (for simulation tools that support VCD)
    initial begin
        $dumpfile("adder_4bit.vcd");
        $dumpvars(0, tb_top);
    end
    
endmodule
