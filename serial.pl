#!/usr/bin/perl

use Getopt::Long;

@smod = ();
$vcomm="";
@uname = ();
@uid = ();
$clkperiod = 5;
$cdly2 = "";
$debug = '';
$synthesis = '';
$toponly = '';
sub checkDW {
  my $rv="";
  if( -e "DW02_mult_2_stage.v") {
    $rv="DW02_mult_2_stage.v";
  }
  $rv = $rv." DW02_mult_3_stage.v" if( -e "DW02_mult_3_stage.v") ;
  $rv = $rv." DW02_mult_4_stage.v" if( -e "DW03_mult_4_stage.v") ;
  return $rv;
}
sub maketop {
  my $nsets=shift(@_);
  my $clkadj=shift(@_);
  my $clkhalf = ($clkperiod/2.0)*$clkadj;
  open(tf,">","ts.sv");
printf tf '// This is a simple testbench for the serial assignment
// It will generate a few test cases...
`timescale 1ns/10ps

module top;

reg debug=';
printf tf ($debug)?"1":"0";
printf tf ';

reg clk,rst,pushin,lastin;
reg datain;
reg pullout;
wire stopout;
wire [63:0] dataout;
wire [6:0] lenout;
reg run=0;
reg delays=0;
reg old_stopout;

reg [63:0] old_dataout,fdata;
reg [6:0] old_lenout,flen;

serial s(clk,rst,pushin,lastin,datain,pullout,stopout,dataout,lenout);

reg [63:0] expData[$];
reg [6:0] expLen[$];

reg [63:0] workData;
reg [6:0] workLen;
integer fcnt;

initial begin
  clk=0;
  forever begin
    #';
printf tf "$clkhalf";
printf tf ' clk=~clk;
  end
end

task Spaces;
  int spout;
  begin
    spout= 5+64-workLen;
    repeat(spout) $write(" ");
    $display("^ HOB");
  end
endtask

task die;
  input reg[511:0] s;
  begin
    $display("\n\n\n%s\n\n",s);
    $display("Error -- simulation failed\n\n\n");
    #3;
    $finish;
  end
endtask

task createWork;
  integer ix;
  begin
    workData={$random,$random};
    workLen = $random;
    workLen = workLen % 65;
    if(workLen <= 0) workLen=1;
    for(ix=workLen; ix < 64; ix=ix+1) begin
      workData[ix]=0;
    end
    expData.push_back(workData);
    expLen.push_back(workLen);
    if(debug) begin
      $display("data %64b len %d",workData,workLen);
      Spaces;
    end
  end
endtask

task sendOne;
  integer hob;
  integer delayAmt;
  begin
    hob = workLen-1;
    pushin=0;
    while(workLen>0) begin
      delayAmt=$random;
      if(delayAmt < 0) delayAmt=-delayAmt;
      if(expData.size() > 25) begin
        delayAmt=0;
      end if(expData.size() < 10) begin
        delayAmt = delayAmt % 3;
      end else begin
        delayAmt = delayAmt %5;
      end
      if(!delays) delayAmt=0;
      while(delayAmt > 0) begin
        pushin=0;
        {lastin,datain}=$random;
        @(posedge(clk)) #1;
        delayAmt=delayAmt-1;
      end
      pushin=1;
      lastin=0;
      workLen=workLen-1;
      if(workLen <= 0) lastin=1;
      datain=workData[hob];
      workData = workData << 1;
      @(posedge(clk)) #1;
    end
    pushin=0;
    lastin=0;
  end
endtask

initial begin
  rst=0;
  pushin=0;
  lastin=0;
  datain=0;
  run=0;
  pullout=0;
  #0.1;
  if(debug) begin
    $dumpfile("serial.vcd");
    $dumpvars(9,top);
  end
  repeat(2) @(posedge(clk)) #1;
  rst=1;
  repeat(5) @(posedge(clk)) #1;
  rst=0;
  repeat(5) @(posedge(clk)) #1;
  run=1;
  delays=0;
  repeat(500) begin
    createWork;
    sendOne;
  end
  delays=1;
  repeat(';
printf tf "$nsets";
printf tf ') begin
    createWork;
    sendOne;
  end
  delays=0;
  fcnt=1000;
  while(fcnt > 0) begin
    @(posedge(clk)) #1;
    if(expData.size()==0) begin
      $display("\n\nYou finished well my young jedi... the design worked\n\n");
      $finish;
    end
    fcnt=fcnt-1;
  end
  die("Error --- Ran out of time");
end

always @(posedge(clk)) begin
  if(run) begin
    old_stopout = stopout;
    old_dataout = dataout;
    old_lenout = lenout;
    #0.08;
    if(stopout === 1\'bx) die("stopout is an x");
    if(stopout !== old_stopout) begin
      die("no hold time on stopout");
    end 
    if( stopout===0 && pullout === 1) begin
      if(expData.size() <= 0) die("You gave data when you should have none");
      if(old_dataout !== dataout) die("No hold time on dataout");
      if(old_lenout !== lenout) die("No hold time on lenout");
      fdata=expData.pop_front();
      flen=expLen.pop_front();
      if(fdata !== dataout) begin
        $display("\n\nExp %b\nGot %b",fdata,dataout);
        die("Data does not match");
      end
      if(flen !== lenout) begin
        $display("\n\nExp %d got %d",flen,lenout);
        die("Length does not match");
      end
    end
    #1;
    pullout = (delays)?(expData.size()>25):$random;
  end

end


endmodule
';
  close(tf);
}

sub makesynscript{
open(sf,">","synthesis.script") or die "\n\n\nFAILED --- Couldn't open the synthesis script for editing\n";
printf sf "set link_library {/apps/toshiba/sjsu/synopsys/tc240c/tc240c.db_NOMIN25 /apps/synopsys/SYNTH/libraries/syn/dw02.sldb /apps/synopsys/SYNTH/libraries/syn/dw01.sldb }
set target_library {/apps/toshiba/sjsu/synopsys/tc240c/tc240c.db_NOMIN25}\n";
my $ix;
printf sf "read_verilog serial.v\n";
printf sf "current_design serial\ncheck_design";
printf sf "
set_drive 0 clk
set_drive 0 rst
set_dont_touch_network clk\n";
printf sf "create_clock clk -name clk -period %f\n",$clkperiod*0.90;
printf sf "set_propagated_clock clk
set_clock_uncertainty 0.25 clk
set_propagated_clock clk
set_output_delay 0.5 -clock clk [all_outputs]
set all_inputs_wo_rst_clk [remove_from_collection [remove_from_collection [all_inputs] [get_port clk]] [get_port rst]]
";
printf sf 'set_driving_cell -lib_cell CND2X1 $all_inputs_wo_rst_clk
set_input_delay 0.5 -clock clk $all_inputs_wo_rst_clk
';
my $outdelay = $clkperiod-1.5;
printf sf "set_max_delay $outdelay -to [all_outputs]
";
my $indelay = $clkperiod-1.5;
printf sf "set_max_delay $indelay";
printf sf ' -from $all_inputs_wo_rst_clk
set_fix_hold [ get_clocks clk ]
compile -map_effort medium -incremental_mapping 
';
printf sf "create_clock clk -name clk -period %f\n",$clkperiod;
printf sf "set_propagated_clock clk
set_clock_uncertainty 0.25 clk
set_propagated_clock clk
update_timing
report -cell
report_timing -max_paths 10
write -hierarchy -format verilog -output serial_gates.v
quit
";
close(sf);


}
sub runvcs {
maketop(500000,1.0);
$ENV{"SFLM_SERVER"}="SFLM_SERVER";
$ENV{"CDS_LIC_FILE"}='5280@innersanctum:/apps/cadence/license-current';
$ENV{"CDSLMD_LICENSE_FILE"}='5280@innersanctum:/apps/cadence/license-current';
$ENV{"LM_LICENSE_FILE"}='27000@innersanctum.engr.sjsu.edu:/apps/synopsys/license/current-license-key:27001@innersanctum.engr.sjsu.edu';
$ENV{"SNPSLMS_LICENSE_FILE"}='27000@innersanctum.engr.sjsu.edu:/apps/synopsys/license/current-license-key';
$ENV{"VCS_HOME"}='/apps/synopsys/VCSMX_NEW';
open(fss,">","fss");
print fss "#!/usr/bin/csh\n";
print fss "source /apps/synopsys/VCSMX_NEW/bin/environ.csh\n";
print fss "vcs +systemverilogext+.sv -sverilog -ntb_opts dtm ".checkDW()." serial.v ts.sv\n";
close(fss);
system("rm ./simv");
system("chmod +x fss");

printf f "vcs Simulation run on %s", `date`;
printf "Starting vcs simulation... Be patient\n";
system("./fss");
printf f "VCS finished\n";
system("rm simres");
system("./simv | tee simres")==0 or die "\n\n\n\n\nFAILED --- simulation failed (Logic problem)";
printf f "simv finished\n";
system("grep -i 'You finished well my young jedi... the design worked' simres")==0 or die "\n\n\n\nFAILED --- simulation didn't get correct results";
printf f " simulation OK\n";
system("rm simres");
system("rm synres.txt");
system("rm -rf simv csrc");
}

sub runncverilog{
maketop(500000,1.0);
my $ncv = "ncverilog +sv +access+r ".checkDW()." serial.v ts.sv";
system("rm -rf fss simres");
open(fss,">","fss");
$ncv=$ncv." | tee simres";
printf fss "#!/usr/bin/csh\n";
printf fss "source /apps/design_environment.csh\n";
printf fss "$ncv\n";
close(fss);
system("chmod +x fss");
printf f "NCverilog\n";
printf f "NCverilog Simulation run on %s", `date`;
printf "Starting NCverilog simulation... Fast simulator, large test cases... Be patient\n";
system("./fss");
system("grep -i 'You finished well my young jedi... the design worked' simres")==0 or die "\n\n\n Failed --- ncverilog didn't get correct results";
printf f " simulation OK\n";
printf "  NC pre-synthesis simulation OK\n";

}

GetOptions("debug" => \$debug,
	   "synthesis" => \$synthesis,
	   "toponly" => \$toponly );
($#ARGV >= 0 ) or die "Require the result name as a parameter";
$clkperiod = 5.0;
open(f,">",$ARGV[0]) or die "Couldn't open the output file";


$vcomm_name = $vcomm;
$vcomm_name=~ s/.v// ;

printf f "Starting the run of the serial synthesis HW\n cycle time %s\n",$ARGV[0] or die "\n\n\n\nFAILED --- didn't write\n\n\n";
printf f "Run on %s", `date`;
printf f "%s on %s\n", $ENV{"USER"}, $ENV{"HOSTNAME"};
if ( $toponly ) {
  maketop(3000,1.0);
  die "\nonly made the top level\n";
} 
if ( ! $synthesis ) {
printf f "Running simulation cases\n";
runvcs;
runncverilog;
} else {
 printf f "Not running simulation\n";
}
makesynscript;
system("rm -f sss");
open(sss,">","sss");
printf sss "#!/usr/bin/csh\nsource /apps/design_environment.csh\n";
printf sss "dc_shell -f synthesis.script | tee synres.txt\n";
close(sss);
system("chmod +x sss");
system("./sss")==0 or die "\n\n\n\nFAILED --- synthesis failed";
printf f "synthesis ran\n";
system("grep '(MET)' synres.txt")==0 or die "\n\n\n\nFAILED --- Didn't find timing met condition";
system("grep -i error synres.txt")!=0 or die "\n\n\n\nFAILED --- synthesis contained errors";
system("grep -i latch synres.txt")!=0 or die "\n\n\n\nFAILED --- synthesis created latches";
system("grep -i violated synres.txt")!=0 or die "\n\n\n\nFAILED --- synthesis violated timing";
$tline = `grep Total synres.txt`;
chomp($tline);
@gates = split(" ",$tline);
$size = @gates[3];
printf f "Total gates %s\n", $size;
die "\n\n\nFAILED --- Number of gates too small, check warinings\n\n" if ($size < 7000.0);
printf f "Design synthesized OK\n";
system("rm command.log");
system("rm default.svf");
print "\n\nSynthesis results are in file synres.txt\n";
$aline = `/sbin/ifconfig | grep eth | grep Bcast`;
chomp($aline);
@astuff = split(" ",$aline);
printf f "%s\n",@astuff[1];
system("rm gatesim.res");
maketop(5000,2.0);
system("rm -f fss");
open(fss,">","fss");
printf fss "#!/usr/bin/csh\nsource /apps/design_environment.csh\n";
printf fss "ncverilog +libext+.tsbvlibp +access+r +sv -y /apps/toshiba/sjsu/verilog/tc240c ts.sv serial_gates.v | tee gatesim.res\n";
close(fss);
system("chmod +x fss");
system("./fss");
system("grep -i 'You finished well my young jedi... the design worked' gatesim.res")==0 or die "\n\n\n Failed --- ncverilog(gates) didn't get correct results";
$md5 = `cat serial.pl | md5sum`;
chomp($md5);
printf f "NCverilog ran on the gates\n";
print "NCverilog ran on the gates\n";
printf f "%s %s %s\n", $md5 , $ENV{"USER"}, $ENV{"HOSTNAME"};
$mdx = `echo '$ENV{"USER"}' | md5sum`;
$mdy = `echo ~`;
chomp($mdy);
$mdz = `echo $mdy | md5sum`;
chomp($mdz);
printf f "<%s>\n",$mdz;
printf f "Completed %s", `date`;
close f;
print "Successful Completion of HW run\n";
printf "Run summary file is %s\n",$ARGV[2];
