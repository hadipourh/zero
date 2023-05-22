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

int: Offset;
int: RU;
int: RL;
int: Nd;
Nd = RU + RL;

constraint assert(RU >= 1,"Invalid value for RU: " ++
                "RU must be greater than or equal to 1");

constraint assert(RL >= 1,"Invalid value for RL: " ++
                "RL must be greater than or equal to 1");

array[0..15] of int: p_permutation = array1d(0..15, [15, 12, 13, 14, 10, 9, 8, 11, 6, 5, 4, 7, 1, 2, 3, 0]);

%   ____                _             _       _          __              _____ _   _ 
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| | | |
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | | | |
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |_| |
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|\___/ 
% constraints for EU

array[0..RU, 0..15] of var 0..3: forward_mask_x;
array[0..RU, 0..15] of var -2..15: forward_class_x;
constraint forall(r in 0..RU, i in 0..15)(link_mask_class(forward_mask_x[r, i], forward_class_x[r, i]));

array[0..(RU - 1), 0..15] of var 0..3: forward_mask_y;
array[0..(RU - 1), 0..15] of var -2..15: forward_class_y;
constraint forall(r in 0..RU-1, i in 0..15)(link_mask_class(forward_mask_y[r, i], forward_class_y[r, i]));

array[0..(RU - 1), 0..3] of var 0..3: forward_mask_aux;
array[0..(RU - 1), 0..3] of var -2..15: forward_class_aux;
constraint forall(r in 0..(RU - 1), i in 0..3)(link_mask_class(forward_mask_aux[r, i], forward_class_aux[r, i]));

% Exclude all-zero input mask
var 0..48: inputmask_distinguisher;
constraint inputmask_distinguisher = sum(i in 0..15)(forward_mask_y[0, i]);
constraint inputmask_distinguisher >= 1;

% MixColumn
% skip the first MixColumn
constraint forall(i in 0..15)
(
    forward_mask_x[0, i] = 0
);
constraint forall(r in 1..(RU - 1), i in 0..3)
(
    mix_column_forward(
        forward_mask_x[r, i], forward_class_x[r, i],
        forward_mask_x[r, i + 4], forward_class_x[r, i + 4],
        forward_mask_x[r, i + 8], forward_class_x[r, i + 8],
        forward_mask_x[r, i + 12], forward_class_x[r, i + 12],
        forward_mask_y[r, i], forward_class_y[r, i],
        forward_mask_y[r, i + 4], forward_class_y[r, i + 4],
        forward_mask_y[r, i + 8], forward_class_y[r, i + 8],
        forward_mask_y[r, i + 12], forward_class_y[r, i + 12],
        forward_mask_aux[r, i], forward_class_aux[r, i]
    )                     
);

% S-box
constraint forall(r in 0..(RU - 1), i in 0..15)
(
    sb_operation(forward_mask_y[r, p_permutation[i]], forward_mask_x[r + 1, i])
);

%   ____                _             _       _          __              _____ _     
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| |    
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | |    
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |___ 
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_____|
% constraints for EL                                                                              

array[0..RL, 0..15] of var 0..3: backward_mask_x;
array[0..RL, 0..15] of var -2..15: backward_class_x;
constraint forall(r in 0..RL, i in 0..15)(link_mask_class(backward_mask_x[r, i], backward_class_x[r, i]));

array[0..(RL - 1), 0..15] of var 0..3: backward_mask_y;
array[0..(RL - 1), 0..15] of var -2..15: backward_class_y;
constraint forall(r in 0..(RL - 1), i in 0..15)(link_mask_class(backward_mask_y[r, i], backward_class_y[r, i]));

array[0..(RL - 1), 0..3] of var 0..3: backward_mask_aux;
array[0..(RL - 1), 0..3] of var -2..15: backward_class_aux;
constraint forall(r in 0..(RL - 1), i in 0..3)(link_mask_class(backward_mask_aux[r, i], backward_class_aux[r, i]));

% Exclude all-zero output mask
var 0..48: outputmask_distinguisher;
constraint outputmask_distinguisher = sum(i in 0..15)(backward_mask_y[RL - 1, i]);
constraint outputmask_distinguisher != 0;

% MixColumn
constraint forall(r in 0..(RL - 1), i in 0..3)
(
    mix_column_backward(
        backward_mask_y[r, i], backward_class_y[r, i],
        backward_mask_y[r, i + 4], backward_class_y[r, i + 4],
        backward_mask_y[r, i + 8], backward_class_y[r, i + 8],
        backward_mask_y[r, i + 12], backward_class_y[r, i + 12],
        backward_mask_x[r, i], backward_class_x[r, i],
        backward_mask_x[r, i + 4], backward_class_x[r, i + 4],
        backward_mask_x[r, i + 8], backward_class_x[r, i + 8],
        backward_mask_x[r, i + 12], backward_class_x[r, i + 12],
        backward_mask_aux[r, i], backward_class_aux[r, i]
    )
);

% S-box
constraint forall(r in 0..(RL - 2), i in 0..15)
(
    sb_operation(backward_mask_x[r + 1, i], backward_mask_y[r, p_permutation[i]])
);

% skip the last S-box layer by moving it into the key recovery part
constraint forall(i in 0..15)
(
    backward_mask_x[RL, i] = 0
);

