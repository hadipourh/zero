#!/usr/env/bin python3
#-*- coding: UTF-8 -*-

"""
# Author: Hosein Hadipour
# Email: hsn.hadipour@gmail.com
# Date: July 2020

A New Automatic Tool for Zero-correlation and Impossible Differential Attacks
Copyright (C) 2022  Hosein Hadipour
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import itertools
import os
import sys
import time
from traceback import print_stack
import minizinc
import datetime
from argparse import ArgumentParser, RawTextHelpFormatter

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

        self.RU = RU
        self.RL = RL
        self.num_of_attacked_rounds = self.RU + self.RL 
        self.num_of_involved_key_cells = 0

        self.cp_solver_name = cp_solver_name
        self.variant = variant
        self.supported_cp_solvers = ['gecode', 'chuffed', 'cbc', 'gurobi',
                                     'picat', 'scip', 'choco', 'ortools']
        assert(self.cp_solver_name in self.supported_cp_solvers)
        self.cp_solver = minizinc.Solver.lookup(self.cp_solver_name)
        self.time_limit = time_limit
        self.mzn_file_name = None
        self.output_file_name = output_file_name
        self.mzn_file_name = "deoxysdist.mzn"

        if self.variant == "tk2":             
            self.target_variant = r"""Deoxys-BC-256"""
            self.p = 2
        elif self.variant == "tk3":             
            self.target_variant = r"""Deoxys-BC-384"""
            self.p = 3
        else:
            raise Exception("Unknown mzn_file_name")
    
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
        self.cp_inst["p"] = self.p
        self.result = self.cp_inst.solve(timeout=time_limit)
        ##########################
        ##########################
        elapsed_time = time.time() - start_time
        print("Elapsed time: {:0.02f} seconds".format(elapsed_time))


        if self.result.status == minizinc.Status.OPTIMAL_SOLUTION or self.result.status == minizinc.Status.SATISFIED or \
                            self.result.status == minizinc.Status.ALL_SOLUTIONS:
            self.print_activeness_pattern(sub_cipher="E1")
            self.print_activeness_pattern(sub_cipher="E2")
            key_counter_sum = self.result["key_counter_sum_dist"]
            key_counter_active_sum = self.result["key_counter_active_sum"]
            self.lazy_tweak_cells = []
            for i in range(16):
                if key_counter_sum[i] <= self.p and key_counter_active_sum[i] >= 1:
                    self.lazy_tweak_cells += ["TK[{:02d}] ".format(i)]
            print("Tweakey cells that are active at most {:02d} times:\n".format(self.p) + ", ".join(self.lazy_tweak_cells))
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
                state = self.result["AXU"][r]
                self.print_state(state)
        elif sub_cipher == "E2":
            print("Activeness pattern in E2:")
            for r in range(self.RL + 1):
                state = self.result["AXL"][r]
                self.print_state(state)
    
    @staticmethod
    def gen_subtwaek_text(permutation_r):
        """
        Generate the text content of subtweakey
        """
        
        text = ""
        for i, j in itertools.product(range(4), range(4)):
            text += "\Cell{{ss{0}{1}}}{{\\texttt{{{2}}}}}".format(i, j, hex(permutation_r[i + 4*j])[2:])
        return text

    def paint_eu(self, r):
        """
        Paint E1
        """

        input_state = ""
        round_key = ""
        after_ark = ""
        after_sb = ""
        after_sr = ""

        for i in range(4):
            for j in range(4):                
                if self.result["AXU"][r][i][j] == 1:
                    input_state += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, j)
                elif self.result["AXU"][r][i][j] == 2:
                    input_state += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, j)
                elif self.result["AXU"][r][i][j] == 3:
                    input_state += "\Fill[unknown]{{ss{0}{1}}}".format(i, j)                
                if r <= self.RU - 1:
                    if self.result["AYU"][r][i][j] == 1:
                        after_sb += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, j)
                        after_sr += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, (j - i)%4)
                    elif  self.result["AYU"][r][i][j] == 2:
                        after_sb += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, j)
                        after_sr += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, (j - i)%4)
                    elif  self.result["AYU"][r][i][j] == 3:
                        after_sb += "\Fill[unknown]{{ss{0}{1}}}".format(i, j)
                        after_sr += "\Fill[unknown]{{ss{0}{1}}}".format(i, (j - i)%4)
        round_key = input_state
        after_ark = input_state
        return input_state, round_key, after_ark, after_sb, after_sr
    
    def paint_el(self, r):
        """
        Paint E1
        """

        input_state = ""
        round_key = ""
        after_ark = ""
        after_sb = ""
        after_sr = ""

        for i in range(4):
            for j in range(4):                
                if self.result["AXL"][r][i][j] == 1:
                    input_state += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, j)
                elif self.result["AXL"][r][i][j] == 2:
                    input_state += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, j)
                elif self.result["AXL"][r][i][j] == 3:
                    input_state += "\Fill[unknown]{{ss{0}{1}}}".format(i, j)                                
                if r <= self.RL - 1:
                    if self.result["AYL"][r][i][j] == 1:
                        after_sb += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, j)
                        after_sr += "\Fill[nonzerofixed]{{ss{0}{1}}}".format(i, (j - i)%4)
                    elif  self.result["AYL"][r][i][j] == 2:
                        after_sb += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, j)
                        after_sr += "\Fill[nonzeroany]{{ss{0}{1}}}".format(i, (j - i)%4)
                    elif  self.result["AYL"][r][i][j] == 3:
                        after_sb += "\Fill[unknown]{{ss{0}{1}}}".format(i, j)
                        after_sr += "\Fill[unknown]{{ss{0}{1}}}".format(i, (j - i)%4)
        after_ark = input_state
        round_key = input_state
        return input_state, round_key, after_ark, after_sb, after_sr

    def draw_graph(self):
        """
        Draw the figure of the ZC distinguisher
        """

        contents = ""
        # head lines
        contents += trim(r"""
                    \documentclass{standalone}
                    \usepackage{skinnyzero}
                    \usepackage{aes}
                    \begin{document}
                    \begin{tikzpicture}
                    \AesInit % init coordinates, print labels""") + "\n\n"                    
        # draw E1
        for r in range(self.RU):
            input_state, round_key, after_ark, after_sb, after_sr = self.paint_eu(r)
            subtweak_state = self.result["permutation_per_round"][r]
            round_key += self.gen_subtwaek_text(subtweak_state)
            if r <= self.RU - 1:
                next_input_state, _, _, _, _ = self.paint_eu(r + 1)
            else:
                next_input_state = ""           
            contents += trim(r"""
            \AesRound[""" + str(r) + r"""]
                    {""" + input_state + r"""} % state input
                    {""" + round_key + r"""} % round key
                    {""" + after_ark + r"""} % state after AK
                    {""" + after_sb + r"""} % state after SB
                    {""" + after_sr + r"""} % state after SR""") + "\n\n"
            if r == self.RU - 1:
                contents += r"""\AesFin[""" + str(r + 1) + r"""]{""" + next_input_state + r"""} % state (after mixcols)""" + "\n\n"                                
            elif r % 2 == 1:
                contents += trim(r"""\AesNewLine[""" + str(r + 1) + r"""]{""") + next_input_state + r"""} % state (after mixcols)""" + "\n"
        # contents += r"""\AesNewLine[""" + str(self.RU) + r"""]""" + "\n\n"

        contents += r"""\tikzset{shift={(0, -2)}}""" + "\n"
        contents += r"""\AesInit""" + "\n"
        # draw E2
        for r in range(self.RL):
            input_state, round_key, after_ark, after_sb, after_sr = self.paint_el(r)
            subtweak_state = self.result["permutation_per_round"][r + self.RU]
            round_key += self.gen_subtwaek_text(subtweak_state)
            if r <= self.RL - 1:
                next_input_state, _, _, _, _ = self.paint_el(r + 1)
            else:
                next_input_state = ""             
            contents += trim(r"""
            \AesRound[""" + str(r + self.RU) + r"""]
                    {""" + input_state + r"""} % state input
                    {""" + round_key + r"""} % round key
                    {""" + after_ark + r"""} % state after AK
                    {""" + after_sb + r"""} % state after SB
                    {""" + after_sr + r"""} % state after SR""") + "\n\n"
            if r == self.RL - 1:
                contents += trim(r"""\AesFin[""" + str(self.RU + r + 1) + r"""]{""") + next_input_state + r"""} % state (after mixcols)""" + "\n\n"
            elif r % 2 == 1:
                contents += trim(r"""\AesNewLine[""" + str(self.RU + r + 1) + r"""]{""") + next_input_state + r"""} % state (after mixcols)""" + "\n"
        # end lines
        contents += trim(r"""\ZeroLegend{
                             \ZLfill{nonzeroany}{nonzero}
                             \ZLfill{unknown}{any}}""") + "\n"
        contents += r"""\end{tikzpicture}""" + "\n"
        contents += r"""%\caption{ZC/Integral attack on """ +  str(self.num_of_attacked_rounds) +\
                    r""" rounds of """ + self.target_variant +\
                    r""". Twakeys cells that are active at most """ + str(self.p) + " times: " + ", ".join(self.lazy_tweak_cells) + \
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
    parser.add_argument("-RU", "--nroundsE1", default=2, type=int, help="choose the number of rounds for E1\n")
    parser.add_argument("-RL", "--nroundsE2", default=5, type=int, help="choose the number of rounds for E2\n")
    parser.add_argument("-RF", "--nroundsEf", default=0, type=int, help="choose the number of rounds for Ef\n")
    parser.add_argument("-v", "--variant", default="tk3", type=str, help="choose input mzn file\n")
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
