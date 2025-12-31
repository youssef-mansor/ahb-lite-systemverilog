// AHB-Lite Slave Module
module Slave(
    /* Inputs */
    // Select
    input logic HSEL,
    // Address and Control
    input logic [31:0] HADDR,
    input logic HWRITE,
    input logic [2:0] HSIZE,
    input logic [2:0] HBURST,
    input logic [3:0] HPROT,
    input logic [1:0] HTRANS,
    input logic HMASTLOCK,
    input logic HREADY,
    // Data
    input logic [31:0] HWDATA,
    // Global Signals
    input logic HCLK,
    input logic HRESETn,

    /* Outputs */
    // Transfer response
    output logic HREADYOUT, // Request extension of the data phase to secure extra time to provide or sample data
    output logic HRESP,
    // Data
    output logic [31:0] HRDATA
);
endmodule