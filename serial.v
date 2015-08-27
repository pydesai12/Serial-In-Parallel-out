`timescale 1ns / 10 ps

module serial(clk,rst,pushin,lastin,datain,pullout,stopout,dataout,lenout);

input clk,rst,pushin,lastin,datain;

input pullout;

output [63:0]dataout;

output[6:0]lenout;

output stopout;


///////////////FIFO//////////////
reg[70:0]memory [31:0];

reg full;
reg stopout;
reg[4:0]read_ptr;
reg[4:0]write_ptr;
reg[5:0]counter;
reg[63:0] dataout;
reg[6:0] lenout;
reg empty;
reg read,write;
/////////////////////SHIFTER /////////////


reg[6:0]lout,lout_new;
reg[63:0] out,out_new;



always @(posedge clk or posedge rst)
begin
    if(rst)
      begin
	
//	empty <= 1;
	//full <=0;
	read_ptr <=0;
	write_ptr <=0;
	out <= 0;
	lout <= 0;
	counter <=0;
	stopout <=1;
 	read <=0;
 	write <=0;
	
	end
	
	else
	  begin
	    
 

	  
	  case ({pushin,lastin})
	  
	  2'b00 : begin
		  lout <=#1 lout;
		  out <=#1 out;
 		  write <= #1 0;
		  end

	  2'b10:begin
		out <=	#1  {out[62:0],datain};
		lout <= #1 lout + 1;
 		 write <= #1 1'b0;
 		 		 
 		
		end

	  2'b11:begin
		
		out_new <= #1 {out[62:0],datain};
		lout_new <= #1 lout +1;
 		write <= #1 1'b1;
 		out <= #1 0;
 		lout <= #1 0;
		 //stopout <=#1 1'b0;
				 
		end
	 2'b01:begin
		lout <=#1 lout;
		 out <=#1 out;
		 write <= #1 1'b0;
		end 

	endcase
	
	if(((write) && (!full)) && ((read) && (!empty)))
	begin
	  memory[write_ptr][63:0]<=#1 out_new[63:0];//,1'b1};
	  memory[write_ptr][70:64]<=#1 lout_new[6:0];
	  write_ptr <=#1 write_ptr+1 ;
	  dataout <= #1 memory[read_ptr][63:0];
	  lenout <= #1 memory[read_ptr][70:64];
	  read_ptr <=#1  read_ptr +1;
	  counter <=#1 counter; 
	  read <= #1 1'b0;
	  stopout <= #1 1'b0;

	 end
	
	else if(write && (!full))
    		begin

			  memory[write_ptr][63:0]<=#1 out_new[63:0];//,1'b1};
			  memory[write_ptr][70:64]<=#1 lout_new[6:0];// +1;	  
			  write_ptr <= #1 write_ptr+1 ;
			  counter <= #1 counter + 1;

		end	  

	else if(read && (!empty)) 
		begin
   		
    		dataout <= #1 memory[read_ptr][63:0];
    		lenout <= #1 memory[read_ptr][70:64];
    		read_ptr <=#1  read_ptr + 1;
		counter <=#1 counter - 1;
    	//	stopout<=#1 1'b1;
    		read<=#1 1'b0;
    		stopout<=#1 1'b0;
		end

	else  
	begin
	
	write_ptr <= #1 write_ptr;
	read_ptr <=#1  read_ptr;
	counter <=#1 counter; 
	end
	
	if(stopout && (!read)) 
	begin
	read <= #1 1'b1;
	end
	
	if(pullout && (!stopout))
	begin
	stopout <= #1 1'b1;
	end
	
  end

end
always @(*)
begin
  if(counter == 0) empty <=1;
  else empty <= 0;
  
  if(counter == 32) full <= 1;
  else full <= 0;
  
end 
endmodule
	
	