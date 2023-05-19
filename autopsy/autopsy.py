#!/usr/bin/env python3
# AUTOmatically Partial Sum-ifY integral distinguishers for SKINNY, SKINNYev2, SKINNYee
#
# Usage:
# 1. select attack parameters at the bottom of this file
# 2a. if pdf=True: python3 autopsy.py (will compile & open PDF)
# 2b. if pdf=False: python3 autopsy.py  > example.tex && latexmk example.tex
#
# compiling TeX requires various cipher *.sty files whose path is included by the .latexmkrc files when using latexmk

import math
import itertools
import contextlib
import os


### TEX OUTPUT #########################################################

def tex_doc_start():
    print(r"""\documentclass[varwidth=50cm]{standalone}
\usepackage{skinnyzero}
\usepackage{booktabs}
\colorlet{key}{tuggreen}
\begin{document}
""")

def tex_doc_final():
    print(r"""
\end{document}
""")

def tex_table_start():
    print(r"\begin{tabular}[t]{@{}clc@{${}\times{}$}c@{${}={}$}cc@{${}\cdot{}$}cl@{}}")
    print(r"  \toprule")
    print(" & ".join(["Step", "Guessed", "Keys", "Data", "Memo", "Time", "Unit", "Stored Texts"]), r"\\ \midrule")

def tex_table_row(rnd, step, guesskey, data, keys, memory, time, unit, textsX, textsY, textsT, final=False):
    # converts rnd to rnd-1!
    sformat = "{s}".format(s=step)
    kformat = "$\\textit{{STK}}_{{{r}}}[{c}]$".format(r=rnd-1, c=",".join([str(k) for k in guesskey])) if guesskey else "--"
    xformat = "$Z_{{{r}}}[{c}]$".format(r=rnd-1, c=",".join([str(k) for k in textsX]))
    tformat = "; ${rc} $".format(rc=",".join(["\\textit{{STK}}_{{{rn}}}[{k}]".format(rn=rn-1,k=k) for rn,k in textsT])) if textsT else ""
    if final:
        yformat = "; $X_{{{r}}}[{c}]$".format(r=rnd-1, c=",".join([str(k) for k in textsY])) if textsY else ""
    else:
        yformat = "; $W_{{{r}}}[{c}]$".format(r=rnd-2, c=",".join([str(k) for k in textsY])) if textsY else ""
    Dformat = "$2^{{{d}}}$".format(d=data)
    Kformat = "$2^{{{k}}}$".format(k=keys)
    Mformat = "$2^{{{m}}}$".format(m=memory)
    Tformat = "$2^{{{t}}}$".format(t=time)
    Uformat = "$2^{{{u:2.1f}}}$".format(u=unit)
    print("  " + " & ".join([sformat, kformat, Kformat, Dformat, Mformat, Tformat, Uformat, xformat + tformat + yformat]), r"\\")

def tex_table_hline():
    print(r"""  \midrule""")

def tex_table_final(maxkeys,maxmemo,maxtime):
    print("  " + " & ".join([r"$\Sigma$", r"\multicolumn{3}{c}{}", "$2^{{{m}}}$".format(m=maxmemo), "$2^{{{t}}}$".format(t=maxtime), ""]), r"\\")
    print(r"  \bottomrule")
    print(r"\end{tabular}")

def tex_skinny_start():
    print(r"""\begin{tikzpicture}[baseline=0pt]
  \SkinnyInit{}{}{}{}""")

