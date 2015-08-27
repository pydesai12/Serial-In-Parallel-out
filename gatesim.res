ncverilog: 14.10-p001: (c) Copyright 1995-2014 Cadence Design Systems, Inc.
file: ts.sv
	module worklib.top:sv
		errors: 0, warnings: 0
file: serial_gates.v
	module worklib.serial:v
		errors: 0, warnings: 0
		Caching library 'tc240c' ....... Done
		Caching library 'worklib' ....... Done
	Elaborating the design hierarchy:
  CIVDXL U5168 ( .A(lastin), .Z0(n79) );
             |
ncelab: *W,CUVWSP (./serial_gates.v,8638|13): 1 output port was not connected:
ncelab: (/apps/toshiba/sjsu/verilog/tc240c/CIVDXL.tsbvlibp,12): Z1

	Building instance overlay tables: .................... Done
	Generating native compiled code:
		worklib.serial:v <0x1838bfd2>
			streams:   0, words:     0
		worklib.top:sv <0x470b308d>
			streams:  11, words: 17344
	Building instance specific data structures.
	Loading native compiled code:     .................... Done
	Design hierarchy summary:
		                   Instances  Unique
		Modules:                8449      62
		UDPs:                   6993       7
		Primitives:            42792       8
		Timing outputs:         5960      28
		Registers:              2527      34
		Scalar wires:           8470       -
		Always blocks:             1       1
		Initial blocks:            5       5
		Pseudo assignments:        1       1
		Timing checks:         15285    5186
		Simulation timescale:   10ps
	Writing initial simulation snapshot: worklib.top:sv
Loading snapshot worklib.top:sv .................... Done
ncsim> source /apps/cadence/INCISIV141/tools/inca/files/ncsimrc
ncsim> run


You finished well my young jedi... the design worked


Simulation complete via $finish(1) at time 4793046 NS + 0
./ts.sv:146       $finish;
ncsim> exit
