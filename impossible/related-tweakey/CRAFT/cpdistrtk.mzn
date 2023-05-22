MIT License

% Copyright (c) 2022 Hosein Hadipour

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:

% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

int: R1;
int: R2;
int: Nd;
int: offset;
Nd = R1 + R2;

constraint assert(R1 >= 1,"Invalid value for R1: " ++
                "R1 must be greater than or equal to 1");

constraint assert(R2 >= 1,"Invalid value for R2: " ++
                "R2 must be greater than or equal to 1");

array[0..15] of int: p_permutation = array1d(0..15, [15, 12, 13, 14, 10, 9, 8, 11, 6, 5, 4, 7, 1, 2, 3, 0]);

%  __  __           _      _   _   _            _____                    _                ____       _              _       _      
% |  \/  | ___   __| | ___| | | |_| |__   ___  |_   _|_      _____  __ _| | _____ _   _  / ___|  ___| |__   ___  __| |_   _| | ___ 
% | |\/| |/ _ \ / _` |/ _ \ | | __| '_ \ / _ \   | | \ \ /\ / / _ \/ _` | |/ / _ \ | | | \___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \
% | |  | | (_) | (_| |  __/ | | |_| | | |  __/   | |  \ V  V /  __/ (_| |   <  __/ |_| |  ___) | (__| | | |  __/ (_| | |_| | |  __/
% |_|  |_|\___/ \__,_|\___|_|  \__|_| |_|\___|   |_|   \_/\_/ \___|\__,_|_|\_\___|\__, | |____/ \___|_| |_|\___|\__,_|\__,_|_|\___|
% model the tweakey schedule         

array[0..15] of int: q_permutation = array1d(0..15, [12, 10, 15, 5, 14, 8, 9, 2, 11, 3, 7, 4, 6, 0, 1, 13]);

array[0..3, 0..15] of var 0..3: at;
array[0..3, 0..15] of var -2..15: dt;
constraint forall(i in 0..3, j in 0..15)(link_pattern_to_value(at[i, j], dt[i, j]));
constraint forall(i in 0..15)
(
    at[1, i] = at[0, i] /\ dt[1, i] = dt[0, i]
    /\
    at[2, i] = at[0, q_permutation[i]] /\ dt[2, i] = dt[0, q_permutation[i]]
    /\
    at[3, i] = at[0, q_permutation[i]] /\ dt[3, i] = dt[0, q_permutation[i]]
);

%   ____                _             _       _          __              _____ _   _ 
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| | | |
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | | | |
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |_| |
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|\___/ 
% constraints for EU

array[0..R1, 0..15] of var 0..3: axu;
array[0..R1, 0..15] of var -2..15: dxu;
constraint forall(r in 0..R1, i in 0..15)(link_pattern_to_value(axu[r, i], dxu[r, i]));

array[0..(R1 - 1), 0..15] of var 0..3: ayu;
array[0..(R1 - 1), 0..15] of var -2..15: dyu;
constraint forall(r in 0..R1-1, i in 0..15)(link_pattern_to_value(ayu[r, i], dyu[r, i]));

array[0..(R1 - 1), 0..15] of var 0..3: azu;
array[0..(R1 - 1), 0..15] of var -2..15: dzu;
constraint forall(r in 0..(R1 - 1), i in 0..15)(link_pattern_to_value(azu[r, i], dzu[r, i]));

array[0..(R1 - 1), 0..3] of var 0..3: dummy_au;
array[0..(R1 - 1), 0..3] of var -2..15: dummy_du;
constraint forall(r in 0..(R1 - 1), i in 0..3)(link_pattern_to_value(dummy_au[r, i], dummy_du[r, i]));

% Exclude all-zero input mask
var 0..96: inputmask_distinguisher;
constraint inputmask_distinguisher = sum(i in 0..15)(ayu[0, i]) + sum(i in 0..15)(at[0, i]);
constraint inputmask_distinguisher != 0;

% MixColumn
% skip the first MixColumn
constraint forall(i in 0..15)
(
    axu[0, i] = 0
);
constraint forall(r in 1..(R1 - 1), i in 0..3)
(
    mix_column_forward(
        axu[r, i], dxu[r, i],
        axu[r, i + 4], dxu[r, i + 4],
        axu[r, i + 8], dxu[r, i + 8],
        axu[r, i + 12], dxu[r, i + 12],
        ayu[r, i], dyu[r, i],
        ayu[r, i + 4], dyu[r, i + 4],
        ayu[r, i + 8], dyu[r, i + 8],
        ayu[r, i + 12], dyu[r, i + 12],
        dummy_au[r, i], dummy_du[r, i]
    )                     
);

% AddTweakey
constraint forall(r in 0..(R1 - 1), i in 0..15)
(
    xor_operation(ayu[r, i], dyu[r, i], at[(offset + r) mod 4, i], dt[(offset + r) mod 4, i], azu[r, i], dzu[r, i])
);

% S-box
constraint forall(r in 0..(R1 - 1), i in 0..15)
(
    sb_operation(azu[r, p_permutation[i]], axu[r + 1, i])
);

%   ____                _             _       _          __              _____ _     
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| |    
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | |    
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |___ 
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_____|
% constraints for EL                                                                              

array[0..R2, 0..15] of var 0..3: axl;
array[0..R2, 0..15] of var -2..15: dxl;
constraint forall(r in 0..R2, i in 0..15)(link_pattern_to_value(axl[r, i], dxl[r, i]));

array[0..(R2 - 1), 0..15] of var 0..3: ayl;
array[0..(R2 - 1), 0..15] of var -2..15: dyl;
constraint forall(r in 0..(R2 - 1), i in 0..15)(link_pattern_to_value(ayl[r, i], dyl[r, i]));

array[0..(R2 - 1), 0..15] of var 0..3: azl;
array[0..(R2 - 1), 0..15] of var -2..15: dzl;
constraint forall(r in 0..(R2 - 1), i in 0..15)(link_pattern_to_value(azl[r, i], dzl[r, i]));

array[0..(R2 - 1), 0..3] of var 0..3: dummy_al;
array[0..(R2 - 1), 0..3] of var -2..15: dummy_dl;
constraint forall(r in 0..(R2 - 1), i in 0..3)(link_pattern_to_value(dummy_al[r, i], dummy_dl[r, i]));

% Exclude all-zero output mask
var 0..96: outputmask_distinguisher;
constraint outputmask_distinguisher = sum(i in 0..15)(ayl[R2 - 1, i]) + sum(i in 0..15)(at[0, i]);
constraint outputmask_distinguisher != 0;

% MixColumn
constraint forall(r in 0..(R2 - 1), i in 0..3)
(
    mix_column_backward(
        ayl[r, i], dyl[r, i],
        ayl[r, i + 4], dyl[r, i + 4],
        ayl[r, i + 8], dyl[r, i + 8],
        ayl[r, i + 12], dyl[r, i + 12],
        axl[r, i], dxl[r, i],
        axl[r, i + 4], dxl[r, i + 4],
        axl[r, i + 8], dxl[r, i + 8],
        axl[r, i + 12], dxl[r, i + 12],
        dummy_al[r, i], dummy_dl[r, i]
    )
);

% AddTweakey
constraint forall(r in 0..(R2 - 1), i in 0..15)
(
    xor_operation(azl[r, i], dzl[r, i], at[(offset + R1 + r) mod 4, i], dt[(offset + R1 + r) mod 4, i], ayl[r, i], dyl[r, i])
);

% S-box
constraint forall(r in 0..(R2 - 2), i in 0..15)
(
    sb_operation(axl[r + 1, i], azl[r, p_permutation[i]])
);

% skip the last S-box layer by moving it into the key recovery part
constraint forall(i in 0..15)
(
    axl[R2, i] = 0
);

%   ____                             _               ____            _                 _ _      _   _             
%  / ___|_   _  __ _ _ __ __ _ _ __ | |_ ___  ___   / ___|___  _ __ | |_ _ __ __ _  __| (_) ___| |_(_) ___  _ __  
% | |  _| | | |/ _` | '__/ _` | '_ \| __/ _ \/ _ \ | |   / _ \| '_ \| __| '__/ _` |/ _` | |/ __| __| |/ _ \| '_ \ 
% | |_| | |_| | (_| | | | (_| | | | | ||  __/  __/ | |__| (_) | | | | |_| | | (_| | (_| | | (__| |_| | (_) | | | |
%  \____|\__,_|\__,_|_|  \__,_|_| |_|\__\___|\___|  \____\___/|_| |_|\__|_|  \__,_|\__,_|_|\___|\__|_|\___/|_| |_|
% include some constraints to guarantee the contradiction in the meeting point

var 0..16: contradict1;
var 0..16: contradict2;
constraint contradict1 = sum(i in 0..15)(bool2int((axu[R1, i] + axl[0, i] > 0) /\ (axu[R1, i] + axl[0, i] < 3) /\ axu[R1, i] != axl[0, i]));
constraint contradict2 = sum(i in 0..15)(bool2int(axu[R1, i] == 1 /\ axl[0, i] == 1 /\ dxu[R1, i] != dxl[0, i]));
constraint contradict1 + contradict2 > 0;

% constraint sum(i in 0..15)(ayl[R2 - 1, i]) = 1;
solve satisfy;

%     _              _ _ _                    _____                 _   _                 
%    / \  _   ___  _(_) (_) __ _ _ __ _   _  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___ 
%   / _ \| | | \ \/ / | | |/ _` | '__| | | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  / ___ \ |_| |>  <| | | | (_| | |  | |_| | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
% /_/   \_\__,_/_/\_\_|_|_|\__,_|_|   \__, | |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%                                     |___/                                               

predicate link_pattern_to_value(var 0..3: mask_vars, var -2..15: class_vars) = 
    if (mask_vars == 0) then class_vars == 0
    elseif (mask_vars == 1) then class_vars > 0
    elseif (mask_vars == 2) then class_vars == -1
    else class_vars = -2 endif
;

predicate sb_operation(var 0..3: mask_in, var 0..3: mask_out) = 
    mask_out != 1 /\
    (mask_in + mask_out) in {0,3,4,6} /\
    mask_out >= mask_in /\
    (mask_out - mask_in) <= 1
;

predicate xor_operation(var 0..3: diff_a, var -2..15: class_a, var 0..3: diff_b, var -2..15: class_b, var 0..3: diff_c, var -2..15: class_c) = 
    if (diff_a + diff_b > 2) then
        (diff_c = 3) /\ (class_c = -2)
    elseif (diff_a + diff_b = 1) then
        (diff_c = 1) /\ (class_c = class_a + class_b)
    elseif ((diff_a == 0) /\ (diff_b == 0)) then
        (diff_c = 0) /\ (class_c = 0)
    elseif (class_a + class_b < 0) then
        (diff_c = 2) /\ (class_c = -1)
    elseif (class_a == class_b) then
        (diff_c = 0) /\ (class_c = 0)
    else
        (diff_c = 1) /\
        class_c = (bool2int((class_a mod 2) != (class_b mod 2)) + 
        bool2int(((class_a div 2) mod 2) != ((class_b div 2) mod 2)) * 2 + 
        bool2int(((class_a div 4) mod 2) != ((class_b div 4) mod 2)) * 4 +
        bool2int(((class_a div 8) mod 2) != ((class_b div 8) mod 2)) * 8)
    endif
;

predicate mix_column_forward(var 0..3: in_diff1, var -2..15: in_class1, 
                           var 0..3: in_diff2, var -2..15: in_class2, 
                           var 0..3: in_diff3, var -2..15: in_class3, 
                           var 0..3: in_diff4, var -2..15: in_class4, 
                           var 0..3: out_diff1, var -2..15: out_class1, 
                           var 0..3: out_diff2, var -2..15: out_class2, 
                           var 0..3: out_diff3, var -2..15: out_class3, 
                           var 0..3: out_diff4, var -2..15: out_class4, 
                           var 0..3: auxi_diff, var -2..15: auxi_class) =
    xor_operation(in_diff3, in_class3, in_diff4, in_class4, auxi_diff, auxi_class)
    /\
    xor_operation(in_diff1, in_class1, auxi_diff, auxi_class, out_diff1, out_class1)
    /\
    xor_operation(in_diff2, in_class2, in_diff4, in_class4, out_diff2, out_class2)
    /\
    out_diff3 = in_diff3 /\
    out_class3 = in_class3
    /\
    out_diff4 = in_diff4 /\
    out_class4 = in_class4
;

predicate mix_column_backward(var 0..3: in_diff1, var -2..15: in_class1, 
                           var 0..3: in_diff2, var -2..15: in_class2, 
                           var 0..3: in_diff3, var -2..15: in_class3, 
                           var 0..3: in_diff4, var -2..15: in_class4, 
                           var 0..3: out_diff1, var -2..15: out_class1, 
                           var 0..3: out_diff2, var -2..15: out_class2, 
                           var 0..3: out_diff3, var -2..15: out_class3, 
                           var 0..3: out_diff4, var -2..15: out_class4, 
                           var 0..3: auxi_diff, var -2..15: auxi_class) =
    % MixColumns of CRAFT is involutory and hence the the constraints are the same as for MixColumns forward
    xor_operation(in_diff3, in_class3, in_diff4, in_class4, auxi_diff, auxi_class)
    /\
    xor_operation(in_diff1, in_class1, auxi_diff, auxi_class, out_diff1, out_class1)
    /\
    xor_operation(in_diff2, in_class2, in_diff4, in_class4, out_diff2, out_class2)
    /\
    out_diff3 = in_diff3 /\
    out_class3 = in_class3
    /\
    out_diff4 = in_diff4 /\
    out_class4 = in_class4
;
