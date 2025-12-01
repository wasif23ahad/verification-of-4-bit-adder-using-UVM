# 4-Bit Adder UVM Verification Environment

## Project Overview

This project implements a complete **Universal Verification Methodology (UVM)** based testbench for verifying a 4-bit adder design. The project demonstrates industry-standard verification practices using SystemVerilog and UVM, providing a robust framework for functional verification of digital arithmetic circuits.

### Key Features
- ✅ Synthesizable 4-bit adder RTL design
- ✅ Complete UVM verification environment
- ✅ Randomized and directed test scenarios
- ✅ Self-checking scoreboard with automated result verification
- ✅ Modular, reusable verification components
- ✅ Comprehensive coverage of corner cases

---

## Project Structure

```
4bitAdder-UVM/
├── adder_4-bit.sv       # RTL design (DUT - Design Under Test)
├── adder_4-bit_tb.sv    # UVM testbench
└── README.md            # This file
```

---

## Design Under Test (DUT)

### File: `adder_4-bit.sv`

The DUT is a simple combinational 4-bit adder with carry propagation.

#### Module Interface

```systemverilog
module adder_4bit (
    input  logic [3:0] a,      // First 4-bit operand
    input  logic [3:0] b,      // Second 4-bit operand
    input  logic       cin,    // Carry input
    output logic [3:0] sum,    // 4-bit sum output
    output logic       cout    // Carry output
);
```

#### Functionality

The adder performs the operation: **`{cout, sum} = a + b + cin`**

- **Inputs:**
  - `a[3:0]`: First operand (0-15)
  - `b[3:0]`: Second operand (0-15)
  - `cin`: Carry input (0 or 1)

- **Outputs:**
  - `sum[3:0]`: Lower 4 bits of the result
  - `cout`: Carry output (overflow bit)

#### Implementation Details

```systemverilog
logic [4:0] result;
assign result = a + b + cin;    // 5-bit result
assign sum    = result[3:0];    // Lower 4 bits
assign cout   = result[4];      // MSB (carry out)
```

The design uses a 5-bit intermediate result to capture both the sum and carry output, making it a straightforward and efficient implementation.

---

## UVM Testbench Architecture

### File: `adder_4-bit_tb.sv`

The testbench follows the standard UVM architecture with a layered, modular approach.

### Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│                  UVM Test                       │
│  ┌───────────────────────────────────────────┐  │
│  │         UVM Environment                   │  │
│  │  ┌─────────────────┐  ┌────────────────┐ │  │
│  │  │   UVM Agent     │  │  Scoreboard    │ │  │
│  │  │ ┌─────────────┐ │  └────────────────┘ │  │
│  │  │ │  Sequencer  │ │                     │  │
│  │  │ └─────────────┘ │                     │  │
│  │  │ ┌─────────────┐ │                     │  │
│  │  │ │   Driver    │───────┐               │  │
│  │  │ └─────────────┘ │     │               │  │
│  │  │ ┌─────────────┐ │     │               │  │
│  │  │ │   Monitor   │───┐   │               │  │
│  │  │ └─────────────┘ │ │   │               │  │
│  │  └─────────────────┘ │   │               │  │
│  └──────────────────────┼───┼───────────────┘  │
└─────────────────────────┼───┼──────────────────┘
                          │   │
                    ┌─────▼───▼──────┐
                    │   Interface    │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │      DUT        │
                    │  (4-bit Adder)  │
                    └─────────────────┘
```

---

## UVM Components Explained

### 1. Transaction Class (`adder_transaction`)

The transaction class defines the data items that flow through the testbench.

```systemverilog
class adder_transaction extends uvm_sequence_item;
    rand bit [3:0] a;      // Randomizable input
    rand bit [3:0] b;      // Randomizable input
    rand bit       cin;    // Randomizable carry in
    bit [3:0] sum;         // Output from DUT
    bit       cout;        // Output from DUT
    
    `uvm_object_utils_begin(adder_transaction)
        `uvm_field_int(a, UVM_ALL_ON)
        `uvm_field_int(b, UVM_ALL_ON)
        `uvm_field_int(cin, UVM_ALL_ON)
        `uvm_field_int(sum, UVM_ALL_ON)
        `uvm_field_int(cout, UVM_ALL_ON)
    `uvm_object_utils_end
endclass
```

