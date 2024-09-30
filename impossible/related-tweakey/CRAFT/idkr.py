#!/usr/env/bin python3
#-*- coding: UTF-8 -*-

"""
# Author: Hosein Hadipour
# Email: hsn.hadipour@gmail.com
# Date:  Sep 2022

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

# Check if "OR Tools" appears in the output of "minizinc --solvers" command 
import subprocess
try:
    output = subprocess.run(['minizinc', '--solvers'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if "com.google.ortools.sat" in output.stdout.decode("utf-8"):
        ortools_available = True
        print("OR Tools is available")
    else:
        ortools_available = False
        print("OR Tools is not available")
except FileNotFoundError:
    ortools_available = False

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

    def __init__(self, Rb, R1, R2, Rf, \
                cp_solver_name, Offset=0, \
                time_limit="None",
                output_file_name="output") -> None:
        ZC.ZC_counter += 1
        self.id = ZC.ZC_counter
        self.name = "ZC" + str(self.id)
        self.type = "ZC"
        self.q_tk_permutation = [12, 10, 15, 5, 14, 8, 9, 2, 11, 3, 7, 4, 6, 0, 1, 13]
        self.p_permutation = [15, 12, 13, 14, 10, 9, 8, 11, 6, 5, 4, 7, 1, 2, 3, 0]
        
        self.Rb = Rb
        self.R1 = R1
        self.R2 = R2
        self.Rf = Rf
        self.num_of_attacked_rounds = self.Rb + self.R1 + self.R2 + self.Rf
        self.num_of_involved_key_cells = 0

        self.cp_solver_name = cp_solver_name
        self.offset = Offset
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
        self.mzn_file_name = "cpkrrtk.mzn"
        self.output_file_name = output_file_name
    
    def search(self):
        """
        Search for a zero-correlation distinguisher
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
        self.cp_inst["Rb"] = self.Rb
        self.cp_inst["R1"] = self.R1
        self.cp_inst["R2"] = self.R2
        self.cp_inst["Rf"] = self.Rf
        self.cp_inst["offset"] = self.offset
        self.result = self.cp_inst.solve(timeout=time_limit)
        ##########################
        ##########################
        elapsed_time = time.time() - start_time
        print("Elapsed time: {:0.02f} seconds".format(elapsed_time))


        if self.result.status == minizinc.Status.OPTIMAL_SOLUTION or self.result.status == minizinc.Status.SATISFIED or \
                            self.result.status == minizinc.Status.ALL_SOLUTIONS:
            self.draw_graph()
            
        elif self.result.status == minizinc.Status.UNSATISFIABLE:
            print("Model is unsatisfiable")
        else:
            print("Solving process was interrupted")
    
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

    def extract_internal_states_ul(self, r, updown):
        """
        Paint Eu and El
        """

        before_mc = ""
        after_mc = ""
        round_tk = ""
        after_addtk = ""
        after_permutation = ""
        if updown == "u":
            rtk_index = (self.offset + self.Rb + r)%4
        elif updown == "l":
            rtk_index = (self.offset + self.Rb + self.R1 + r)%4

        for i in range(16):
            if self.result["ax" + updown][r][i] == 1:
                before_mc += "\Fill[nonzerofixed]{{s{0}}}".format(i)
            elif self.result["ax" + updown][r][i] == 2:
                before_mc += "\Fill[nonzeroany]{{s{0}}}".format(i)
            elif self.result["ax" + updown][r][i] == 3:
                before_mc += "\Fill[unknown]{{s{0}}}".format(i)
            if (updown == "u" and r <= self.R1 - 1) or (updown == "l" and r <= self.R2 - 1):
                if self.result["ay" + updown][r][i] == 1:
                    after_mc += "\Fill[nonzerofixed]{{s{0}}}".format(i)
                elif self.result["ay" + updown][r][i] == 2:
                    after_mc += "\Fill[nonzeroany]{{s{0}}}".format(i)
                elif self.result["ay" + updown][r][i] == 3:
                    after_mc += "\Fill[unknown]{{s{0}}}".format(i)
                if self.result["az" + updown][r][i] == 1:
                    after_addtk += "\Fill[nonzerofixed]{{s{0}}}".format(i)
                    after_permutation += "\Fill[nonzerofixed]{{s{0}}}".format(self.p_permutation[i])
                elif self.result["az" + updown][r][i] == 2:
                    after_addtk += "\Fill[nonzeroany]{{s{0}}}".format(i)
                    after_permutation += "\Fill[nonzeroany]{{s{0}}}".format(self.p_permutation[i])
                elif self.result["az" + updown][r][i] == 3:    
                    after_addtk += "\Fill[unknown]{{s{0}}}".format(i)
                    after_permutation += "\Fill[unknown]{{s{0}}}".format(self.p_permutation[i])
                if self.result["at"][rtk_index][i] == 1:
                    round_tk += "\Fill[nonzerofixed]{{s{0}}}".format(i)
                elif self.result["at"][rtk_index][i] == 2:
                    round_tk += "\Fill[nonzeroany]{{s{0}}}".format(i)
                elif self.result["at"][rtk_index][i] == 3:
                    round_tk += "\Fill[unknown]{{s{0}}}".format(i)
        return before_mc, after_mc, round_tk, after_addtk, after_permutation
    
    def draw_eb(self, r):
        """
        Paint Eb
        """

        before_mc = ""
        after_mc = ""
        round_tk = ""
        after_addtk = ""
        after_permutation = ""

        for i in range(16):
            if self.result["axb"][r][i] == 1:
                before_mc += "\Fill[active]{{s{0}}}".format(i)
            if self.result["ayb"][r][i] == 1:
                after_mc += "\Fill[active]{{s{0}}}".format(i)
            if r <= (self.Rb - 1) and self.result["axb"][r + 1][self.p_permutation[i]] == 1:
                after_addtk += "\Fill[active]{{s{0}}}".format(i)
                after_permutation += "\Fill[active]{{s{0}}}".format(self.p_permutation[i])
            if self.result["atbf"][(self.offset + r)%4][i] == 1:
                round_tk += "\Fill[active]{{s{0}}}".format(i)
            
            if self.result["kdxb"][r][i] == 1:
                before_mc += "\PattCell[black]{{s{0}}}".format(i)
            if self.result["kdyb"][r][i] == 1:
                after_mc += "\PattCell[black]{{s{0}}}".format(i)
            if r <=  (self.Rb - 1) and self.result["kdzb"][r][i] == 1:
                after_addtk += "\PattCell[black]{{s{0}}}".format(i)
                after_permutation += "\PattCell[black]{{s{0}}}".format(self.p_permutation[i])
            
            if self.result["kxb"][r][i] == 1:
                before_mc += "\MarkCell[marc]{{s{0}}}".format(i)
            if self.result["kyb"][r][i] == 1:
                after_mc += "\MarkCell[marc]{{s{0}}}".format(i)
                round_tk += "\MarkCell[marc]{{s{0}}}".format(i)
                after_addtk += "\MarkCell[marc]{{s{0}}}".format(i)
                after_permutation += "\MarkCell[marc]{{s{0}}}".format(self.p_permutation[i])
        return before_mc, after_mc, round_tk, after_addtk, after_permutation
    
    def draw_ef(self, r):
        """
        Paint Ef
        """

        before_mc = ""
        after_mc = ""
        round_tk = ""
        after_addtk = ""
        after_permutation = ""

        for i in range(16):
            if self.result["axf"][r][i] == 1:
                before_mc += "\Fill[active]{{s{0}}}".format(i)
            if r <= (self.Rf - 1) and self.result["ayf"][r][i] == 1:
                after_mc += "\Fill[active]{{s{0}}}".format(i)
            if r <= (self.Rf - 1) and self.result["azf"][r][i] == 1:
                after_addtk += "\Fill[active]{{s{0}}}".format(i)
                after_permutation += "\Fill[active]{{s{0}}}".format(self.p_permutation[i])
            if self.result["atbf"][(self.offset + self.Rb + self.R1 + self.R2 + r)%4][i] == 1:
                round_tk += "\Fill[active]{{s{0}}}".format(i)
            
            if r <= (self.Rf - 1) and self.result["kdxf"][r][i] == 1:
                before_mc += "\PattCell[black]{{s{0}}}".format(i)
            if r <= (self.Rf - 1) and self.result["kdyf"][r][i] == 1:
                after_mc += "\PattCell[black]{{s{0}}}".format(i)
            if r <= (self.Rf - 1) and self.result["kdzf"][r][i] == 1:
                after_addtk += "\PattCell[black]{{s{0}}}".format(i)
                after_permutation += "\PattCell[black]{{s{0}}}".format(self.p_permutation[i])
            
            if self.result["kxf"][r][i] == 1:
                before_mc += "\MarkCell[marc]{{s{0}}}".format(i)
            if r <= (self.Rf - 1) and self.result["kyf"][r][i] == 1:
                after_mc += "\MarkCell[marc]{{s{0}}}".format(i)
                round_tk += "\MarkCell[marc]{{s{0}}}".format(i)
                after_addtk += "\MarkCell[marc]{{s{0}}}".format(i)
                after_permutation += "\MarkCell[marc]{{s{0}}}".format(self.p_permutation[i])
        return before_mc, after_mc, round_tk, after_addtk, after_permutation

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

    def draw_graph(self):
        """
        Draw the figure of the ZC distinguisher
        """

        contents = ""
        # head lines
        contents += trim(r"""
                    \documentclass[10pt]{standalone}
                    % \documentclass[11pt,a3paper,parskip=half]{scrartcl}
                    % \usepackage[margin=1cm]{geometry}
                    \usepackage{craft}
                    \usepackage{tugcolors}
                    \usetikzlibrary{patterns}
                    \newcommand{\PattCell}[2][markopts]{\draw[pattern color=#1,pattern=north east lines] (#2) ++(-.5,.5) rectangle +(1,-1);}
                    \newcommand{\MarkCell}[2][markopts]{\fill[#1] (#2) ++(-.5,.5) -- +(0,-.3) -- +(.7,-1) -- +(1,-1) -- +(1,-.7) -- +(.3,0) -- cycle;}


                    \begin{document}
                    \colorlet{nonzerofixed}{tugyellow}
                    \colorlet{nonzeroany}{tugred}
                    \colorlet{unknown}{tugblue}
                    \colorlet{active}{cyan}
                    \colorlet{marc}{tugred}
                    
                    %\begin{figure}
                    %\centering

                    \begin{tikzpicture}
                    \CraftInit""") + "\n\n"
        # draw Eb
        for r in range(self.Rb):
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
        for r in range(self.R1):
            before_mc, after_mc, round_tk, after_addtk, after_permutation = self.extract_internal_states_ul(r, "u")
            if r == 0:
                temp = self.draw_eb(self.Rb)
                before_mc += temp[0]
            round_tk += self.gen_subtweak_text(r + self.Rb)
            contents += trim(r"""
            \CraftRound[""" + str(r + self.Rb) + r"""]
                       {""" + before_mc + r"""} % state (input)
                       {""" + after_mc + r"""} % state (after mixcolumns)
                       {""" + round_tk + """} % round tweakey
                       {""" + after_addtk + r"""} % state (after addroundtweakey)
                       {""" + after_permutation + r"""} % state (after permutenibbles)""") + "\n\n"            
            before_mc, _, _, _, _ = self.extract_internal_states_ul(r + 1, "u")                
            if (r + self.Rb) % 2 == 1 or r == self.R1 - 1:
                contents += trim(r"""\CraftNewLine[""" + str(r + self.Rb + 1) + r"""]{""") + before_mc + r"""} % state (after s-box)""" + "\n"            
        # draw E2
        for r in range(self.R2):
            before_mc, after_mc, round_tk, after_addtk, after_permutation = self.extract_internal_states_ul(r, "l")
            round_tk += self.gen_subtweak_text(self.Rb + self.R1 + r)
            contents += trim(r"""
            \CraftRound[""" + str(r + self.Rb + self.R1) + r"""]
                       {""" + before_mc + r"""} % state (input)
                       {""" + after_mc + r"""} % state (after mixcolumns)
                       {""" + round_tk + """} % round tweakey
                       {""" + after_addtk + r"""} % state (after addroundtweakey)
                       {""" + after_permutation + r"""} % state (after permutenibbles)""") + "\n\n"
            before_mc, _, _, _, _ = self.extract_internal_states_ul(r + 1, "l")
            if r == (self.R2 - 1):
                before_mc, _, _, _, _ = self.draw_ef(0)
            if (r + self.Rb + self.R1) % 2 == 1:
                contents += trim(r"""\CraftNewLine[""" + str(r + self.Rb + self.R1 + 1) + r"""]{""") + before_mc + r"""} % state (after s-box)""" + "\n"
        # draw Ef
        for r in range(self.Rf):
            before_mc, after_mc, round_tk, after_addtk, after_permutation = self.draw_ef(r)
            round_tk += self.gen_key_text(r + self.Rb + self.R1 + self.R2)
            contents += trim(r"""
            \CraftRound[""" + str(r + self.Rb + self.R1 + self.R2) + r"""]
                       {""" + before_mc + r"""} % state (input)
                       {""" + after_mc + r"""} % state (after mixcolumns)
                       {""" + round_tk + """} % round tweakey
                       {""" + after_addtk + r"""} % state (after addroundtweakey)
                       {""" + after_permutation + r"""} % state (after permutenibbles)""") + "\n\n"
            before_mc, _, _, _, _ = self.draw_ef(r + 1)
            if r == self.Rf - 1:
                contents += r"""\CraftFin[""" + str(r + self.Rb + self.R1 + self.R2 + 1) + r"""]{""" + before_mc + r"""} % state (after s-box)""" + "\n\n"            
            elif (r + self.Rb + self.R1 + self.R2) % 2 == 1:
                contents += trim(r"""\CraftNewLine[""" + str(r + self.Rb + self.R1  + self.R2 + 1) + r"""]{""") + before_mc + r"""} % state (after s-box)""" + "\n\n"
        # end lines
        contents += r"""\end{tikzpicture}""" + "\n"
        contents += r"""%\caption{ZC/Integral attack on """ +  str(self.num_of_attacked_rounds) + "of CRAFT." + "\n"
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
    parser.add_argument("-Rb", "--nroundsEb", default=4, type=int, help="choose the number of rounds for Eb\n")
    parser.add_argument("-R1", "--nroundsEu", default=6, type=int, help="choose the number of rounds for Eu\n")
    parser.add_argument("-R2", "--nroundsEl", default=7, type=int, help="choose the number of rounds for El\n")
    parser.add_argument("-Rf", "--nroundsEf", default=4, type=int, help="choose the number of rounds for Ef\n")
    parser.add_argument("-of", "--offset", default=1, type=int, help="0, 1, 2, 3\n")
    parser.add_argument("-sl", "--solver", default="ortools", type=str,
                        choices=['gecode', 'chuffed', 'coin-bc', 'gurobi', 'picat', 'scip', 'choco', 'ortools'],
                        help="choose a cp solver\n")
    parser.add_argument("-tl", "--timelimit", default=3600, type=int, help="set a time limit for the solver in seconds\n")
    parser.add_argument("-out", "--outputfile", default="output.tex", type=str, help="output file including the Tikz code to generate the figure of the attack\n")
    return vars(parser.parse_args())

