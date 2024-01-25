module DigitalClock (pCLK, nRST, TSW, DLED, SLED0, SLED1, SLED2, SLED3);
   input pCLK, nRST;
   input [7:0] TSW;
   output [7:0] DLED, SLED0, SLED1, SLED2, SLED3;

   //変数
   reg [3:0] cnt3, cnt2, cnt1, cnt0;
	reg [5:0] sec;//秒カウンタ
   reg       cy0, cy1, cy2, cy3, cy4;//繰り上げcy4は時間1桁目が4になった時のフラグ
	reg [22:0] div;	//分周回路用
   reg clk;
	reg switch_h;//12時間表記と24時間表記を切り替えるための変数
	reg [22:0] divFigure;

	assign SLED3 = dec_led( cnt3 );
	assign SLED2 = dec_led( cnt2 );
   assign SLED1 = dec_led( cnt1 );
   assign SLED0 = dec_led( cnt0 );
	assign DLED  = led ( sec );


   always @( posedge pCLK or negedge nRST ) begin

      if ( nRST == 1'b0 ) begin
         div <= 0; // divは何bitでしょう？
         clk <= 1'b0;
      end else if ( div == divFigure ) begin
         div <= 0;
         clk <= 1'b1;
      end else begin
         div <= div + 1'b1;
         clk <= 1'b0;
      end
   end


	always @( posedge pCLK or negedge nRST)begin	//切り替え用のスイッチを読む
	if ( pCLK == 1'b1 ) begin	//スイッチはクロックの立ち上がりの時に読まないとだめらしい
			//時間が進む速さ切り替え
			if (TSW[0] == 1) begin
				divFigure <= 7999999;
			end else if (TSW[0] == 0) begin
				divFigure <= 399;//実験用で速くしておく。もとは3999999
			end

			//12/24時間切り替え
			if(TSW[1] == 0) begin
				switch_h <= 1'b1;
			end else begin
				switch_h <= 1'b0;
			end
		end
	end



   // 秒done
   always @( posedge clk or negedge nRST ) begin//div[15]がいい感じデフォ22//div[22]&div[21]&div[20]
      if ( nRST == 1'b0 ) begin
         sec <= 6'b000000;
         cy0  <= 1'b0;
      end else if ( sec == 59 ) begin
         sec <= 6'b000000;
         cy0  <= 1'b1;
      end else begin
			if(TSW[7] == 0) begin
				sec <= sec;
			end else begin
				sec <= sec + 1'b1;
				cy0  <= 1'b0;
			end
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

	//時間, 1つのalways文にまとめたやつ
	always @( posedge cy2 or negedge nRST ) begin
      if ( nRST == 1'b0 ) begin
         cnt2 <= 4'b0000;
			cnt3 <= 4'b0000;
      end else begin//12時間↓↓↓
			if(switch_h == 1'b0) begin
				if ( cnt3 == 4'b0000 ) begin
					cnt2 <= cnt2 + 1'b1;
					if(cnt2 == 4'h9) begin
						cnt2 <= 4'b0000;
						cnt3 <= cnt3 + 1'b1;
					end
				end else begin
					cnt2 <= cnt2 + 1'b1;
					if(cnt2 == 4'h1) begin
						cnt2 <= 4'b0000;
						cnt3 <= 4'b0000;
					end
				end
			end else begin//24時間↓↓↓
				if(switch_h == 1'b1) begin
					if ( cnt3 == 4'b0000 ) begin
						cnt2 <= cnt2 + 1'b1;
						if(cnt2 == 4'd9) begin
							cnt2 <= 4'b0000;
							cnt3 <= cnt3 + 1'b1;
						end
					end else if ( cnt3 == 4'b0001) begin
						cnt2 <= cnt2 + 1'b1;
						if(cnt2 == 4'd9) begin
							cnt2 <= 4'b0000;
							cnt3 <= cnt3 + 1'b1;
						end
					end else if ( cnt3 == 4'b0010 )begin
						cnt2 <= cnt2 + 1'b1;
						if(cnt2 == 4'd3) begin
							cnt2 <= 4'b0000;
							cnt3 <= 4'b0000;
						end
					end
				end
			end
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
	endfunction
endmodule
