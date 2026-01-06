import ahb_pkg::*;

module Master_tb;
    // Clock and reset
    logic HCLK;
    logic HRESETn;
    
    // Signals from slave to master
    logic HREADY;
    logic HRESP;
    logic [31:0] HRDATA;
    
    // Testbench control signals
    logic test_start_transfer;
    logic [31:0] test_HADDR;
    hwrite_t test_HWRITE;
    hsize_t test_HSIZE;
    hburst_t test_HBURST;
    htrans_t test_HTRANS;
    logic [31:0] test_HWDATA;
    
    // Signals from master
    logic [31:0] HADDR;
    hwrite_t HWRITE;
    hsize_t HSIZE;
    hburst_t HBURST;
    htrans_t HTRANS;
    logic [31:0] HWDATA;
    
    // Instantiate Master
    Master dut (.*);
    
    // Clock generation
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end
    
    //==========================================================================
    // REUSABLE TASKS
    //==========================================================================
    
    // Task: Initialize testbench
    task automatic init_tb();
        HRESETn = 0;
        HREADY = 1;
        HRESP = 0;
        HRDATA = 0;
        test_start_transfer = 1;
        test_HTRANS = HTRANS_IDLE;
        test_HADDR = 0;
        test_HWRITE = HWRITE_READ;
        test_HSIZE = HSIZE_BYTE;
        test_HBURST = HBURST_SINGLE;
        test_HWDATA = 0;
    endtask
    
    // Task: Apply reset
    task automatic apply_reset(int cycles = 2);
        HRESETn = 0;
        repeat(cycles) @(posedge HCLK);
        HRESETn = 1;
        @(posedge HCLK);
    endtask
    
    // Task: Drive a single AHB transfer
    task automatic drive_transfer(
        input logic [31:0] addr,
        input hwrite_t wr,
        input hsize_t size,
        input hburst_t burst,
        input htrans_t trans,
        input logic [31:0] wdata = 0,
        input logic ready = 1
    );
        test_HADDR = addr;
        test_HWRITE = wr;
        test_HSIZE = size;
        test_HBURST = burst;
        test_HTRANS = trans;
        test_HWDATA = wdata;
        HREADY = ready;
        @(posedge HCLK);
    endtask
    
    // Task: Insert wait states
    task automatic insert_wait_states(int num_cycles);
        HREADY = 0;
        repeat(num_cycles) @(posedge HCLK);
        HREADY = 1;
    endtask
    
    // Task: Complete WRAP4 burst
    task automatic wrap4_burst_write(
        input logic [31:0] base_addr,
        input hsize_t size,
        input logic [31:0] data[4]
    );
        // First transfer - NONSEQ
        drive_transfer(base_addr, HWRITE_WRITE, size, HBURST_WRAP4, HTRANS_NONSEQ);
        
        // Remaining transfers - SEQ
        for (int i = 0; i < 3; i++) begin
            logic [31:0] next_addr = base_addr + ((i+1) * (1 << size));
            drive_transfer(next_addr, HWRITE_WRITE, size, HBURST_WRAP4, HTRANS_SEQ, data[i]);
        end
        
        // Last data
        drive_transfer(0, HWRITE_READ, size, HBURST_SINGLE, HTRANS_IDLE, data[3]);
    endtask
    
    //==========================================================================
    // TEST CASES
    //==========================================================================
    
    // Test 1: Basic WRAP4 with wait states
    task automatic test_wrap4_with_wait();
        $display("\n[TEST] WRAP4 burst with wait states");
        
        init_tb();
        apply_reset();
        
        drive_transfer(32'h0000_0038, HWRITE_WRITE, HSIZE_WORD, HBURST_WRAP4, HTRANS_NONSEQ);
        drive_transfer(32'h0000_003C, HWRITE_WRITE, HSIZE_WORD, HBURST_WRAP4, HTRANS_SEQ, 32'hAAAA_AAAA, 0);
        drive_transfer(32'h0000_003C, HWRITE_WRITE, HSIZE_WORD, HBURST_WRAP4, HTRANS_SEQ, 32'hAAAA_AAAA);
        
        // Wait state inserted by slave
        //@(posedge HCLK);
        //HREADY = 1;
        
        drive_transfer(32'h0000_0030, HWRITE_WRITE, HSIZE_WORD, HBURST_WRAP4, HTRANS_SEQ, 32'hBBBB_BBBB);
        drive_transfer(32'h0000_0034, HWRITE_WRITE, HSIZE_WORD, HBURST_WRAP4, HTRANS_SEQ, 32'hCCCC_CCCC);
        drive_transfer(32'h0000_0000, HWRITE_READ, HSIZE_WORD, HBURST_SINGLE, HTRANS_IDLE, 32'hDDDD_DDDD);
        
        #20;
        $display("[TEST] WRAP4 test completed\n");
    endtask
    
    // Test 2: Simple single transfers
    task automatic test_single_transfers();
        $display("\n[TEST] Single transfers");
        
        init_tb();
        apply_reset();
        
        // Write
        drive_transfer(32'h0000_1000, HWRITE_WRITE, HSIZE_WORD, HBURST_SINGLE, HTRANS_NONSEQ, 32'h1234_5678);
        drive_transfer(0, HWRITE_READ, HSIZE_BYTE, HBURST_SINGLE, HTRANS_IDLE);
        
        // Read
        drive_transfer(32'h0000_1000, HWRITE_READ, HSIZE_WORD, HBURST_SINGLE, HTRANS_NONSEQ);
        drive_transfer(0, HWRITE_READ, HSIZE_BYTE, HBURST_SINGLE, HTRANS_IDLE);
        
        #20;
        $display("[TEST] Single transfers completed\n");
    endtask
    
    // Test 3: INCR4 burst
    task automatic test_incr4_burst();
        $display("\n[TEST] INCR4 burst");
        
        init_tb();
        apply_reset();
        
        drive_transfer(32'h0000_0038, HWRITE_WRITE, HSIZE_WORD, HBURST_INCR4, HTRANS_NONSEQ);
        drive_transfer(32'h0000_003C, HWRITE_WRITE, HSIZE_WORD, HBURST_INCR4, HTRANS_SEQ, 32'h1111_1111, 0);
        drive_transfer(32'h0000_003C, HWRITE_WRITE, HSIZE_WORD, HBURST_INCR4, HTRANS_SEQ, 32'h1111_1111);
        drive_transfer(32'h0000_0040, HWRITE_WRITE, HSIZE_WORD, HBURST_INCR4, HTRANS_SEQ, 32'h2222_2222);
        drive_transfer(32'h0000_0044, HWRITE_WRITE, HSIZE_WORD, HBURST_INCR4, HTRANS_SEQ, 32'h3333_3333);
        drive_transfer(0, HWRITE_READ, HSIZE_BYTE, HBURST_SINGLE, HTRANS_IDLE, 32'h4444_4444);
        
        #20;
        $display("[TEST] INCR4 test completed\n");
    endtask

    //==========================================================================
    // MAIN TEST EXECUTION
    //==========================================================================
    
    initial begin
        // Run all tests
        test_incr4_burst();
        
        // Add more tests as needed
        
        $display("All tests completed");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, Master_tb);
    end
    
endmodule