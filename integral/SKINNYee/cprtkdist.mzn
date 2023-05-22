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

int: R1;
int: R2;
int: Nd;
int: p;
Nd = R1 + R2;

constraint assert(R1 >= 1,"Invalid value for R1: " ++
                "R1 must be greater than or equal to 1");

constraint assert(R2 >= 1,"Invalid value for R2: " ++
                "R2 must be greater than or equal to 1");

%   ____                _             _       _          __              _____                    _                ____       _              _       _      
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  |_   _|_      _____  __ _| | _____ _   _  / ___|  ___| |__   ___  __| |_   _| | ___ 
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__|   | | \ \ /\ / / _ \/ _` | |/ / _ \ | | | \___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |      | |  \ V  V /  __/ (_| |   <  __/ |_| |  ___) | (__| | | |  __/ (_| | |_| | |  __/
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|      |_|   \_/\_/ \___|\__,_|_|\_\___|\__, | |____/ \___|_| |_|\___|\__,_|\__,_|_|\___|
% constraints for tweakey schedule
    
array[0..(Nd - 1), 0..15] of var 0..1: any_or_active_subtweakey;
array[0..(Nd - 1), 0..15] of var 0..1: active_subtweakeys;
array[0..15] of var 0..(R1 + R2): key_counter_sum;
array[0..15] of var 0..(R1 + R2): key_counter_active_sum;
array[0..15] of int: tweakey_permutation = array1d(0..15,[9,15,8,13,10,14,12,11,0,1,2,3,4,5,6,7]);
array[0..(Nd - 1), 0..15] of var int: permutation_per_round;
constraint forall (i in 0..15) (permutation_per_round[0,i] = i);
constraint forall (n in 1..(Nd - 1), i in 0..15) (permutation_per_round[n,i] = tweakey_permutation[permutation_per_round[n-1,i]]);

%   ____                _             _       _          __              _____ _ 
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____/ |
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | |
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_|
% constraints for E1

array[0..R1, 0..3, 0..3] of var 0..3: forward_mask_x;
array[0..R1, 0..3, 0..3] of var -2..15: forward_class_x;
constraint forall(i in 0..R1, j in 0..3, k in 0..3)(link_mask_class(forward_mask_x[i,j,k], forward_class_x[i,j,k]));

array[0..R1-1, 0..3, 0..3] of var 0..3: forward_mask_sbx;
array[0..R1-1, 0..3, 0..3] of var -2..15: forward_class_sbx;
constraint forall(i in 0..R1-1, j in 0..3, k in 0..3)(link_mask_class(forward_mask_sbx[i,j,k], forward_class_sbx[i,j,k]));

array[0..R1-1, 0..3] of var 0..3: forward_mask_aux;
array[0..R1-1, 0..3] of var -2..15: forward_class_aux;
constraint forall(i in 0..R1-1, j in 0..3)(link_mask_class(forward_mask_aux[i,j], forward_class_aux[i,j]));

% % Fix Input mask_vars
% constraint forall(i in 0..3, j in 0..3)
% (
%     forward_mask_x[0,i,j] = input_pattern[i,j]
%);

% Exclude all-zero input mask
var 0..48: inputmask_distinguisher;
constraint inputmask_distinguisher = sum(i in 0..3, j in 0..3)(forward_mask_x[0,i,j]);
constraint inputmask_distinguisher >= 1;
% constraint forward_mask_x[0, 3, 0] = 2;
% constraint forward_mask_x[0, 3, 1] = 2;

% SB Operation
% in case the first SB layer is skipped:
% constraint forall(r in 0..0, i in 0..3, j in 0..3)
% (
%     forward_mask_sbx[r,i,j] = forward_mask_x[r,i,j] /\
%     forward_class_sbx[r,i,j] = forward_class_x[r,i,j]
% );
% do not forget to start r from 1 if the previous block comes into effect
constraint forall(r in 0..R1-1, i in 0..3, j in 0..3)
(
    sb_operation(forward_mask_x[r,i,j], forward_mask_sbx[r,i,j])
);

% MixColumn
constraint forall(r in 0..R1-1, j in 0..3)
(
    mix_column_forward(forward_mask_sbx[r,0,(j-0+4) mod 4], forward_class_sbx[r,0,(j-0+4) mod 4],
                     forward_mask_sbx[r,1,(j-1+4) mod 4], forward_class_sbx[r,1,(j-1+4) mod 4],
                     forward_mask_sbx[r,2,(j-2+4) mod 4], forward_class_sbx[r,2,(j-2+4) mod 4],
                     forward_mask_sbx[r,3,(j-3+4) mod 4], forward_class_sbx[r,3,(j-3+4) mod 4],
                     forward_mask_x[r+1,0,j], forward_class_x[r+1,0,j], 
                     forward_mask_x[r+1,1,j], forward_class_x[r+1,1,j],
                     forward_mask_x[r+1,2,j], forward_class_x[r+1,2,j],
                     forward_mask_x[r+1,3,j], forward_class_x[r+1,3,j],
                     forward_mask_aux[r,j], forward_class_aux[r,j])
                     
);

% link the subtweakey and the internal state

constraint forall(r in 0..(R1 - 1), i in 0..1, j in 0..3)
(
    if forward_mask_sbx[r, i, j] == 3 then
        any_or_active_subtweakey[r, permutation_per_round[r, 4*i + j]] = 1
        /\
        active_subtweakeys[r, permutation_per_round[r, 4*i + j]] = 0
    elseif forward_mask_sbx[r, i, j] >= 1 then
        any_or_active_subtweakey[r, permutation_per_round[r, 4*i + j]] = 1 
        /\ 
        active_subtweakeys[r, permutation_per_round[r, 4*i + j]] = 1
    else
        any_or_active_subtweakey[r, permutation_per_round[r, 4*i + j]] = 0
        /\
        active_subtweakeys[r, permutation_per_round[r, 4*i + j]] = 0
    endif 
    /\
    any_or_active_subtweakey[r, permutation_per_round[r, 4*i + j + 8]] = 0
    /\
    active_subtweakeys[r, permutation_per_round[r, 4*i + j + 8]] = 0
);

%   ____                _             _       _          __              _____ ____  
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____|___ \ 
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _|   __) |
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___ / __/ 
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_____|
% Constraints for E2 

array[0..R2, 0..3, 0..3] of var 0..3: backward_mask_x;
array[0..R2, 0..3, 0..3] of var -2..15: backward_class_x;
constraint forall(i in 0..R2, j in 0..3, k in 0..3)(link_mask_class(backward_mask_x[i,j,k], backward_class_x[i,j,k]));

array[0..R2-1, 0..3, 0..3] of var 0..3: backward_mask_sbx;
array[0..R2-1, 0..3, 0..3] of var -2..15: backward_class_sbx;
constraint forall(i in 0..R2-1, j in 0..3, k in 0..3)(link_mask_class(backward_mask_sbx[i,j,k], backward_class_sbx[i,j,k]));

array[0..R2-1, 0..3] of var 0..3: backward_mask_aux;
array[0..R2-1, 0..3] of var -2..15: backward_class_aux;
constraint forall(i in 0..R2-1, j in 0..3)(link_mask_class(backward_mask_aux[i,j], backward_class_aux[i,j]));
% ----------------------------- %
% Fix Output mask_vars
% constraint forall(i in 0..3, j in 0..3)
% (
%     backward_mask_x[R2,i,j] = output_pattern[i,j]
%);
% Exlude all-zero output mask
var 0..48: outputmask_distinguisher;
constraint outputmask_distinguisher = sum(i in 0..3, j in 0..3)(backward_mask_x[R2,i,j]);
constraint outputmask_distinguisher != 0;
% constraint outputmask_distinguisher <= 1;
% constraint backward_mask_x[R2 - 1, 1, 2] = 2;

% MixColumn
constraint forall(r in 0..(R2 - 1), j in 0..3)
(
    mix_column_backward(backward_mask_x[r+1, 0, j], backward_class_x[r+1, 0, j],
                      backward_mask_x[r+1, 1, j], backward_class_x[r+1, 1, j],
                      backward_mask_x[r+1, 2, j], backward_class_x[r+1, 2, j],
                      backward_mask_x[r+1, 3, j], backward_class_x[r+1, 3, j],
                      backward_mask_sbx[r, 0, (j-0+4) mod 4], backward_class_sbx[r, 0, (j-0+4) mod 4],
                      backward_mask_sbx[r, 1, (j-1+4) mod 4], backward_class_sbx[r, 1, (j-1+4) mod 4],
                      backward_mask_sbx[r, 2, (j-2+4) mod 4], backward_class_sbx[r, 2, (j-2+4) mod 4],
                      backward_mask_sbx[r, 3, (j-3+4) mod 4], backward_class_sbx[r, 3, (j-3+4) mod 4],
                      backward_mask_aux[r,j], backward_class_aux[r,j])
);

% constraint forward_mask_x[0, 0, 0] = 1;
% constraint forward_mask_x[0, 0, 3] = 1;
% constraint sum(i in 0..3, j in 0..3)(forward_mask_x[0, i, j]) = 2;
% constraint backward_mask_x[R2, 1, 1] = 1;
% constraint backward_mask_x[R2, 3, 1] = 1;
% constraint sum(i in 0..3, j in 0..3)(backward_mask_x[R2, i, j]) = 2;

% SB Operation
constraint forall(r in 0..R2-1, i in 0..3, j in 0..3)
(
    sb_operation(backward_mask_sbx[r,i,j], backward_mask_x[r,i,j])
);

% link the subtweakey and the internal state

constraint forall(r in 0..(R2 - 1), i in 0..1, j in 0..3)
(
    if backward_mask_sbx[r, i, j] == 3 then
        any_or_active_subtweakey[r + R1, permutation_per_round[r + R1, 4*i + j]] = 1
        /\
        active_subtweakeys[r + R1, permutation_per_round[r + R1, 4*i + j]] = 0
    elseif backward_mask_sbx[r, i, j] >= 1 then
        any_or_active_subtweakey[r + R1, permutation_per_round[r + R1, 4*i + j]] = 1
        /\
        active_subtweakeys[r + R1, permutation_per_round[r + R1, 4*i + j]] = 1
    else
        any_or_active_subtweakey[r + R1, permutation_per_round[r + R1, 4*i + j]] = 0
        /\
        active_subtweakeys[r + R1, permutation_per_round[r + R1, 4*i + j]] = 0
    endif /\
    any_or_active_subtweakey[r + R1, permutation_per_round[r + R1, 4*i + j + 8]] = 0
    /\
    active_subtweakeys[r + R1, permutation_per_round[r + R1, 4*i + j + 8]] = 0
);

%   ____                             _               ____            _                 _ _      _   _             
%  / ___|_   _  __ _ _ __ __ _ _ __ | |_ ___  ___   / ___|___  _ __ | |_ _ __ __ _  __| (_) ___| |_(_) ___  _ __  
% | |  _| | | |/ _` | '__/ _` | '_ \| __/ _ \/ _ \ | |   / _ \| '_ \| __| '__/ _` |/ _` | |/ __| __| |/ _ \| '_ \ 
% | |_| | |_| | (_| | | | (_| | | | | ||  __/  __/ | |__| (_) | | | | |_| | | (_| | (_| | | (__| |_| | (_) | | | |
%  \____|\__,_|\__,_|_|  \__,_|_| |_|\__\___|\___|  \____\___/|_| |_|\__|_|  \__,_|\__,_|_|\___|\__|_|\___/|_| |_|
% include some constraints to guarantee the contradiction in the tweakey schedule

constraint forall(i in 0..15)
(
    key_counter_sum[i] = sum(r in 0..(Nd - 1))(any_or_active_subtweakey[r, i])
    /\
    key_counter_active_sum[i] = sum(r in 0..(Nd - 1))(active_subtweakeys[r, i])
);

var 0..16: contradict1;
var 0..16: contradict2;
constraint contradict1 = sum(i in 0..15)(bool2int(key_counter_sum[i] <= p /\ key_counter_active_sum[i] >= 1));
constraint contradict2 = sum(i in 0..15)(bool2int(key_counter_sum[i] == 0));
constraint contradict1 + contradict2 >= 1;


% solve satisfy;
constraint forall(i in 0..3, j in 0..3)
(
    forward_mask_x[0, i, j] = 3 \/
    forward_mask_x[0, i, j] = 0
);
solve maximize sum(i in 0..3, j in 0..3)(forward_mask_x[0, i, j]);

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
    % The First Row
    out_mask1 = in_mask4 /\
    out_class1 = in_class4
    /\
    % The Third Row
    out_mask3 = in_mask2 /\
    out_class3 = in_class2
    /\
    % Computing Aux
    % A: in_mask2, in_class2
    % B: in_mask3, in_class3
    % C: auxi_mask, auxi_class
    xor_operation(in_mask2, in_class2, in_mask3, in_class3, auxi_mask, auxi_class)
    /\
    % The Second Row
    % A: auxi_mask, auxi_class
    % B: in_mask1, in_class1
    % C: out_mask2, out_class2
    xor_operation(auxi_mask, auxi_class, in_mask1, in_class1, out_mask2, out_class2)
    /\
    % The Fourth Row
    % A: auxi_mask, auxi_class
    % B: in_mask4, in_class4
    % C: out_mask4, out_class4
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
    % The Second Row
    out_mask2 = in_mask3 /\
    out_class2 = in_class3
    /\
    % The Fourth Row
    out_mask4 = in_mask1 /\
    out_class4 = in_class1
    /\
    % Computing Aux
    % A: in_mask1 in_class1
    % B: in_mask4 in_class4
    % C: auxi_mask auxi_class
    xor_operation(in_mask1, in_class1, in_mask4, in_class4, auxi_mask, auxi_class)
    /\
    % The First Row
    % A: auxi_mask auxi_class
    % B: in_mask2 in_class2
    % C: out_mask1 out_class1
    xor_operation(auxi_mask, auxi_class, in_mask2, in_class2, out_mask1, out_class1)
    /\
    % The Third Row
    % A: auxi_mask auxi_class
    % B: in_mask3 in_class3
    % C: out_mask3 out_class3
    xor_operation(auxi_mask, auxi_class, in_mask3, in_class3, out_mask3, out_class3)
;
