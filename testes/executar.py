"""Regressao funcional sobre os modulos Verilog reais; requer Python 3 e Icarus."""
from collections import deque
from pathlib import Path
import argparse
import json
import subprocess

LINES = ((0,1,2),(3,4,5),(6,7,8),(0,3,6),(1,4,7),(2,5,8),(0,4,8),(2,4,6))

def status(board):
    a = any(all(board[i] == 1 for i in line) for line in LINES)
    b = any(all(board[i] == 2 for i in line) for line in LINES)
    d = all(board) and not (a or b)
    return int(a), int(b), int(d), int(a or b or d)

def packed(board, player):
    a,b,d,g = status(board)
    bits = sum((1 if v == 1 else 2 if v == 2 else 0) << (2*i) for i,v in enumerate(board))
    leds = (15 if a else 0) | (240 if b else 0) | (256 if g else 0)
    return (bits << 14) | (a<<13) | (b<<12) | (d<<11) | (g<<10) | (player<<9) | leds

def move(board, player, sw):
    if not status(board)[3] and 1 <= sw <= 9 and board[sw-1] == 0:
        board = list(board)
        board[sw-1] = player+1
        return tuple(board), 1-player
    return board, player

def reachable():
    empty = (0,)*9
    paths = {empty: ()}
    queue = deque([empty])
    while queue:
        board = queue.popleft()
        if status(board)[3]:
            continue
        player = len(paths[board]) % 2
        for sw in range(1,10):
            child,_ = move(board,player,sw)
            if child not in paths:
                paths[child] = paths[board]+(sw,)
                queue.append(child)
    return paths

def vectors(path):
    paths = reachable()
    count = 0
    with path.open('w',encoding='ascii',newline='\n') as f:
        for sequence in paths.values():
            for candidate in range(16):
                board,player = (0,)*9,0
                f.write('0 0 00000000\n'); count += 1
                for sw in sequence:
                    board,player = move(board,player,sw)
                    f.write(f'1 {sw} {packed(board,player):08x}\n'); count += 1
                # Alterar as chaves sem pressionar o botao nao registra jogada.
                f.write(f'2 {candidate} {packed(board,player):08x}\n'); count += 1
                board,player = move(board,player,candidate)
                f.write(f'1 {candidate} {packed(board,player):08x}\n'); count += 1
    return {'estados_alcancaveis':len(paths),'transicoes_candidatas':len(paths)*16,'vetores':count}

def run(command, cwd):
    result = subprocess.run([str(x) for x in command],cwd=cwd,text=True,capture_output=True)
    if result.stdout: print(result.stdout.strip())
    if result.stderr: print(result.stderr.strip())
    if result.returncode: raise SystemExit(result.returncode)
    return result.stdout.strip()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--iverilog',default='iverilog')
    parser.add_argument('--vvp',default='vvp')
    parser.add_argument('--ivl-base',default=None,help='Diretorio lib/ivl em distribuicoes portateis')
    parser.add_argument('--project-dir',type=Path,default=None)
    parser.add_argument('--game-only',action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    source = (args.project_dir or root/'projeto').resolve()
    build = root/'testes/build'
    build.mkdir(exist_ok=True)
    report = vectors(build/'vetores.txt')
    print(json.dumps(report,ensure_ascii=False))
    compiler = [args.iverilog]+(['-B',args.ivl_base] if args.ivl_base else [])+['-g2012']
    run(compiler+['-s','tb_velha','-o',build/'velha.vvp',source/'Velha.v',root/'testes/tb_velha.sv'],root)
    report['velha'] = run([args.vvp,build/'velha.vvp','+vectors=vetores.txt'],build)
    if not args.game_only:
        run(compiler+['-s','tb_vga','-o',build/'vga.vvp',source/'VGA.v',root/'testes/tb_vga.sv'],root)
        report['vga'] = run([args.vvp,build/'vga.vvp'],build)
    (build/'resultado.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    main()
