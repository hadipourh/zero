#!/usr/env/bin python3
#-*- coding: UTF-8 -*-

"""
# Author: Hosein Hadipour
# Contact: hsn.hadipour@gmail.com

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
import minizinc
import datetime
from argparse import ArgumentParser, RawTextHelpFormatter
from draw import *

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

    def __init__(self, params) -> None:
        ZC.ZC_counter += 1
        self.id = ZC.ZC_counter
        self.name = "ZC" + str(self.id)
        self.type = "ZC"

        self.variant = params["variant"]
        self.RB = params["RB"]
        self.RU = params["RU"]
        self.RL = params["RL"]
        self.RF = params["RF"]
        self.cp_solver_name = params["cp_solver_name"]
        self.num_of_threads = params["num_of_threads"]
        self.time_limit = params["time_limit"]
        self.output_file_name = params["output_file_name"]
        
        self.RD = self.RU + self.RL
        self.num_of_attacked_rounds = self.RB + self.RU + self.RL + self.RF
        self.num_of_involved_key_cells = 0
        # number of parallel paths in tweakey schedule
        self.P = 1

        self.supported_cp_solvers = ['gecode', 'chuffed', 'cbc', 'gurobi',
                                     'picat', 'scip', 'choco', 'ortools']
        assert(self.cp_solver_name in self.supported_cp_solvers)
        self.cp_solver = minizinc.Solver.lookup(self.cp_solver_name)
        
        self.mzn_file_name = None
        if  self.RB + self.RF == 0:
            self.mzn_file_name = "distinguisher.mzn"
            self.target_variant = r"""\SKINNY"""
        elif self.variant == "tk1":
            self.mzn_file_name = "attack.mzn"
            self.P = 1
            self.target_variant = r"""\SKINNY[$n$-$n$]"""
        elif self.variant == "tk2": 
            self.mzn_file_name = "attack.mzn"
            self.P = 2
            self.target_variant = r"""\SKINNY[$n$-$2n$]"""
        elif self.variant == "tk3":
            self.mzn_file_name = "attack.mzn"
            self.P = 3
            self.target_variant = r"""\SKINNY[$n$-$3n$]"""
        else:
            raise Exception("Unknown variant!")
    

    #############################################################################################################################################
    #############################################################################################################################################
    #############################################################################################################################################
    #  ____          _               _    _             __  __             _        _ 
    # / ___|   ___  | |__   __ ___  | |_ | |__    ___  |  \/  |  ___    __| |  ___ | |
    # \___ \  / _ \ | |\ \ / // _ \ | __|| '_ \  / _ \ | |\/| | / _ \  / _` | / _ \| |
    #  ___) || (_) || | \ V /|  __/ | |_ | | | ||  __/ | |  | || (_) || (_| ||  __/| |
    # |____/  \___/ |_|  \_/  \___|  \__||_| |_| \___| |_|  |_| \___/  \__,_| \___||_|
    
    def search(self):
        """
        Search for a zero-correlation distinguisher (optimized for key recovery)
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
        self.cp_inst["RB"] = self.RB
        self.cp_inst["RU"] = self.RU
        self.cp_inst["RL"] = self.RL
        self.cp_inst["RF"] = self.RF
        self.cp_inst["P"] = self.P
        self.result = self.cp_inst.solve(timeout=time_limit, processes=self.num_of_threads)
        ##########################
        ##########################
        elapsed_time = time.time() - start_time
        print("Elapsed time: {:0.02f} seconds".format(elapsed_time))


        if self.result.status == minizinc.Status.OPTIMAL_SOLUTION or self.result.status == minizinc.Status.SATISFIED or \
                            self.result.status == minizinc.Status.ALL_SOLUTIONS:            
            if self.RF + self.RB > 0:
                self.num_of_involved_key_cells = self.result["KS"]
            self.print_activeness_pattern()
            self.print_attack_parameters()
            draw = Draw(self, output_file_name=self.output_file_name)
            draw.generate_attack_shape()
        elif self.result.status == minizinc.Status.UNSATISFIABLE:
            print("Model is unsatisfiable")
        else:
            print("Solving process was interrupted")
    #############################################################################################################################################
    #############################################################################################################################################
    #############################################################################################################################################

    @staticmethod
    def print_state(state):
        """
        Print the state of the ZC distinguisher
        """

        output = ""
        for i in range(16):
            output += str(state[i]) + " "
            if (i + 1) % 4 == 0:
                output += "\n"
        print(output)

    def print_activeness_pattern(self):
        """
        Print the activeness pattern of the ZC distinguisher
        """
        print("#"*50)
        if self.RB > 0:            
            print("Activeness pattern in EB:")
            for r in range(self.RB + 1):
                state = self.result["AXB"][r]
                self.print_state(state)                    
        print("Activeness pattern in EU:")
        for r in range(self.RU + 1):
            state = self.result["AXU"][r]
            self.print_state(state)
        print("Activeness pattern in EL:")
        for r in range(self.RL + 1):
            state = self.result["AXL"][r]
            self.print_state(state)
        if self.RF > 0:
            print("Activeness pattern in EF:")
            for r in range(self.RF + 1):
                state = self.result["AXF"][r]
                self.print_state(state)
        
    def print_attack_parameters(self):
        """
        Print the attack parameters
        """

        print("Attack parameters:")
        print("RB                    = \t{:02d}".format(self.RB))
        print("RU                    = \t{:02d}".format(self.RU))
        print("RL                    = \t{:02d}".format(self.RL))
        print("RF                    = \t{:02d}".format(self.RF))
        print("#attacked rounds      = \t{:02d}".format(self.num_of_attacked_rounds))          
        print("#involved key cells   = \t{:02d}".format(self.num_of_involved_key_cells))