**Key Points:**
- `rand` keyword enables randomization for inputs
- `uvm_field_int` macros provide automatic print, copy, compare functions
- Extends `uvm_sequence_item` for sequence/driver communication

---

### 2. Sequence Classes

#### Random Sequence (`adder_sequence`)

Generates randomized test transactions for comprehensive coverage.

```systemverilog
task body();
    adder_transaction tx;
    repeat(20) begin
        tx = adder_transaction::type_id::create("tx");
        start_item(tx);
        assert(tx.randomize());  // Randomize all rand fields
        finish_item(tx);
    end
endtask
```

**Features:**
- Generates 20 random test cases
- Uses SystemVerilog randomization
- Tests various input combinations

#### Directed Sequence (`adder_directed_sequence`)

Targets specific corner cases and boundary conditions.

```systemverilog
task body();
    // Test case 1: All zeros (0 + 0 + 0)
    tx.a = 4'b0000; tx.b = 4'b0000; tx.cin = 0;
    
    // Test case 2: Maximum overflow (15 + 15 + 1 = 31)
    tx.a = 4'b1111; tx.b = 4'b1111; tx.cin = 1;
    
    // Test case 3: Boundary test (15 + 15 + 0 = 30)
    tx.a = 4'b1111; tx.b = 4'b1111; tx.cin = 0;
    
    // Additional corner cases...
endtask
```

**Corner Cases Covered:**
1. **Minimum values:** All inputs zero
2. **Maximum overflow:** All inputs at maximum
3. **Carry propagation:** Tests carry chain behavior
4. **Boundary conditions:** Edge cases for sum/carry

---

### 3. Sequencer (`adder_sequencer`)

Acts as an arbiter between sequences and the driver.

```systemverilog
class adder_sequencer extends uvm_sequencer#(adder_transaction);
    `uvm_component_utils(adder_sequencer)
endclass
```

**Role:**
- Manages sequence execution
- Provides transactions to the driver
- Handles multiple sequences if needed

---

### 4. Driver (`adder_driver`)

Converts transactions into pin-level activity on the DUT interface.

```systemverilog
task drive_transaction(adder_transaction tx);
    @(posedge vif.clk);      // Wait for clock edge
    vif.a   <= tx.a;          // Drive inputs
    vif.b   <= tx.b;
    vif.cin <= tx.cin;
    @(posedge vif.clk);      // Wait for DUT to process
endtask
```

**Responsibilities:**
- Gets transactions from sequencer via TLM port
- Drives stimulus to DUT through virtual interface
- Synchronizes with clock signals

---

### 5. Monitor (`adder_monitor`)

Observes DUT pins and collects transactions for analysis.

```systemverilog
task run_phase(uvm_phase phase);
    forever begin
        @(posedge vif.clk);
        tx.a   = vif.a;       // Capture inputs
        tx.b   = vif.b;
        tx.cin = vif.cin;
        @(posedge vif.clk);
        tx.sum  = vif.sum;    // Capture outputs
        tx.cout = vif.cout;
        ap.write(tx);         // Send to scoreboard
    end
endtask
```

**Functions:**
- Protocol-aware signal observation
- Non-intrusive monitoring (read-only)
- Broadcasts transactions via analysis port

---

### 6. Scoreboard (`adder_scoreboard`)

Implements self-checking mechanism with reference model.

```systemverilog
function void write(adder_transaction tx);
    // Reference model (golden reference)
    bit [4:0] expected_result = tx.a + tx.b + tx.cin;
    bit [3:0] expected_sum    = expected_result[3:0];
    bit       expected_cout   = expected_result[4];
    
    // Compare actual vs expected
    if(tx.sum === expected_sum && tx.cout === expected_cout) begin
        `uvm_info("SCOREBOARD", "PASS: ...", UVM_MEDIUM)
        pass_count++;
    end else begin
        `uvm_error("SCOREBOARD", "FAIL: ...", UVM_MEDIUM)
        fail_count++;
    end