if __name__ == '__main__':
    locals().update(parse_args())
    print("Input arguments:")
    print("(Rb, R1, R2, Rf, solver, offset, timelimit) = ({}, {}, {}, {}, {}, {}, {})\n".format(\
           nroundsEb, nroundsEu, nroundsEl, nroundsEf, \
           solver, offset, timelimit))
    zc = ZC(Rb = nroundsEb,
            R1 = nroundsEu, 
            R2 = nroundsEl,
            Rf = nroundsEf,
            cp_solver_name = solver, 
            Offset = offset, 
            time_limit = timelimit,
            output_file_name = outputfile)
    zc.search()
    if zc.result.status == minizinc.Status.OPTIMAL_SOLUTION:        
        print("data_complexity1_1    = \t{:0.02f}".format(zc.result["data_complexity1_1"]))
        print("data_complexity1_2    = \t{:0.02f}".format(zc.result["data_complexity1_2"]))
        print("data_complexity1      = \t{:0.02f}".format(zc.result["data_complexity1"]))
        print("data_complexity2      = \t{:0.02f}".format(zc.result["data_complexity2"]))    
        print("g                     = \t{}".format(zc.result["g"]))        
        print("log2(g) - 0.53        = \t{:0.02f}".format(zc.result["log_2_minus_053_of_g"]))
        print("t_complexity[0]       = \t{:0.02f}".format(zc.result["t_complexity"][0]))
        print("t_complexity[1]       = \t{:0.02f}".format(zc.result["t_complexity"][1]))
        print("t_complexity[2]       = \t{:0.02f}".format(zc.result["t_complexity"][2]))
        print("t_complexity[3]       = \t{:0.02f}".format(zc.result["t_complexity"][3]))
        print("#"*40)
        print("no. of attacked rounds: \t{:02d}".format(zc.num_of_attacked_rounds))
        print("time complexity       = \t{:0.02f}".format(zc.result["max_term"]))
        print("data_complexity       = \t{:0.02f}".format(zc.result["t_complexity"][0]))
        print("memory complexity     = \t{:0.02f}".format(zc.result["memory_complexity"]))
        print("cin                   = \t{:0.02f}".format(zc.result["c_in"]))
        print("cout                  = \t{:0.02f}".format(zc.result["c_out"]))
        print("delta_in              = \t{:0.02f}".format(zc.result["delta_in_weight"]))
        print("delta_out             = \t{:0.02f}".format(zc.result["delta_out_weight"]))
        print("#involved key cells   = \t{:02d}".format(zc.result["k_tot"]))   
    else:
        print("I think there is no ID attack on {} rounds with this configuration!".format(zc.num_of_attacked_rounds))

