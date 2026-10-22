`timescale 1ns/1ps
module tb_velha;
    reg [3:0] KEY = 4'b1111;
    reg [3:0] SW = 0;
    wire [17:0] board;
    wire [8:0] LEDR;
    wire winA, winB, draw, gameover, player;
    wire [31:0] actual = {board,winA,winB,draw,gameover,player,LEDR};
    reg [31:0] expected, saved;
    integer fd, n, action, value, checks = 0;
    reg [4095:0] vectors;
    Velha dut(KEY,SW,board,LEDR,winA,winB,draw,gameover,player);
    initial begin
        if (!$value$plusargs("vectors=%s",vectors)) $fatal(1,"Vetor ausente");
        fd = $fopen(vectors,"r");
        if (!fd) $fatal(1,"Nao foi possivel abrir os vetores");
        while (!$feof(fd)) begin
            n = $fscanf(fd,"%d %d %h\n",action,value,expected);
            if (n != 3) $fatal(1,"Vetor invalido");
            if (action == 0) begin
                KEY = 4'b1111; #1; KEY[0] = 0; #1;
                KEY[0] = 1; #1;
            end else if (action == 1) begin
                SW = value; KEY[2] = 1; #1; KEY[2] = 0; #1;
            end else begin
                SW = value; #1;
            end
            if (actual !== expected)
                $fatal(1,"Divergencia vetor %0d acao=%0d SW=%0d: obtido=%08h esperado=%08h",
                       checks,action,value,actual,expected);
            saved = actual;
            KEY[2] = 1; #1;
            if (actual !== saved) $fatal(1,"Soltar KEY2 alterou estado");
            checks = checks + 1;
        end
        $fclose(fd);
        $display("PASS Velha: %0d vetores; liberacao de KEY2 verificada em cada vetor",checks);
        $finish;
    end
endmodule
