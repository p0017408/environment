//Opcodes

`define NOP	 	4'b0000
`define LOADMEM 	4'b0001
`define READMEM		4'b0010
`define ROTCLKWISE	4'b0011
`define ROTCNTCLKWISE	4'b0100
`define DARKEN		4'b0101
`define LIGHTEN		4'b0110
`define INVERTALL	4'b0111
`define ALLBLACK	4'b1000
`define ALLWHITE	4'b1001
`define ALLGREY         4'b1010
`define CHECKERBOARD    4'b1011
`define ZOOMIN		4'b1100
`define ZOOMOUT		4'b1101
`define CHECKSUM	4'b1110
`define READSTAT	4'b1111


`define PIXELOP_DARK 2'b00
`define PIXELOP_LITE 2'b01
`define PIXELOP_INVT 2'b10
`define PIXELOP_CKSM 2'b11