def tex_skinny_state(state):
    return "".join([r"\Fill{ss" + str(i//4) + str(i%4) + r"}" for i,s in enumerate(state) if s])

def tex_skinny_stkey(state, cells, tk_cell):
    fill = "".join([r"\Fill{ss" + str(i//4) + str(i%4) + r"}" for i,s in enumerate(state) if s and cells[i] == tk_cell])
    fill += "".join([r"\Fill[key]{ss" + str(i//4) + str(i%4) + r"}" for i,s in enumerate(state) if s and cells[i] != tk_cell])
    return fill + tex_skinny_label(cells)

def tex_skinny_label(state, font=r"\ttfamily "):
    return "".join([r"\Cell{ss" + str(i//4) + str(i%4) + r"}{" + font + hex(s)[2:] + r"}" for i,s in enumerate(state)])

def tex_skinny_round(r, T, X, Y, Z, tk_cell, final=False):
    print(r"""
  \SkinnyRoundTK[""" + str(r-1) + r"""] % round number should be 0-indexed
                {""" + tex_skinny_state(X) + r"""} % state (input)
                {""" + tex_skinny_stkey(X[:8], T[:8], tk_cell) + r"""}{}{} % tk[1,2,3]
                {""" + tex_skinny_state(X) + r"""} % state (after subcells)
                {""" + tex_skinny_state(X) + r"""} % state (after addtweakey)
                {""" + tex_skinny_state(Y) + r"""} % state (after shiftrows)""")
    if final:
        print(r"""
  \SkinnyFin[""" + str(r) + r"""]
                {""" + tex_skinny_state(Z) + r"""}""")
    else:
        print(r"""
  \SkinnyNewLine[""" + str(r) + r"""]
                {""" + tex_skinny_state(Z) + r"""} % state (after mixcolumns)""")

def tex_skinnyee_round(r, T, X, Y, Z, tk_cell, final=False):
    print(r"""
  \SkinnyeeRoundTK[""" + str(r-1) + r"""] % round number should be 0-indexed
                  {""" + tex_skinny_state(X) + r"""} % state (input)
                  {""" + tex_skinny_stkey(X, T, tk_cell) + r"""}{}{} % tk[1,2,3]
                  {""" + tex_skinny_state(X) + r"""} % state (after subcells)
                  {""" + tex_skinny_state(X) + r"""} % state (after addtweakey)
                  {""" + tex_skinny_state(Y) + r"""} % state (after shiftrows)""")
    if final:
        print(r"""
  \SkinnyFin[""" + str(r) + r"""]
                {""" + tex_skinny_state(Z) + r"""}""")
    else:
        print(r"""
  \SkinnyNewLine[""" + str(r) + r"""]
                {""" + tex_skinny_state(Z) + r"""} % state (after mixcolumns)""")

def tex_skinny_final():
    print(r"""\end{tikzpicture}""")


### PROPAGATING DEPENDENCIES & PARTIAL SUM #############################

def propagate_dependency(start_round, final_round, balanced_cell):
    # Round i: Zi-1 -(ARK)-> Xi -(SR)-> Yi -(MC)-> Zi
    S = [[1 if c == balanced_cell else 0 for c in range(16)]]
    or3 = lambda x, y, z: [int(xi or yi or zi) for xi, yi, zi in zip(x, y, z)]
    shiftrows = lambda X : X[0:4] + X[7:8] + X[4:7] + X[10:12] + X[8:10] + X[13:16] + X[12:13]
    mixcolumn = lambda X : X[12:16] + or3(X[0:4], X[4:8], X[8:12]) + X[4:8] + or3(X[4:8], X[8:12], X[12:16])
    for r in range(start_round, final_round+1):
        S.append(shiftrows(S[-1]))
        S.append(mixcolumn(S[-1]))
    # Tweakey schedule
    #RT = [[hex(c)[2:] for c in range(16)]]
    RT = [[], [c for c in range(16)]] # rounds are 1-indexed
    permute = lambda X : [X[9], X[15], X[8], X[13], X[10], X[14], X[12], X[11]] + X[:8]
    for r in range(final_round-1):
        RT.append(permute(RT[-1]))
    return S, RT

def optimize_column_order(MCin, MCout, Key, Twk):
    colbest = None
    costbest = 1000
    keys_c = [sum([Key[4*row+col] for row in range(int(len(Key)/4))]) for col in range(4)]
    data_c = [sum([MCin[4*row+col] for row in range(4)]) - sum([MCout[4*row+col] for row in range(4)]) - sum([Twk[4*row+col] for row in range(int(len(Twk)/4))]) for col in range(4)]
    for colsort in itertools.permutations(range(4)):
        costs = []
        data = 0
        keys = 0
        for step in range(4):
            col = colsort[step]
            keys += keys_c[col]
            costs.append(data+keys)
            data += data_c[col]
        if max(costs) < costbest:
            costbest = max(costs)
            colbest = colsort
        #print("%", 4*max(costs), [4*cst for cst in costs])
    return colbest

# SKINNY key schedule
def partial_sum_attack(start_round, final_round, balanced_cell, tk_cell, b=4, tksetting=2, input_active=1):
    # b = cell bitsize
    S, RT = propagate_dependency(start_round, final_round, balanced_cell)
    # convert to X, Y
    X = [([] if r<start_round else S[2*(r-start_round)]) for r in range(final_round+2)]
    Y = [([] if r<start_round else S[2*(r-start_round)+1]) for r in range(final_round+1)]
    #
    tex_skinny_start()
    for r in range(start_round, final_round+1):
        tex_skinny_round(r, RT[r], X[r], Y[r], X[r+1], tk_cell, final=(r==final_round))
    tex_skinny_final()
    #
    Key_guessed = [0 for c in range(16)]
    Rtk_guessed = [rtkc for r in range(start_round, final_round+1) for rtkc, patc in zip(RT[r][:8], X[r][:8]) if patc]
    Twk_guessed = [(r,c) for r in range(start_round, final_round+1) for c, (rtkc, patc) in enumerate(zip(RT[r][:8], X[r][:8])) if patc and rtkc == tk_cell][:tksetting] # (round, rtkindex)
    #
    step = 0
    Twk_data = min(tksetting, len([rtkc for rtkc in Rtk_guessed if rtkc == tk_cell]))
    data_initial = b*(16 - input_active + tksetting)
    data = [min(data_initial, b*len(X[final_round]) + b*Twk_data)]
    keys = [0]
    time = [data[-1]]
    memo = [data[-1]]
    tex_table_start()
    tex_table_row(final_round, 0, [], data[-1], keys[-1], memo[-1], time[-1], 0,
            [c for c in range(16) if X[final_round][c]], [], Twk_guessed)
    tex_table_hline()
    for r in range(final_round, start_round-1, -1):
        textsX = [c for c in range(16) if X[r][c]]
        textsY = []
        textsT = [(rnd,c) for rnd,c in Twk_guessed if rnd <= r]
        key_guessed = [x*(RT[r][c] != tk_cell)*(Key_guessed[RT[r][c]] < tksetting) for c,x in enumerate(X[r][:8])] # key is guessed if it's (1) active in X (2) not chosen (3) not already determined
        twk_used = [x*(RT[r][c] == tk_cell) for c,x in enumerate(X[r][:8])]
        cols = optimize_column_order(X[r] if r == start_round else Y[r-1], X[r], key_guessed, twk_used)
        for col in cols:
            # Y[r-1], X[r]
            if r == start_round:
                Cin = [X[r][4*row+col] for row in range(4)]
            else:
                Cin = [Y[r-1][4*row+col] for row in range(4)]
            Cout = [X[r][4*row+col] for row in range(4)]
            Rtk = [RT[r][4*row+col] for row in range(2)]
            Twk = [c for rnd,c in textsT if rnd == r and c%4 == col]
            if sum(Cin):
                step += 1
                # RT[r]
                active_rtk = [] # act. round tweakey indinces (0..7)
                active_tk = [] # act. master tweakey indinces (0..f)
                for row in range(2):
                    if Cout[row]:
                        if Rtk[row] == tk_cell:
                            #assert(Twk)
                            print("% NOTE: not guessing known TK cell")
                        elif Key_guessed[Rtk[row]] == tksetting:
                            print("% NOTE: key cell", Rtk[row], "is already determined")
                        else:
                            active_rtk.append(4*row+col)
                            active_tk.append(Rtk[row])
                            Key_guessed[Rtk[row]] += 1
                if not active_rtk:
                    print("% NOTE: No tweakey involved! optimize manually")
                textsX = [x for x in textsX if x%4 != col]
                textsT = [(rnd,t) for rnd,t in textsT if t%4 != col or rnd != r]
                if r == start_round:
                    textsY = textsY + [y for y in range(16) if X[r][y] and y%4 == col]
                else:
                    textsY = textsY + [y for y in range(16) if Y[r-1][y] and y%4 == col]
                data.append(min(data_initial, b*len(textsX)+b*len(textsY)+b*len(textsT)))
                keys.append(keys[-1] + b*len(active_rtk))
                time.append(data[-2]+keys[-1])
                memo.append(data[-1]+keys[-1])
                unit = math.log(sum(Cout)/(final_round*16),2)
                tex_table_row(r, step, active_rtk, data[-1], keys[-1], memo[-1], time[-1], unit, textsX, textsY, textsT, final=(r == start_round))
        tex_table_hline()
    tex_table_final(keys[-1], max(memo), max(time))

# SKINNYee key schedule
def partial_sum_attack_ee(start_round, final_round, balanced_cell, tk_cell, b=4, tksetting=2, input_active=1):
    # b = cell bitsize
    S, RT = propagate_dependency(start_round, final_round, balanced_cell)
    # convert to X, Y
    X = [([] if r<start_round else S[2*(r-start_round)]) for r in range(final_round+2)]
    Y = [([] if r<start_round else S[2*(r-start_round)+1]) for r in range(final_round+1)]
    #
    tex_skinny_start()
    for r in range(start_round, final_round+1):
        tex_skinnyee_round(r, RT[r], X[r], Y[r], X[r+1], tk_cell, final=(r==final_round))
    tex_skinny_final()
    #
    Key_guessed = [0 for c in range(8*4)]
    #Rtk_guessed = [(r,8*(r%4)+c) for r in range(start_round, final_round+1) for c, patc in enumerate(X[r][8:]) if patc]
    Twk_guessed = [(r,c) for r in range(start_round, final_round+1) for c, (rtkc, patc) in enumerate(zip(RT[r][:8], X[r][:8])) if patc and rtkc == tk_cell][:tksetting] # (round, rtkindex)
    #
    step = 0
    Twk_data = len(Twk_guessed)
    data_initial = b*(16 - input_active + tksetting)
    data = [min(data_initial, b*len(X[final_round]) + b*Twk_data)]
    keys = [0]
    time = [data[-1]]
    memo = [data[-1]]
    tex_table_start()
    tex_table_row(final_round, 0, [], data[-1], keys[-1], memo[-1], time[-1], 0,
            [c for c in range(16) if X[final_round][c]], [], Twk_guessed)
    tex_table_hline()
    for r in range(final_round, start_round-1, -1):
        textsX = [c for c in range(16) if X[r][c]]
        textsY = []
        textsT = [(rnd,c) for rnd,c in Twk_guessed if rnd <= r]
        key_guessed = [x*(1-Key_guessed[8*(r%4)+c]) for c,x in enumerate(X[r][8:])] # key is guessed if it's (1) active in X (2) not already determined
        twk_used = [x*(RT[r][c] == tk_cell) for c,x in enumerate(X[r][:8])] # should depend on whether it's really used up?
        cols = optimize_column_order(X[r] if r == start_round else Y[r-1], X[r], key_guessed, twk_used)
        for col in cols:
            if r == start_round:
                Cin = [X[r][4*row+col] for row in range(4)]
            else:
                Cin = [Y[r-1][4*row+col] for row in range(4)]
            if sum(Cin):
                step += 1
                active_rtk = [] # act. round tweakey indinces (0..7)
                for row in [2,3]:
                    c = 4*row+col
                    if X[r][c] and not Key_guessed[8*(r%4)+c-8]:
                        active_rtk.append(c-8)
                        Key_guessed[8*(r%4)+c-8] = 1
                if not active_rtk:
                    print("% NOTE: No tweakey involved! optimize manually")
                textsX = [x for x in textsX if x%4 != col]
                textsT = [(rnd,t) for rnd,t in textsT if t%4 != col or rnd != r]
                if r == start_round:
                    textsY = textsY + [y for y in range(16) if X[r][y] and y%4 == col]
                else:
                    textsY = textsY + [y for y in range(16) if Y[r-1][y] and y%4 == col]
                data.append(min(data_initial, b*len(textsX)+b*len(textsY)+b*len(textsT)))
                keys.append(keys[-1] + b*len(active_rtk))
                time.append(data[-2]+keys[-1])
                memo.append(data[-1]+keys[-1])
                unit = math.log(sum([X[r][4*row+col] for row in range(4)])/(final_round*16),2)
                tex_table_row(r, step, active_rtk, data[-1], keys[-1], memo[-1], time[-1], unit, textsX, textsY, textsT, final=(r == start_round))
        tex_table_hline()
    tex_table_final(keys[-1], max(memo), max(time))


### APPLICATIONS #######################################################

def tex_autopsy(cipher, tksetting, final_round, start_round, tk_cell, balanced_cell, label="", b=4, input_active=1, pdf=True, pdfopen=True):
    # start_round is the first round involving a mitm branch, starting at 1
    # final_round equals the total number of attacked rounds
    file_path = "{cipher}_tk{tksetting}_{rounds}R_{tk_cell}{label}".format(cipher=cipher, tksetting=tksetting, rounds=final_round, tk_cell=tk_cell, label=("_"+label) if label else "")
    with open(file_path + ".tex", "w") as texfile:
        with contextlib.redirect_stdout(texfile):
            tex_doc_start()

            if cipher == "skinny":
                partial_sum_attack(start_round, final_round, balanced_cell, tk_cell, tksetting=tksetting, input_active=input_active)
            elif cipher == "skinnyee":
                partial_sum_attack_ee(start_round, final_round, balanced_cell, tk_cell, tksetting=tksetting, input_active=input_active)
            tex_doc_final()
    if pdf:
        os.system("latexmk " + file_path + ".tex")
        os.system("latexmk -c")
        if pdfopen:
            os.system("exo-open " + file_path + ".pdf" + " &")



### MAIN ###############################################################

if __name__ == "__main__":
    ### SKINNY
    #           TK Rnds Dist  Tcell 0sum  Label
    ### SKINNY-n-2n: 22-round attack variants
    #tex_autopsy("skinny", 2, 22,  16,   7,    1,    "blue")
    #tex_autopsy("skinny", 2, 22,  16,   7,    13,   "green")

    #tex_autopsy("skinny", 2, 22,  16,   9,    0,    "v1_blue", input_active = 12)
    #tex_autopsy("skinny", 2, 22,  16,   9,    12,   "v1_green", input_active = 12)

    # tex_autopsy("skinny", 2, 22,  16,   8,    2,    "v2_blue", input_active = 4)
    # tex_autopsy("skinny", 2, 22,  16,   8,    14,   "v2_green", input_active = 4)

    ### SKINNY-n-3n: 26-round attack variants

    tex_autopsy("skinny", 3, 26,  18,   14,   1,    "blue", input_active=4)
    tex_autopsy("skinny", 3, 26,  18,   14,   13,   "green", input_active=4)

    # Ankele et al.: "Zero-Correlation Attacks on Tweakable Block Ciphers with Linear Tweakey Expansion"
    # tex_autopsy("skinny", 2, 20,  15,   9,    11,   "ankele") # Figure 20, Table 3 - Error in the paper! Figure 20 between X[18], Y[18], the last row isn't shifted correctly!
    # tex_autopsy("skinny", 3, 23,  17,   11,   5,    "ankele_red") # Figure 22, Table 4 - Several errors in the paper's propagation! Key schedule is off-by-1 (tweak cell 7 there)
    # tex_autopsy("skinny", 3, 23,  17,   11,   13,   "ankele_blue") # Figure 22, Table 5 - Several errors in the paper's propagation! Key schedule is off-by-1 (tweak cell 7 there)

    ### SKINNYev2: 30-round attack variants
    #tex_autopsy("skinny", 4, 30,  20,   10,   3,    "blue", input_active = 4)
    #tex_autopsy("skinny", 4, 30,  20,   10,   15,   "green", input_active = 4)

    # tex_autopsy("skinny", 4, 30,  20,   15,   2,    "blue", input_active = 4)
    # tex_autopsy("skinny", 4, 30,  20,   15,   14,   "green", input_active = 4)

    ### SKINNYee: 26-round attack variants
    #tex_autopsy("skinnyee", 4, 26,  20,   10,   3,    "blue", input_active = 4)
    #tex_autopsy("skinnyee", 4, 26,  20,   10,   15,   "green", input_active = 4)

    #tex_autopsy("skinnyee", 4, 26,  20,   15,   2,    "blue", input_active = 4)
    #tex_autopsy("skinnyee", 4, 26,  20,   15,   14,   "green", input_active = 4)
