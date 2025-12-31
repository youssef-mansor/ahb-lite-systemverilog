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
    logic test_HWRITE;
    logic [2:0] test_HSIZE;
    logic [2:0] test_HBURST;
    logic [1:0] test_HTRANS;
    logic [31:0] test_HWDATA;

    
    // Signals from master
    logic [31:0] HADDR;
    logic HWRITE;
    logic [2:0] HSIZE;
    logic [2:0] HBURST;
    logic [3:0] HPROT;
    logic [1:0] HTRANS;
    logic HMASTLOCK;
    logic [31:0] HWDATA;
    
    // Instantiate Master
    Master dut (.*);
    
    // Clock generation
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK; // 10ns period
    end
    
    // Test stimulus
    initial begin
        // Initialize
        HRESETn = 0;
        HREADY = 1;  // Slave ready (no wait states)
        HRESP = 0;   // OKAY response
        HRDATA = 0;
        test_start_transfer = 1;
        
        // Reset pulse
        #15 HRESETn = 1;
        
        // Wait for first clock edge after reset
        @(posedge HCLK);
        
        // Clock 1: Address Phase of READ transfer
        // Master should drive: HADDR, HWRITE=0
        // We just observe the master outputs here
        test_HTRANS = HTRANS_NONSEQ;
        test_HADDR = 32'h0000_0038; 
        test_HWRITE = HWRITE_WRITE;
        test_HBURST = HBURST_WRAP4;
        test_HSIZE = HSIZE_WORD;
        HREADY = 1;

        @(posedge HCLK);
        
        // Clock 2
        test_HTRANS = HTRANS_SEQ;
        test_HADDR = 32'h0000_003C;
        test_HWRITE = HWRITE_WRITE;
        HREADY = 0;
        test_HWDATA = 32'hAAAA_AAAA; // Data to be written

        
        @(posedge HCLK);
        // Clock 3
        // Master can not really change stuff here since HREADY=0
        HREADY = 1; // Slave ready again

        @(posedge HCLK);
        // Clock 4
        test_HTRANS = HTRANS_SEQ;
        test_HADDR = 32'h0000_0030; // WRAP4 to 0x30
        test_HWRITE = HWRITE_WRITE;
        test_HWDATA = 32'hBBBB_BBBB; // Data to be written

        @(posedge HCLK);
        // Clock 5
        test_HTRANS = HTRANS_SEQ;
        test_HADDR = 32'h0000_0034; // WRAP4 to 0x34
        test_HWRITE = HWRITE_WRITE;
        test_HWDATA = 32'hCCCC_CCCC; // Data to be written

        @(posedge HCLK);
        // Clock 6: Idle transfer
        test_HTRANS = HTRANS_IDLE;
        test_HADDR = 32'h0000_0000;
        test_HWRITE = HWRITE_READ;
        test_HWDATA = 32'hDDDD_DDDD; // Data to be written

        
        // End simulation
        #20;
        $display("Simulation completed");
        $finish;
    end
    
    // Monitor signals
    initial begin
        $monitor("Time=%0t | HADDR=%h | HWRITE=%b | HRDATA=%h | HREADY=%b", 
                 $time, HADDR, HWRITE, HRDATA, HREADY);
    end
    
    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, Master_tb);
    end
    
endmodule
