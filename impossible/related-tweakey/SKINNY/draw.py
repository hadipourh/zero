"""
# Author: Hosein Hadipour
# Email: hsn.hadipour@gmail.com
# Date: Nov 2022

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
    Draw the shape of ID attack
    """

    def __init__(self, id_object, output_file_name="output.tex"):
        self.result = id_object.result
        self.RB = id_object.RB
        self.RU = id_object.RU
        self.RL = id_object.RL
        self.RF = id_object.RF
        self.RD = id_object.RD
        self.RT = id_object.RT        
        self.num_of_involved_key_cells = id_object.result["KS"]
        self.CB_tot = id_object.result["CB_tot"]
        self.CF_tot = id_object.result["CF_tot"]
        self.WB = id_object.result["WB"]
        self.WF = id_object.result["WF"]
        self.variant = id_object.variant
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
        for i in range(16):
            if self.result["KDXB"][1][i] == 1:
                output["after_mix_columns"] += "\PattCell{{s{0}}}".format(i)
            if self.result["KDXB"][0][i] == 1:
                output["before_sb"] += "\PattCell{{s{0}}}".format(i)
                output["after_sb"] += "\PattCell{{s{0}}}".format(i)
                output["after_sr"] += "\PattCell{{s{0}}}".format(self.inv_permutation[i])
        for i in range(16):
            if self.result["KXB"][1][i] == 1:
                output["subtweakey"] += "\MarkCell{{s{0}}}".format(i)
                output["after_mix_columns"] += "\MarkCell{{s{0}}}".format(i)
            if self.result["KXB"][0][i] == 1:
                output["before_sb"] += "\MarkCell{{s{0}}}".format(i)
            if self.result["KYB"][0][i] == 1:
                output["after_sb"] += "\MarkCell{{s{0}}}".format(i)
                output["after_sr"] += "\MarkCell{{s{0}}}".format(self.inv_permutation[i])
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
            if self.result["AZB"][r][i] == 1:
                output["after_addtk"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_sr"] += "\Fill[active]{{s{0}}}".format(self.inv_permutation[i])
            if self.result["AXB"][r + 1][i] == 1:
                output["after_mix_columns"] += "\Fill[active]{{s{0}}}".format(i)
            if (i <= 7) and (self.result["ASTK"][r][i] == 1):
                output["subtweakey"] += "\Fill[active]{{s{0}}}".format(i)
        for i in range(16):
            if self.result["KDXB"][r][i] == 1:
                output["before_sb"] += "\PattCell[black]{{s{0}}}".format(i)
                output["after_sb"] += "\PattCell[black]{{s{0}}}".format(i)          
            if self.result["KDZB"][r][i] == 1:
                output["after_addtk"] += "\PattCell[black]{{s{0}}}".format(i)
                output["after_sr"] += "\PattCell[black]{{s{0}}}".format(self.inv_permutation[i])
            if self.result["KDXB"][r + 1][i] == 1:
                output["after_mix_columns"] += "\PattCell[black]{{s{0}}}".format(i)
        for i in range(16):
            if self.result["KXB"][r][i] == 1:
                output["before_sb"] += "\MarkCell{{s{0}}}".format(i)
            if self.result["KYB"][r][i] == 1:
                output["after_sb"] += "\MarkCell{{s{0}}}".format(i)
                output["after_addtk"] += "\MarkCell{{s{0}}}".format(i)
                output["after_sr"] += "\MarkCell{{s{0}}}".format(self.inv_permutation[i])
                if i <= 7:
                    output["subtweakey"] += "\MarkCell{{s{0}}}".format(i)
            if self.result["KXB"][r + 1][i] == 1:
                output["after_mix_columns"] += "\MarkCell{{s{0}}}".format(i)
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
            if self.result["AZF"][r][i] == 1:
                output["after_addtk"] += "\Fill[active]{{s{0}}}".format(i)
                output["after_sr"] += "\Fill[active]{{s{0}}}".format(self.inv_permutation[i])
            if self.result["AXF"][r + 1][i] == 1:
                output["after_mix_columns"] += "\Fill[active]{{s{0}}}".format(i)
            if (i <= 7) and (self.result["ASTK"][self.RB + self.RU + self.RL + r][i] == 1):
                output["subtweakey"] += "\Fill[active]{{s{0}}}".format(i)
        for i in range(16):
            if self.result["KDXF"][r][i] == 1:
                output["before_sb"] += "\PattCell[black]{{s{0}}}".format(i)
                output["after_sb"] += "\PattCell[black]{{s{0}}}".format(i)                
            if self.result["KDZF"][r][i] == 1:
                output["after_addtk"] += "\PattCell[black]{{s{0}}}".format(i)
                output["after_sr"] += "\PattCell[black]{{s{0}}}".format(self.inv_permutation[i])
            if self.result["KDXF"][r + 1][i] == 1:
                output["after_mix_columns"] += "\PattCell[black]{{s{0}}}".format(i)
        for i in range(16):
            if self.result["KXF"][r][i] == 1:
                output["before_sb"] += "\MarkCell{{s{0}}}".format(i)
            if self.result["KYF"][r][i] == 1:
                output["after_sb"] += "\MarkCell{{s{0}}}".format(i)
                output["after_addtk"] += "\MarkCell{{s{0}}}".format(i)
                output["after_sr"] += "\MarkCell{{s{0}}}".format(self.inv_permutation[i])
                if i <= 7:
                    output["subtweakey"] += "\MarkCell{{s{0}}}".format(i)
            if self.result["KXF"][r + 1][i] == 1:
                output["after_mix_columns"] += "\MarkCell{{s{0}}}".format(i)
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
            output["after_addtk"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AZU"][r][i]], i)
            output["after_sr"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AZU"][r][i]], self.inv_permutation[i])
            output["after_mix_columns"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AXU"][r + 1][i]], i)
            if i <= 7:
                output["subtweakey"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["ASTK"][self.RB + r][i]], i)
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
            output["after_addtk"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AZL"][r][i]], i)                
            output["after_sr"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AZL"][r][i]], self.inv_permutation[i])
            output["after_mix_columns"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["AXL"][r + 1][i]], i)
            if i <= 7:
                output["subtweakey"] += "\FillCell[{0}]{{s{1}}}".format(self.fillcolor[self.result["ASTK"][self.RB + self.RU + r][i]], i)
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
                    %\begin{figure}
                    %\centering
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
        contents += r"""\ZeroIDLegend""" + "\n"
        contents += r"""\end{tikzpicture}""" + "\n"
        contents += r"""%\caption{ID attack on """ +  str(self.RT) +\
                    r""" rounds of SKINNY-TK""" + str(self.variant) +\
                    r""". $|k\In \cup k\Out| = """ +  str(self.num_of_involved_key_cells) + "$" +\
                    r""". $c\In = """ + str(self.CB_tot) + "$" + \
                    r""". $c\Out = """ + str(self.CF_tot) + "$" + \
                    r""". $\Delta\In = """ + str(self.WB) + "$" + \
                    r""". $\Delta\Out = """ + str(self.WF) + "$" + "}\n"
        contents += trim(r"""%\end{figure}""") + "\n"
        contents += trim(r"""\end{document}""")
        with open(self.output_file_name, "w") as output_file:
            output_file.write(contents)
