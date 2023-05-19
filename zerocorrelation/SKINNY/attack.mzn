% number of parallel tweakey lines in the tweakey schedule
int: P;
% the length of upper trail throughout the distinguisher part
int: RU;
% the length of lower trail throughout the distinguisher part
int: RL;
int: RD = RU + RL;
% the length of prepended rounds in key-recovery
int: RB;
% the length of appended rounds in key-recovery
int: RF;
% total number of rounds
int: RT = RB + RD + RF;
bool: skip_first_sbox_layer = true;

constraint assert(RB >= 1, "Invalid value for RB: " ++
                  "RB must be greater than or equal to 1");

constraint assert(RU >= 1, "Invalid value for RU: " ++
                  "RU must be greater than or equal to 1");

constraint assert(RL >= 1, "Invalid value for RL: " ++
                  "RL must be greater than or equal to 1");

constraint assert(RF >= 1, "Invalid value for RF: " ++
                  "RF must be greater than or equal to 1");

constraint assert(P >= 1 /\ P <= 3, "Invalid value for P: " ++
                  "P must be in [1, 2, 3]");

% skinny state round_permutation
array[0..15] of int: round_permutation = array1d(0..15, [0, 1, 2, 3, 7, 4, 5, 6, 10, 11, 8, 9, 13, 14, 15, 12]);
array[0..15] of int: inv_tweakey_permutation = array1d(0..15, [8, 9, 10, 11, 12, 13, 14, 15, 2, 0, 4, 7, 6, 3, 5, 1]);
array[0..(RT - 1), 0..15] of var int: inv_tkp;
constraint forall(i in 0..15) (inv_tkp[0, i] = i);
constraint forall(r in 1..(RT - 1), i in 0..15)
(
    inv_tkp[r, i] = inv_tweakey_permutation[inv_tkp[r - 1, i]]
);

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _____  _   _ 
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  | ____|| | | |
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__| |  _|  | | | |
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |    | |___ | |_| |
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|    |_____| \___/ 
% constraints for EU

% AXU: Activeness of the state cell before the sbox in the Upper trail
% LXU: Mask value of the state cell before the sbox in the Upper trail
% AYU: Active state cell after the sbox in the Upper trail
% LYU: Mask value of the state cell after the sbox in the Upper trail
% DummyAU: Dummy variable to handle the MixColumn
% DummyLU: Dummy variable to handle the MixColumn

array[0..RU, 0..15] of var 0..3: AXU;
array[0..RU, 0..15] of var -2..15: LXU;
constraint forall(r in 0..RU, i in 0..15) (
    link_mask(AXU[r, i], LXU[r, i])
);

array[0..(RU - 1), 0..15] of var 0..3: AYU;
array[0..(RU - 1), 0..15] of var -2..15: LYU;
constraint forall(r in 0..(RU - 1), i in 0..15) (
    link_mask(AYU[r, i], LYU[r, i])
);

array[0..(RU - 1), 0..3] of var 0..3: DummyAU;
array[0..(RU - 1), 0..3] of var -2..15: DummyLU;
constraint forall(r in 0..(RU - 1), i in 0..3) (
    link_mask(DummyAU[r, i], DummyLU[r, i])
);

% exclude all-zero input mask
var 0..48: input_mask_distinguisher;
constraint input_mask_distinguisher = sum(i in 0..15)(AXU[0, i]);
constraint input_mask_distinguisher != 0;

% S-box
constraint if (skip_first_sbox_layer) then
(
    forall(i in 0..15)
    (
        AYU[0, i] = AXU[0, i] /\
        LYU[0, i] = LXU[0, i]
    )
) else
(
    forall(i in 0..15)
    (
        sbox(AXU[0, i], AYU[0, i])
    )   
) endif;

constraint forall(r in 1..(RU - 1), i in 0..15)
(
    sbox(AXU[r, i], AYU[r, i])
);

% mix-column

constraint forall(r in 0..(RU - 1), i in 0..3)
(
    mix_column_forward(AYU[r, round_permutation[i]], LYU[r, round_permutation[i]],
                       AYU[r, round_permutation[i + 4]], LYU[r, round_permutation[i + 4]],
                       AYU[r, round_permutation[i + 8]], LYU[r, round_permutation[i + 8]],
                       AYU[r, round_permutation[i + 12]], LYU[r, round_permutation[i + 12]],
                       AXU[r + 1, i], LXU[r + 1, i],
                       AXU[r + 1, i + 4], LXU[r + 1, i + 4],
                       AXU[r + 1, i + 8], LXU[r + 1, i + 8],
                       AXU[r + 1, i + 12], LXU[r + 1, i + 12],
                       DummyAU[r, i], DummyLU[r, i])
);

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _____  _     
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  | ____|| |    
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__| |  _|  | |    
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |    | |___ | |___ 
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|    |_____||_____|
% constraints for EL                    

