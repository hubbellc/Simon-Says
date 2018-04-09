/*Simon Project by Caleb Hubbel and Michael Mackprang
*/
`timescale 1ns / 1ps
module Final_top(output[2:0] simon_led0, simon_led1, simon_led2, simon_led3, output spkr, input [3:0] simon_btns_n, nexys_btns, input reset, clk, cheat, output [7:0] segments_n, output [3:0] anodes_n, output lcd_regsel, lcd_read, lcd_enable, inout [7:0] lcd_data); 

parameter one_sec = 50000000, half_sec = 25000000, quart_sec = 12500000;
parameter Reset = 0, Initialize = 1, Randomize = 2, Start = 3, Simon_Play = 4, Simon_rest = 5, Simon_Next = 6, Player_Init = 7, Player_Victory = 8, Player_Defeat = 9, Player_Held = 10, StartTone0 = 11, StartTone1 = 12, StartTone2 = 13, StartTone3 = 14, FailTone0 = 15, FailTone1 = 16, FailTone2 = 17, FailTone3 = 18, VictoryTone0 = 19, VictoryTone1 = 20, VictoryTone2 = 21, VictoryTone3 = 22, Check_State = 23, Cookie_dispenser = 24, Play_Again0 = 25, Play_Again1 = 26, Tough_Luck = 27, Player_Held1 = 28, Tough_Luck1 = 29, Simon_Pause0 = 30, Simon_Pause1 = 31;

wire [3:0] hold, enable, lcd_string_available;
wire [3:0] simon_btns;
wire [3:0] press, unpress, LFSR1, LFSR2;
wire [3:0] A, B, C, D;
wire [1:0] random;
wire off_btn, pressed;
wire [7:0] cookies_dc;

reg tone_en, led_enable;
reg spkr_en;
reg timer_en;
reg [31:0] timer, MaxCount, turn, count;
reg [7:0] cookies;
reg [31:0] next_state, current_state;
reg randomize;
reg [1:0] color, button_enc, button_saved, save_btn, binum1, binum2, binum3, binum4;
reg step;
reg simonsTurn;
reg rerun;
reg turn_ce, count_ce, count_rst, turn_rst, cookies_ce, cookies_rst;
reg timer_rst;

reg [1:0] Simon_Check;

reg [8*16-1:0] topline, bottomline;
reg lcd_string_print, count_enable;

assign simon_btns = ~simon_btns_n;
assign pressed = press[0] || press[1] || press[2] || press[3];

simon_leds_ctrl m1 (.simon_btn0(simon_led0), .simon_btn1(simon_led1), .simon_btn2(simon_led2), .simon_btn3(simon_led3), .color(color), .enable(led_enable), .clk(clk));
speaker m2(.spkr(spkr), .clk(clk), .tone(color), .spkr_en(spkr_en));
lcd_string m3(.available(lcd_string_available), .lcd_regsel(lcd_regsel), .lcd_read(lcd_read), .lcd_enable(lcd_enable), .print(lcd_string_print), .lcd_data(lcd_data), .topline(topline), .bottomline(bottomline), .reset(reset), .clk(clk));
seg_ctrl m4(.segments_n(segments_n), .anodes_n(anodes_n), .D(D), .C(C), .B(B), .A(A), .clk(clk));

BCD_converter conv0(.units(A), .binum(binum1));
BCD_converter conv1(.units(B), .binum(binum2));
BCD_converter conv2(.units(C), .binum(binum3));
BCD_converter conv3(.units(D), .binum(binum4));
BCD_converter conv4(.tens(cookies_dc[7:4]), .units(cookies_dc[3:0]), .binum(cookies));

debouncer db0(.hold(hold[0]), .pulse(press[0]), .pulse_fall(unpress[0]), .clk(clk), .btn(simon_btns[0] || nexys_btns[0]), .reset(reset));
debouncer db1(.hold(hold[1]), .pulse(press[1]), .pulse_fall(unpress[1]), .clk(clk), .btn(simon_btns[1]), .reset(reset));
debouncer db2(.hold(hold[2]), .pulse(press[2]), .pulse_fall(unpress[2]), .clk(clk), .btn(simon_btns[2]), .reset(reset));
debouncer db3(.hold(hold[3]), .pulse(press[3]), .pulse_fall(unpress[3]), .clk(clk), .btn(simon_btns[3]), .reset(reset));

prng m5(.random(random), .step(step), .rerun(rerun), .randomize(randomize), .clk(clk), .reset(reset), .LFSR1(LFSR1), .LFSR2(LFSR2));

//***********************************************************************************//
//												FINITE STATE MACHINE:
//***********************************************************************************//
always@(posedge clk)begin

	if(reset)begin
		current_state <= Reset;
		timer <= 0;
		count  <= 0;
		turn <= 0;
	end
	
	else begin
		current_state <= next_state;
		
		if(cheat) begin
			binum1 <= {LFSR1[0], LFSR2[0]};
			binum2 <= {LFSR1[1], LFSR2[1]};
			binum3 <= {LFSR1[2], LFSR2[2]};
			binum4 <= {LFSR1[3], LFSR2[3]};
		end
		
		else if(!cheat) begin
			binum1 <= 0;
			binum2 <= 0;
			binum3 <= 0; 
			binum4 <= 0;
		end
		
		if(timer_en) begin
		
			if(timer >= MaxCount)begin
				timer <= 0;
			end
			
			else begin
				timer <= timer + 1;
			end
		end
		
		if(timer_rst)begin
			timer <= 0;
		end
		
		if(count_ce)begin
			count <= count +1;
		end
		
		if(count_rst || reset)begin
			count <= 0;
		end
		
		
		if(turn_ce)begin
			turn <= turn + 1;
		end
		
		if (turn_rst || reset) begin
			turn <= 0;
		end
	
	
	   if (save_btn)
		  button_saved <= button_enc;
		end
		
		if(cookies_ce)begin
			cookies <= cookies + 1;
		end
		
		if(cookies_rst || reset)begin
			cookies <= 0;
		end

end

always @* begin

	next_state = current_state;
	lcd_string_print = 0;
	randomize = 0;
	timer_en = 0;
	simonsTurn = 0;
	spkr_en = 0;
	rerun = 0;
	count_ce = 0;
	turn_ce = 0;
	step = 0;
	count_rst = 0;
	tone_en = 0;
	color = 0;
	led_enable = 0;
	save_btn = 0;
	turn_rst = 0;
	cookies_rst = 0;
	cookies_ce = 0;

	if(next_state !=current_state)begin
	timer_rst = 1;
	end
	
	else begin
	timer_rst = 0;
	end
	
	case(current_state)
		
	Reset:begin		
		if(~reset)begin
			next_state = StartTone0;
		end
		
	end
//***********************************************************//
//                         INITIAL STATE
//***********************************************************//	
	StartTone0:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en =1;
		MaxCount = (quart_sec - 1);
		color = 0;
		if(timer >= MaxCount)begin
			next_state = StartTone1;
		end
	end

	StartTone1:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en =1;
		MaxCount = (quart_sec - 1);
		color = 1;
		if(timer >= MaxCount)begin
			next_state = StartTone2;
		end
	end

	StartTone2:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en = 1;
		MaxCount = (quart_sec - 1);
		color = 2;
		if(timer >= MaxCount)begin
			next_state = StartTone3;
		end
	end

	StartTone3:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en = 1;
		MaxCount = (quart_sec - 1);
		color = 3;
		if(timer >= MaxCount)begin
			next_state = Initialize;
		end
	end
	
	Initialize:begin
	
		lcd_string_print = 1; 
		timer_en = 1;
		spkr_en = enable;
		MaxCount = (4*one_sec - 1);
		
		if (timer <= (2*one_sec-1)) begin 
			topline = " I want to play ";
			bottomline = "   a game :)    "; 
		end 
		
		else begin
			topline = "Press my buttons"; 
			bottomline = "  to continue...";
		end
		
	if (simon_btns) begin
			next_state = Randomize;
	end
		
	end

	Randomize:begin
		color = button_enc;
		led_enable = 1;
		spkr_en = 1;
		randomize = 1;
		lcd_string_print = 1;
		topline = "                "; 
		bottomline = "                "; 
		
		if(unpress)begin
			next_state = Start;
		end
		
	end

	
	Start:begin
		MaxCount = (2*one_sec - 1);
		timer_en = 1;
		lcd_string_print = 1;
		topline = "   Lets Play!   "; 
		bottomline = "                ";
		
		if(timer >= MaxCount)begin
			next_state = Simon_Play;
		end
	end
	
	
	Simon_Play:begin
		color = random;
		led_enable = 1;
		MaxCount = (3*quart_sec - 1);
		timer_en = 1;
		
		spkr_en = 1;
		
		lcd_string_print = 1;
		topline = "   Lets Play!   "; 
		bottomline = "Watch closely...";
		
		if(timer >= MaxCount)begin
			next_state = Simon_rest;
		end

	end

	Simon_rest:begin
		simonsTurn = 1;
		MaxCount = (quart_sec - 1);
		timer_en = 1;
		
		if(timer >= MaxCount)begin	
			next_state = Simon_Next;
			step = 1;
		end
	end
	
	Simon_Next:begin
	
		simonsTurn = 1;

		if(count >= turn) begin
			count_rst = 1;
			rerun = 1;
			next_state = Player_Init;
		end
		
		else begin
			count_ce = 1;
			next_state = Simon_Play;
		end
	end
	
	Player_Init:begin
		lcd_string_print = 1;
		topline = "  Now you try!  "; 
		bottomline = "                ";
		
		if(hold)begin
			if (nexys_btns[0]) begin
				next_state = Simon_Play;
			end
		   else begin
				save_btn = 1;
				next_state = Player_Held;
			end
		end
	end
	
	Player_Held:begin
		color = button_enc;
		led_enable = 1;
		spkr_en = 1;
		if(!hold)begin
			next_state = Check_State;
			count_ce = 1;
		end
	end
		
	Check_State: begin
		if(button_saved == random) begin
			if(count > turn)begin
				next_state = Simon_Pause0;		
			end
			else begin
				step = 1;
				next_state = Player_Init;
			end
		end
		else begin
		next_state = Simon_Pause1;
		end
	end
	
	Simon_Pause0:begin
		timer_en = 1;
		MaxCount = (quart_sec-1);
		
		if(timer >= MaxCount)begin
			next_state = VictoryTone0;
		end
	end
	
	Simon_Pause1:begin
		timer_en = 1;
		MaxCount = (quart_sec-1);
		
		if(timer >= MaxCount)begin
			next_state = FailTone0;
		end
	end
	
	VictoryTone0:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en =1;
		MaxCount = (quart_sec - 1);
		color = 0;
		if(timer >= MaxCount)begin
			next_state = VictoryTone1;
		end
	end

	VictoryTone1:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en =1;
		MaxCount = (quart_sec - 1);
		color = 2;
		if(timer >= MaxCount)begin
			next_state = VictoryTone2;
		end
	end

	VictoryTone2:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en = 1;
		MaxCount = (quart_sec - 1);
		color = 1;
		if(timer >= MaxCount)begin
			next_state = VictoryTone3;
		end
	end

	VictoryTone3:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en = 1;
		MaxCount = (quart_sec - 1);
		color = 3;
		if(timer >= MaxCount)begin
			next_state = Player_Victory;
			cookies_ce = 1;
		end
	end
	
	
	Player_Victory:begin
		lcd_string_print = 1;
		topline = "   Good Job!    "; 
		bottomline = " U get a cookie! ";
		MaxCount = (one_sec - 1);
		timer_en = 1;
		if (timer >= MaxCount) begin
				next_state = Cookie_dispenser;
				count_rst = 1;
				rerun = 1;
				turn_ce = 1;
		end
	end
	
	Cookie_dispenser:begin
		timer_en = 1;
		lcd_string_print = 1;
		topline = "    Cookies:    "; 
		bottomline = {"       ",{4'b0011, cookies_dc[7:4]},{4'b0011,cookies_dc[3:0]},"       "};
		MaxCount = (one_sec - 1);
		if(timer >= MaxCount)begin
			next_state = Simon_Play;
		end
		
	end
	
	FailTone0:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en =1;
		MaxCount = (quart_sec - 1);
		color = 3;
		if(timer >= MaxCount)begin
			next_state = FailTone1;
		end
	end

	FailTone1:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en =1;
		MaxCount = (quart_sec - 1);
		color = 2;
		if(timer >= MaxCount)begin
			next_state = FailTone2;
		end
	end

	FailTone2:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en = 1;
		MaxCount = (quart_sec - 1);
		color = 1;
		if(timer >= MaxCount)begin
			next_state = FailTone3;
		end
	end

	FailTone3:begin
		timer_en = 1;
		led_enable = 1;
		tone_en = 1;
		spkr_en = 1;
		MaxCount = (quart_sec - 1);
		color = 0;
		if(timer >= MaxCount)begin
			next_state = Player_Defeat;
		end
	end

	Player_Defeat: begin
		lcd_string_print = 1;
		topline = " Bad Job :(...  "; 
		bottomline = "   No cookies!  ";
		rerun = 1;
		MaxCount = (2*one_sec - 1);
		timer_en = 1;
		if(timer >= MaxCount)begin
			next_state = Play_Again0;
			count_rst  = 1;
			turn_rst = 1;
			cookies_rst = 1;
		end
	end
	
	Play_Again0: begin
		lcd_string_print = 1;
		topline = " Would you like "; 
		bottomline = " to play again? ";
		
		timer_en = 1;
		MaxCount = (one_sec - 1);
		
		if(timer >= MaxCount)begin
			next_state = Play_Again1;
		end

		if(hold)begin
			save_btn = 1;
			next_state = Player_Held1;
		end
		
	end
	
	Play_Again1:begin
		lcd_string_print = 1;
		topline = "   Green: yes   "; 
		bottomline = "     Red: no    ";
		
		timer_en = 1;
		MaxCount = (one_sec - 1);
			if(timer>=MaxCount)begin
				next_state = Play_Again0;
			end
			
			if(hold)begin
				save_btn = 1;
				next_state = Player_Held1;
			end

	end
	
	Player_Held1:begin
		color = button_enc;
		led_enable = 1;
		spkr_en = 1;
		if(!hold)begin
			if(button_saved == 0)begin
				next_state = StartTone0;
			end
		
			else if(button_saved == 1 )begin
				next_state = Tough_Luck;
			end
			
			else begin
				next_state = Play_Again0;
			end
		end
	end
	
	Tough_Luck:begin
		lcd_string_print = 1;
		topline = "   Tough luck   "; 
		bottomline = "                ";
		
		timer_en= 1;
		MaxCount = (2*one_sec - 1);
		
		if(timer>=MaxCount)begin
			next_state = Tough_Luck1;
		end
	end
	
	Tough_Luck1:begin
		lcd_string_print = 1;
		topline = "Restarting Simon"; 
		bottomline = "                ";
		
		timer_en= 1;
		MaxCount = (2*one_sec - 1);
		
		if(timer>=MaxCount)begin
			next_state = StartTone0;
		end
	end
endcase
	
end
	
always @*begin

	case(hold)
		4'b0001: button_enc = 0;
		4'b0010: button_enc = 1;
		4'b0100: button_enc = 2;
		4'b1000: button_enc = 3;
	endcase
end

endmodule
