module VGA (
    input wire        clk,
    input wire [9:0]  h_counter,
    input wire [9:0]  v_counter,
    input wire [17:0] tabuleiro,
	 input wire winA,
	 input wire winB,
	 input wire draw,

    output reg vga_r,
    output reg vga_g,
    output reg vga_b
);

    // Tabuleiro: 360 x 360 pixels
    localparam X_INI = 30;
    localparam Y_INI = 60;
    localparam TAM_CASA = 120;
    localparam TAM_TABULEIRO = 360;
    localparam ESP_GRADE = 4;

    // Quadrados dos jogadores dentro de cada casa
    localparam MARGEM = 24;
    localparam FIM = 96;

    // Legenda lateral
    localparam LEGENDA_X = 430;
    localparam JOGADOR1_Y = 150;
    localparam JOGADOR2_Y = 270;
    localparam TAM_LEGENDA = 70;

    integer linha;
    integer coluna;
    integer indice;
    integer x_local;
    integer y_local;

    reg [1:0] casa;

    always @(posedge clk) begin

        // Fundo preto
        vga_r = 1'b0;
        vga_g = 1'b0;
        vga_b = 1'b0;


        // Valores iniciais
        linha = 0;
        coluna = 0;
        indice = 0;
        x_local = 0;
        y_local = 0;
        casa = 2'b00;

        // ==========================================
        // TABULEIRO
        // ==========================================

        if ((h_counter >= X_INI) &&
            (h_counter < X_INI + TAM_TABULEIRO) &&
            (v_counter >= Y_INI) &&
            (v_counter < Y_INI + TAM_TABULEIRO)) begin

            // Linha e coluna da casa atual
            coluna = (h_counter - X_INI) / TAM_CASA;
            linha  = (v_counter - Y_INI) / TAM_CASA;

            // Coordenadas locais dentro da casa
            x_local = (h_counter - X_INI) % TAM_CASA;
            y_local = (v_counter - Y_INI) % TAM_CASA;

            // Indice de 0 a 8
            indice = linha * 3 + coluna;

            // Leitura dos dois bits da casa
            casa = tabuleiro[2*indice +: 2];

            // Grade branca
            if ((x_local < ESP_GRADE) ||
                (y_local < ESP_GRADE) ||
                (x_local >= TAM_CASA - ESP_GRADE) ||
                (y_local >= TAM_CASA - ESP_GRADE)) begin

                vga_r = 1'b1;
                vga_g = 1'b1;
                vga_b = 1'b1;

            end

            // Jogador 1: quadrado vermelho
            else if ((casa == 2'b10) &&
                     (x_local >= MARGEM) &&
                     (x_local < FIM) &&
                     (y_local >= MARGEM) &&
                     (y_local < FIM)) begin

                vga_r = 1'b1;
                vga_g = 1'b0;
                vga_b = 1'b0;

            end

            // Jogador 2: quadrado azul
            else if ((casa == 2'b01) &&
                     (x_local >= MARGEM) &&
                     (x_local < FIM) &&
                     (y_local >= MARGEM) &&
                     (y_local < FIM)) begin

                vga_r = 1'b0;
                vga_g = 1'b0;
                vga_b = 1'b1;

            end

        end

        
        // ==========================================
        // LEGENDA: JOGADOR 1
        // ==========================================

        if ((h_counter >= LEGENDA_X) &&
            (h_counter < LEGENDA_X + TAM_LEGENDA) &&
            (v_counter >= JOGADOR1_Y) &&
            (v_counter < JOGADOR1_Y + TAM_LEGENDA)) begin

            // Em caso de empate: borda amarela
            if (draw == 1'b1) begin
                if ((h_counter < LEGENDA_X + ESP_GRADE) ||
                    (h_counter >= LEGENDA_X + TAM_LEGENDA - ESP_GRADE) ||
                    (v_counter < JOGADOR1_Y + ESP_GRADE) ||
                    (v_counter >= JOGADOR1_Y + TAM_LEGENDA - ESP_GRADE)) begin

                    vga_r = 1'b1;
                    vga_g = 1'b1;
                    vga_b = 1'b0;
                end
                else begin
                    // Interior vermelho
                    vga_r = 1'b1;
                    vga_g = 1'b0;
                    vga_b = 1'b0;
                end
            end

            // Vitória do jogador 1: borda verde
            else if (winB == 1'b1) begin
                if ((h_counter < LEGENDA_X + ESP_GRADE) ||
                    (h_counter >= LEGENDA_X + TAM_LEGENDA - ESP_GRADE) ||
                    (v_counter < JOGADOR1_Y + ESP_GRADE) ||
                    (v_counter >= JOGADOR1_Y + TAM_LEGENDA - ESP_GRADE)) begin

                    vga_r = 1'b0;
                    vga_g = 1'b1;
                    vga_b = 1'b0;
                end
                else begin
                    vga_r = 1'b1;
                    vga_g = 1'b0;
                    vga_b = 1'b0;
                end
            end
            else begin
                // Normal: vermelho
                vga_r = 1'b1;
                vga_g = 1'b0;
                vga_b = 1'b0;
            end
        end


        // ==========================================
        // LEGENDA: JOGADOR 2
        // ==========================================

        if ((h_counter >= LEGENDA_X) &&
            (h_counter < LEGENDA_X + TAM_LEGENDA) &&
            (v_counter >= JOGADOR2_Y) &&
            (v_counter < JOGADOR2_Y + TAM_LEGENDA)) begin

            // Em caso de empate: borda amarela
            if (draw == 1'b1) begin
                if ((h_counter < LEGENDA_X + ESP_GRADE) ||
                    (h_counter >= LEGENDA_X + TAM_LEGENDA - ESP_GRADE) ||
                    (v_counter < JOGADOR2_Y + ESP_GRADE) ||
                    (v_counter >= JOGADOR2_Y + TAM_LEGENDA - ESP_GRADE)) begin

                    vga_r = 1'b1;
                    vga_g = 1'b1;
                    vga_b = 1'b0;
                end
                else begin
                    // Interior azul
                    vga_r = 1'b0;
                    vga_g = 1'b0;
                    vga_b = 1'b1;
                end
            end

            // Vitória do jogador 2: borda verde
            else if (winA == 1'b1) begin
                if ((h_counter < LEGENDA_X + ESP_GRADE) ||
                    (h_counter >= LEGENDA_X + TAM_LEGENDA - ESP_GRADE) ||
                    (v_counter < JOGADOR2_Y + ESP_GRADE) ||
                    (v_counter >= JOGADOR2_Y + TAM_LEGENDA - ESP_GRADE)) begin

                    vga_r = 1'b0;
                    vga_g = 1'b1;
                    vga_b = 1'b0;
                end
                else begin
                    vga_r = 1'b0;
                    vga_g = 1'b0;
                    vga_b = 1'b1;
                end
            end
            else begin
                // Normal: azul
                vga_r = 1'b0;
                vga_g = 1'b0;
                vga_b = 1'b1;
            end
        end
end
endmodule