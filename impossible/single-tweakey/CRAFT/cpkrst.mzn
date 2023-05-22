% MIT License

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

int: RB;
int: RU;
int: RL;
int: RF;
int: Nd;
int: Nr;
Nd = RU + RL;
Nr = RB + RU + RL + RF;

constraint assert(RB >= 1,"Invalid value for RB: " ++
                "RB must be greater than or equal to 1");

constraint assert(RU >= 1,"Invalid value for RU: " ++
                "RU must be greater than or equal to 1");

constraint assert(RL >= 1,"Invalid value for RL: " ++
                "RL must be greater than or equal to 1");

constraint assert(RF >= 1,"Invalid value for RF: " ++
                "RF must be greater than or equal to 1");

array[0..15] of int: p_permutation = array1d(0..15, [15, 12, 13, 14, 10, 9, 8, 11, 6, 5, 4, 7, 1, 2, 3, 0]);

%   ____                _             _       _          __              _____ _     
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| |__  
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | '_ \ 
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |_) |
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_.__/ 
% constraints for Eb

% #####################################################################
% modeling the differeence propagation and the difference cancellations
% #####################################################################

array[0..(RB + 1), 0..15] of var 0..1: axb;
array[0..15] of var 0..1: ayb_rb;
array[0..RB, 0..11] of var 0..1: cb;
array[0..RB, 0..7] of var 0..1: auxib;

% link the end of Eb to the beginning of Eu
constraint forall(i in 0..15)
(
    if ayu[0, i] >= 1 then
        ayb_rb[i] = 1
    else
        ayb_rb[i] = 0
    endif
);

constraint forall(i in 0..3)
(
    mix_column_backward_with_probability_one_diff(
        ayb_rb[i], ayb_rb[i + 4], ayb_rb[i + 8], ayb_rb[i + 12],
        axb[RB, i], axb[RB, i + 4], axb[RB, i + 8], axb[RB, i + 12],
        cb[RB, 3*i], cb[RB, 3*i + 1], cb[RB, 3*i + 2],
        auxib[RB, 2*i], auxib[RB, 2*i + 1]
    )
);

constraint forall(r in 0..(RB - 1), i in 0..3)
(
    mix_column_backward_with_probability_one_diff(
        axb[r + 1, p_permutation[i]], axb[r + 1, p_permutation[i + 4]], axb[r + 1, p_permutation[i + 8]], axb[r + 1, p_permutation[i + 12]],
        axb[r, i], axb[r, i + 4], axb[r, i + 8], axb[r, i + 12],
        cb[r, 3*i], cb[r, 3*i + 1], cb[r, 3*i + 2],
        auxib[r, 2*i], auxib[r, 2*i + 1]
    )
);


% #######################################
% modeling the guess-and-determine
% #######################################

array[0..RB, 0..15] of var 0..1: kdxb;
array[0..RB, 0..15] of var 0..1: kdyb;
array[0..RB, 0..15] of var 0..1: kxb;
array[0..RB, 0..15] of var 0..1: kyb;

% link the end of Eb to the beginning of Eu
constraint forall(i in 0..15)
(
    if ayu[0, i] == 1 then
        kdyb[RB, i] = 1
    else
        kdyb[RB, i] = 0
    endif
);

constraint forall(r in 0..RB, i in 0..3)
(
    if kdyb[r, i] == 1 then (kdxb[r, i] = axb[r, i] /\ kdxb[r, i + 8] = axb[r, i + 8] /\ kdxb[r, i + 12] = axb[r, i + 12]) endif
    /\
    if kdyb[r, i + 4] == 1 then (kdxb[r, i + 4] = axb[r, i + 4] /\ kdxb[r, i + 12] = axb[r, i + 12]) endif
    /\
    if kdyb[r, i + 8] == 1 then (kdxb[r, i + 8] = axb[r, i + 8]) endif
    /\
    if kdyb[r, i + 12] == 1 then (kdxb[r, i + 12] = axb[r, i + 12]) endif
    /\
    mix_column_backward_data(
        kyb[r, i], kyb[r, i + 4], kyb[r, i + 8], kyb[r, i + 12],
        kxb[r, i], kxb[r, i + 4], kxb[r, i + 8], kxb[r, i + 12]
    )
    /\
    if cb[r, 3*i] == 1 then (kdxb[r, i] = 1 /\ kdxb[r, i + 8] = 1) endif
    /\
    if cb[r, 3*i + 1] == 1 then (kdxb[r, i] = 1 /\ kdxb[r, i + 8] = 1 /\ kdxb[r, i + 12] = 1) endif
    /\
    if cb[r, 3*i + 2] == 1 then (kdxb[r, i + 4] = 1 /\ kdxb[r, i + 12] = 1) endif
);

