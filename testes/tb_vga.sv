`timescale 1ns/1ps
module tb_vga;
    reg clk = 0;
    reg [9:0] h_counter = 0, v_counter = 0;
    reg [17:0] tabuleiro = 0;
    reg winA = 0, winB = 0, draw = 0;
    wire vga_r, vga_g, vga_b;
    integer i, code, x, y, checks = 0;
    reg [2:0] color;
    VGA dut(clk,h_counter,v_counter,tabuleiro,winA,winB,draw,vga_r,vga_g,vga_b);
    task pixel(input integer px, input integer py, input [2:0] expected);
        begin
            h_counter = px; v_counter = py; #1; clk = 1; #1;
            if ({vga_r,vga_g,vga_b} !== expected)
                $fatal(1,"Pixel (%0d,%0d): obtido=%b esperado=%b",px,py,{vga_r,vga_g,vga_b},expected);
            clk = 0; #1; checks = checks + 1;
        end
    endtask
    initial begin
        // Cada par de bits e cada posicao sao verificados separadamente.
        for (i=0;i<9;i=i+1) begin
            x = 30+(i%3)*120; y = 60+(i/3)*120;
            for (code=0;code<4;code=code+1) begin
                tabuleiro = 0; tabuleiro[2*i +: 2] = code;
                case (code)
                    1: color = 3'b001;
                    2: color = 3'b100;
                    default: color = 3'b000;
                endcase
                pixel(x+60,y+60,color);
                pixel(x+24,y+24,color);
                pixel(x+95,y+95,color);
                pixel(x+23,y+60,3'b000);
                pixel(x+96,y+60,3'b000);
            end
            pixel(x,y,3'b111);
            pixel(x+3,y+60,3'b111);
            pixel(x+4,y+60,3'b000);
            pixel(x+115,y+60,3'b000);
            pixel(x+116,y+60,3'b111);
            pixel(x+119,y+119,3'b111);
        end
        pixel(29,60,3'b000); pixel(390,60,3'b000);
        pixel(30,59,3'b000); pixel(30,420,3'b000);
        pixel(0,0,3'b000); pixel(639,479,3'b000);
        tabuleiro = 0;
        pixel(430,150,3'b100); pixel(499,219,3'b100);
        pixel(430,270,3'b001); pixel(499,339,3'b001);
        winA = 1;
        pixel(430,270,3'b010); pixel(433,300,3'b010);
        pixel(434,300,3'b001); pixel(495,300,3'b001);
        pixel(496,300,3'b010); pixel(499,339,3'b010);
        pixel(460,273,3'b010); pixel(460,274,3'b001);
        pixel(460,335,3'b001); pixel(460,336,3'b010);
        pixel(430,150,3'b100);
        winA = 0; winB = 1;
        pixel(430,150,3'b010); pixel(434,180,3'b100);
        pixel(496,180,3'b010); pixel(499,219,3'b010);
        pixel(430,270,3'b001);
        draw = 1; winA = 1; // Empate tem prioridade grafica.
        pixel(430,150,3'b110); pixel(499,219,3'b110);
        pixel(430,270,3'b110); pixel(499,339,3'b110);
        pixel(434,180,3'b100); pixel(434,300,3'b001);
        pixel(429,150,3'b000); pixel(500,150,3'b000);
        pixel(430,149,3'b000); pixel(430,220,3'b000);
        pixel(430,269,3'b000); pixel(430,340,3'b000);
        $display("PASS VGA: %0d verificacoes de cor, posicao e limites",checks);
        $finish;
    end
endmodule
