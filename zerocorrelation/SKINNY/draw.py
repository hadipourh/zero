"""
# Author: Hosein Hadipour
# Email: hsn.hadipour@gmail.com
# Date: Nov 2022

A module to draw the shape of zero-correlation attacks
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


import sys

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

class Draw():
    """
    Draw the shape of rectangle attack
    """

    def __init__(self, zc_object, output_file_name="output.tex"):
        self.result = zc_object.result
        self.RB = zc_object.RB
        self.RU = zc_object.RU
        self.RL = zc_object.RL
        self.RF = zc_object.RF
        self.RD = zc_object.RD
        self.related_tweak = False
        self.inv_permutation = [0, 1, 2, 3, 5, 6, 7, 4, 10, 11, 8, 9, 15, 12, 13, 14]
        self.tweakey_permutation = [9, 15, 8, 13, 10, 14, 12, 11, 0, 1, 2, 3, 4, 5, 6, 7]
        self.output_file_name = output_file_name
        self.fillcolor = {0: "white", 1: "nonzerofixed", 2: "nonzeroany", 3: "unknown"}


    def gen_round_tweakey_labels(self, round_number):
        """
        Generate the round tweakey labels
        """
        if round_number == 0 and self.RB != 0:
            text = \
                r"""\Cell{ss00}{\texttt{0}}\Cell{ss01}{\texttt{1}}\Cell{ss02}{\texttt{2}}\Cell{ss03}{\texttt{3}}""" + \
                r"""\Cell{ss10}{\texttt{0}}\Cell{ss11}{\texttt{1}}\Cell{ss12}{\texttt{2}}\Cell{ss13}{\texttt{3}}""" + \
                r"""\Cell{ss20}{\texttt{7}}\Cell{ss21}{\texttt{4}}\Cell{ss22}{\texttt{5}}\Cell{ss23}{\texttt{6}}""" + \
                r"""\Cell{ss30}{\texttt{0}}\Cell{ss31}{\texttt{1}}\Cell{ss32}{\texttt{2}}\Cell{ss33}{\texttt{3}}"""
            return text
        round_tweakey_state = list(range(16))
        for r in range(round_number):
            round_tweakey_state = [self.tweakey_permutation[i] for i in round_tweakey_state]
        text = ""
        for i in range(8):
            text += "\Cell{{s{0}}}{{\\texttt{{{1}}}}}".format(i, hex(round_tweakey_state[i])[2:])
        return text

    def draw_1st_round_eb(self):
        """
        Pait the first round of EB
        """

        output = dict()    
        output["before_sb"] = ""              
        output["after_sb"] = ""
        output["after_addtk"] = ""
        output["after_sr"] = ""
        output["subtweakey"] = ""
        output["after_mix_columns"] = ""
        for i in range(16):
            if self.result["AXB"][0][i] == 1:
                output["before_sb"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_sb"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_sr"] += "\Fill[active]{{s{0}}}".format(self.inv_permutation[i])
            if self.result["AXB"][1][i] == 1:
                output["after_mix_columns"] += "\Fill[active]{{s{0}}}".format(i)
                output["subtweakey"] += "\Fill[active]{{s{0}}}".format(i)
        return output

    def draw_eb(self, r):
        """
        Paint EB
        """
        
        if r == 0:
            return self.draw_1st_round_eb()
        output = dict()    
        output["before_sb"] = ""              
        output["after_sb"] = ""
        output["after_addtk"] = ""
        output["after_sr"] = ""
        output["subtweakey"] = ""
        output["after_mix_columns"] = ""
        for i in range(16):
            if self.result["AXB"][r][i] == 1:
                output["before_sb"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_sb"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_addtk"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_sr"] += "\Fill[active]{{s{0}}}".format(self.inv_permutation[i])
                if i <= 7:
                    output["subtweakey"] += "\Fill[active]{{s{0}}}".format(i)
            if self.result["AXB"][r + 1][i] == 1:
                output["after_mix_columns"] += "\Fill[active]{{s{0}}}".format(i)
        return output
    
    def draw_ef(self, r):
        """
        Paint EF
        """

        output = dict()    
        output["before_sb"] = ""              
        output["after_sb"] = ""
        output["after_addtk"] = ""
        output["after_sr"] = ""
        output["subtweakey"] = ""
        output["after_mix_columns"] = ""
        for i in range(16):
            if self.result["AXF"][r][i] == 1:
                output["before_sb"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_sb"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_addtk"] += "\Fill[active]{{s{0}}}".format(i)                
                output["after_sr"] += "\Fill[active]{{s{0}}}".format(self.inv_permutation[i])
                if i <= 7:
                    output["subtweakey"] += "\Fill[active]{{s{0}}}".format(i)
            if self.result["AXF"][r + 1][i] == 1:
                output["after_mix_columns"] += "\Fill[active]{{s{0}}}".format(i)
        return output
    
    def draw_eu(self, r):
        """
        Paint EU
        """
        
        output = dict()
        output["before_sb"] = ""              
        output["after_sb"] = ""
        output["after_addtk"] = ""
        output["after_sr"] = ""
        output["subtweakey"] = ""
        output["after_mix_columns"] = ""
        for i in range(16):
            output["before_sb"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AXU"][r][i]], i)
            output["after_sb"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AYU"][r][i]], i)
            output["after_addtk"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AYU"][r][i]], i)                
            output["after_sr"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AYU"][r][i]], self.inv_permutation[i])
            output["after_mix_columns"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AXU"][r + 1][i]], i)
        return output

    def draw_el(self, r):
        """
        Paint EL
        """
        
        output = dict()
        output["before_sb"] = ""              
        output["after_sb"] = ""
        output["after_addtk"] = ""
        output["after_sr"] = ""
        output["subtweakey"] = ""
        output["after_mix_columns"] = ""
        for i in range(16):
            output["before_sb"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AXL"][r][i]], i)
            output["after_sb"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AYL"][r][i]], i)
            output["after_addtk"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AYL"][r][i]], i)                
            output["after_sr"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AYL"][r][i]], self.inv_permutation[i])
            output["after_mix_columns"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AXL"][r + 1][i]], i)
        return output


    def generate_attack_shape(self):
        """
        Draw the figure of the Rectangle distinguisher
        """

        contents = ""
        # head lines
        contents += trim(r"""
                    \documentclass[varwidth=50cm]{standalone}
                    \usepackage{skinnyzero}
                    \begin{document}
                    \begin{tikzpicture}
                    \SkinnyInit{}{}{}{} % init coordinates, print labels""") + "\n\n"
        # draw EB
        for r in range(self.RB):
            state = self.draw_eb(r)
            state["subtweakey"] += self.gen_round_tweakey_labels(r)
            if r == 0:                
                contents += trim(r"""
                \SkinnyRoundEK[0]
                            {""" + state["before_sb"] + r"""} % state (input)
                            {""" + state["subtweakey"] + r"""} % etk[1] (xored AFTER mixcolumns)
                            {} % tk[2] (ignored)
                            {} % tk[3] (ignored)
                            {""" + state["after_sb"] + r"""} % state (after subcells)
                            {""" + state["after_sr"] + r"""} % state (after shiftrows)
                            {""" + state["after_mix_columns"] + r"""} % state (after mixcolumns)
                """) + "\n\n"  
            else:
                contents += trim(r"""
                \SkinnyRoundTK[""" + str(r) + """]
                            {""" + state["before_sb"] + r"""} % state (input)
                            {""" + state["subtweakey"] + r"""} % tk[1]
                            {""" + r"""} % tk[2]
                            {""" + r"""} % tk[3]
                            {""" + state["after_sb"] + """} % state (after subcells)
                            {""" + state["after_addtk"] + r"""} % state (after addtweakey)
                            {""" + state["after_sr"] + r"""} % state (after shiftrows)""") + "\n\n"
            if r % 2 == 1:
                contents += trim(r"""\SkinnyNewLine[""" + str(r + 1) + r"""]{""") + state["after_mix_columns"] + r"""} % state (after mixcols)""" + "\n"

        # draw EU
        for r in range(self.RU):
            state = self.draw_eu(r)
            state["subtweakey"] += self.gen_round_tweakey_labels(r + self.RB)
            contents += trim(r"""            
            \SkinnyRoundTK[""" + str(r + self.RB) + """]
                          {""" + state["before_sb"] + r"""} % state (input)
                          {""" + state["subtweakey"] + r"""} % tk[1]
                          {""" + r"""} % tk[2]
                          {""" + r"""} % tk[3]
                          {""" + state["after_sb"] + """} % state (after subcells)
                          {""" + state["after_addtk"] + r"""} % state (after addtweakey)
                          {""" + state["after_sr"] + r"""} % state (after shiftrows)""") + "\n\n"
            if r == (self.RU - 1) and (r + self.RB)%2 == 0:
                contents += trim(r"""\SkinnyMismatchAligned[""" + str(r + self.RB + 1) + r"""]{""") + state["after_mix_columns"] + r"""} % state (after mixcols)""" + "\n"
            elif r == (self.RU - 1) and (r + self.RB)%2 == 1:
                contents += trim(r"""\SkinnyMismatchNewLine[""" + str(r + self.RB + 1) + r"""]{""") + state["after_mix_columns"] + r"""} % state (after mixcols)""" + "\n"
            elif (r  + self.RB) % 2 == 1:
                contents += trim(r"""\SkinnyNewLine[""" + str(r + self.RB + 1) + r"""]{""") + state["after_mix_columns"] + r"""} % state (after mixcols)""" + "\n"
        
        # draw EL
        for r in range(self.RL):
            state = self.draw_el(r)
            state["subtweakey"] += self.gen_round_tweakey_labels(r + self.RB + self.RU)
            contents += trim(r"""
            \SkinnyRoundTK[""" + str(r + self.RB + self.RU) + """]
                          {""" + state["before_sb"] + r"""} % state (input)
                          {""" + state["subtweakey"] + r"""} % tk[1]
                          {""" + r"""} % tk[2]
                          {""" + r"""} % tk[3]
                          {""" + state["after_sb"] + """} % state (after subcells)
                          {""" + state["after_addtk"] + r"""} % state (after addtweakey)
                          {""" + state["after_sr"] + r"""} % state (after shiftrows)""") + "\n\n"
            if (r == self.RL - 1) and (self.RF == 0):
                contents += trim(r"""\SkinnyFin[""" + str(r + self.RB + self.RU + 1) + r"""]{""") + state["after_mix_columns"] + r"""} % state (after mixcols)""" + "\n"
            elif (r + self.RB + self.RU) % 2 == 1:
                contents += trim(r"""\SkinnyNewLine[""" + str(r + self.RB + self.RU + 1) + r"""]{""") + state["after_mix_columns"] + r"""} % state (after mixcols)""" + "\n"

        # draw Ef
        for r in range(self.RF):
            state = self.draw_ef(r)
            state["subtweakey"] += self.gen_round_tweakey_labels(r + self.RB + self.RD)
            contents += trim(r"""            
            \SkinnyRoundTK[""" + str(r + self.RB + self.RD) + """]
                          {""" + state["before_sb"] + r"""} % state (input)
                          {""" + state["subtweakey"] + r"""} % tk[1]
                          {""" + r"""} % tk[2]
                          {""" + r"""} % tk[3]
                          {""" + state["after_sb"] + """} % state (after subcells)
                          {""" + state["after_addtk"] + r"""} % state (after addtweakey)
                          {""" + state["after_sr"] + r"""} % state (after shiftrows)""") + "\n\n"
            if r == self.RF - 1:
                contents += trim(r"""\SkinnyFin[""" + str(r + self.RB + self.RD + 1) + r"""]{""") + state["after_mix_columns"] + r"""} % state (after mixcols)""" + "\n"
            elif (r + self.RB + self.RD) % 2 == 1:
                contents += trim(r"""\SkinnyNewLine[""" + str(r + self.RB + self.RD + 1) + r"""]{""") + state["after_mix_columns"] + r"""} % state (after mixcols)""" + "\n"
        if self.RB + self.RF == 0:
            contents += r"""\ZeroZILegendDist""" + "\n"
        else:
            contents += r"""\ZeroZCLegend""" + "\n"
        contents += r"""\end{tikzpicture}""" + "\n"
        contents += trim(r"""\end{document}""")
        with open(self.output_file_name, "w") as output_file:
            output_file.write(contents)