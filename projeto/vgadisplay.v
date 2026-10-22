module vgadisplay (input clk, input draw, input [9:0] h_counter, input [9:0] v_counter, input [17:0] tabuleiro, input player, input wing, input winr,
output reg vga_r, output reg vga_g, output reg vga_b);

	 assign red   = 1'b1;
	assign green = 1'b0;
	assign blue  = 1'b0;

always@(posedge clk)
begin

	// Primeira coluna
	if((h_counter <= 122 && h_counter >= 5) && (v_counter <= 122 && v_counter >= 5)) 
	begin 
		vga_r = tabuleiro[0];			//assim como em todos abaixo, o quadrado receberá a cor respectiva de acordo com a memória
		vga_b = tabuleiro[9];			//exemplo: se na memória tabuleiro[0] for 1 o quadrado na área acima será preenchido pela cor vermelha
		vga_g = 0;
	end
	
	else if((h_counter <= 122 && h_counter >= 5) && (v_counter <= 250 && v_counter >= 132)) 
	begin 
		vga_r = tabuleiro[3];
		vga_b = tabuleiro[12];
		vga_g = 0;
	end
	
	else if((h_counter <= 122 && h_counter >= 5) && (v_counter <= 378 && v_counter >= 261)) 
	begin 
		vga_r = tabuleiro[6];
		vga_b = tabuleiro[15];
		vga_g = 0;
	end
	
	
	// Segunda Coluna
	else if((h_counter <= 250 && h_counter >= 133) && (v_counter <= 122 && v_counter >= 5))
	begin 
		vga_r = tabuleiro[1];
		vga_b = tabuleiro[10];
		vga_g = 0;
	end
	
	else if((h_counter <= 250 && h_counter >= 132) && (v_counter <= 250 && v_counter >= 133)) 
	begin 
		vga_r = tabuleiro[4];
		vga_b = tabuleiro[13];
		vga_g = 0;
	end
	
	else if((h_counter <= 250 && h_counter >= 133) && (v_counter <= 378 && v_counter >= 261)) 
	begin 
		vga_r = tabuleiro[7];
		vga_b = tabuleiro[16];
		vga_g = 0;
	end
	
	
	// Terceira Coluna
	else if((h_counter <= 378 && h_counter >= 261) && (v_counter <= 122 && v_counter >= 5)) 
	begin 
		vga_r = tabuleiro[2];
		vga_b = tabuleiro[11];
		vga_g = 0;
	end
	
	else if((h_counter <= 378 && h_counter >= 261) && (v_counter <= 250 && v_counter >= 133)) 
	begin 
		vga_r = tabuleiro[5];
		vga_b = tabuleiro[14];
		vga_g = 0;
	end
	
	else if((h_counter <= 378 && h_counter >= 261) && (v_counter <= 378 && v_counter >= 261)) 
	begin 
		vga_r = tabuleiro[8];
		vga_b = tabuleiro[17];
		vga_g = 0;
	end
	
	else if((h_counter > 378 || h_counter < 5) || (v_counter > 378 || v_counter < 5))
	begin
		vga_r = 0;
		vga_b = 0;					//garante que todo o fundo estará preto
		vga_g = 0;
	end
	
	else
	begin 
		vga_r = 1;							
		vga_b = 1;					//desenha as linhas do tabuleiro em branco
		vga_g = 1;
	end
	
	if(!player && !draw && !winr && !wing)
	begin
		if((h_counter >= 495 && h_counter <= 555) && (v_counter >= 95 && v_counter <= 155))
		begin
			vga_r = 1;
			vga_b = 1;			//contorna o quadrado do jogador ativo de branco para simbolizar que é sua vez
			vga_g = 1;
		end
	end
	
	else if(player && !draw && !winr && !wing)
	begin
		if((h_counter >= 495 && h_counter <= 555) && (v_counter >= 165 && v_counter <= 225))
		begin
			vga_r = 1;
			vga_b = 1;			//a mesma coisa que o de cima, mas para o outro jogador
			vga_g = 1;
		end
	end
	
	else if(draw)
	begin
		if (((h_counter >= 495 && h_counter <= 555) && (v_counter >= 165 && v_counter <= 225)) || (h_counter >= 495 && h_counter <= 555) && (v_counter >= 95 && v_counter <= 155))
		begin
			vga_r = 1;
			vga_b = 0;			//em caso de ocorrência de empate, os quadrados laterais que simbolizam os dois jogadores serão preenchidos pela cor amarela, determinando o empate
			vga_g = 1;
		end
	end
	
	else if (!player && winr)
	begin
		if((h_counter >= 495 && h_counter <= 555) && (v_counter >= 165 && v_counter <= 225))
		begin
			vga_r = 0;
			vga_b = 0;					//determina o surgimento de um quadrado verde em torno do bloco vermelho que simboliza o jogador, demonstrando a vitória deste
			vga_g = 1;
		end
	end
	
	else if (player && wing)
	begin
		if((h_counter >= 495 && h_counter <= 555) && (v_counter >= 95 && v_counter <= 155))
		begin
			vga_r = 0;
			vga_b = 0;					//determina o surgimento de um quadrado verde em torno do bloco azul que simboliza o jogador, demonstrando a vitória deste
			vga_g = 1;
		end
	end
	
	if((h_counter >= 500 && h_counter <= 550) && (v_counter >= 100 && v_counter <= 150))
	begin
		vga_r = 1;
		vga_b = 0;   				//essa parte do código determina o surgimento de um quadrado vermelho para facilitar a visualização de vitória, empate e o turno do jogador respectivo
		vga_g = 0;
	end
	
	if((h_counter >= 500 && h_counter <= 550) && (v_counter >= 170 && v_counter <= 220))
	begin
		vga_r = 0;
		vga_b = 1;					//a mesma coisa que acima, mas para o jogador azul
		vga_g = 0;
	end
	
	
end
	
endmodule
