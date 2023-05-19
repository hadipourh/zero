int: Ru;
int: Rl;
int: p;
int: Nd;
Nd = Ru + Rl;

constraint assert(Ru >= 1,"Invalid value for Ru: " ++
                "Ru must be greater than or equal to 1");

constraint assert(Rl >= 1,"Invalid value for Rl: " ++
                "Rl must be greater than or equal to 1");

%  __  __           _      _   _   _            _____                    _                   ____       _              _       _      
% |  \/  | ___   __| | ___| | | |_| |__   ___  |_   _|_      _____  __ _| | _____ _   _     / ___|  ___| |__   ___  __| |_   _| | ___ 
% | |\/| |/ _ \ / _` |/ _ \ | | __| '_ \ / _ \   | | \ \ /\ / / _ \/ _` | |/ / _ \ | | |____\___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \
% | |  | | (_) | (_| |  __/ | | |_| | | |  __/   | |  \ V  V /  __/ (_| |   <  __/ |_| |_____|__) | (__| | | |  __/ (_| | |_| | |  __/
% |_|  |_|\___/ \__,_|\___|_|  \__|_| |_|\___|   |_|   \_/\_/ \___|\__,_|_|\_\___|\__, |    |____/ \___|_| |_|\___|\__,_|\__,_|_|\___|
%                                                                                 |___/                                               

array[0..Nd, 0..15] of var 0..1: any_or_active_subtweakey;
array[0..Nd, 0..15] of var 0..1: active_subtweakeys;
array[0..15] of var 0..(Nd + 1): key_counter_sum_dist;
array[0..15] of var 0..(Nd + 1): key_counter_active_sum;
array[0..15] of int: tweakey_permutation = array1d(0..15,[1, 6, 11, 12, 5, 10, 15, 0, 9, 14, 3, 4, 13, 2, 7, 8]);
array[0..Nd, 0..15] of var int: permutation_per_round;
constraint forall (i in 0..15) (permutation_per_round[0,i] = i);
constraint forall (n in 1..Nd, i in 0..15) (permutation_per_round[n,i] = tweakey_permutation[permutation_per_round[n-1,i]]);

%  __  __           _      _   _____ _   _ 
% |  \/  | ___   __| | ___| | | ____| | | |
% | |\/| |/ _ \ / _` |/ _ \ | |  _| | | | |
% | |  | | (_) | (_| |  __/ | | |___| |_| |
% |_|  |_|\___/ \__,_|\___|_| |_____|\___/ 

array[0..Ru, 0..3, 0..3] of var 0..3: AXU;
array[0..Ru, 0..3, 0..3] of var -2..15: LXU;
constraint forall(r in 0..Ru, i in 0..3, j in 0..3)(link_mask_class(AXU[r, i, j], LXU[r, i, j]));

array[0..(Ru - 1), 0..3, 0..3] of var 0..3: AYU;
array[0..(Ru - 1), 0..3, 0..3] of var -2..15: LYU;
constraint forall(r in 0..(Ru - 1), i in 0..3, j in 0..3)(link_mask_class(AYU[r, i, j], LYU[r, i, j]));

% S-box
constraint forall(r in 0..(Ru - 1), i in 0..3, j in 0..3)
(
    sb_operation(AXU[r, i, j], AYU[r, i, j])
);

% SR and MixColumn
constraint forall(r in 0..(Ru - 1), j in 0..3)
(
    mix_column(AYU[r, 0, j], AYU[r, 1, (j + 1) mod 4], AYU[r, 2, (j + 2) mod 4], AYU[r, 3, (j + 3) mod 4],
               LYU[r, 0, j], LYU[r, 1, (j + 1) mod 4], LYU[r, 2, (j + 2) mod 4], LYU[r, 3, (j + 3) mod 4],
               AXU[r + 1, 0, j], AXU[r + 1, 1, j], AXU[r + 1, 2, j], AXU[r + 1, 3, j])
);

% link the subtweakey and the internal state
constraint forall(r in 0..(Ru - 1), i in 0..3, j in 0..3)
(
    if AXU[r, i, j] == 3 then 
        any_or_active_subtweakey[r, permutation_per_round[r, i + 4*j]] = 1
        /\
        active_subtweakeys[r, permutation_per_round[r, i + 4*j]] = 0
    elseif AXU[r, i, j] >= 1 then
        any_or_active_subtweakey[r, permutation_per_round[r, i + 4*j]] = 1
        /\
        active_subtweakeys[r, permutation_per_round[r, i + 4*j]] = 1
    else
        any_or_active_subtweakey[r, permutation_per_round[r, i + 4*j]] = 0
        /\
        active_subtweakeys[r, permutation_per_round[r, i + 4*j]] = 0
    endif
);

% exlcude all-zero input
constraint sum(i in 0..3, j in 0..3)(AXU[0, i, j]) != 0;

%  __  __           _      _   _____ _     
% |  \/  | ___   __| | ___| | | ____| |    
% | |\/| |/ _ \ / _` |/ _ \ | |  _| | |    
% | |  | | (_) | (_| |  __/ | | |___| |___ 
% |_|  |_|\___/ \__,_|\___|_| |_____|_____|
                
array[0..Rl, 0..3, 0..3] of var 0..3: AXL;
array[0..Rl, 0..3, 0..3] of var -2..15: LXL;
constraint forall(r in 0..Rl, i in 0..3, j in 0..3)(link_mask_class(AXL[r, i, j], LXL[r, i, j]));

array[0..(Rl - 1), 0..3, 0..3] of var 0..3: AYL;
array[0..(Rl - 1), 0..3, 0..3] of var -2..15: LYL;
constraint forall(r in 0..(Rl - 1), i in 0..3, j in 0..3)(link_mask_class(AYL[r, i, j], LYL[r, i, j]));

% S-box
constraint forall(r in 0..(Rl - 1), i in 0..3, j in 0..3)
(
    sb_operation(AYL[r, i, j], AXL[r, i, j])
);

% SR and MixColumn
constraint forall(r in 0..(Rl - 2), j in 0..3)
(
    mix_column(AXL[r + 1, 0, j], AXL[r + 1, 1, j], AXL[r + 1, 2, j], AXL[r + 1, 3, j],
               LXL[r + 1, 0, j], LXL[r + 1, 1, j], LXL[r + 1, 2, j], LXL[r + 1, 3, j],
               AYL[r, 0, j], AYL[r, 1, (j + 1) mod 4], AYL[r, 2, (j + 2) mod 4], AYL[r, 3, (j + 3) mod 4])
);

% link the subtweakey and the internal state
constraint forall(r in 0..(Rl - 1), i in 0..3, j in 0..3)
(
    if AXL[r, i, j] == 3 then 
        any_or_active_subtweakey[r + Ru, permutation_per_round[r + Ru, i + 4*j]] = 1
        /\
        active_subtweakeys[r + Ru, permutation_per_round[r + Ru, i + 4*j]] = 0
    elseif AXL[r, i, j] >= 1 then
        any_or_active_subtweakey[r + Ru, permutation_per_round[r + Ru, i + 4*j]] = 1
        /\
        active_subtweakeys[r + Ru, permutation_per_round[r + Ru, i + 4*j]] = 1
    else
        any_or_active_subtweakey[r + Ru, permutation_per_round[r + Ru, i + 4*j]] = 0
        /\
        active_subtweakeys[r + Ru, permutation_per_round[r + Ru, i + 4*j]] = 0
    endif
);

% exclude all-zero output
constraint sum(i in 0..3, j in 0..3)(AXL[Rl - 1, i, j]) != 0;

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

constraint forall(i in 0..3, j in 0..3)
(
    AXU[0, i, j] = 3 \/
    AXU[0, i, j] = 0
);

constraint forall(i in 0..3, j in 0..3)
(
    AYL[Rl - 1, i, j] = 2 \/
    AYL[Rl - 1, i, j] = 0
);
constraint AYL[Rl - 1, 1, 3] = 0;
constraint AYL[Rl - 1, 0, 3] = 0;
var 0..48: WI;
constraint WI = sum(i in 0..3, j in 0..3)(AXU[0, i, j]);
solve maximize WI;

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

predicate mix_column(var 0..3: AX1,
                     var 0..3: AX2,
                     var 0..3: AX3,
                     var 0..3: AX4,
                     var -2..15: LX1,
                     var -2..15: LX2,
                     var -2..15: LX3,
                     var -2..15: LX4,
                     var 0..3: AY1,
                     var 0..3: AY2,
                     var 0..3: AY3,
                     var 0..3: AY4) =
    if AX1 + AX2 + AX3 + AX3 + AX4 == 0 then 
        AY1 = 0 /\ AY2 = 0 /\ AY3 = 0 /\ AY4 = 0
    elseif AX1 + AX2 + AX3 + AX3 + AX4 == 1 then 
        AY1 = 1 /\ AY2 = 1 /\ AY3 = 1 /\ AY4 = 1
    elseif ((AX1 + AX2 + AX3 + AX3 + AX4 == 2) /\ LX1 + LX2 + LX3 + LX4 < 0) then 
        AY1 = 2 /\ AY2 = 2 /\ AY3 = 2 /\ AY4 = 2
    else
        AY1 = 3 /\ AY2 = 3 /\ AY3 = 3 /\ AY4 = 3
    endif
;
