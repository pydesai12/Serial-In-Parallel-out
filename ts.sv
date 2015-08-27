// This is a simple testbench for the serial assignment
// It will generate a few test cases...
`timescale 1ns/10ps

module top;

reg debug=1;

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
    #2.5 clk=~clk;
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
    $display("\n\n\n\n\n",s);
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
      $display("data                                                                0 len 0",workData,workLen);
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
  repeat(500000) begin
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
    if(stopout === 1'bx) die("stopout is an x");
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
        $display("\n\nExp 0\nGot 0",fdata,dataout);
        die("Data does not match");
      end
      if(flen !== lenout) begin
        $display("\n\nExp 0 got 0",flen,lenout);
        die("Length does not match");
      end
    end
    #1;
    pullout = (delays)?(expData.size()>25):$random;
  end

end


endmodule