#############################################################################################################################################
#############################################################################################################################################
#############################################################################################################################################
#  _   _                    ___         _                __                   
# | | | | ___   ___  _ __  |_ _| _ __  | |_  ___  _ __  / _|  __ _   ___  ___ 
# | | | |/ __| / _ \| '__|  | | | '_ \ | __|/ _ \| '__|| |_  / _` | / __|/ _ \
# | |_| |\__ \|  __/| |     | | | | | || |_|  __/| |   |  _|| (_| || (__|  __/
#  \___/ |___/ \___||_|    |___||_| |_| \__|\___||_|   |_|   \__,_| \___|\___|
                                                                                
def loadparameters(args):
    '''
    Extract parameters from the argument list and input file
    '''

    # Load default values
    params = {"variant" : "tk3",
              "RB" : 4,
              "RU" : 4,
              "RL" : 5,
              "RF" : 8,
              "cp_solver_name" : "ortools",
              "num_of_threads" : 8,
              "time_limit" : None,
              "output_file_name" : "output.tex"}
    # Overwrite parameters if they are set on command line
    if args.variant is not None:
        params["variant"] = args.variant
    if args.RU is not None:
        params["RU"] = args.RU
    if args.RL is not None:
        params["RL"] = args.RL
    if args.RB is not None:
        params["RB"] = args.RB
    if args.RF is not None:
        params["RF"] = args.RF
    if args.sl is not None:
        params["cp_solver_name"] = args.sl
    if args.p is not None:
        params["num_of_threads"] = args.p
    if args.tl is not None:
        params["time_limit"] = args.tl
    if args.o is not None:
        params["output_file_name"] = args.o
    return params

def main():
    '''
    Parse the arguments and start the request functionality with the provided
    parameters
    '''
    parser = ArgumentParser(description="This tool finds the optimum zero-correlation attack",
                            formatter_class=RawTextHelpFormatter)
    parser.add_argument("-v", "--variant", default="tk3", type=str, help="SKINNY variant (tk1, tk2, tk3)\n")

    parser.add_argument("-RB", default=4, type=int, help="Number of rounds for EB")
    parser.add_argument("-RU", default=4, type=int, help="Number of rounds for EU")
    parser.add_argument("-RL", default=5, type=int, help="Number of rounds for EL")
    parser.add_argument("-RF", default=8, type=int, help="Number of rounds for EF")    

    parser.add_argument("-sl", default="ortools", type=str,
                        choices=['gecode', 'chuffed', 'coin-bc', 'gurobi', 'picat', 'scip', 'choco', 'ortools'],
                        help="choose a cp solver\n")    
    parser.add_argument("-p", default=8, type=int, help="number of threads for solvers supporting multi-threading\n")    
    parser.add_argument("-tl", default=3600, type=int, help="set a time limit for the solver in seconds\n")
    parser.add_argument("-o", default="output.tex", type=str, help="output file including the Tikz code to generate the shape of the attack\n")

    # Parse command line arguments and construct parameter list
    args = parser.parse_args()
    params = loadparameters(args)
    zc_attack = ZC(params)
    print("#"*50)
    print("Searching for an attack with the following parameters")
    print("Variant: {}".format(params["variant"]))
    print("RB: {}".format(params["RB"]))
    print("RU: {}".format(params["RU"]))
    print("RL: {}".format(params["RL"]))
    print("RF: {}".format(params["RF"]))
    print("CP solver: {}".format(params["cp_solver_name"]))
    print("Number of threads: {}".format(params["num_of_threads"]))
    print("Time limit: {}".format(params["time_limit"]))
    print("#"*50)
    zc_attack.search()
#############################################################################################################################################
#############################################################################################################################################
#############################################################################################################################################

if __name__ == "__main__":
    main()