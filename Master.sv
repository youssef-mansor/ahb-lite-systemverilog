import ahb_pkg::*;

// AHB-Lite Master Module: Bus Functional Model (BFM )
module Master(
    /* Inputs */
    // Global Signals
    input logic HCLK,
    input logic HRESETn,
    // Transfer response
    input logic HREADY,
    input logic HRESP,
    // Data
    input logic [31:0] HRDATA,

    /* Outputs */
    // Address and Control
    output logic [31:0] HADDR,
    output logic HWRITE,
    output logic [2:0] HSIZE,
    output logic [2:0] HBURST,
    //output logic [3:0] HPROT,
    output logic [1:0] HTRANS,
    //output logic HMASTLOCK,
    // Data
    output logic [31:0] HWDATA,

    /* Testbench control inputs */
    input logic [31:0] test_HADDR,
    input logic test_HWRITE,
    input logic [2:0] test_HSIZE,
    input logic [2:0] test_HBURST,
    //input logic [3:0] test_HPROT,
    input logic [1:0] test_HTRANS,
    //input logic test_HMASTLOCK,
    input logic [31:0] test_HWDATA,
    input logic test_start_transfer
);

    // State definitions
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        INITIAL = 2'b01,
        PIPELINE = 2'b10
    } state_t;

    // State registers
    state_t previous_state, current_state, next_state;

    // internal signals
    logic prev_HREADY;

    // Sequential logic for state transition
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            current_state <= IDLE;
        end else begin
            previous_state <= current_state;
            current_state <= next_state;
            prev_HREADY <= HREADY;
        end
    end

    // Combinational logic for next state
    always_comb begin
        case (current_state)

            IDLE: begin
                if (HREADY && test_start_transfer) begin
                    next_state = INITIAL;
                end else begin
                    next_state = IDLE;
                end
            end

            INITIAL: begin
                next_state = PIPELINE;
            end

            PIPELINE: begin
                if (test_HTRANS == 2'b00 && HREADY) begin
                    next_state = IDLE;
                end else begin
                    next_state = PIPELINE;
                end
            end

            default: next_state = IDLE;
            
        endcase
    end

    // Output logic based on current state
    always_comb begin

        case (current_state)

            IDLE: begin
                HADDR = 32'b0;
                HWRITE = 1'b0;
                HSIZE = 3'b000;
                HBURST = HBURST_SINGLE;
                HTRANS = HTRANS_IDLE;
                HWDATA = 32'b0;
            end

            INITIAL: begin
                HADDR = test_HADDR;
                HWRITE = test_HWRITE;
                HSIZE = test_HSIZE;
                HBURST = test_HBURST;
                // HTRANS logic
                if (previous_state == IDLE) begin
                    HTRANS = HTRANS_NONSEQ;
                end else begin
                    HTRANS = test_HTRANS;
                end
                HWDATA = test_HWDATA;
            end

            PIPELINE: begin
                HADDR = test_HADDR; // Address remains the same for simplicity
                HWRITE = test_HWRITE;
                HSIZE = test_HSIZE;
                HBURST = test_HBURST;
                HTRANS = test_HTRANS;
                HWDATA = test_HWDATA; // Data remains the same for simplicity
            end

        endcase
    end

    /* SVA Assertions */
    property valid_HSIZE;
        @(posedge HCLK) disable iff (!HRESETn)
        (HSIZE == HSIZE_BYTE || HSIZE == HSIZE_HALFWORD || HSIZE == HSIZE_WORD);
    endproperty

    property addr_alignment;
        @(posedge HCLK) disable iff (!HRESETn)
        (HTRANS != 2'b00) |-> (
            (HSIZE == HSIZE_BYTE) || // Byte - any alignment OK
            (HSIZE == HSIZE_HALFWORD && HADDR[0] == 1'b0) || // Halfword - aligned to 2 bytes
            (HSIZE == HSIZE_WORD && HADDR[1:0] == 2'b00)    // Word - aligned to 4 bytes
        );
    endproperty

    property hold_signals_stable_when_not_ready;
        @(posedge HCLK) disable iff (!HRESETn)
        (prev_HREADY == 1'b0 && HTRANS != HTRANS_IDLE) |-> (
            HADDR == $past(HADDR) &&
            HWRITE == $past(HWRITE) &&
            HSIZE == $past(HSIZE) &&
            HBURST == $past(HBURST) &&
            HTRANS == $past(HTRANS) &&
            HWDATA == $past(HWDATA)
        );
    endproperty

    // Assume properties
    assume property (valid_HSIZE);

    // Assert properties
    assert property (addr_alignment);
    assert property (hold_signals_stable_when_not_ready);
endmodule