constraint forall(r in 0..(RB - 1), i in 0..15)
(
    sb_operation_value_diff(kxb[r + 1, i], kdxb[r + 1, i], kyb[r, p_permutation[i]])
);

%   ____                _             _       _          __              _____ _   _ 
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| | | |
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | | | |
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |_| |
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|\___/ 
% constraints for EU

array[0..RU, 0..15] of var 0..3: axu;
array[0..RU, 0..15] of var -2..15: dxu;
constraint forall(r in 0..RU, i in 0..15)(link_pattern_to_value(axu[r, i], dxu[r, i]));

array[0..(RU - 1), 0..15] of var 0..3: ayu;
array[0..(RU - 1), 0..15] of var -2..15: dyu;
constraint forall(r in 0..RU-1, i in 0..15)(link_pattern_to_value(ayu[r, i], dyu[r, i]));

array[0..(RU - 1), 0..3] of var 0..3: dummy_au;
array[0..(RU - 1), 0..3] of var -2..15: dummy_du;
constraint forall(r in 0..(RU - 1), i in 0..3)(link_pattern_to_value(dummy_au[r, i], dummy_du[r, i]));

% Exclude all-zero input mask
var 0..48: inputmask_distinguisher;
constraint inputmask_distinguisher = sum(i in 0..15)(ayu[0, i]);
constraint inputmask_distinguisher >= 1;

% MixColumn
% skip the first MixColumn
constraint forall(i in 0..15)
(
    axu[0, i] = 0
);
constraint forall(r in 1..(RU - 1), i in 0..3)
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

% S-box
constraint forall(r in 0..(RU - 1), i in 0..15)
(
    sb_operation(ayu[r, p_permutation[i]], axu[r + 1, i])
);

%   ____                _             _       _          __              _____ _     
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| |    
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | |    
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |___ 
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_____|
% constraints for EL                                                                              

array[0..RL, 0..15] of var 0..3: axl;
array[0..RL, 0..15] of var -2..15: dxl;
constraint forall(r in 0..RL, i in 0..15)(link_pattern_to_value(axl[r, i], dxl[r, i]));

array[0..(RL - 1), 0..15] of var 0..3: ayl;
array[0..(RL - 1), 0..15] of var -2..15: dyl;
constraint forall(r in 0..(RL - 1), i in 0..15)(link_pattern_to_value(ayl[r, i], dyl[r, i]));

array[0..(RL - 1), 0..3] of var 0..3: dummy_al;
array[0..(RL - 1), 0..3] of var -2..15: dummy_dl;
constraint forall(r in 0..(RL - 1), i in 0..3)(link_pattern_to_value(dummy_al[r, i], dummy_dl[r, i]));

% Exclude all-zero output mask
var 0..48: outputmask_distinguisher;
constraint outputmask_distinguisher = sum(i in 0..15)(ayl[RL - 1, i]);
constraint outputmask_distinguisher != 0;

% MixColumn
constraint forall(r in 0..(RL - 1), i in 0..3)
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

% S-box
constraint forall(r in 0..(RL - 2), i in 0..15)
(
    sb_operation(axl[r + 1, i], ayl[r, p_permutation[i]])
);

% skip the last S-box layer by moving it into the key recovery part
constraint forall(i in 0..15)
(
    axl[RL, i] = 0
);

