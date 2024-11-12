#!/usr/env/bin python3
#-*- coding: UTF-8 -*-

"""
# Author: Hosein Hadipour
# Email: hsn.hadipour@gmail.com
# Date: July 2020

MIT License

Copyright (c) 2022 Hosein Hadipour

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import itertools
import sys
import time
from traceback import print_stack
import minizinc
import datetime
from argparse import ArgumentParser, RawTextHelpFormatter

# Check if "OR Tools" appears in the output of "minizinc --solvers" command 
import subprocess

def check_ortools_availability():
    try:
        output = subprocess.run(['minizinc', '--solvers'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return "com.google.ortools.sat" in output.stdout.decode("utf-8")
    except FileNotFoundError:
        return False

ortools_available = check_ortools_availability()
print("OR Tools is available" if ortools_available else "OR Tools is not available")

def trim(docstring):
    if not docstring:
        return ''
    # Convert tabs to spaces (following the normal Python rules)
    # and split into a list of lines:
    lines = docstring.expandtabs().splitlines()
    # Determine minimum indentation (first line doesn't count):
    indent = sys.maxsize
    for line in lines[1:]:
        stripped = line.lstrip()
        if stripped:
            indent = min(indent, len(line) - len(stripped))
    # Remove indentation (first line is special):
    trimmed = [lines[0].strip()]
    if indent < sys.maxsize:
        for line in lines[1:]:
            trimmed.append(line[indent:].rstrip())
    # Strip off trailing and leading blank lines:
    while trimmed and not trimmed[-1]:
        trimmed.pop()
    while trimmed and not trimmed[0]:
        trimmed.pop(0)
    # Return a single string:
    return '\n'.join(trimmed)

class ZC:
    ZC_counter = 0

    def __init__(self, RB, RU, RL, RF, \
                cp_solver_name, variant="tk2", \
                time_limit="None",
                output_file_name="output") -> None:
        ZC.ZC_counter += 1
        self.id = ZC.ZC_counter
        self.name = "ZC" + str(self.id)
        self.type = "ZC"

        self.RB = RB
        self.RU = RU
        self.RL = RL
        self.RF = RF
        self.num_of_attacked_rounds = self.RB + self.RU + self.RL + self.RF
        self.num_of_involved_key_cells = 0

        self.cp_solver_name = cp_solver_name
        self.variant = variant
        self.supported_cp_solvers = ['gecode', 'chuffed', 'cbc', 'gurobi',
                                     'picat', 'scip', 'choco', 'ortools']
        assert(self.cp_solver_name in self.supported_cp_solvers)
        ##################################################
        if ortools_available:
            if self.cp_solver_name == "ortools":
                self.cp_solver_name = "com.google.ortools.sat"
        ################################################# 
        self.cp_solver = minizinc.Solver.lookup(self.cp_solver_name)
        self.time_limit = time_limit
        self.mzn_file_name = None
        self.output_file_name = output_file_name
        self.mzn_file_name = "cprtkdist.mzn"
        self.NPT = variant
        self.target_variant = r"""\SKINNY[$n$-$""" + str(self.NPT) + r"""$]"""
    
    def search(self):
        """
        Search for a zero-correlation distinguisher optimized for key recovery
        """

        if self.time_limit != -1:
            time_limit = datetime.timedelta(seconds=self.time_limit)
        else:
            time_limit = None
    
        start_time = time.time()
        ##########################
        ##########################
        self.cp_model = minizinc.Model()
        self.cp_model.add_file(self.mzn_file_name)
        self.cp_inst = minizinc.Instance(solver=self.cp_solver, model=self.cp_model)
        self.cp_inst["RU"] = self.RU
        self.cp_inst["RL"] = self.RL
        self.cp_inst["NPT"] = self.NPT
        self.result = self.cp_inst.solve(timeout=time_limit)
        ##########################
        ##########################
        elapsed_time = time.time() - start_time
        print("Elapsed time: {:0.02f} seconds".format(elapsed_time))


        if self.result.status == minizinc.Status.OPTIMAL_SOLUTION or self.result.status == minizinc.Status.SATISFIED or \
                            self.result.status == minizinc.Status.ALL_SOLUTIONS:
            if self.RB > 0:     
                self.print_activeness_pattern(sub_cipher="Eb")
            self.print_activeness_pattern(sub_cipher="E1")
            self.print_activeness_pattern(sub_cipher="E2")
            if self.RF > 0:
                self.print_activeness_pattern(sub_cipher="Ef")
            if self.RF + self.RB > 0:
                self.num_of_involved_key_cells = self.result["key_entropy_sum"]
            print("Number of actual involved key cells: {:02d}".format(self.num_of_involved_key_cells))
            key_counter_sum = self.result["key_counter_sum"]
            key_counter_active_sum = self.result["key_counter_active_sum"]
            self.lazy_tweak_cells = []
            for i in range(16):
                if key_counter_sum[i] <= self.NPT and key_counter_active_sum[i] >= 1:
                    self.lazy_tweak_cells += ["TK[{:02d}] ".format(i)]
            print("Tweakey cells that are active at most {:02d} times:\n".format(self.NPT) + ", ".join(self.lazy_tweak_cells))
            self.draw_graph()
            
        elif self.result.status == minizinc.Status.UNSATISFIABLE:
            print("Model is unsatisfiable")
        else:
            print("Solving process was interrupted")

    @staticmethod
    def print_state(state):
        """
        Print the state of the ZC distinguisher
        """
    
        temp = ""
        for i in range(4):
            for j in range(4):
                temp += str(state[i][j]) + " "
            temp += "\n"
        print(temp)

    def print_activeness_pattern(self, sub_cipher):
        """
        Print the (upper/lower) trail of the ZC distinguisher
        """

        if sub_cipher == "E1":
            print("Activeness pattern in E1:")
            for r in range(self.RU + 1):
                state = self.result["forward_mask_x"][r]
                self.print_state(state)
        elif sub_cipher == "E2":
            print("Activeness pattern in E2:")
            for r in range(self.RL + 1):
                state = self.result["backward_mask_x"][r]
                self.print_state(state)
        elif sub_cipher == "Eb":
            print("Activeness pattern in Eb:")
            for r in range(self.RB + 1):
                state = self.result["backward_eb_mask_x"][r]
                self.print_state(state)
        elif sub_cipher == "Ef":
            print("Activeness pattern in Ef:")
            for r in range(self.RF + 1):
                state = self.result["forward_ef_mask_x"][r]
                self.print_state(state)
    
    @staticmethod
    def paint_eb_ef(state):
        """
        Paint Eb or Ef
        """

        before_sb = ""
        after_sb = ""
        after_addtk = ""
        after_sr = ""
        subtweakey = ""

        for i, j in itertools.product(range(0, 4), range(0, 4)):
            if state[i][j] == 1:
                before_sb += "\Fill[active]{{ss{0}{1}}}".format(i, j)
                after_sr += "\Fill[active]{{ss{0}{1}}}".format(i, (j + i)%4)
        after_sb = before_sb
        subtweakey = after_addtk = after_sb
        return before_sb, after_sb, after_addtk, after_sr, subtweakey
    
    @staticmethod
    def gen_subtwaek_text(permutation_r):
        """
        Generate the text content of subtweakey
        """
        
        text = ""
        for i, j in itertools.product(range(2), range(4)):
            text += "\Cell{{ss{0}{1}}}{{\\texttt{{{2}}}}}".format(i, j, hex(permutation_r[4*i + j])[2:])
        return text

    @staticmethod
    def paint_e1_e2(state_before_sb, state_after_sb):
        """
        Paint E1
        """

        before_sb = ""
        after_sb = ""
        after_addtk = ""
        after_sr = ""
        subtweakey = ""

        for i in range(4):
            for j in range(4):
                ######## paint before sb ########
                if state_before_sb[i][j] == 1:
                    before_sb += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, j)
                elif state_before_sb[i][j] == 2:
                    before_sb += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, j)
                elif state_before_sb[i][j] == 3:
                    before_sb += "\Fill[unknown]{{ss{0}{1}}}".format(i, j)
                ######## paint after sb ########
                if state_after_sb[i][j] == 1:
                    after_sb += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, j)
                    after_sr += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, (j + i)%4)
                elif state_after_sb[i][j] == 2:
                    after_sb += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, j)
                    after_sr += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, (j + i)%4)
                elif state_after_sb[i][j] == 3:
                    after_sb += "\Fill[unknown]{{ss{0}{1}}}".format(i, j)
                    after_sr += "\Fill[unknown]{{ss{0}{1}}}".format(i, (j + i)%4)
            if i <= 1:
                subtweakey += after_sb   
        after_addtk = after_sb
        return before_sb, after_sb, after_addtk, after_sr, subtweakey

    def draw_graph(self):
        """
        Draw the figure of the ZC distinguisher
        """

        contents = ""
        # head lines
        contents += trim(r"""
                    % \documentclass[11pt,a3paper,parskip=half]{scrartcl}
                    \documentclass[varwidth=50cm]{standalone}
                    % \usepackage[margin=1cm]{geometry}
                    \usepackage{skinnyzero}
                    \usepackage{tugcolors}

                    \begin{document}

                    \TKthreefalse % true: show 3 tweakey states / false: show 1 tweakey state
                    \substeptrue  % true: show state after each substep / false: show only 2 state per round

                    %\begin{figure}
                    %\centering
                    \begin{tikzpicture}
                    \SkinnyInit{}{}{}{} % init coordinates, print labels""") + "\n\n"
        # draw E1
        for r in range(self.RU):
            state_before_sb = self.result["forward_mask_x"][r]
            state_after_sb = self.result["forward_mask_sbx"][r]
            before_sb, after_sb, after_addtk, after_sr, subtweakey = self.paint_e1_e2(state_before_sb, state_after_sb)
            subtweak_state = self.result["permutation_per_round"][r + self.RB]
            subtweakey += self.gen_subtwaek_text(subtweak_state)
            next_state_before_sb = self.result["forward_mask_x"][r + 1]
            if r == self.RU - 1:
                next_state_after_sb = next_state_before_sb
            else:
                next_state_after_sb = self.result["forward_mask_sbx"][r + 1]
            after_mixcol, _, _, _, _ = self.paint_e1_e2(next_state_before_sb, next_state_after_sb)
            contents += trim(r"""
            \SkinnyRoundTK[""" + str(self.RB + r) + r"""]
                          {""" + before_sb + r"""} % state (input)
                          {""" + subtweakey + r"""} % tk[1]
                          {""" + r"""} % tk[2]
                          {""" + r"""} % tk[3]
                          {""" + after_sb + """} % state (after subcells)
                          {""" + after_addtk + r"""} % state (after addtweakey)
                          {""" + after_sr + r"""} % state (after shiftrows)""") + "\n\n"
            if r == self.RU - 1:
                contents += r"""\SkinnyFin[""" + str(self.RB + r + 1) + r"""]{""" + after_mixcol + r"""} % state (after mixcols)""" + "\n\n"                
            elif (r + self.RB) % 2 == 1:
                contents += trim(r"""\SkinnyNewLine[""" + str(self.RB + r + 1) + r"""]{""") + after_mixcol + r"""} % state (after mixcols)""" + "\n"                
        
        contents += r"""\end{tikzpicture}""" + "\n\n" + r"""\begin{tikzpicture}""" + "\n\n"
        contents += r"""\SkinnyInit{}{}{}{}""" + "\n\n"
        # draw E2
        for r in range(self.RL):
            state_before_sb = self.result["backward_mask_x"][r]
            state_after_sb = self.result["backward_mask_sbx"][r]
            before_sb, after_sb, after_addtk, after_sr, subtweakey = self.paint_e1_e2(state_before_sb, state_after_sb)
            subtweak_state = self.result["permutation_per_round"][r + self.RB + self.RU]
            subtweakey += self.gen_subtwaek_text(subtweak_state)
            next_state_before_sb = self.result["backward_mask_x"][r + 1]
            if r == self.RL - 1:
                next_state_after_sb = next_state_before_sb
            else:
                next_state_after_sb = self.result["backward_mask_sbx"][r + 1]
            after_mixcol, _, _, _, _ = self.paint_e1_e2(next_state_before_sb, next_state_after_sb)
            contents += trim(r"""
            \SkinnyRoundTK[""" + str(self.RB + self.RU + r) + r"""]
                          {""" + before_sb + r"""} % state (input)
                          {""" + subtweakey + r"""} % tk[1]
                          {""" + r"""} % tk[2]
                          {""" + r"""} % tk[3]
                          {""" + after_sb + """} % state (after subcells)
                          {""" + after_addtk + r"""} % state (after addtweakey)
                          {""" + after_sr + r"""} % state (after shiftrows)""") + "\n\n"
            if r == self.RL - 1:
                    contents += trim(r"""\SkinnyFin[""" + str(self.RB + self.RU + r + 1) + r"""]{""") + after_mixcol + r"""} % state (after mixcols)""" + "\n\n"
            elif (r + self.RB + self.RU + self.RL) % 2 == 1:
                    contents += trim(r"""\SkinnyNewLine[""" + str(self.RB + self.RU + r + 1) + r"""]{""") + after_mixcol + r"""} % state (after mixcols)""" + "\n"
        # end lines
        contents += trim(r"""\ZeroLegend{\ZLfill{nonzerofixed}{fixed}
                             \ZLfill{nonzeroany}{nonzero}
                             \ZLfill{unknown}{any}}""") + "\n"
        contents += r"""\end{tikzpicture}""" + "\n"
        contents += r"""%\caption{ZC/Integral attack on """ +  str(self.num_of_attacked_rounds) +\
                    r""" rounds of """ + self.target_variant +\
                    r""". Twakeys cells that are active at most """ + str(self.NPT) + " times: " + ", ".join(self.lazy_tweak_cells) + \
                    r""". No. of involved key cells: """ +  str(self.num_of_involved_key_cells) + "}\n"
        contents += trim(r"""%\end{figure}
                              \end{document}""")
        with open(self.output_file_name, "w") as output_file:
            output_file.write(contents)

def parse_args():
    """
    parse input parameters
    """

    parser = ArgumentParser(description="This tool finds a zero-correlation distinguisher"
                                        "optimized for key recovery",
                            formatter_class=RawTextHelpFormatter)
    parser.add_argument("-RB", "--nroundsEb", default=0, type=int, help="choose the number of rounds for Eb\n")
    parser.add_argument("-RU", "--nroundsE1", default=4, type=int, help="choose the number of rounds for E1\n")
    parser.add_argument("-RL", "--nroundsE2", default=8, type=int, help="choose the number of rounds for E2\n")
    parser.add_argument("-RF", "--nroundsEf", default=0, type=int, help="choose the number of rounds for Ef\n")
    parser.add_argument("-v", "--variant", default=2, type=int, help="choose input mzn file\n")
    parser.add_argument("-sl", "--solver", default="ortools", type=str,
                        choices=['gecode', 'chuffed', 'coin-bc', 'gurobi', 'picat', 'scip', 'choco', 'ortools'],
                        help="choose a cp solver\n")
    parser.add_argument("-tl", "--timelimit", default=3600, type=int, help="set a time limit for the solver in seconds\n")
    parser.add_argument("-out", "--outputfile", default="output.tex", type=str, help="output file including the Tikz code to generate the figure of the attack\n")
    return vars(parser.parse_args())

if __name__ == '__main__':
    locals().update(parse_args())
    print("Input arguments:")
    print("(RB, RU, RL, RF, solver, variant, timelimit) = ({}, {}, {}, {}, {}, {}, {})\n".format(\
            nroundsEb, nroundsE1, nroundsE2,\
            nroundsEf, solver, variant, timelimit))
    zc = ZC(RB = nroundsEb, 
            RU = nroundsE1, 
            RL = nroundsE2, 
            RF = nroundsEf,
            cp_solver_name = solver, 
            variant = variant, 
            time_limit = timelimit,
            output_file_name = outputfile)
    zc.search()
