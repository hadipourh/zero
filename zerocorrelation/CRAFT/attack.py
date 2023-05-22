#!/usr/env/bin python3
#-*- coding: UTF-8 -*-

"""
# Author: Hosein Hadipour
# Email: hsn.hadipour@gmail.com
# Date: Sep 2022

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
                cp_solver_name, offset=0, \
                time_limit="None",
                output_file_name="output",
                num_of_threads=8) -> None:
        ZC.ZC_counter += 1
        self.id = ZC.ZC_counter
        self.name = "ZC" + str(self.id)
        self.type = "ZC"
        self.q_tk_permutation = [12, 10, 15, 5, 14, 8, 9, 2, 11, 3, 7, 4, 6, 0, 1, 13]
        self.p_permutation = [15, 12, 13, 14, 10, 9, 8, 11, 6, 5, 4, 7, 1, 2, 3, 0]

        self.RB = RB
        self.RU = RU
        self.RL = RL
        self.RF = RF
        self.num_of_attacked_rounds = self.RB + self.RU + self.RL + self.RF
        self.max_num_of_involved_key_cells = 0

        self.cp_solver_name = cp_solver_name
        self.offset = offset
        self.supported_cp_solvers = ['gecode', 'chuffed', 'cbc', 'gurobi',
                                     'picat', 'scip', 'choco', 'ortools']
        assert(self.cp_solver_name in self.supported_cp_solvers)
        self.cp_solver = minizinc.Solver.lookup(self.cp_solver_name)
        self.time_limit = time_limit
        self.num_of_threads = num_of_threads
        self.mzn_file_name = "attack.mzn"
        self.output_file_name = output_file_name

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
        self.cp_inst["Offset"] = self.offset
        self.cp_inst["RB"] = self.RB
        self.cp_inst["RU"] = self.RU
        self.cp_inst["RL"] = self.RL
        self.cp_inst["RF"] = self.RF        
        self.result = self.cp_inst.solve(timeout=time_limit, processes=self.num_of_threads, verbose=True)
        ##########################
        ##########################
        elapsed_time = time.time() - start_time
        print("Elapsed time: {:0.02f} seconds".format(elapsed_time))

        if self.result.status == minizinc.Status.OPTIMAL_SOLUTION or self.result.status == minizinc.Status.SATISFIED or \
                            self.result.status == minizinc.Status.ALL_SOLUTIONS:
            if self.RF + self.RB > 0:
                self.max_num_of_involved_key_cells = self.result["k_tot"]
            print("Number of actual involved key cells: {:02d}".format(self.max_num_of_involved_key_cells))        
            self.draw_graph()            
        elif self.result.status == minizinc.Status.UNSATISFIABLE:
            print("Model is unsatisfiable")
        else:
            print("Solving process was interrupted")
        
    def draw_eb(self, r):
        """
        Draw Eb
        """
        
        before_mc = ""
        after_mc = ""
        round_tk = ""
        after_addtk = ""
        after_permutation = ""

        for i in range(16):
            if self.result["kxb"][r][i] == 1:
                before_mc += "\Fill[active]{{s{0}}}".format(i)
            # if r <= self.RB - 1:
            if self.result["kxb"][r + 1][i] == 1:
                after_mc += "\Fill[active]{{s{0}}}".format(self.p_permutation[i])
                after_permutation += "\Fill[active]{{s{0}}}".format(i)                                            
        after_addtk += after_mc
        round_tk += after_mc
        return before_mc, after_mc, round_tk, after_addtk, after_permutation

    def draw_ef(self, r):
        """
        Draw Ef
        """

        before_mc = ""
        after_mc = ""
        round_tk = ""
        after_addtk = ""
        after_permutation = ""

        state_before_mc = self.result["kxf"][r]
        if r <= self.RF - 1:
            state_after_permutation = self.result["kxf"][r + 1]
        else:
            state_after_permutation = self.result["kxf"][r]    
        for i in range(16):
            if state_before_mc[i] == 1:
                before_mc += "\Fill[active]{{s{0}}}".format(i)
            if state_after_permutation[i] == 1:
                after_permutation += "\Fill[active]{{s{0}}}".format(i)
                after_mc += "\Fill[active]{{s{0}}}".format(self.p_permutation[i])
                after_addtk += "\Fill[active]{{s{0}}}".format(self.p_permutation[i])
                round_tk += "\Fill[active]{{s{0}}}".format(self.p_permutation[i]) 
        return before_mc, after_mc, round_tk, after_addtk, after_permutation
    
    def gen_subtweak_text(self, r):
        """
        Generate the text content of round tweakey
        """
        
        text = ""
        if (self.offset + r) % 4 <= 1:
            for i in range(16):
                text += "\Cell{{s{0}}}{{\\texttt{{{1}}}}}".format(i, hex(i)[2:])
        else:
            for i in range(16):
                text += "\Cell{{s{0}}}{{\\texttt{{{1}}}}}".format(i, hex(self.q_tk_permutation[i])[2:])
        return text
    
    def gen_key_text(self, r):
        """
        Generate the text content of round key
        """
        
        text = ""
        if (self.offset + r) % 2 == 0:
            for i in range(16):
                text += "\Cell{{s{0}}}{{\\textsc{{{1}}}}}".format(i, hex(i)[2:])
        else:
            for i in range(16):
                text += "\Cell{{s{0}}}{{\\textit{{{1}}}}}".format(i, hex(i)[2:])
        return text

    def draw_eul(self, r, updown):
        """
        Paint Eu and El
        """

        before_mc = ""
        after_mc = ""
        round_tk = ""
        after_addtk = ""
        after_permutation = ""

        if updown == "u":
            ul = "forward_mask"
        elif updown == "l":
            ul = "backward_mask"
        else:
            raise ValueError("updown must be either u or l")

        for i in range(16):
            if self.result[ul + "_x"][r][i] == 1:
                before_mc += "\Fill[nonzerofixed]{{s{0}}}".format(i)
            elif self.result[ul + "_x"][r][i] == 2:
                before_mc += "\Fill[nonzeroany]{{s{0}}}".format(i)
            elif self.result[ul + "_x"][r][i] == 3:
                before_mc += "\Fill[unknown]{{s{0}}}".format(i)
            if (updown == "u" and r <= self.RU - 1) or (updown == "l" and r <= self.RL - 1):
                if self.result[ul + "_y"][r][i] == 1:
                    after_mc += "\Fill[nonzerofixed]{{s{0}}}".format(i)
                    after_addtk += "\Fill[nonzerofixed]{{s{0}}}".format(i)
                    after_permutation += "\Fill[nonzerofixed]{{s{0}}}".format(self.p_permutation[i])
                elif self.result[ul + "_y"][r][i] == 2:
                    after_mc += "\Fill[nonzeroany]{{s{0}}}".format(i)
                    after_addtk += "\Fill[nonzeroany]{{s{0}}}".format(i)
                    after_permutation += "\Fill[nonzeroany]{{s{0}}}".format(self.p_permutation[i])
                elif self.result[ul + "_y"][r][i] == 3:
                    after_mc += "\Fill[unknown]{{s{0}}}".format(i)
                    after_addtk += "\Fill[unknown]{{s{0}}}".format(i)
                    after_permutation += "\Fill[unknown]{{s{0}}}".format(self.p_permutation[i])
        round_tk = ""#after_mc
        return before_mc, after_mc, round_tk, after_addtk, after_permutation


    def draw_graph(self):
        """
        Draw the figure of the integral attack
        """

        contents = ""
        # head lines
        contents += trim(r"""
                    \documentclass[10pt]{standalone}
                    % \documentclass[11pt,a3paper,parskip=half]{scrartcl}
                    % \usepackage[margin=1cm]{geometry}
                    \usepackage{craft}
                    \usepackage{tugcolors}

                    \newcommand{\TFill}[2][active]{\fill[#1] (#2) ++(-.5,.5) -- +(0,-1) -- +(1,0) -- cycle;}
                    \newcommand{\BFill}[2][green!60]{\fill[#1] (#2) ++(.5,-.5) -- +(0,1) -- +(-1,0) -- cycle;}
                    

                    \begin{document}
                    \colorlet{nonzerofixed}{tugyellow}
                    \colorlet{nonzeroany}{tugred}
                    \colorlet{unknown}{tugblue}
                    \colorlet{active}{cyan}
                    \colorlet{lazy}{gray}""" + "\n\n")
        contents += trim(r"""
                    % \begin{figure}
                    % \centering
                    \begin{tikzpicture}
                    \CraftInit{}{}{}{} % init coordinates, print labels""") + "\n\n"
        # draw Eb
        for r in range(self.RB):
            before_mc, after_mc, round_tk, after_addtk, after_permutation = self.draw_eb(r)
            round_tk += self.gen_key_text(r)
            contents += trim(r"""
            \CraftRound[""" + str(r) + r"""]
                       {""" + before_mc + r"""} % state (input)
                       {""" + after_mc + r"""} % state (after mixcolumns)
                       {""" + round_tk + """} % round tweakey
                       {""" + after_addtk + r"""} % state (after addroundtweakey)
                       {""" + after_permutation + r"""} % state (after permutenibbles)""") + "\n\n"
            before_mc, _, _, _, _ = self.draw_eb(r + 1)
            if r % 2 == 1:
               contents += trim(r"""\CraftNewLine[""" + str(r + 1) + r"""]{""") + before_mc + r"""} % state (after s-box)""" + "\n"        
        # draw E1
        for r in range(self.RU):            
            before_mc, after_mc, round_tk, after_addtk, after_permutation = self.draw_eul(r, "u")
            if r == 0:
                temp = self.draw_eb(self.RB)
                before_mc += temp[0]
            round_tk += self.gen_subtweak_text(r + self.RB)
            contents += trim(r"""
            \CraftRound[""" + str(r + self.RB) + r"""]
                       {""" + before_mc + r"""} % state (input)
                       {""" + after_mc + r"""} % state (after mixcolumns)
                       {""" + round_tk + """} % round tweakey
                       {""" + after_addtk + r"""} % state (after addroundtweakey)
                       {""" + after_permutation + r"""} % state (after permutenibbles)""") + "\n\n"            
            before_mc, _, _, _, _ = self.draw_eul(r + 1, "u")    
            if (r + self.RB) % 2 == 1 or r == self.RU - 1:
                contents += trim(r"""\CraftNewLine[""" + str(r + + self.RB + 1) + r"""]{""") + before_mc + r"""} % state (after s-box)""" + "\n"
        # draw E2
        for r in range(self.RL):
            before_mc, after_mc, round_tk, after_addtk, after_permutation = self.draw_eul(r, "l")
            round_tk += self.gen_subtweak_text(r + self.RB + self.RU)
            contents += trim(r"""
            \CraftRound[""" + str(r + self.RB + self.RU) + r"""]
                       {""" + before_mc + r"""} % state (input)
                       {""" + after_mc + r"""} % state (after mixcolumns)
                       {""" + round_tk + """} % round tweakey
                       {""" + after_addtk + r"""} % state (after addroundtweakey)
                       {""" + after_permutation + r"""} % state (after permutenibbles)""") + "\n\n"
            before_mc, _, _, _, _ = self.draw_eul(r + 1, "l")    
            if (r + self.RB + self.RU) % 2 == 1 and r != self.RL - 1:
                contents += trim(r"""\CraftNewLine[""" + str(r + self.RB + self.RU + 1) + r"""]{""") + before_mc + r"""} % state (after s-box)""" + "\n"
        # draw Ef
        for r in range(self.RF):
            before_mc, after_mc, round_tk, after_addtk, after_permutation = self.draw_ef(r)
            if r == 0 and (self.RB + self.RU + self.RL) % 2 == 0:
                contents += trim(r"""\CraftNewLine[""" + str(self.RB + self.RU + self.RL) + r"""]{""") + before_mc + r"""} % state (after s-box)""" + "\n"            
            round_tk += self.gen_key_text(r + self.RB + self.RU + self.RL)
            contents += trim(r"""
            \CraftRound[""" + str(r + self.RB + self.RU + self.RL) + r"""]
                       {""" + before_mc + r"""} % state (input)
                       {""" + after_mc + r"""} % state (after mixcolumns)
                       {""" + round_tk + """} % round tweakey
                       {""" + after_addtk + r"""} % state (after addroundtweakey)
                       {""" + after_permutation + r"""} % state (after permutenibbles)""") + "\n\n"
            before_mc, _, _, _, _ = self.draw_ef(r + 1)
            if r == self.RF - 1:
                contents += r"""\CraftFin[""" + str(r + self.RB + self.RU + self.RL + 1) + r"""]{""" + before_mc + r"""} % state (after s-box)""" + "\n\n"            
            elif (r + self.RB + self.RU + self.RL) % 2 == 1:
                contents += trim(r"""\CraftNewLine[""" + str(r + self.RB + self.RU  + self.RL + 1) + r"""]{""") + before_mc + r"""} % state (after s-box)""" + "\n\n"
        # end lines
        contents += r"""\end{tikzpicture}""" + "\n"
        contents += r"""%\caption{ZC/Integral attack on """ +  str(self.num_of_attacked_rounds) + "of CRAFT"\
                    r""". \#Involved key cells (maximum): """ +  str(self.max_num_of_involved_key_cells) + "}\n"
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
    parser.add_argument("-RB", "--nroundsEb", default=4, type=int, help="choose the number of rounds for Eb\n")
    parser.add_argument("-RU", "--nroundsE1", default=7, type=int, help="choose the number of rounds for E1\n")
    parser.add_argument("-RL", "--nroundsE2", default=6, type=int, help="choose the number of rounds for E2\n")
    parser.add_argument("-RF", "--nroundsEf", default=4, type=int, help="choose the number of rounds for Ef\n")
    parser.add_argument("-of", "--offset", default=0, type=int, help="0, 1, 2, 3\n")
    parser.add_argument("-sl", "--solver", default="ortools", type=str,
                        choices=['gecode', 'chuffed', 'coin-bc', 'gurobi', 'picat', 'scip', 'choco', 'ortools'],
                        help="choose a cp solver\n")
    parser.add_argument("-t", "--timelimit", default=3600, type=int, help="set a time limit for the solver in seconds\n")
    parser.add_argument("-o", "--outputfile", default="output.tex", type=str, help="output file including the Tikz code to generate the figure of the attack\n")
    parser.add_argument("-p", "--processes", default=8, type=int, help="number of threads for solvers supporting multi-threading\n")    
    return vars(parser.parse_args())

if __name__ == '__main__':
    locals().update(parse_args())
    print("Input arguments:")
    print("(RB, RU, RL, RF, solver, offset, timelimit, #threads) = ({}, {}, {}, {}, {}, {}, {}, {})\n".format(\
            nroundsEb, nroundsE1, nroundsE2,\
            nroundsEf, solver, offset, timelimit, processes))
    zc = ZC(RB = nroundsEb, 
            RU = nroundsE1, 
            RL = nroundsE2, 
            RF = nroundsEf,
            cp_solver_name = solver, 
            offset = offset, 
            time_limit = timelimit,
            output_file_name = outputfile,
            num_of_threads = processes)
    zc.search()