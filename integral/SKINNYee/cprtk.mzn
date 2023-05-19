int: Rb;
int: R1;
int: R2;
int: Rf;
int: Nr;
int: Nd;
int: p;
Nd = R1 + R2;
Nr = Rb + R1 + R2 + Rf;

constraint assert(Rb >= 1,"Invalid value for Rb: " ++
                "Rb must be greater than or equal to 1");

constraint assert(R1 >= 1,"Invalid value for R1: " ++
                "R1 must be greater than or equal to 1");

constraint assert(R2 >= 1,"Invalid value for R2: " ++
                "R2 must be greater than or equal to 1");

constraint assert(Rf >= 1,"Invalid value for Rf: " ++
                "Rf must be greater than or equal to 1");

%   ____                _             _       _          __              _____                    _                ____       _              _       _      
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  |_   _|_      _____  __ _| | _____ _   _  / ___|  ___| |__   ___  __| |_   _| | ___ 
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__|   | | \ \ /\ / / _ \/ _` | |/ / _ \ | | | \___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |      | |  \ V  V /  __/ (_| |   <  __/ |_| |  ___) | (__| | | |  __/ (_| | |_| | |  __/
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|      |_|   \_/\_/ \___|\__,_|_|\_\___|\__, | |____/ \___|_| |_|\___|\__,_|\__,_|_|\___|
% constraints for tweakey schedule
    
array[0..(Nd - 1), 0..15] of var 0..1: any_or_active_subtweakey;
array[0..(Nd - 1), 0..15] of var 0..1: active_subtweakeys;
array[0..15] of var 0..Nd: key_counter_sum_dist;
array[0..15] of var 0..Nd: key_counter_active_sum;
array[0..15] of int: tweakey_permutation = array1d(0..15,[9,15,8,13,10,14,12,11,0,1,2,3,4,5,6,7]);
array[0..(Nr - 1), 0..15] of var int: permutation_per_round;
constraint forall (i in 0..15) (permutation_per_round[0,i] = i);
constraint forall (n in 1..(Nr - 1), i in 0..15) (permutation_per_round[n,i] = tweakey_permutation[permutation_per_round[n-1,i]]);

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
constraint forall(i in 0..(R1 - 1), j in 0..3, k in 0..3)(link_mask_class(forward_mask_sbx[i,j,k], forward_class_sbx[i,j,k]));

array[0..R1-1, 0..3] of var 0..3: forward_mask_aux;
array[0..R1-1, 0..3] of var -2..15: forward_class_aux;
constraint forall(i in 0..(R1 - 1), j in 0..3)(link_mask_class(forward_mask_aux[i,j], forward_class_aux[i,j]));

% Exclude all-zero input mask
var 0..48: inputmask_distinguisher;
constraint inputmask_distinguisher = sum(i in 0..3, j in 0..3)(forward_mask_x[0,i,j]);
constraint inputmask_distinguisher >= 1;

% SB Operation
constraint forall(r in 0..R1 - 1, i in 0..3, j in 0..3)
(
    sb_operation(forward_mask_x[r, i, j], forward_mask_sbx[r, i, j])
);

% MixColumn
constraint forall(r in 0..(R1 - 1), j in 0..3)
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
        any_or_active_subtweakey[r, permutation_per_round[r + Rb, 4*i + j]] = 1
        /\
        active_subtweakeys[r, permutation_per_round[r + Rb, 4*i + j]] = 0
    elseif forward_mask_sbx[r, i, j] >= 1 then
        any_or_active_subtweakey[r, permutation_per_round[r + Rb, 4*i + j]] = 1 
        /\ 
        active_subtweakeys[r, permutation_per_round[r + Rb, 4*i + j]] = 1
    else
        any_or_active_subtweakey[r, permutation_per_round[r + Rb, 4*i + j]] = 0
        /\
        active_subtweakeys[r, permutation_per_round[r + Rb, 4*i + j]] = 0
    endif 
    /\
    any_or_active_subtweakey[r, permutation_per_round[r + Rb, 4*i + j + 8]] = 0
    /\
    active_subtweakeys[r, permutation_per_round[r + Rb, 4*i + j + 8]] = 0
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
constraint forall(i in 0..(R2 - 1), j in 0..3, k in 0..3)(link_mask_class(backward_mask_sbx[i,j,k], backward_class_sbx[i,j,k]));

array[0..R2-1, 0..3] of var 0..3: backward_mask_aux;
array[0..R2-1, 0..3] of var -2..15: backward_class_aux;
constraint forall(i in 0..(R2 - 1), j in 0..3)(link_mask_class(backward_mask_aux[i,j], backward_class_aux[i,j]));

% Exlude all-zero output mask
var 0..48: outputmask_distinguisher;
constraint outputmask_distinguisher = sum(i in 0..3, j in 0..3)(backward_mask_x[R2,i,j]);
constraint outputmask_distinguisher != 0;

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
% SB Operation
constraint forall(r in 0..R2-1, i in 0..3, j in 0..3)
(
    sb_operation(backward_mask_sbx[r,i,j], backward_mask_x[r,i,j])
);

% link the subtweakey and the internal state

constraint forall(r in 0..(R2 - 1), i in 0..1, j in 0..3)
(
    if backward_mask_sbx[r, i, j] == 3 then
        any_or_active_subtweakey[r + R1, permutation_per_round[r + Rb + R1, 4*i + j]] = 1
        /\
        active_subtweakeys[r + R1, permutation_per_round[r + Rb + R1, 4*i + j]] = 0
    elseif backward_mask_sbx[r, i, j] >= 1 then
        any_or_active_subtweakey[r + R1, permutation_per_round[r + Rb + R1, 4*i + j]] = 1
        /\
        active_subtweakeys[r + R1, permutation_per_round[r + Rb + R1, 4*i + j]] = 1
    else
        any_or_active_subtweakey[r + R1, permutation_per_round[r + Rb + R1, 4*i + j]] = 0
        /\
        active_subtweakeys[r + R1, permutation_per_round[r + Rb + R1, 4*i + j]] = 0
    endif /\
    any_or_active_subtweakey[r + R1, permutation_per_round[r + Rb + R1, 4*i + j + 8]] = 0
    /\
    active_subtweakeys[r + R1, permutation_per_round[r + Rb + R1, 4*i + j + 8]] = 0
);

%   ____                             _               ____            _                 _ _      _   _             
%  / ___|_   _  __ _ _ __ __ _ _ __ | |_ ___  ___   / ___|___  _ __ | |_ _ __ __ _  __| (_) ___| |_(_) ___  _ __  
% | |  _| | | |/ _` | '__/ _` | '_ \| __/ _ \/ _ \ | |   / _ \| '_ \| __| '__/ _` |/ _` | |/ __| __| |/ _ \| '_ \ 
% | |_| | |_| | (_| | | | (_| | | | | ||  __/  __/ | |__| (_) | | | | |_| | | (_| | (_| | | (__| |_| | (_) | | | |
%  \____|\__,_|\__,_|_|  \__,_|_| |_|\__\___|\___|  \____\___/|_| |_|\__|_|  \__,_|\__,_|_|\___|\__|_|\___/|_| |_|
% include some constraints to guarantee the contradiction in the tweakey schedule

constraint forall(i in 0..15)
(
    key_counter_sum_dist[i] = sum(r in 0..(Nd - 1))(any_or_active_subtweakey[r, i])
    /\
    key_counter_active_sum[i] = sum(r in 0..(Nd - 1))(active_subtweakeys[r, i])
);

array[0..15] of var 0..1: contradict;
constraint forall(i in 0..15)
(
    contradict[i] = bool2int(key_counter_sum_dist[i] <= p /\ key_counter_active_sum[i] >= 1) + bool2int(key_counter_sum_dist[i] == 0)
);

constraint sum(i in 0..15)(contradict[i]) >= 1;

%   ____                _             _       _          __              _____ _     
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| |__  
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | '_ \ 
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |_) |
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_.__/ 
% constraints for Eb

array[0..Rb, 0..3, 0..3] of var 0..1: backward_eb_mask_x;
array[0..(Rb - 1), 0..3] of var 0..1: backward_eb_mask_aux;

% Exlude the masks with all active words
var 0..16: input_mask_keyrecovery;
constraint input_mask_keyrecovery = sum(i in 0..3, j in 0..3)(backward_eb_mask_x[0,i,j]);
constraint input_mask_keyrecovery <= 15;

% link the end of Eb to the beginning of E1

constraint forall(i in 0..3, j in 0..3)
(
    if forward_mask_x[0,i,j] >= 2 then
        backward_eb_mask_x[Rb,i,j] = 1
    else
        backward_eb_mask_x[Rb,i,j] = forward_mask_x[0,i,j]
    endif
);

% MixColumn
constraint forall(r in 0..(Rb - 1), j in 0..3)
(
    mix_column_backward_with_probability_one(backward_eb_mask_x[r+1, 0, j], backward_eb_mask_x[r+1, 1, j], 
                                            backward_eb_mask_x[r+1, 2, j], backward_eb_mask_x[r+1, 3, j], 
                                            backward_eb_mask_x[r, 0, (j-0+4) mod 4], backward_eb_mask_x[r, 1, (j-1+4) mod 4],
                                            backward_eb_mask_x[r, 2, (j-2+4) mod 4], backward_eb_mask_x[r, 3, (j-3+4) mod 4],
                                            backward_eb_mask_aux[r,j])
);

%   ____                _             _       _          __              _____  __ 
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____|/ _|
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | |_ 
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___|  _|
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_|  
% cnstraints for Ef

array[0..15, 0..Rf, 0..3, 0..3] of var 0..1: forward_ef_mask_x;
array[0..15, 0..(Rf - 1), 0..3] of var 0..1: forward_ef_mask_aux;

% Link the beginning of Ef to the end of E2
constraint forall(i in 0..3, j in 0..3)
(
    if backward_mask_x[R2, i, j] >= 1 then
        forward_ef_mask_x[4*i + j, 0, i, j] = 1
        /\
        forall(k in 0..15 where k != 4*i + j)(forward_ef_mask_x[k, 0, i, j] = 0)
    else
        forall(k in 0..15)(forward_ef_mask_x[k, 0, i, j] = 0)
    endif
);

% MixColumn
constraint forall(k in 0..15, r in 0..(Rf - 1), j in 0..3)
(
    mix_column_forward_with_probability_one(forward_ef_mask_x[k, r, 0, (j-0+4) mod 4], forward_ef_mask_x[k, r, 1, (j-1+4) mod 4],
                    forward_ef_mask_x[k, r, 2, (j-2+4) mod 4], forward_ef_mask_x[k, r, 3, (j-3+4) mod 4],
                    forward_ef_mask_x[k, r+1, 0, j], forward_ef_mask_x[k, r+1, 1, j],
                    forward_ef_mask_x[k, r+1, 2, j], forward_ef_mask_x[k, r+1, 3, j],
                    forward_ef_mask_aux[k, r, j])   
);

%  _  __                ____       _     _       _             
% | |/ /___ _   _      | __ ) _ __(_) __| | __ _(_)_ __   __ _ 
% | ' // _ \ | | |_____|  _ \| '__| |/ _` |/ _` | | '_ \ / _` |
% | . \  __/ |_| |_____| |_) | |  | | (_| | (_| | | | | | (_| |
% |_|\_\___|\__, |     |____/|_|  |_|\__,_|\__, |_|_| |_|\__, |
%           |___/                          |___/         |___/ 
% constraints to model the key bridging

array[0..15, 0..3, 0..7] of var 0..(Rb + Rf): key_counter_sum;
array[0..15, 0..3, 0..7] of var 0..1: key_entropy;
array[0..15] of var 0..32: key_entropy_sum;
var 0..32: max_key_entropy_sum;

constraint forall (k in 0..15, t in 0..3, i in 0..1, j in 0..3)
(
    key_counter_sum[k, ((t + Nd + Rb) mod 4), 4*i + j] = sum(r in 0..(Rf - 1) where (((r + Nd + Rb) mod 4) = (t + Nd + Rb) mod 4))(forward_ef_mask_x[k, r, i + 2, j])
);

constraint forall(k in 0..15, i in 0..3, j in 0..7)
(
    if (key_counter_sum[k, i, j] >= 1) then
        key_entropy[k, i, j] = 1
    else
        key_entropy[k, i, j] = 0
    endif
);

constraint forall(k in 0..15)
(
    key_entropy_sum[k] = sum(i in 0..3, j in 0..7)(key_entropy[k, i, j])
);

% compute the maximum of the key_entropy_sum
constraint max_key_entropy_sum = max(k in 0..15)(key_entropy_sum[k]);

constraint sum(i in 0..3, j in 0..3)(backward_mask_x[R2, i, j]) <= 2;
constraint sum(i in 0..15)(contradict[i]) <= 1;
constraint max_key_entropy_sum <= 31;

% constraint forward_mask_x[0, 0, 0] = 3;
% constraint forward_mask_x[0, 0, 1] = 3;
% constraint forward_mask_x[0, 2, 3] = 3;
% constraint forward_mask_x[0, 3, 2] = 3;
% constraint sum(i in 0..3, j in 0..3)(forward_mask_x[0, i, j]) = 2;
% constraint backward_mask_x[R2, 1, 1] = 1;
% constraint backward_mask_x[R2, 3, 1] = 1;
% constraint sum(i in 0..3, j in 0..3)(backward_mask_x[R2, i, j]) = 2;


% solve minimize max_key_entropy_sum;
constraint max_key_entropy_sum <= 29;
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

predicate xor_with_probability_one(var 0..1: A, var 0..1: B, var 0..1: C) =
    (C >= A)
    /\ 
    (C >= B) 
    /\ 
    (A + B - C >= 0) 
;

predicate mix_column_forward_with_probability_one(var 0..1: in_mask1, var 0..1: in_mask2,
                                                var 0..1: in_mask3, var 0..1: in_mask4, 
                                                var 0..1: out_mask1, var 0..1: out_mask2, 
                                                var 0..1: out_mask3, var 0..1: out_mask4, var 0..1: auxi_mask) =
    % The First Row
    out_mask1 = in_mask4
    /\
    % The Third Row
    out_mask3 = in_mask2
    /\
    % Computing Aux
    % A: in_mask2
    % B: in_mask3
    % C: auxi_mask
    xor_with_probability_one(in_mask2, in_mask3, auxi_mask)
    /\
    % The Second Row
    % A: auxi_mask, auxi_class
    % B: in_mask1, in_class1
    % C: out_mask2, out_class2
    xor_with_probability_one(auxi_mask, in_mask1, out_mask2)
    /\
    % The Fourth Row
    % A: auxi_mask
    % B: in_mask4
    % C: out_mask4
    xor_with_probability_one(auxi_mask, in_mask4, out_mask4)
;

predicate mix_column_backward_with_probability_one(var 0..1: in_mask1, var 0..1: in_mask2,
                                                var 0..1: in_mask3, var 0..1: in_mask4, 
                                                var 0..1: out_mask1, var 0..1: out_mask2, 
                                                var 0..1: out_mask3, var 0..1: out_mask4, var 0..1: auxi_mask) =
    % The Second Row
    out_mask2 = in_mask3
    /\
    % The Fourth Row
    out_mask4 = in_mask1
    /\
    % Computing Aux
    % A: in_mask1
    % B: in_mask4
    % C: auxi_mask
    xor_with_probability_one(in_mask1, in_mask4, auxi_mask)
    /\
    % The First Row
    % A: auxi_mask
    % B: in_mask2
    % C: out_mask1
    xor_with_probability_one(auxi_mask, in_mask2, out_mask1)
    /\
    % The Third Row
    % A: auxi_mask
    % B: in_mask3
    % C: out_mask3
    xor_with_probability_one(auxi_mask, in_mask3, out_mask3)
;