%   ____                             _               ____            _                 _ _      _   _             
%  / ___|_   _  __ _ _ __ __ _ _ __ | |_ ___  ___   / ___|___  _ __ | |_ _ __ __ _  __| (_) ___| |_(_) ___  _ __  
% | |  _| | | |/ _` | '__/ _` | '_ \| __/ _ \/ _ \ | |   / _ \| '_ \| __| '__/ _` |/ _` | |/ __| __| |/ _ \| '_ \ 
% | |_| | |_| | (_| | | | (_| | | | | ||  __/  __/ | |__| (_) | | | | |_| | | (_| | (_| | | (__| |_| | (_) | | | |
%  \____|\__,_|\__,_|_|  \__,_|_| |_|\__\___|\___|  \____\___/|_| |_|\__|_|  \__,_|\__,_|_|\___|\__|_|\___/|_| |_|
% include some constraints to guarantee the contradiction in the meeting point

var 0..16: contradict1;
var 0..16: contradict2;
constraint contradict1 = sum(i in 0..15)(bool2int((axu[RU, i] + axl[0, i] > 0) /\ (axu[RU, i] + axl[0, i] < 3) /\ axu[RU, i] != axl[0, i]));
constraint contradict2 = sum(i in 0..15)(bool2int(axu[RU, i] == 1 /\ axl[0, i] == 1 /\ dxu[RU, i] != dxl[0, i]));
constraint contradict1 + contradict2 > 0;

%   ____                _             _       _          __              _____  __ 
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____|/ _|
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | |_ 
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___|  _|
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_|  
% constraints for Ef

% #####################################################################
% modeling the differeence propagation and the difference cancellations
% #####################################################################

array[0..RF, 0..15] of var 0..1: axf;
array[0..(RF - 1), 0..11] of var 0..1: cf;
array[0..(RF - 1), 0..7] of var 0..1: auxif;

% link the end of El to the beginning of Ef
constraint forall(i in 0..15)
(
    if ayl[RL - 1, p_permutation[i]] >= 1 then 
        axf[0, i] = 1 
    else 
        axf[0, i] = 0 
    endif
);

constraint forall(r in 0..(RF - 1), i in 0..3)
(
    mix_column_forward_with_probability_one_diff(
        axf[r, i], axf[r, i + 4], axf[r, i + 8], axf[r, i + 12],
        axf[r + 1, p_permutation[i]], axf[r + 1, p_permutation[i + 4]], axf[r + 1, p_permutation[i + 8]], axf[r + 1, p_permutation[i + 12]],
        cf[r, 3*i], cf[r, 3*i + 1], cf[r, 3*i + 2],
        auxif[r, 2*i], auxif[r, 2*i + 1])
);

% #######################################
% modeling the guess-and-determine
% #######################################

array[0..RF, 0..15] of var 0..1: kxf;
array[0..(RF - 1), 0..15] of var 0..1: kyf;
array[0..RF, 0..15] of var 0..1: kdxf;
array[0..(RF - 1), 0..15] of var 0..1: kdyf;

% link the end of El to the beginning of Ef

constraint forall(i in 0..15)
(
    if ayl[RL - 1, p_permutation[i]] == 1 then 
        (kxf[0, i] = 1 /\ kdxf[0, i] = 1)
    else 
        (kxf[0, i] = 0 /\ kdxf[0, i] = 0)
    endif
);

constraint forall(r in 0..(RF - 1), i in 0..3)
(
    if kdxf[r, i] == 1 then (kdyf[r, i] = axf[r + 1, p_permutation[i]] /\ kdyf[r, i + 8] = axf[r + 1, p_permutation[i + 8]] /\ kdyf[r, i + 12] = axf[r + 1, p_permutation[i + 12]]) endif
    /\
    if kdxf[r, i + 4] == 1 then (kdyf[r, i + 4] = axf[r + 1, p_permutation[i + 4]] /\ kdyf[r, i + 12] = axf[r + 1, p_permutation[i + 12]]) endif
    /\
    if kdxf[r, i + 8] == 1 then (kdyf[r, i + 8] = axf[r + 1, p_permutation[i + 8]]) endif
    /\
    if kdxf[r, i + 12] == 1 then (kdyf[r, i + 12] = axf[r + 1, p_permutation[i + 12]]) endif
    /\
    mix_column_forward_data(
        kxf[r, i], kxf[r, i + 4], kxf[r, i + 8], kxf[r, i + 12],
        kyf[r, i], kyf[r, i + 4], kyf[r, i + 8], kyf[r, i + 12]
    )
    /\
    if cf[r, 3*i] == 1 then (kdyf[r, i] = 1 /\ kdyf[r, i + 12] = 1) endif
    /\
    if cf[r, 3*i + 1] == 1 then (kdyf[r, i] = 1 /\ kdyf[r, i + 8] = 1 /\ kdyf[r, i + 12] = 1) endif
    /\
    if cf[r, 3*i + 2] == 1 then (kdyf[r, i + 4] = 1 /\ kdyf[r, i + 12] = 1) endif
);

constraint forall(r in 0..(RF - 1), i in 0..15)
(
    sb_operation_value_diff(kdyf[r, p_permutation[i]], kyf[r, p_permutation[i]], kxf[r + 1, i])
);

%  __  __           _      _ _               _   _            _  __                ____       _     _       _             
% |  \/  | ___   __| | ___| (_)_ __   __ _  | |_| |__   ___  | |/ /___ _   _      | __ ) _ __(_) __| | __ _(_)_ __   __ _ 
% | |\/| |/ _ \ / _` |/ _ \ | | '_ \ / _` | | __| '_ \ / _ \ | ' // _ \ | | |_____|  _ \| '__| |/ _` |/ _` | | '_ \ / _` |
% | |  | | (_) | (_| |  __/ | | | | | (_| | | |_| | | |  __/ | . \  __/ |_| |_____| |_) | |  | | (_| | (_| | | | | | (_| |
% |_|  |_|\___/ \__,_|\___|_|_|_| |_|\__, |  \__|_| |_|\___| |_|\_\___|\__, |     |____/|_|  |_|\__,_|\__, |_|_| |_|\__, |
%                                    |___/                             |___/                          |___/         |___/ 
% modeling the key-bridging

array[0..1, 0..15] of var 0..RB: ikb;

constraint forall(i in 0..15)
(
    ikb[0, i] = sum(r in 0..(RB - 1) where (r mod 2) == 0)(kyb[r, p_permutation[i]])
    /\
    ikb[1, i] = sum(r in 0..(RB - 1) where (r mod 2) == 1)(kyb[r, p_permutation[i]])
);

array[0..1, 0..15] of var 0..RF: ikf;

constraint forall(k in 0..15, i in 0..15)
(
    ikf[((RB + RU + RL) mod 2), i] = sum(r in 0..(RF - 1) where ((r + RB + RU + RL) mod 2) == ((RB + RU + RL) mod 2))(kyf[r, p_permutation[i]])
    /\
    ikf[((RB + RU + RL + 1) mod 2), i] = sum(r in 0..(RF - 1) where ((r + RB + RU + RL) mod 2) == ((RB + RU + RL + 1) mod 2))(kyf[r, p_permutation[i]])
);

array[0..1, 0..15] of var 0..(RB + RF): sk;

constraint forall(i in 0..15)
(
    if (ikb[0, i] + ikf[0, i]) >= 1 then sk[0, i] = 1 else sk[0, i] = 0 endif
    /\
    if (ikb[1, i] + ikf[1, i]) >= 1 then sk[1, i] = 1 else sk[1, i] = 0 endif
);

var 0..32: k_tot;

constraint k_tot = sum(i in 0..15)(sk[0, i] + sk[1, i]);

solve minimize k_tot;

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

predicate sb_operation_value_diff(var 0..1: diff_value_before_sb, var 0..1: value_before_sb, var 0..1: value_after_sb) = 
    value_after_sb >= value_before_sb
    /\ 
    value_after_sb >= diff_value_before_sb
    /\
    value_after_sb <= value_before_sb + diff_value_before_sb
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

predicate xor_with_probability_one(var 0..1: A, var 0..1: B, var 0..1: C) =
    C >= A
    /\ 
    C >= B
    /\ 
    C <= A + B
;

predicate xor3_with_probability_one(var 0..1: A, var 0..1: B, var 0..1: C, var 0..1: D) =
    D >= A
    /\ 
    D >= B
    /\ 
    D >= C
    /\ 
    D <= A + B + C
;

predicate xor_cancellation(var 0..1: AX, var 0..1: AY, var 0..1: AZ, var 0..1: C) = 
    if (AX + AY = 2 /\ AZ = 0) then C = 1 else C = 0 endif 
;

predicate mix_column_forward_with_probability_one_diff(var 0..1: in_diff1,
                                                  var 0..1: in_diff2,
                                                  var 0..1: in_diff3,
                                                  var 0..1: in_diff4,
                                                  var 0..1: out_diff1,
                                                  var 0..1: out_diff2,
                                                  var 0..1: out_diff3,
                                                  var 0..1: out_diff4,
                                                  var 0..1: c1,
                                                  var 0..1: c2,
                                                  var 0..1: c3,
                                                  var 0..1: auxi_var1,
                                                  var 0..1: auxi_var2) =
    xor3_with_probability_one(in_diff1, in_diff3, in_diff4, out_diff1)
    /\
    xor_with_probability_one(in_diff2, in_diff4, out_diff2)
    /\
    out_diff3 = in_diff3
    /\
    out_diff4 = in_diff4
    /\
    xor_with_probability_one(in_diff1, in_diff3, auxi_var1)
    /\
    xor_with_probability_one(out_diff1, out_diff4, auxi_var2)
    /\
    xor_cancellation(out_diff1, out_diff4, auxi_var1, c1)
    /\
    xor_cancellation(auxi_var2, out_diff3, in_diff1, c2)
    /\
    xor_cancellation(out_diff2, out_diff4, in_diff2, c3)
;

predicate mix_column_backward_with_probability_one_diff(var 0..1: in_diff1,
                                                  var 0..1: in_diff2,
                                                  var 0..1: in_diff3,
                                                  var 0..1: in_diff4,
                                                  var 0..1: out_diff1,
                                                  var 0..1: out_diff2,
                                                  var 0..1: out_diff3,
                                                  var 0..1: out_diff4,
                                                  var 0..1: c1,
                                                  var 0..1: c2,
                                                  var 0..1: c3,
                                                  var 0..1: auxi_var1,
                                                  var 0..1: auxi_var2) =
    xor3_with_probability_one(in_diff1, in_diff3, in_diff4, out_diff1)
    /\
    xor_with_probability_one(in_diff2, in_diff4, out_diff2)
    /\
    out_diff3 = in_diff3
    /\
    out_diff4 = in_diff4
    /\
    xor_with_probability_one(out_diff1, out_diff3, auxi_var1)
    /\
    xor_with_probability_one(in_diff1, in_diff4, auxi_var2)
    /\
    xor_cancellation(out_diff1, out_diff3, auxi_var2, c1)
    /\
    xor_cancellation(auxi_var1, out_diff4, in_diff1, c2)
    /\
    xor_cancellation(out_diff2, out_diff4, in_diff2, c3)
;

predicate mix_column_forward_data(var 0..1: in1, var 0..1: in2,
                                  var 0..1: in3, var 0..1: in4, 
                                  var 0..1: out1, var 0..1: out2, 
                                  var 0..1: out3, var 0..1: out4) =
    out1 = in1
    /\
    out2 = in2    
    /\
    xor_with_probability_one(in1, in3, out3)
    /\
    xor3_with_probability_one(in1, in2, in4, out4)
;

predicate mix_column_backward_data(var 0..1: in1, var 0..1: in2,
                                  var 0..1: in3, var 0..1: in4, 
                                  var 0..1: out1, var 0..1: out2, 
                                  var 0..1: out3, var 0..1: out4) =
    out1 = in1
    /\
    out2 = in2    
    /\
    xor_with_probability_one(in1, in3, out3)
    /\
    xor3_with_probability_one(in1, in2, in4, out4)
;