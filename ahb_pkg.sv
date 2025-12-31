// File: ahb_pkg.sv
package ahb_pkg;
    
    // HSIZE encoding using typedef enum
    typedef enum logic [2:0] {
        HSIZE_BYTE     = 3'b000,
        HSIZE_HALFWORD = 3'b001,
        HSIZE_WORD     = 3'b010
    } hsize_t;
    
    // HTRANS encoding using typedef enum
    typedef enum logic [1:0] {
        HTRANS_IDLE   = 2'b00,
        HTRANS_BUSY   = 2'b01,
        HTRANS_NONSEQ = 2'b10,
        HTRANS_SEQ    = 2'b11
    } htrans_t;
    
    // HBURST encoding
    typedef enum logic [2:0] {
        HBURST_SINGLE = 3'b000,
        HBURST_INCR   = 3'b001,
        HBURST_WRAP4  = 3'b010,
        HBURST_INCR4  = 3'b011
    } hburst_t;

    // HWRITE encoding
    typedef enum logic {
        HWRITE_READ  = 1'b0,
        HWRITE_WRITE = 1'b1
    } hwrite_t;

endpackage