endfunction
```

**Key Features:**
- **Reference Model:** Software implementation of expected behavior
- **Automated Checking:** Compares DUT output with golden reference
- **Statistical Reporting:** Tracks pass/fail counts
- **Detailed Logging:** Reports mismatches with expected vs actual values

**Report Phase Output:**
```
========== Test Results ==========
Total Tests: 20
Passed:      20
Failed:      0
==================================
*** TEST PASSED ***
```

---

### 7. Agent (`adder_agent`)

Encapsulates driver, monitor, and sequencer into a reusable component.

```systemverilog
class adder_agent extends uvm_agent;
    adder_driver    driver;
    adder_monitor   monitor;
    adder_sequencer sequencer;
    
    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_port);
    endfunction
endclass
```

**Purpose:**
- Groups related components
- Provides clean interface to environment
- Enhances reusability across projects

---

### 8. Environment (`adder_env`)

Top-level container for all verification components.

```systemverilog
class adder_env extends uvm_env;
    adder_agent      agent;
    adder_scoreboard scoreboard;
    
    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(scoreboard.ap_imp);
    endfunction
endclass
```

**Connections:**
- Links monitor's analysis port to scoreboard
- Configures agent and scoreboard
- Manages component hierarchy

---

### 9. Test Classes

#### Base Test (`adder_test`)

Executes random stimulus generation.

```systemverilog
task run_phase(uvm_phase phase);
    phase.raise_objection(this);   // Keep simulation alive
    
    seq = adder_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #100;  // Additional settling time
    phase.drop_objection(this);    // End simulation
endtask
```

#### Directed Test (`adder_directed_test`)

Runs corner-case scenarios.

```systemverilog
task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq = adder_directed_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #100;
    phase.drop_objection(this);
endtask
```

---

### 10. Interface (`adder_if`)

Provides abstraction between testbench and DUT.

```systemverilog
interface adder_if;
    logic        clk;
    logic [3:0]  a, b;
    logic        cin;
    logic [3:0]  sum;
    logic        cout;
endinterface
```

**Benefits:**
- Clean separation of concerns
- Easier protocol changes
- Simplified driver/monitor implementation

---

### 11. Testbench Top (`tb_top`)

Instantiates and connects all components.

```systemverilog
module tb_top;
    // Clock generation
    bit clk;
    always #5 clk = ~clk;  // 10ns period (100MHz)
    
    // Interface and DUT instantiation
    adder_if vif();
    assign vif.clk = clk;
    
    adder_4bit dut (
        .a(vif.a),
        .b(vif.b),
        .cin(vif.cin),
        .sum(vif.sum),
        .cout(vif.cout)
    );
    
    // Configure and run UVM test
    initial begin
        uvm_config_db#(virtual adder_if)::set(null, "*", "vif", vif);
        run_test("adder_test");
    end
endmodule
```

**Components:**
- **Clock Generator:** Creates 100MHz clock
- **Interface Instance:** Connects testbench to DUT
- **DUT Instance:** The design being verified
- **UVM Configuration:** Makes interface accessible to all components
- **Test Execution:** Launches the selected test

---

## Simulation Flow

### Execution Sequence

1. **Elaboration Phase**
   - Compile RTL and testbench
   - Build UVM component hierarchy
   - Configure virtual interfaces

2. **Build Phase**
   - Create all UVM components
   - Retrieve configuration from database

3. **Connect Phase**
   - Connect TLM ports (driver ↔ sequencer)
   - Connect analysis ports (monitor → scoreboard)

4. **Run Phase**
   - Generate clock
   - Execute sequences
   - Drive stimulus (Driver)
   - Monitor signals (Monitor)
   - Check results (Scoreboard)

5. **Report Phase**
   - Display test statistics
   - Report pass/fail status

---

## How to Run

### Prerequisites
- SystemVerilog simulator (QuestaSim, VCS, Xcelium, etc.)
- UVM library (usually included with modern simulators)

### Compilation & Simulation

#### Using QuestaSim/ModelSim
```bash
# Compile source files
vlog adder_4-bit.sv adder_4-bit_tb.sv

