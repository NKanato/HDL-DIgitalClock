module DigitalClock (pCLK, nRST, TSW, DLED, SLED0, SLED1, SLED2, SLED3);
   input pCLK, nRST;
   input [7:0] TSW;
   output [7:0] DLED, SLED0, SLED1, SLED2, SLED3;

   //変数
   reg [3:0] cnt3, cnt2, cnt1, cnt0;
	reg [5:0] sec;//秒カウンタ
   reg       cy0, cy1, cy2, cy3, cy4;//繰り上げcy4は時間1桁目が4になった時のフラグ
	reg [22:0] div;	//分周回路用

	assign SLED3 = dec_led( cnt3 );
	assign SLED2 = dec_led( cnt2 );
   assign SLED1 = dec_led( cnt1 );
   assign SLED0 = dec_led( cnt0 );
	assign DLED  = led ( sec );

	always @(posedge pCLK) begin
		div <= div + 1'b1;
	end



   // 秒done
   always @( posedge div[10] or negedge nRST ) begin//div[15]がいい感じデフォ22
      if ( nRST == 1'b0 ) begin
         sec <= 4'b00000000;
         cy0  <= 1'b0;
      end else if ( sec == 59 ) begin
         sec <= 4'b00000000;
         cy0  <= 1'b1;
      end else begin
         sec <= sec + 1'b1;
         cy0  <= 1'b0;
      end
   end

   // 分1桁目done
   always @( posedge cy0 or negedge nRST ) begin
      if ( nRST == 1'b0 ) begin
         cnt0 <= 4'b0000;
			cy1  <= 1'b0;
      end else if ( cnt0 == 9 ) begin
         cnt0 <= 4'b0000;
			cy1  <= 1'b1;
      end else begin
         cnt0 <= cnt0 + 1'b1;
			cy1  <= 1'b0;
      end
   end

	// 分2桁目done
   always @( posedge cy1 or negedge nRST ) begin
      if ( nRST == 1'b0 ) begin
         cnt1 <= 4'b0000;
			cy2  <= 1'b0;
      end else if ( cnt1 == 5 ) begin
         cnt1 <= 4'b0000;
			cy2  <= 1'b1;
      end else begin
         cnt1 <= cnt1 + 1'b1;
			cy2  <= 1'b0;
      end
   end

	//時間1桁目
	always @( posedge cy2 or negedge nRST ) begin
      if ( nRST == 1'b0 ) begin
         cnt2 <= 4'b0000;
			cy3  <= 1'b0;
      end else if ( cnt2 == 9 ) begin
         cnt2 <= 4'b0000;
			cy3  <= 1'b1;
		end else begin
			if( cnt2 == 4 ) begin
				cy4 <= 1'b1;
			end
         cnt2 <= cnt2 + 1'b1;
			cy3  <= 1'b0;
      end
		
		/*if ( nRST == 1'b0 ) begin
         cnt2 <= 4'b0000;
			//cy3  <= 1'b0;
      end else if( cnt2 == 4 ) begin
			cy4 <= 1'b1;
      end else begin
			cy4 <= 1'b0;
		end*/
   end

	//時間2桁目
	always @( posedge cy3 or negedge nRST ) begin
      if ( nRST == 1'b0 ) begin
         cnt3 <= 4'b0000;
      end else if ( cnt3 == 2 && cy4 == 1'b1) begin
         cnt3 <= 4'b0000;
      end else begin
         cnt3 <= cnt3 + 1'b1;
      end
   end

   //7セグの数字を表示
   function [7:0] dec_led;
      input[3:0] in;
      begin
         case ( in )
            4'b0000: dec_led = 8'b11000000;
            4'b0001: dec_led = 8'b11111001;
            4'b0010: dec_led = 8'b10100100;
            4'b0011: dec_led = 8'b10110000;
            4'b0100: dec_led = 8'b10011001;
            4'b0101: dec_led = 8'b10010010;
            4'b0110: dec_led = 8'b10000010;
            4'b0111: dec_led = 8'b11011000;
            4'b1000: dec_led = 8'b10000000;
            4'b1001: dec_led = 8'b10010000;
            default: dec_led = 8'b01111111;
         endcase
      end
   endfunction

	//DLEDの表示用
	function [7:0] led;
		input[7:0] in;
		//ビットシフトで秒を表示
		if(in == 0) begin
			led = 8'b11111111;
		end
		else begin
			led = ~(8'b11111111 & in);
		end
      //led = 8'b01110110;
	endfunction
endmodule