% AXL: Activeness of the state cell before the sbox in the Lower trail
% LXL: Mask value of the state cell before the sbox in the Lower trail
% AYL: Active state cell after the sbox in the Lower trail
% LYL: Mask value of the state cell after the sbox in the Lower trail
% DummyAL: Dummy variable to handle the MixColumn
% DummyLL: Dummy variable to handle the MixColumn

array[0..RL, 0..15] of var 0..3: AXL;
array[0..RL, 0..15] of var -2..15: LXL;
constraint forall(r in 0..RL, i in 0..15) (
    link_mask(AXL[r, i], LXL[r, i])
);

array[0..(RL - 1), 0..15] of var 0..3: AYL;
array[0..(RL - 1), 0..15] of var -2..15: LYL;
constraint forall(r in 0..(RL - 1), i in 0..15) (
    link_mask(AYL[r, i], LYL[r, i])
);

array[0..(RL - 1), 0..3] of var 0..3: DummyAL;
array[0..(RL - 1), 0..3] of var -2..15: DummyLL;
constraint forall(r in 0..(RL - 1), i in 0..3) (
    link_mask(DummyAL[r, i], DummyLL[r, i])
);

% exclude all-zero output mask
var 0..48: output_mask_distinguisher;
constraint output_mask_distinguisher = sum(i in 0..15)(AXL[RL, i]);
constraint output_mask_distinguisher != 0;

% mix-column
constraint forall(r in 0..(RL - 1), i in 0..3)
(
    mix_column_backward(AXL[r + 1, i], LXL[r + 1, i],
                        AXL[r + 1, i + 4], LXL[r + 1, i + 4],
                        AXL[r + 1, i + 8], LXL[r + 1, i + 8],
                        AXL[r + 1, i + 12], LXL[r + 1, i + 12],
                        AYL[r, round_permutation[i]], LYL[r, round_permutation[i]],
                        AYL[r, round_permutation[i + 4]], LYL[r, round_permutation[i + 4]],
                        AYL[r, round_permutation[i + 8]], LYL[r, round_permutation[i + 8]],
                        AYL[r, round_permutation[i + 12]], LYL[r, round_permutation[i + 12]],
                        DummyAL[r, i], DummyLL[r, i])
);