# Run simulation (random test)
vsim -c tb_top -do "run -all; quit"

# Run simulation (directed test)
vsim -c tb_top +UVM_TESTNAME=adder_directed_test -do "run -all; quit"

# GUI mode with waveforms
vsim tb_top
run -all
```

#### Using Synopsys VCS
```bash
# Compile and run
vcs -sverilog +incdir+$UVM_HOME/src $UVM_HOME/src/uvm.sv \
    adder_4-bit.sv adder_4-bit_tb.sv -R

# Run directed test
./simv +UVM_TESTNAME=adder_directed_test
```

#### Using Cadence Xcelium
```bash
# Compile and run (random test)
xrun -uvm adder_4-bit.sv adder_4-bit_tb.sv

# Run directed test
xrun -uvm adder_4-bit.sv adder_4-bit_tb.sv +UVM_TESTNAME=adder_directed_test
```

---

## Test Selection

The testbench supports multiple test types. Select a test by modifying the `run_test()` call in `tb_top`:

```systemverilog
// Random test (default)
run_test("adder_test");

// Directed test (corner cases)
run_test("adder_directed_test");
```

Or use command-line option:
```bash
+UVM_TESTNAME=adder_directed_test
```

---

## Verification Strategy

### Coverage Goals

1. **Functional Coverage**
   - All possible 4-bit input combinations
   - Carry input variations (0 and 1)
   - Overflow conditions

2. **Corner Cases**
   - Minimum: `0 + 0 + 0 = 0`
   - Maximum: `15 + 15 + 1 = 31` (overflow)
   - Carry propagation scenarios

3. **Code Coverage**
   - 100% line coverage
   - 100% branch coverage (if any)

### Test Scenarios

| Test Case | a    | b    | cin | Expected Sum | Expected Cout | Description |
|-----------|------|------|-----|--------------|---------------|-------------|
| 1         | 0000 | 0000 | 0   | 0000         | 0             | All zeros   |
| 2         | 1111 | 1111 | 1   | 1111         | 1             | Max overflow|
| 3         | 1111 | 1111 | 0   | 1110         | 1             | Near max    |
| 4         | 0101 | 0011 | 0   | 1000         | 0             | Simple add  |
| 5         | 1000 | 1000 | 0   | 0000         | 1             | Carry out   |
| Random    | X    | X    | X   | Computed     | Computed      | 20 random   |

---

## Output Examples

### Successful Test Output
```
UVM_INFO @ 0: reporter [RNTST] Running test adder_test...
UVM_INFO @ 25: uvm_test_top.env.scoreboard [SCOREBOARD] PASS: a=7, b=3, cin=0 | sum=10, cout=0
UVM_INFO @ 35: uvm_test_top.env.scoreboard [SCOREBOARD] PASS: a=15, b=1, cin=1 | sum=1, cout=1
...
UVM_INFO @ 500: uvm_test_top.env.scoreboard [SCOREBOARD]
========== Test Results ==========
Total Tests: 20
Passed:      20
Failed:      0
==================================

UVM_INFO @ 500: uvm_test_top.env.scoreboard [SCOREBOARD] *** TEST PASSED ***
```

### Failed Test Example (if bug exists)
```
UVM_ERROR @ 45: uvm_test_top.env.scoreboard [SCOREBOARD] FAIL: a=8, b=8, cin=0 | 
    Expected: sum=0, cout=1 | Got: sum=0, cout=0
