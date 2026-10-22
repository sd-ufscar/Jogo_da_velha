module Velha(KEY, SW, board, LEDR, winA, winB, draw, gameover, player);

    input [3:0] KEY;
    input [3:0] SW;

    output reg [17:0] board;
    output reg [8:0]  LEDR;
    output reg winA;
    output reg winB;
    output reg draw;
    output reg gameover;
    output reg player;

    reg [4:0] position;
    reg [4:0] aux;

    wire rst = !KEY[0];
    wire clk = !KEY[2];
	 

    always @(posedge clk or posedge rst) begin


        if (rst) begin
            board    <= 18'b0;
            winA     <= 0;
            winB     <= 0;
            draw     <= 0;
            gameover <= 0;
            player   <= 0;
        end

        else begin

            if (!gameover) begin

            if ((SW <= 9) && (SW > 0)) begin


                // Definição do switch como posição do board
                position = (SW * 2 + player) - 2;
                /* Explicação da formula: playerA joga se count é par,playerB se é impar.
                   o 1°bit das 9 duplas de 0 (10) equivale a posição preenchida por p1, e o segundo(01), por p2. */

                // Marcação da casa escolhida no board
                aux = player ? position - 1 : position + 1;

                if (board[position] || board[aux]) begin
                    //mensagem de erro
                end
                else begin //se a casa jogada nao esta preenchida
                    board[position] = 1;
                    player <= !player;
                    if ( /*linhas p0*/ (board[0]&board[2]&board[4]) || (board[6]&board[8]&board[10]) || (board[12]&board[14]&board[16])
                     /*colunas p0*/ || (board[0]&board[6]&board[12]) || (board[2]&board[8]&board[14]) || (board[4]&board[10]&board[16])
                     /*diagonais p0*/ || (board[0]&board[8]&board[16]) || (board[4]&board[8]&board[12])
                   ) begin
                    winA <= 1;
                    gameover <= 1;
                end

                else if ( /*linhas p1*/ (board[1]&board[3]&board[5]) || (board[7]&board[9]&board[11]) || (board[13]&board[15]&board[17])
                     /*colunas p1*/ || (board[1]&board[7]&board[13]) || (board[3]&board[9]&board[15]) || (board[5]&board[11]&board[17])
                     /*diagonais p1*/ || (board[1]&board[9]&board[17]) || (board[5]&board[9]&board[13])
                   ) begin
                    winB <= 1;
                    gameover <= 1;
                end

                /* Verificação de empate*/
					else if (
						 (board[0]  | board[1])  &&
						 (board[2]  | board[3])  &&
						 (board[4]  | board[5])  &&
						 (board[6]  | board[7])  &&
						 (board[8]  | board[9])  &&
						 (board[10] | board[11]) &&
						 (board[12] | board[13]) &&
						 (board[14] | board[15]) &&
						 (board[16] | board[17])
					) begin
						 draw <= 1'b1;
						 gameover <= 1'b1;
					end
               end
                

            end
        end
    end
    end

    always @(*) begin
        LEDR = 9'b0;
        if (winA)     LEDR[3:0] = 4'b1111;
        if (winB)     LEDR[7:4] = 4'b1111;
        if (gameover) LEDR[8]   = 1'b1;
    end

endmodule