% S-box
constraint forall(r in 0..(RL - 1), i in 0..15)
(
    sbox(AYL[r, i], AXL[r, i])
);

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _    _             __  __              _    _                 ____         _         _   
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  | |_ | |__    ___  |  \/  |  ___   ___ | |_ (_) _ __    __ _  |  _ \  ___  (_) _ __  | |_ 
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__| | __|| '_ \  / _ \ | |\/| | / _ \ / _ \| __|| || '_ \  / _` | | |_) |/ _ \ | || '_ \ | __|
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |    | |_ | | | ||  __/ | |  | ||  __/|  __/| |_ | || | | || (_| | |  __/| (_) || || | | || |_ 
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|     \__||_| |_| \___| |_|  |_| \___| \___| \__||_||_| |_| \__, | |_|    \___/ |_||_| |_| \__|
%                                                                                                                                          |___/                              
% constraints for the meeting point
var 0..16: contradict1;
var 0..16: contradict2;
constraint contradict1 = sum(i in 0..15)(bool2int((AXU[RU, i] + AXL[0, i] > 0) /\ (AXU[RU, i] + AXL[0, i] < 3) /\ (AXU[RU, i] != AXL[0, i])));
constraint contradict2 = sum(i in 0..15)(bool2int(AXU[RU, i] == 1 /\ AXL[0, i] == 1 /\ (LXU[RU, i] != LXL[0, i])));
constraint contradict1 + contradict2 > 0;

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _____  ____  
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  | ____|| __ ) 
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__| |  _|  |  _ \ 
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |    | |___ | |_) |
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|    |_____||____/ 
% constraints for EB

array[0..RB, 0..15] of var 0..1: AXB;
array[0..(RB - 1), 0..3] of var 0..1: DummyB;

% link the end of EB to the beginning of EU
constraint forall(i in 0..15)
(
    if (AXU[0, i] >= 1) then 
        AXB[RB, i] = 1
    else
        AXB[RB, i] = 0
    endif
);

% mix-column
constraint forall(r in 0..(RB - 1), i in 0..3)
(
    mix_column_backward_with_probability_one(AXB[r + 1, i], AXB[r + 1, i + 4], AXB[r + 1, i + 8], AXB[r + 1, i + 12],
                                             AXB[r, round_permutation[i]], AXB[r, round_permutation[i + 4]], AXB[r, round_permutation[i + 8]], AXB[r, round_permutation[i + 12]],
                                             DummyB[r, i])
);

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _____  _____ 
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  | ____||  ___|
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__| |  _|  | |_   
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |    | |___ |  _|  
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|    |_____||_|    
% constraints for EF

array[0..RF, 0..15] of var 0..1: AXF;
array[0..(RF - 1), 0..3] of var 0..1: DummyF;

% link the beginning of EF to the end of EL
constraint forall(i in 0..15)
(
    if (AXL[RL, i] >= 1) then 
        AXF[0, i] = 1
    else
        AXF[0, i] = 0
    endif
);

% mix-column
constraint forall(r in 0..(RF - 1), i in 0..3)
(
    mix_column_forward_with_probability_one(AXF[r, round_permutation[i]], AXF[r, round_permutation[i + 4]], AXF[r, round_permutation[i + 8]], AXF[r, round_permutation[i + 12]],
                                            AXF[r + 1, i], AXF[r + 1, i + 4], AXF[r + 1, i + 8], AXF[r + 1, i + 12],
                                            DummyF[r, i])
);

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%  _  __                    ____         _      _         _               
% | |/ / ___  _   _        | __ )  _ __ (_)  __| |  __ _ (_) _ __    __ _ 
% | ' / / _ \| | | | _____ |  _ \ | '__|| | / _` | / _` || || '_ \  / _` |
% | . \|  __/| |_| ||_____|| |_) || |   | || (_| || (_| || || | | || (_| |
% |_|\_\\___| \__, |       |____/ |_|   |_| \__,_| \__, ||_||_| |_| \__, |
%             |___/                                |___/            |___/ 
% constraints for key-bridging
array[0..(RB - 1), 0..15] of var 0..1: IKB;
array[0..(RF - 1), 0..15] of var 0..1: IKF;

% involved key cells in the first round (equivalent sub-key)
constraint IKB[0, 0] >= AXB[1, 0];
constraint IKB[0, 0] >= AXB[1, 4];
constraint IKB[0, 0] >= AXB[1, 12];
constraint IKB[0, 0] <= AXB[1, 0] + AXB[1, 4] + AXB[1, 12];

constraint IKB[0, 1] >= AXB[1, 1];
constraint IKB[0, 1] >= AXB[1, 5];
constraint IKB[0, 1] >= AXB[1, 13];
constraint IKB[0, 1] <= AXB[1, 1] + AXB[1, 5] + AXB[1, 13];

constraint IKB[0, 2] >= AXB[1, 2];
constraint IKB[0, 2] >= AXB[1, 6];
constraint IKB[0, 2] >= AXB[1, 14];
constraint IKB[0, 2] <= AXB[1, 2] + AXB[1, 6] + AXB[1, 14];

constraint IKB[0, 3] >= AXB[1, 3];
constraint IKB[0, 3] >= AXB[1, 7];
constraint IKB[0, 3] >= AXB[1, 15];
constraint IKB[0, 3] <= AXB[1, 3] + AXB[1, 7] + AXB[1, 15];

constraint IKB[0, 7] = AXB[1, 8];
constraint IKB[0, 4] = AXB[1, 9];
constraint IKB[0, 5] = AXB[1, 10];
constraint IKB[0, 6] = AXB[1, 11];

% encode involved key-cells in EB
constraint forall(r in 1..(RB - 1), i in 0..7)
(
    IKB[r, i] = AXB[r, i] /\ IKB[r, i + 8] = 0
);

% encode involved key-cells in EF
constraint forall(r in 0..(RF - 1), i in 0..7)
(
    IKF[r, i] = AXF[r, i] /\ IKF[r, i + 8] = 0
);

array[0..15] of var 0..(RB + RF): IK;
constraint forall(i in 0..15)
(
    IK[i] = sum(r in 0..(RB - 1))(IKB[r, inv_tkp[r, i]]) + sum(r in 0..(RF - 1))(IKF[r, inv_tkp[r + RB + RD, i]])
);

array[0..15] of var 0..P: KE;
constraint forall(i in 0..15)
(
    if (IK[i] >= P) then (KE[i] = P) else (KE[i] = IK[i]) endif
);

var 0..(P*16): KS;
constraint KS = sum(i in 0..15)(KE[i]);

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _  __                    ____                                           
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  | |/ / ___  _   _        |  _ \  ___   ___  ___ __   __ ___  _ __  _   _ 
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__| | ' / / _ \| | | | _____ | |_) |/ _ \ / __|/ _ \\ \ / // _ \| '__|| | | |
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |    | . \|  __/| |_| ||_____||  _ <|  __/| (__| (_) |\ V /|  __/| |   | |_| |
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|    |_|\_\\___| \__, |       |_| \_\\___| \___|\___/  \_/  \___||_|    \__, |
%                                                                                               |___/                                                  |___/ 
% constraints for key-recovery
%% objective function (choose one of the following objectives)
% solve minimize KS_Boundaries + input_weight_round2_eb + output_before_last_mc_in_ef;
constraint forall(i in 0..15)
(
    (AXU[0, i] == 0 \/ AXU[0, i] >= 2)
    /\
    (AXL[RL, i] == 0 \/ AXL[RL, i] >= 2)
);
solve minimize KS;

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%     _                 _  _  _                       _____                     _    _                    
%    / \   _   _ __  __(_)| |(_)  __ _  _ __  _   _  |  ___|_   _  _ __    ___ | |_ (_)  ___   _ __   ___ 
%   / _ \ | | | |\ \/ /| || || | / _` || '__|| | | | | |_  | | | || '_ \  / __|| __|| | / _ \ | '_ \ / __|
%  / ___ \| |_| | >  < | || || || (_| || |   | |_| | |  _| | |_| || | | || (__ | |_ | || (_) || | | |\__ \
% /_/   \_\\__,_|/_/\_\|_||_||_| \__,_||_|    \__, | |_|    \__,_||_| |_| \___| \__||_| \___/ |_| |_||___/
%                                             |___/       
% auxiliary functions

predicate link_mask(var 0..3: mask, var -2..15: value) = 
    if (mask == 0) then value == 0
    elseif (mask == 1) then value > 0
    elseif (mask == 2) then value == -1
    else value == -2 endif
;

predicate sbox(var 0..3: in_mask, var 0..3: out_mask) = 
    out_mask != 1 /\
    (in_mask + out_mask) in {0, 3, 4, 6} /\
    out_mask >= in_mask /\
    (out_mask - in_mask) <= 1
;

predicate xor_operation(var 0..3: mask_a, var -2..15: value_a, 
                        var 0..3: mask_b, var -2..15: value_b, 
                        var 0..3: mask_c, var -2..15: value_c) = 
    if (mask_a + mask_b > 2) then
        (mask_c = 3) /\ (value_c = -2)
    elseif (mask_a + mask_b = 1) then
        (mask_c = 1) /\ (value_c = value_a + value_b)
    elseif ((mask_a == 0) /\ (mask_b == 0)) then
        (mask_c = 0) /\ (value_c = 0)
    elseif (value_a + value_b < 0) then
        (mask_c = 2) /\ (value_c = -1)
    elseif (value_a == value_b) then
        (mask_c = 0) /\ (value_c = 0)
    else
        (mask_c = 1) /\
        value_c = (bool2int((value_a mod 2) != (value_b mod 2)) + 
        bool2int(((value_a div 2) mod 2) != ((value_b div 2) mod 2)) * 2 + 
        bool2int(((value_a div 4) mod 2) != ((value_b div 4) mod 2)) * 4 +
        bool2int(((value_a div 8) mod 2) != ((value_b div 8) mod 2)) * 8)
    endif
;

predicate xor_with_probability_one(var 0..1: a, var 0..1: b, var 0..1: c) =
    (c >= a) /\ (c >= b) /\ (a + b - c >= 0)
;

predicate mix_column_forward(var 0..3: in_mask1, var -2..15: in_value1, 
                             var 0..3: in_mask2, var -2..15: in_value2, 
                             var 0..3: in_mask3, var -2..15: in_value3, 
                             var 0..3: in_mask4, var -2..15: in_value4, 
                             var 0..3: out_mask1, var -2..15: out_value1, 
                             var 0..3: out_mask2, var -2..15: out_value2, 
                             var 0..3: out_mask3, var -2..15: out_value3, 
                             var 0..3: out_mask4, var -2..15: out_value4, 
                             var 0..3: auxi_mask, var -2..15: auxi_val) =
    % the first row
    out_mask1 = in_mask4 /\
    out_value1 = in_value4
    /\
    % the third row
    out_mask3 = in_mask2 /\
    out_value3 = in_value2
    /\
    % compute auxiliary variable
    % a: in_mask2, in_value2
    % b: in_mask3, in_value3
    % c: auxi_mask, auxi_val
    xor_operation(in_mask2, in_value2, in_mask3, in_value3, auxi_mask, auxi_val)
    /\
    % the second row
    % a: auxi_mask, auxi_val
    % b: in_mask1, in_value1
    % c: out_mask2, out_value2
    xor_operation(auxi_mask, auxi_val, in_mask1, in_value1, out_mask2, out_value2)
    /\
    % the fourth row
    % a: auxi_mask, auxi_val
    % b: in_mask4, in_value4
    % c: out_mask4, out_value4
    xor_operation(auxi_mask, auxi_val, in_mask4, in_value4, out_mask4, out_value4)
;

predicate mix_column_backward(var 0..3: in_mask1, var -2..15: in_value1, 
                              var 0..3: in_mask2, var -2..15: in_value2, 
                              var 0..3: in_mask3, var -2..15: in_value3, 
                              var 0..3: in_mask4, var -2..15: in_value4, 
                              var 0..3: out_mask1, var -2..15: out_value1, 
                              var 0..3: out_mask2, var -2..15: out_value2, 
                              var 0..3: out_mask3, var -2..15: out_value3, 
                              var 0..3: out_mask4, var -2..15: out_value4, 
                              var 0..3: auxi_mask, var -2..15: auxi_val) =
    % the second row
    out_mask2 = in_mask3 /\
    out_value2 = in_value3
    /\
    % the fourth row
    out_mask4 = in_mask1 /\
    out_value4 = in_value1
    /\
    % compute auxiliary variable
    % a: in_mask1 in_value1
    % b: in_mask4 in_value4
    % c: auxi_mask auxi_val
    xor_operation(in_mask1, in_value1, in_mask4, in_value4, auxi_mask, auxi_val)
    /\
    % the first row
    % a: auxi_mask auxi_val
    % b: in_mask2 in_value2
    % c: out_mask1 out_value1
    xor_operation(auxi_mask, auxi_val, in_mask2, in_value2, out_mask1, out_value1)
    /\
    % the third row
    % a: auxi_mask auxi_val
    % b: in_mask3 in_value3
    % c: out_mask3 out_value3
    xor_operation(auxi_mask, auxi_val, in_mask3, in_value3, out_mask3, out_value3)
;

predicate mix_column_forward_with_probability_one(var 0..1: in_mask1, var 0..1: in_mask2,
                                                  var 0..1: in_mask3, var 0..1: in_mask4, 
                                                  var 0..1: out_mask1, var 0..1: out_mask2, 
                                                  var 0..1: out_mask3, var 0..1: out_mask4, 
                                                  var 0..1: auxi_mask) =
    % first row
    out_mask1 = in_mask4
    /\
    % third row
    out_mask3 = in_mask2
    /\
    % compute auxi_mask
    xor_with_probability_one(in_mask2, in_mask3, auxi_mask)
    /\
    % second row
    xor_with_probability_one(auxi_mask, in_mask1, out_mask2)
    /\
    % fourth row
    xor_with_probability_one(auxi_mask, in_mask4, out_mask4)
;


predicate mix_column_backward_with_probability_one(var 0..1: in_mask1, var 0..1: in_mask2,
                                                   var 0..1: in_mask3, var 0..1: in_mask4,
                                                   var 0..1: out_mask1, var 0..1: out_mask2,
                                                   var 0..1: out_mask3, var 0..1: out_mask4,
                                                   var 0..1: auxi_mask) =
    % second row
    out_mask2 = in_mask3
    /\
    % fourth row
    out_mask4 = in_mask1
    /\
    % compute auxi_mask
    xor_with_probability_one(in_mask1, in_mask4, auxi_mask)
    /\
    % first row
    xor_with_probability_one(auxi_mask, in_mask2, out_mask1)
    /\
    % third Row
    xor_with_probability_one(auxi_mask, in_mask3, out_mask3)
;