```

---

## Key UVM Concepts Demonstrated

### 1. **Transaction-Level Modeling (TLM)**
   - Sequences produce transactions
   - Driver consumes transactions
   - Monitor broadcasts transactions
   - Scoreboard analyzes transactions

### 2. **Phased Execution**
   - Build → Connect → Run → Report
   - Ensures proper component initialization

### 3. **Configuration Database**
   - Virtual interface shared across components
   - Decouples testbench from DUT

### 4. **Factory Pattern**
   - Dynamic object creation with `type_id::create()`
   - Enables test/sequence overrides

### 5. **Objections Mechanism**
   - `raise_objection()` prevents simulation end
   - `drop_objection()` allows completion

---

## Project Style & Best Practices

### Coding Standards

1. **Naming Conventions**
   - Classes: `snake_case` with component suffix (e.g., `adder_driver`)
   - Variables: `snake_case` (e.g., `pass_count`)
   - Constants: `UPPER_CASE`

2. **Modularity**
   - Each UVM component in separate class
   - Clear separation of concerns
   - Reusable agents and environments

3. **Documentation**
   - Inline comments for complex logic
   - Header comments for each class
   - Descriptive variable names

4. **Error Handling**
   - Fatal errors for missing interfaces
   - Errors for functional failures
   - Info messages for debug traces

---

## Extending the Testbench

### Adding New Test Scenarios

```systemverilog
class my_custom_sequence extends uvm_sequence#(adder_transaction);
    `uvm_object_utils(my_custom_sequence)
    
    task body();
        // Implement custom test logic
    endtask
endclass

class my_custom_test extends uvm_test;
    task run_phase(uvm_phase phase);
        my_custom_sequence seq;
        phase.raise_objection(this);
        seq = my_custom_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass
```

### Adding Functional Coverage

```systemverilog
covergroup adder_cov;
    a_cp: coverpoint tx.a;
    b_cp: coverpoint tx.b;
    cin_cp: coverpoint tx.cin;
    cross_cov: cross a_cp, b_cp, cin_cp;
endgroup
```

---

## Troubleshooting

### Common Issues

1. **"Virtual interface not found"**
   - Ensure `uvm_config_db::set()` is called before `run_test()`
   - Check interface name matches in get/set calls

2. **Simulation hangs**
   - Verify `raise_objection()` has matching `drop_objection()`
   - Check clock generation is active

3. **Compilation errors**
   - Include UVM library path
   - Use `+incdir+$UVM_HOME/src` flag

4. **No output displayed**
   - Set UVM verbosity: `+UVM_VERBOSITY=UVM_HIGH`
   - Check report phase messages

---

## Future Enhancements

- ✨ Add functional coverage collection
- ✨ Implement constrained randomization
- ✨ Add assertion-based verification (SVA)
- ✨ Create regression suite
- ✨ Add timing checks for setup/hold violations
- ✨ Implement different agent configurations (active/passive)

---

## References

- [UVM 1.2 User Guide](https://www.accellera.org/downloads/standards/uvm)
- [SystemVerilog IEEE 1800-2017](https://standards.ieee.org/standard/1800-2017.html)
- [Verification Academy](https://verificationacademy.com/)

---

## License

This project is provided as-is for educational and verification learning purposes.

---

## Author

Mohammad Wasif Ahad

**Date:** 1st December, 2025

---

## Conclusion

This project serves as a comprehensive template for UVM-based verification, demonstrating:
- ✅ Industry-standard verification practices
- ✅ Modular, scalable testbench architecture  
- ✅ Self-checking methodology with reference models
- ✅ Randomized and directed testing strategies
- ✅ Professional coding standards and documentation

The testbench can be easily extended and adapted for more complex designs, making it an excellent starting point for learning UVM or verifying arithmetic circuits.
