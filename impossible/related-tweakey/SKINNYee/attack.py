#!/usr/env/bin python3
#-*- coding: UTF-8 -*-

"""
# Author: Hosein Hadipour
# Email: hsn.hadipour@gmail.com

A New Automatic Tool to Search for Full Impossible Differential,
Zero-correlation and Integral Attacks
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

import time
import minizinc
import datetime
from argparse import ArgumentParser, RawTextHelpFormatter
from draw import *

line_separator = "#"*55

class ID:
    ID_counter = 0

    def __init__(self, params) -> None:
        ID.ID_counter += 1
        self.id = ID.ID_counter
        self.name = "ID" + str(self.id)
        self.type = "ID"

        self.variant = params["variant"]
        self.cell_size = params["cell_size"]
        self.RB = params["RB"]
        self.RU = params["RU"]
        self.RL = params["RL"]
        self.RF = params["RF"]
        self.RD = self.RU + self.RL
        self.RT = self.RB + self.RU + self.RL + self.RF
        self.skip_first_sbox_layer = params["sks"]
        self.is_real = params["real"]
        self.cp_solver_name = params["cp_solver_name"]
        self.time_limit = params["time_limit"]
        self.num_of_threads = params["num_of_threads"]
        self.output_file_name = params["output_file_name"]

        self.supported_cp_solvers = ['gecode', 'chuffed', 'cbc', 'gurobi',
                                     'picat', 'scip', 'choco', 'ortools']
        assert(self.cp_solver_name in self.supported_cp_solvers)
        self.cp_solver = minizinc.Solver.lookup(self.cp_solver_name)

        if self.is_real:
            self.mzn_file_name = "attackr.mzn"
        else:
            self.mzn_file_name = "attacki.mzn"            
        
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
        self.cp_inst["RB"] = self.RB
        self.cp_inst["RU"] = self.RU
        self.cp_inst["RL"] = self.RL
        self.cp_inst["RF"] = self.RF
        self.cp_inst["skip_first_sbox_layer"] = self.skip_first_sbox_layer
        self.cp_inst["cell_size"] = self.cell_size
        self.cp_inst["NPT"] = self.variant
        self.result = self.cp_inst.solve(timeout=time_limit, processes=self.num_of_threads, verbose=True)
        ##########################
        ##########################
        elapsed_time = time.time() - start_time
        print("Elapsed time: {:0.02f} seconds".format(elapsed_time))


        if self.result.status == minizinc.Status.OPTIMAL_SOLUTION or self.result.status == minizinc.Status.SATISFIED or \
                            self.result.status == minizinc.Status.ALL_SOLUTIONS:            
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

    def print_attack_parameters(self):
        """
        Print attack parameters
        """
        print("data_complexity[0]    = \t{:0.02f}".format(self.result["data_complexity"][0]))
        print("data_complexity[1]    = \t{:0.02f}".format(self.result["data_complexity"][1]))
        print("data_complexity[2]    = \t{:0.02f}".format(self.result["data_complexity"][2]))
        print("data_complexity[3]    = \t{:0.02f}".format(self.result["data_complexity"][3]))
        print("g                     = \t{}".format(self.result["g"]))
        print("log2(g) - 0.53        = \t{:0.02f}".format(self.result["log_2_minus_053_of_g"]))
        print("t_complexity[0]       = \t{:0.02f}".format(self.result["t_complexity"][0]))
        print("t_complexity[1]       = \t{:0.02f}".format(self.result["t_complexity"][1]))
        print("t_complexity[2]       = \t{:0.02f}".format(self.result["t_complexity"][2]))
        print("t_complexity[3]       = \t{:0.02f}".format(self.result["t_complexity"][3]))
        print(line_separator)
        print("#attacked rounds      = \t{:02d}".format(self.RT))
        print("#involved key cells   = \t{:02d}".format(self.result["KS"]))
        print("CB                    = \t{:02d}".format(self.result["CB_tot"]))
        print("CF                    = \t{:02d}".format(self.result["CF_tot"]))
        print("WB                    = \t{:02d}".format(self.result["WB"]))
        print("WF                    = \t{:02d}".format(self.result["WF"]))        
        print("time complexity       = \t{:0.02f}".format(self.result["max_term"]))
        print("data_complexity       = \t{:0.02f}".format(self.result["t_complexity"][0]))
        print("memory complexity     = \t{:0.02f}".format(self.result["memory_complexity"]))

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
    params = {"variant" : 2,
              "cell_size" : 4,
              "RB" : 5,
              "RU" : 12,
              "RL" : 6,
              "RF" : 4,
              "sks" : True,
              "real" : False,
              "cp_solver_name" : "ortools",
              "num_of_threads" : 8,
              "time_limit" : None,
              "output_file_name" : "output.tex"}
    # Overwrite parameters if they are set on command line
    if args.variant is not None:
        params["variant"] = args.variant
    if args.cs is not None:
        params["cell_size"] = args.cs
    if args.RU is not None:
        params["RU"] = args.RU
    if args.RL is not None:
        params["RL"] = args.RL
    if args.RB is not None:
        params["RB"] = args.RB
    if args.RF is not None:
        params["RF"] = args.RF
    if args.sks is not None:
        params["sks"] = args.sks
    if args.real is not None:
        params["real"] = args.real
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
    parser = ArgumentParser(description="This tool finds the optimum impossible-differential attack",
                            formatter_class=RawTextHelpFormatter)
    parser.add_argument("-v", "--variant", default=4, type=int, help="For SKINNYee, it should be 4\n")
    parser.add_argument("-cs", default=4, type=int, help="For SKINNYee, it should be 4\n")

    parser.add_argument("-RB", default=5, type=int, help="Number of rounds for EB")
    parser.add_argument("-RU", default=12, type=int, help="Number of rounds for EU")
    parser.add_argument("-RL", default=6, type=int, help="Number of rounds for EL")
    parser.add_argument("-RF", default=4, type=int, help="Number of rounds for EF")

    parser.add_argument("-sks", action='store_true', default=None, help="Use this flag to move the fist S-box layer of distinguisher to key-recovery part\n")
    parser.add_argument("-real", action='store_true', default=None, help="Use this flag if you want to create a floating point CP model and then use Gurobi\n")
    parser.add_argument("-sl", default="ortools", type=str,
                        choices=['gecode', 'chuffed', 'coin-bc', 'gurobi', 'picat', 'scip', 'choco', 'ortools'],
                        help="The CP solver\n")    
    parser.add_argument("-p", default=8, type=int, help="Number of threads for solvers supporting multi-threading\n")    
    parser.add_argument("-tl", default=3600, type=int, help="Time limit for the solver in seconds\n")
    parser.add_argument("-o", default="output.tex", type=str, help="Output file including the Tikz code to generate the shape of the attack\n")

    # Parse command line arguments and construct parameter list
    args = parser.parse_args()
    params = loadparameters(args)
    id_attack = ID(params)
    print(line_separator)
    print("Searching for an attack with the following parameters")
    print("Variant: {}".format(params["variant"]))
    print("Cell size: {}".format(params["cell_size"]))
    print("RB: {}".format(params["RB"]))
    print("RU: {}".format(params["RU"]))
    print("RL: {}".format(params["RL"]))
    print("RF: {}".format(params["RF"]))
    print("sks: {}".format(params["sks"]))
    print("real: {}".format(params["real"]))
    print("CP solver: {}".format(params["cp_solver_name"]))
    print("Number of threads: {}".format(params["num_of_threads"]))
    print("Time limit: {}".format(params["time_limit"]))
    print(line_separator)
    id_attack.search()
    
#############################################################################################################################################
#############################################################################################################################################
#############################################################################################################################################

if __name__ == "__main__":
    main()