%   ____                             _               ____            _                 _ _      _   _             
%  / ___|_   _  __ _ _ __ __ _ _ __ | |_ ___  ___   / ___|___  _ __ | |_ _ __ __ _  __| (_) ___| |_(_) ___  _ __  
% | |  _| | | |/ _` | '__/ _` | '_ \| __/ _ \/ _ \ | |   / _ \| '_ \| __| '__/ _` |/ _` | |/ __| __| |/ _ \| '_ \ 
% | |_| | |_| | (_| | | | (_| | | | | ||  __/  __/ | |__| (_) | | | | |_| | | (_| | (_| | | (__| |_| | (_) | | | |
%  \____|\__,_|\__,_|_|  \__,_|_| |_|\__\___|\___|  \____\___/|_| |_|\__|_|  \__,_|\__,_|_|\___|\__|_|\___/|_| |_|
% include some constraints to guarantee the contradiction in the meeting point

var 0..16: contradict1;
var 0..16: contradict2;
constraint contradict1 = sum(i in 0..15)(bool2int((forward_mask_x[RU, i] + backward_mask_x[0, i] > 0) /\ (forward_mask_x[RU, i] + backward_mask_x[0, i] < 3) /\ forward_mask_x[RU, i] != backward_mask_x[0, i]));
constraint contradict2 = sum(i in 0..15)(bool2int(forward_mask_x[RU, i] == 1 /\ backward_mask_x[0, i] == 1 /\ forward_class_x[RU, i] != backward_class_x[0, i]));
constraint contradict1 + contradict2 > 0;

solve maximize sum(i in 0..15)(forward_mask_x[1, i]);

%     _              _ _ _                    _____                 _   _                 
%    / \  _   ___  _(_) (_) __ _ _ __ _   _  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___ 
%   / _ \| | | \ \/ / | | |/ _` | '__| | | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  / ___ \ |_| |>  <| | | | (_| | |  | |_| | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
% /_/   \_\__,_/_/\_\_|_|_|\__,_|_|   \__, | |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%                                     |___/                                               

predicate link_mask_class(var 0..3: mask_vars, var -2..15: class_vars) = 
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

predicate xor_operation(var 0..3: mask_a, var -2..15: class_a, var 0..3: mask_b, var -2..15: class_b, var 0..3: mask_c, var -2..15: class_c) = 
    if (mask_a + mask_b > 2) then
        (mask_c = 3) /\ (class_c = -2)
    elseif (mask_a + mask_b = 1) then
        (mask_c = 1) /\ (class_c = class_a + class_b)
    elseif ((mask_a == 0) /\ (mask_b == 0)) then
        (mask_c = 0) /\ (class_c = 0)
    elseif (class_a + class_b < 0) then
        (mask_c = 2) /\ (class_c = -1)
    elseif (class_a == class_b) then
        (mask_c = 0) /\ (class_c = 0)
    else
        (mask_c = 1) /\
        class_c = (bool2int((class_a mod 2) != (class_b mod 2)) + 
        bool2int(((class_a div 2) mod 2) != ((class_b div 2) mod 2)) * 2 + 
        bool2int(((class_a div 4) mod 2) != ((class_b div 4) mod 2)) * 4 +
        bool2int(((class_a div 8) mod 2) != ((class_b div 8) mod 2)) * 8)
    endif
;

predicate mix_column_forward(var 0..3: in_mask1, var -2..15: in_class1, 
                           var 0..3: in_mask2, var -2..15: in_class2, 
                           var 0..3: in_mask3, var -2..15: in_class3, 
                           var 0..3: in_mask4, var -2..15: in_class4, 
                           var 0..3: out_mask1, var -2..15: out_class1, 
                           var 0..3: out_mask2, var -2..15: out_class2, 
                           var 0..3: out_mask3, var -2..15: out_class3, 
                           var 0..3: out_mask4, var -2..15: out_class4, 
                           var 0..3: auxi_mask, var -2..15: auxi_class) =
    
    out_mask1 = in_mask1 /\
    out_class1 = in_class1
    /\
    out_mask2 = in_mask2 /\
    out_class2 = in_class2
    /\
    xor_operation(in_mask1, in_class1, in_mask3, in_class3, out_mask3, out_class3)
    /\
    xor_operation(in_mask1, in_class1, in_mask2, in_class2, auxi_mask, auxi_class)
    /\
    xor_operation(auxi_mask, auxi_class, in_mask4, in_class4, out_mask4, out_class4)
;

predicate mix_column_backward(var 0..3: in_mask1, var -2..15: in_class1, 
                           var 0..3: in_mask2, var -2..15: in_class2, 
                           var 0..3: in_mask3, var -2..15: in_class3, 
                           var 0..3: in_mask4, var -2..15: in_class4, 
                           var 0..3: out_mask1, var -2..15: out_class1, 
                           var 0..3: out_mask2, var -2..15: out_class2, 
                           var 0..3: out_mask3, var -2..15: out_class3, 
                           var 0..3: out_mask4, var -2..15: out_class4, 
                           var 0..3: auxi_mask, var -2..15: auxi_class) =
    % MixColumns of CRAFT is involutory and hence the the constraints are the same as for MixColumns forward
    out_mask1 = in_mask1 /\
    out_class1 = in_class1
    /\
    out_mask2 = in_mask2 /\
    out_class2 = in_class2
    /\
    xor_operation(in_mask1, in_class1, in_mask3, in_class3, out_mask3, out_class3)
    /\
    xor_operation(in_mask1, in_class1, in_mask2, in_class2, auxi_mask, auxi_class)
    /\
    xor_operation(auxi_mask, auxi_class, in_mask4, in_class4, out_mask4, out_class4)
;
