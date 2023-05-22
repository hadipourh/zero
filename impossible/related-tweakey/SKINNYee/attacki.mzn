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

include "table.mzn";
% number of parallel tweakey lines in the tweakey schedule
int: NPT;
% the length of upper trail throughout the distinguisher part
int: RU;
% the length of lower trail throughout the distinguisher part
int: RL;
% the length of distinguisher
int: RD;
RD = RU + RL;
% the length of prepended rounds in key-recovery
int: RB;
% the length of appended rounds in key-recovery
int: RF;
% total number of rounds
int: RT = RB + RD + RF;
% skip the first S-box layer 
bool: skip_first_sbox_layer;
int: block_size;
int: cell_size;
block_size = 16*cell_size;
int: tolerance;
tolerance = 2;

constraint assert(RB >= 1, "Invalid value for RB: " ++
                  "RB must be greater than or equal to 1");

constraint assert(RU >= 1, "Invalid value for RU: " ++
                  "RU must be greater than or equal to 1");

constraint assert(RL >= 1, "Invalid value for RL: " ++
                  "RL must be greater than or equal to 1");

constraint assert(RF >= 1, "Invalid value for RF: " ++
                  "RF must be greater than or equal to 1");

constraint assert(NPT == 4, "Invalid value for NPT: " ++
                  "NPT must be in 4 for SKINNYee");

constraint assert(cell_size == 4, "cell_size must be 4");

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%  ____          __  _                _                   _                    _____       _      _            
% |  _ \   ___  / _|(_) _ __    ___  | |     ___    ___  | | __ _   _  _ __   |_   _|__ _ | |__  | |  ___  ___ 
% | | | | / _ \| |_ | || '_ \  / _ \ | |    / _ \  / _ \ | |/ /| | | || '_ \    | | / _` || '_ \ | | / _ \/ __|
% | |_| ||  __/|  _|| || | | ||  __/ | |___| (_) || (_) ||   < | |_| || |_) |   | || (_| || |_) || ||  __/\__ \
% |____/  \___||_|  |_||_| |_| \___| |_____|\___/  \___/ |_|\_\ \__,_|| .__/    |_| \__,_||_.__/ |_| \___||___/
%                                                                     |_|                 
% define lookup tables

% define the ceil(log2(x) - 0.53) function
array[1..256, 1..2] of int: log2_minus_053_table = array2d(1..256, 1..2, [1, 0, 2, 1, 3, 2, 4, 2, 5, 2, 6, 3, 7, 3, 8, 3, 9, 3, 10, 3, 11, 3, 12, 4, 13, 4, 14, 4, 15, 4, 16, 4, 17, 4, 18, 4, 19, 4, 20, 4, 21, 4, 22, 4, 23, 4, 24, 5, 25, 5, 26, 5, 27, 5, 28, 5, 29, 5, 30, 5, 31, 5, 32, 5, 33, 5, 34, 5, 35, 5, 36, 5, 37, 5, 38, 5, 39, 5, 40, 5, 41, 5, 42, 5, 43, 5, 44, 5, 45, 5, 46, 5, 47, 6, 48, 6, 49, 6, 50, 6, 51, 6, 52, 6, 53, 6, 54, 6, 55, 6, 56, 6, 57, 6, 58, 6, 59, 6, 60, 6, 61, 6, 62, 6, 63, 6, 64, 6, 65, 6, 66, 6, 67, 6, 68, 6, 69, 6, 70, 6, 71, 6, 72, 6, 73, 6, 74, 6, 75, 6, 76, 6, 77, 6, 78, 6, 79, 6, 80, 6, 81, 6, 82, 6, 83, 6, 84, 6, 85, 6, 86, 6, 87, 6, 88, 6, 89, 6, 90, 6, 91, 6, 92, 6, 93, 7, 94, 7, 95, 7, 96, 7, 97, 7, 98, 7, 99, 7, 100, 7, 101, 7, 102, 7, 103, 7, 104, 7, 105, 7, 106, 7, 107, 7, 108, 7, 109, 7, 110, 7, 111, 7, 112, 7, 113, 7, 114, 7, 115, 7, 116, 7, 117, 7, 118, 7, 119, 7, 120, 7, 121, 7, 122, 7, 123, 7, 124, 7, 125, 7, 126, 7, 127, 7, 128, 7, 129, 7, 130, 7, 131, 7, 132, 7, 133, 7, 134, 7, 135, 7, 136, 7, 137, 7, 138, 7, 139, 7, 140, 7, 141, 7, 142, 7, 143, 7, 144, 7, 145, 7, 146, 7, 147, 7, 148, 7, 149, 7, 150, 7, 151, 7, 152, 7, 153, 7, 154, 7, 155, 7, 156, 7, 157, 7, 158, 7, 159, 7, 160, 7, 161, 7, 162, 7, 163, 7, 164, 7, 165, 7, 166, 7, 167, 7, 168, 7, 169, 7, 170, 7, 171, 7, 172, 7, 173, 7, 174, 7, 175, 7, 176, 7, 177, 7, 178, 7, 179, 7, 180, 7, 181, 7, 182, 7, 183, 7, 184, 7, 185, 8, 186, 8, 187, 8, 188, 8, 189, 8, 190, 8, 191, 8, 192, 8, 193, 8, 194, 8, 195, 8, 196, 8, 197, 8, 198, 8, 199, 8, 200, 8, 201, 8, 202, 8, 203, 8, 204, 8, 205, 8, 206, 8, 207, 8, 208, 8, 209, 8, 210, 8, 211, 8, 212, 8, 213, 8, 214, 8, 215, 8, 216, 8, 217, 8, 218, 8, 219, 8, 220, 8, 221, 8, 222, 8, 223, 8, 224, 8, 225, 8, 226, 8, 227, 8, 228, 8, 229, 8, 230, 8, 231, 8, 232, 8, 233, 8, 234, 8, 235, 8, 236, 8, 237, 8, 238, 8, 239, 8, 240, 8, 241, 8, 242, 8, 243, 8, 244, 8, 245, 8, 246, 8, 247, 8, 248, 8, 249, 8, 250, 8, 251, 8, 252, 8, 253, 8, 254, 8, 255, 8, 256, 8]);
% skinny round permutation
array[0..15] of int: round_permutation = array1d(0..15, [0, 1, 2, 3, 7, 4, 5, 6, 10, 11, 8, 9, 13, 14, 15, 12]);
% skinny tweakey permutation
array[0..15] of int: inv_tweakey_permutation = array1d(0..15, [8, 9, 10, 11, 12, 13, 14, 15, 2, 0, 4, 7, 6, 3, 5, 1]);

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _____                        _                  ____         _                _         _       
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  |_   _|__      __ ___   __ _ | | __ ___  _   _  / ___|   ___ | |__    ___   __| | _   _ | |  ___ 
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__|   | |  \ \ /\ / // _ \ / _` || |/ // _ \| | | | \___ \  / __|| '_ \  / _ \ / _` || | | || | / _ \
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |      | |   \ V  V /|  __/| (_| ||   <|  __/| |_| |  ___) || (__ | | | ||  __/| (_| || |_| || ||  __/
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|      |_|    \_/\_/  \___| \__,_||_|\_\\___| \__, | |____/  \___||_| |_| \___| \__,_| \__,_||_| \___|
%                                                                                                                            |___/                                                   

array[0..(RT - 1), 0..15] of var int: inv_tkp;
constraint forall(i in 0..15) (inv_tkp[0, i] = i);
constraint forall(r in 1..(RT - 1), i in 0..15)
(
    inv_tkp[r, i] = inv_tweakey_permutation[inv_tkp[r - 1, i]]
);

array[0..15] of var 0..1: LANE; % activeness pattern in each lane through EB + EU + EL + EF
array[0..(RT - 1), 0..15] of var 0..1: ASTK; % activeness pattern in each round tweakey through EB + EU + EL + EF
array[0..(RT - 1), 0..15] of var -2..15: DSTK; % difference value in each round tweakey through EB + EU + EL + EF

constraint forall(r in 0..(RT - 1), i in 0..15)
(
    link_difference(ASTK[r, i], DSTK[r, i])
);

constraint forall(i in 0..15)
(
    forall(r in 0..(RT - 1)) (ASTK[r, inv_tkp[r, i]] - LANE[i] <= 0)
    /\
    sum(r in 0..(RT - 1))(ASTK[r, inv_tkp[r, i]]) - RT*LANE[i] >= (1 - NPT)
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
array[0..RU, 0..15] of var 0..3: AXU;
array[0..RU, 0..15] of var -2..15: DXU;
constraint forall(i in 0..RU, j in 0..15) (
    link_difference(AXU[i,j], DXU[i,j])
);

array[0..(RU - 1), 0..15] of var 0..3: AYU;
array[0..(RU - 1), 0..15] of var -2..15: DYU;
constraint forall(i in 0..(RU - 1), j in 0..15) (
    link_difference(AYU[i,j], DYU[i,j])
);

array[0..(RU - 1), 0..15] of var 0..3: AZU;
array[0..(RU - 1), 0..15] of var -2..15: DZU;
constraint forall(i in 0..(RU - 1), j in 0..15) (
    link_difference(AZU[i,j], DZU[i,j])
);

% exclude all-zero input difference
constraint sum(i in 0..15)(AXU[0, i]) + sum(i in 0..15)(LANE[i]) != 0;

% S-box
constraint if (skip_first_sbox_layer) then 
(
    forall(i in 0..15)
    (
        AYU[0, i] = AXU[0, i] /\
        DYU[0, i] = DXU[0, i]
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

% xor with round tweakey
constraint forall(r in 0..(RU - 1), i in 0..7)
(
    xor_operation(AYU[r, i], DYU[r, i], ASTK[RB + r, i], DSTK[RB + r, i], AZU[r, i], DZU[r, i])
    /\
    AZU[r, i + 8] = AYU[r, i + 8]
    /\
    DZU[r, i + 8] = DYU[r, i + 8]
);

% mix-column and shift-rows
constraint forall(r in 0..(RU - 1), i in 0..3)
(
    mix_column_forward(AZU[r, round_permutation[i]], DZU[r, round_permutation[i]],
                       AZU[r, round_permutation[i + 4]], DZU[r, round_permutation[i + 4]],
                       AZU[r, round_permutation[i + 8]], DZU[r, round_permutation[i + 8]],
                       AZU[r, round_permutation[i + 12]], DZU[r, round_permutation[i + 12]],
                       AXU[r + 1, i], DXU[r + 1, i],
                       AXU[r + 1, i + 4], DXU[r + 1, i + 4],
                       AXU[r + 1, i + 8], DXU[r + 1, i + 8],
                       AXU[r + 1, i + 12], DXU[r + 1, i + 12])
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

array[0..RL, 0..15] of var 0..3: AXL;
array[0..RL, 0..15] of var -2..15: DXL;
constraint forall(i in 0..RL, j in 0..15) (
    link_difference(AXL[i,j], DXL[i,j])
);

array[0..(RL - 1), 0..15] of var 0..3: AYL;
array[0..(RL - 1), 0..15] of var -2..15: DYL;
constraint forall(i in 0..(RL - 1), j in 0..15) (
    link_difference(AYL[i,j], DYL[i,j])
);

array[0..(RL - 1), 0..15] of var 0..3: AZL;
array[0..(RL - 1), 0..15] of var -2..15: DZL;
constraint forall(i in 0..(RL - 1), j in 0..15) (
    link_difference(AZL[i,j], DZL[i,j])
);

% exclude all-zero output difference
constraint sum(i in 0..15)(AXL[RL, i]) + sum(i in 0..15)(LANE[i]) != 0;

% mix-column and shift-rows
constraint forall(r in 0..(RL - 1), i in 0..3)
(
    mix_column_backward(AXL[r + 1, i], DXL[r + 1, i],
                        AXL[r + 1, i + 4], DXL[r + 1, i + 4],
                        AXL[r + 1, i + 8], DXL[r + 1, i + 8],
                        AXL[r + 1, i + 12], DXL[r + 1, i + 12],
                        AZL[r, round_permutation[i]], DZL[r, round_permutation[i]],
                        AZL[r, round_permutation[i + 4]], DZL[r, round_permutation[i + 4]],
                        AZL[r, round_permutation[i + 8]], DZL[r, round_permutation[i + 8]],
                        AZL[r, round_permutation[i + 12]], DZL[r, round_permutation[i + 12]])
);

% xor with round tweakey
constraint forall(r in 0..(RL - 1), i in 0..7)
(
    xor_operation(AZL[r, i], DZL[r, i], ASTK[RB + RU + r, i], DSTK[RB + RU + r, i], AYL[r, i], DYL[r, i])
    /\
    AYL[r, i + 8] = AZL[r, i + 8]
    /\
    DYL[r, i + 8] = DZL[r, i + 8]
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
var 0..15: contradict1;
var 0..15: contradict2;
constraint contradict1 = sum(i in 0..15)(bool2int((AXU[RU, i] + AXL[0, i] > 0) /\ (AXU[RU, i] + AXL[0, i] < 3) /\ (AXU[RU, i] != AXL[0, i])));
constraint contradict2 = sum(i in 0..15)(bool2int(AXU[RU, i] == 1 /\ AXL[0, i] == 1 /\ (DXU[RU, i] != DXL[0, i])));
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
array[0..(RB - 1), 0..15] of var 0..1: AZB;
array[0..(RB - 1), 0..19] of var 0..1: CB;

% link the end of EB to the beginning of EU
constraint forall(i in 0..15)
(
    if AXU[0, i] >= 1 then
        AXB[RB, i] = 1
    else
        AXB[RB, i] = 0
    endif
);

% mix-column and shift-rows
constraint forall(r in 0..(RB - 1), i in 0..3)
(
    minvdiff_1(AXB[r + 1, i], AXB[r + 1, i + 4], AXB[r + 1, i + 8], AXB[r + 1, i + 12],
               AZB[r, round_permutation[i]], AZB[r, round_permutation[i + 4]], AZB[r, round_permutation[i + 8]], AZB[r, round_permutation[i + 12]])
    /\
    xor_p(AZB[r, round_permutation[i + 4]], AZB[r, round_permutation[i + 8]], AXB[r + 1, i + 8], CB[r, i])
    /\
    xor_p(AZB[r, round_permutation[i]], AZB[r, round_permutation[i + 8]], AXB[r + 1, i + 12], CB[r, i + 4])
    /\
    xor_p(AXB[r + 1, i + 12], AZB[r, round_permutation[i + 12]], AXB[r + 1, i], CB[r, i + 8])
);

% xor with round-tweakey
constraint forall(r in 0..(RB - 1), i in 0..7)
(
    xor_1(AZB[r, i], ASTK[r, i], AXB[r, i])
    /\
    xor_p(AXB[r, i], ASTK[r, i], AZB[r, i], CB[r, i + 12])
    /\
    AXB[r, i + 8] = AZB[r, i + 8]
);

array[0..RB, 0..15] of var 0..1: KDXB;
constraint forall(r in 0..RB, i in 0..15) (KDXB[r, i] <= AXB[r, i]);
array[0..(RB - 1), 0..15] of var 0..1: KDZB;
constraint forall(r in 0..(RB - 1), i in 0..15) (KDZB[r, i] <= AZB[r, i]);

array[0..RB, 0..15] of var 0..1: KXB;
array[0..(RB - 1), 0..15] of var 0..1: KYB;
constraint forall(i in 0..15)
(
    if (AXU[0, i] == 1) then (KDXB[RB, i] = 1) else (KDXB[RB, i] = 0) endif
    /\
    if (AYU[0, i] == 1) then (KXB[RB, i] = 1) else (KXB[RB, i] = 0) endif
);

constraint forall(r in 0..(RB - 1), i in 0..3)
(
    if (KDXB[r + 1, i] == 1) then
    (
        KDZB[r, round_permutation[i]] = AZB[r, round_permutation[i]]
        /\
        KDZB[r, round_permutation[i + 8]] = AZB[r, round_permutation[i + 8]]
        /\
        KDZB[r, round_permutation[i + 12]] = AZB[r, round_permutation[i + 12]]
    ) endif
    /\
    if (KDXB[r + 1, i + 4] == 1) then 
    (
        KDZB[r, round_permutation[i]] = AZB[r, round_permutation[i]]
    ) endif
    /\
    if (KDXB[r + 1, i + 8] == 1) then 
    (
        KDZB[r, round_permutation[i + 4]] = AZB[r, round_permutation[i + 4]]
        /\
        KDZB[r, round_permutation[i + 8]] = AZB[r, round_permutation[i + 8]]
    ) endif
    /\
    if (KDXB[r + 1, i + 12] == 1) then 
    (
        KDZB[r, round_permutation[i]] = AZB[r, round_permutation[i]]
        /\
        KDZB[r, round_permutation[i + 8]] = AZB[r, round_permutation[i + 8]]
    ) endif
    /\
    if (CB[r, i] == 1) then 
    (
        KDZB[r, round_permutation[i + 4]] = 1
        /\
        KDZB[r, round_permutation[i + 8]] = 1
    ) endif
    /\
    if (CB[r, i + 4] == 1) then 
    (
        KDZB[r, round_permutation[i]] = 1
        /\
        KDZB[r, round_permutation[i + 8]] = 1
    ) endif
    /\
    if (CB[r, i + 8] == 1) then 
    (
        KDZB[r, round_permutation[i]] = AZB[r, round_permutation[i]]
        /\
        KDZB[r, round_permutation[i + 8]] = AZB[r, round_permutation[i + 8]]
        /\
        KDZB[r, round_permutation[i + 12]] = 1
    ) endif
    /\
    minv_data(KXB[r + 1, i], KXB[r + 1, i + 4], KXB[r + 1, i + 8], KXB[r + 1, i + 12],
              KYB[r, round_permutation[i]], KYB[r, round_permutation[i + 4]], KYB[r, round_permutation[i + 8]], KYB[r, round_permutation[i + 12]])
);

constraint forall(r in 0..(RB - 1), i in 0..7)
(
    KDXB[r, i] >= KDZB[r, i]
    /\
    KDXB[r, i + 8] = KDZB[r, i + 8]
    /\
    if CB[r, i + 12] == 1 then KDXB[r, i] = 1 endif
);

% S-box
constraint forall(r in 0..(RB - 1), i in 0..15)
(
    xor_1(KYB[r, i], KDXB[r, i], KXB[r, i])
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
array[0..(RF - 1), 0..15] of var 0..1: AZF;
array[0..(RF - 1), 0..19] of var 0..1: CF;

% link the end of EL to the beginning of EF
constraint forall(i in 0..15)
(
    if AXL[RL, i] >= 1 then 
        AXF[0, i] = 1
    else
        AXF[0, i] = 0
    endif
);

% xor with round tweakey
constraint forall(r in 0..(RF - 1), i in 0..7)
(
    xor_1(AXF[r, i], ASTK[RB + RD + r, i], AZF[r, i])
    /\
    xor_p(AZF[r, i], ASTK[RB + RD + r, i], AXF[r, i], CF[r, i])
    /\
    AZF[r, i + 8] = AXF[r, i + 8]
);

% mix-column and shift-rows
constraint forall(r in 0..(RF - 1), i in 0..3)
(
    mdiff_1(AZF[r, round_permutation[i]], AZF[r, round_permutation[i + 4]], AZF[r, round_permutation[i + 8]], AZF[r, round_permutation[i + 12]],
            AXF[r + 1, i], AXF[r + 1, i + 4], AXF[r + 1, i + 8], AXF[r + 1, i + 12])
    /\
    xor_p(AZF[r, round_permutation[i + 8]], AXF[r + 1, i + 8], AZF[r, round_permutation[i + 4]], CF[r, i + 8])
    /\
    xor_p(AXF[r + 1, i + 4], AXF[r + 1, i + 12], AZF[r, round_permutation[i + 8]], CF[r, i + 12])
    /\
    xor_p(AXF[r + 1, i], AXF[r + 1, i + 12], AZF[r, round_permutation[i + 12]], CF[r, i + 16])
);

array[0..RF, 0..15] of var 0..1: KDXF;
constraint forall(r in 0..RF, i in 0..15) (KDXF[r, i] <= AXF[r, i]);
array[0..(RF - 1), 0..15] of var 0..1: KDZF;
constraint forall(r in 0..(RF - 1), i in 0..15) (KDZF[r, i] <= AZF[r, i]);



array[0..RF, 0..15] of var 0..1: KXF;
array[0..(RF - 1), 0..15] of var 0..1: KYF;
constraint forall(i in 0..15)
(
    if (AXL[RL, i] == 1) then (KDXF[0, i] = 1) else (KDXF[0, i] = 0) endif
    /\
    if (AXL[RL, i] == 1) then (KXF[0, i] = 1) else (KXF[0, i] = 0) endif
);

% S-box
constraint forall(r in 0..(RF - 1), i in 0..15)
(
    xor_1(KXF[r, i], KDXF[r, i], KYF[r, i])
);

% xor with round tweakey
constraint forall(r in 0..(RF - 1), i in 0..7)
(
    KDZF[r, i] >= KDXF[r, i]
    /\
    KDZF[r, i + 8] = KDXF[r, i + 8]
    /\
    if CF[r, i] == 1 then KDZF[r, i] = 1 endif
);

constraint forall(r in 0..(RF - 1), i in 0..3)
(
    if (KDZF[r, round_permutation[i]] == 1) then 
    (
        KDXF[r + 1, i + 4] = AXF[r + 1, i + 4] 
    ) endif
    /\
    if (KDZF[r, round_permutation[i + 4]] == 1) then 
    (
        KDXF[r + 1, i + 4] = AXF[r + 1, i + 4]
        /\
        KDXF[r + 1, i + 8] = AXF[r + 1, i + 8]
        /\
        KDXF[r + 1, i + 12] = AXF[r + 1, i + 12]
    ) endif
    /\
    if (KDZF[r, round_permutation[i + 8]] == 1) then
    (
        KDXF[r + 1, i + 4] = AXF[r + 1, i + 4]
        /\
        KDXF[r + 1, i + 12] = AXF[r + 1, i + 12]
    ) endif
    /\
    if (KDZF[r, round_permutation[i + 12]] == 1) then
    (
        KDXF[r + 1, i] = AXF[r + 1, i]
        /\
        KDXF[r + 1, i + 12] = AXF[r + 1, i + 12]
    ) endif
    /\
    if (CF[r, i + 8] == 1) then
    (
        KDXF[r + 1, i + 4] = AXF[r + 1, i + 4]
        /\
        KDXF[r + 1, i + 12] = AXF[r + 1, i + 12]
        /\
        KDXF[r + 1, i + 8] = 1
    ) endif
    /\
    if (CF[r, i + 12] == 1) then
    (
        KDXF[r + 1, i + 4] = 1
        /\
        KDXF[r + 1, i + 12] = 1
    ) endif
    /\
    if (CF[r, i + 16] == 1) then
    (
        KDXF[r + 1, i] = 1
        /\
        KDXF[r + 1, i + 12] = 1
    ) endif
    /\
    mdata(KYF[r, round_permutation[i]], KYF[r, round_permutation[i + 4]], KYF[r, round_permutation[i + 8]], KYF[r, round_permutation[i + 12]],
          KXF[r + 1, i], KXF[r + 1, i + 4], KXF[r + 1, i + 8], KXF[r + 1, i + 12])
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

array[0..3, 0..7] of var 0..RB: IKB;
array[0..3, 0..7] of var 0..RF: IKF;
array[0..3, 0..7] of var 0..(RB + RF): IK;
array[0..3, 0..7] of var 0..1: KE;
var 0..32: KS;

% #############################################################################################################################################
% equivalent round key in the first round
array[0..7] of var 0..1: ETK0;
array[0..7] of var 0..1: RG;
array[0..7] of var 0..(RB + RF): GK;
constraint ETK0[2] >= KXB[1, 8] /\ ETK0[2] >= KXB[1, 12];
constraint ETK0[2] <= KXB[1, 8] + KXB[1, 12];
constraint ETK0[3] >= KXB[1, 9] /\ ETK0[3] >= KXB[1, 13];
constraint ETK0[3] <= KXB[1, 9] + KXB[1, 13];
constraint ETK0[0] >= KXB[1, 10] /\ ETK0[0] >= KXB[1, 14];
constraint ETK0[0] <= KXB[1, 10] + KXB[1, 14];
constraint ETK0[1] >= KXB[1, 11] /\ ETK0[1] >= KXB[1, 15];
constraint ETK0[1] <= KXB[1, 11] + KXB[1, 15];
constraint ETK0[4] = KXB[1, 0];
constraint ETK0[5] = KXB[1, 1];
constraint ETK0[6] = KXB[1, 2];
constraint ETK0[7] = KXB[1, 3];

constraint GK[0] = sum(r in 1..(RB - 1) where (r mod 4) = (0 mod 4))(KYB[r, 0 + 8]) + sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (0 mod 4)))(KYF[r, 0 + 8]);
constraint GK[1] = sum(r in 1..(RB - 1) where (r mod 4) = (0 mod 4))(KYB[r, 1 + 8]) + sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (0 mod 4)))(KYF[r, 1 + 8]);
constraint GK[2] = sum(r in 1..(RB - 1) where (r mod 4) = (0 mod 4))(KYB[r, 2 + 8]) + sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (0 mod 4)))(KYF[r, 2 + 8]);
constraint GK[3] = sum(r in 1..(RB - 1) where (r mod 4) = (0 mod 4))(KYB[r, 3 + 8]) + sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (0 mod 4)))(KYF[r, 3 + 8]);
constraint GK[4] = sum(r in 1..(RB - 1) where (r mod 4) = (0 mod 4))(KYB[r, 4 + 8]) + sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (0 mod 4)))(KYF[r, 4 + 8]);
constraint GK[5] = sum(r in 1..(RB - 1) where (r mod 4) = (0 mod 4))(KYB[r, 5 + 8]) + sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (0 mod 4)))(KYF[r, 5 + 8]);
constraint GK[6] = sum(r in 1..(RB - 1) where (r mod 4) = (0 mod 4))(KYB[r, 6 + 8]) + sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (0 mod 4)))(KYF[r, 6 + 8]);
constraint GK[7] = sum(r in 1..(RB - 1) where (r mod 4) = (0 mod 4))(KYB[r, 7 + 8]) + sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (0 mod 4)))(KYF[r, 7 + 8]);

constraint if (ETK0[2] == 1) /\ (GK[2] >= 1) then RG[2] = 1 else RG[2] = 0 endif;
constraint if (ETK0[3] == 1) /\ (GK[3] >= 1) then RG[3] = 1 else RG[3] = 0 endif;
constraint if (ETK0[0] == 1) /\ (GK[0] >= 1) then RG[0] = 1 else RG[0] = 0 endif;
constraint if (ETK0[1] == 1) /\ (GK[1] >= 1) then RG[1] = 1 else RG[1] = 0 endif;
constraint if (ETK0[4] == 1 /\ GK[2] >= 1 /\ GK[5] >= 1) then RG[4] = 1 else RG[4] = 0 endif;
constraint if (ETK0[5] == 1 /\ GK[3] >= 1 /\ GK[6] >= 1) then RG[5] = 1 else RG[5] = 0 endif;
constraint if (ETK0[6] == 1 /\ GK[0] >= 1 /\ GK[7] >= 1) then RG[6] = 1 else RG[6] = 0 endif;
constraint if (ETK0[7] == 1 /\ GK[1] >= 1 /\ GK[4] >= 1) then RG[7] = 1 else RG[7] = 0 endif;
% #############################################################################################################################################

constraint forall(i in 0..3, j in 0..7)
(
    IKB[(i mod 4), j] = sum(r in 1..(RB - 1) where (r mod 4) = (i mod 4))(KYB[r, j + 8])
);

constraint forall(i in 0..3, j in 0..7)
(
    IKF[((RB + RD + i) mod 4), j] = sum(r in 0..(RF - 1) where (((RB + RD + r) mod 4) = (RB + RD + i) mod 4))(KYF[r, j + 8])
);

constraint forall(i in 0..3, j in 0..7)
(
    IK[i, j] = IKB[i, j] + IKF[i, j]
);

constraint forall(i in 0..3, j in 0..7)
(
    if (IK[i, j] >= 1) then
        KE[i, j] = 1
    else
        KE[i, j] = 0
    endif
);

constraint KS = sum(i in 0..3, j in 0..7)(KE[i, j]) + sum(i in 0..7)(ETK0[i]) - sum(i in 0..7)(RG[i]);
constraint KS <= 31;

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                          _              _  _               _                   _              _      
%  / ___| ___   _ __ ___   _ __  | |  ___ __  __(_)| |_  _   _     / \    _ __    __ _ | | _   _  ___ (_) ___ 
% | |    / _ \ | '_ ` _ \ | '_ \ | | / _ \\ \/ /| || __|| | | |   / _ \  | '_ \  / _` || || | | |/ __|| |/ __|
% | |___| (_) || | | | | || |_) || ||  __/ >  < | || |_ | |_| |  / ___ \ | | | || (_| || || |_| |\__ \| |\__ \
%  \____|\___/ |_| |_| |_|| .__/ |_| \___|/_/\_\|_| \__| \__, | /_/   \_\|_| |_| \__,_||_| \__, ||___/|_||___/
%                         |_|                            |___/                             |___/              
% constraints for complexity analysis

var 0..(RB*20 + 16): CB_tot;
var 0..(RF*20 + 16): CF_tot;
constraint CB_tot = sum(r in 1..(RB - 1), i in 0..19)(CB[r, i]) + sum(i in 0..15)(KXB[RB, i]);
constraint CF_tot = sum(r in 0..(RF - 2), i in 0..19)(CF[r, i]) + sum(i in 0..15)(KXF[0, i]);

var 0..16: WB;
var 0..16: WF;
constraint WB = sum(i in 0..15)(AXB[1, i]);
constraint WF = sum(i in 0..15)(AXF[RF - 1, i]);

var 0..9: log_2_minus_053_of_g;
var 1..384: g;
constraint table([g, log_2_minus_053_of_g], log2_minus_053_table);

array[0..3] of var 0..384: data_complexity;
var 0..384: memory_complexity;
constraint data_complexity[0] = ((cell_size*CB_tot + cell_size*CF_tot + block_size - cell_size*WF + log_2_minus_053_of_g) div 2) + 1;
constraint data_complexity[1] = ((cell_size*CB_tot + cell_size*CF_tot + block_size - cell_size*WB + log_2_minus_053_of_g) div 2) + 1;
constraint data_complexity[2] = min(data_complexity[0], data_complexity[1]);
constraint data_complexity[3] = cell_size*CB_tot + cell_size*CF_tot + block_size + 1 - cell_size*WB - cell_size*WF + log_2_minus_053_of_g;
array[0..3] of var 0..384: t_complexity;
constraint t_complexity[0] = max(data_complexity[2], data_complexity[3]);
constraint t_complexity[1] = cell_size*CB_tot + cell_size*CF_tot + log_2_minus_053_of_g;
constraint t_complexity[2] = cell_size*KS + log_2_minus_053_of_g;
constraint t_complexity[3] = 128 - g;
constraint memory_complexity = min(cell_size*KS, t_complexity[1]);

% constrain g
constraint g > 1;
constraint g <= cell_size*KS;

var 0..384: max_term;
constraint max_term = max(i in 0..3)(t_complexity[i]);

constraint t_complexity[0] <= block_size + tolerance; % data complexity
constraint memory_complexity < 128 + tolerance; % memory complexity
constraint max_term < 128 + tolerance; % time complexity

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################

solve minimize max_term; 

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

predicate xor_1(var 0..1: AX, var 0..1: AY, var 0..1: AZ) = 
    AZ >= AX
    /\
    AZ >= AY
    /\
    AZ <= AX + AY
;

predicate xor3_1(var 0..1: AX, var 0..1: AY, var 0..1: AZ, var 0..1: AW) = 
    AW >= AX
    /\
    AW >= AY
    /\
    AW >= AZ
    /\
    AW <= AX + AY + AZ
;

predicate xor_p(var 0..1: AX, var 0..1: AY, var 0..1: AZ, var 0..1: CB) = 
    if ((AX + AY == 2) /\ AZ == 0) then (CB = 1) else (CB = 0) endif
;

predicate mdiff_1(var 0..1: AX0, var 0..1: AX1, var 0..1: AX2, var 0..1: AX3,
                 var 0..1: AY0, var 0..1: AY1, var 0..1: AY2, var 0..1: AY3) =
    AY1 = AX0
    /\
    xor_1(AX1, AX2, AY2)
    /\
    xor_1(AX0, AX2, AY3)
    /\
    xor_1(AY3, AX3, AY0)
;

predicate mdata(var 0..1: data_in1,
                var 0..1: data_in2,
                var 0..1: data_in3,
                var 0..1: data_in4,
                var 0..1: data_out1,
                var 0..1: data_out2,
                var 0..1: data_out3,
                var 0..1: data_out4) =
    % the first row
    data_out1 = data_in4
    /\
    % the third row
    data_out3 = data_in2
    /\
    % the second row
    xor3_1(data_in2, data_in3, data_in1, data_out2)    
    /\
    % The fourth row
    xor3_1(data_in2, data_in3, data_in4, data_out4)    
;

predicate minvdiff_1(var 0..1: AX0, var 0..1: AX1, var 0..1: AX2, var 0..1: AX3,
                    var 0..1: AY0, var 0..1: AY1, var 0..1: AY2, var 0..1: AY3) =
    AY0 = AX1
    /\
    xor_1(AX1, AX3, AY2)
    /\
    xor_1(AX0, AX3, AY3)
    /\
    xor_1(AY2, AX2, AY1)
;

predicate minv_data(var 0..1: data_in1,
                    var 0..1: data_in2,
                    var 0..1: data_in3,
                    var 0..1: data_in4,
                    var 0..1: data_out1,
                    var 0..1: data_out2,
                    var 0..1: data_out3,
                    var 0..1: data_out4) =
    % the second row
    data_out2 = data_in3
    /\
    % the fourth row
    data_out4 = data_in1
    /\
    % the first row
    xor3_1(data_in1, data_in4, data_in2, data_out1)
    /\
    % the thrid row
    xor3_1(data_in1, data_in4, data_in3, data_out3)
;

predicate link_difference(var 0..3: diff_pattern, var -2..15: diff_value) =  
    if (diff_pattern == 0) then diff_value == 0
    elseif (diff_pattern == 1) then diff_value > 0
    elseif (diff_pattern == 2) then diff_value == -1
    else diff_value = -2
    endif
;

predicate sbox(var 0..3: diff_in, var 0..3: diff_out) = 
    diff_out != 1 /\
    (diff_in + diff_out) in {0, 3, 4, 6} /\
    diff_out >= diff_in /\
    (diff_out - diff_in) <= 1
;

predicate xor_operation(var 0..3: diff_a, var -2..15: dvalue_a, 
                        var 0..3: diff_b, var -2..15: dvalue_b, 
                        var 0..3: diff_c, var -2..15: dvalue_c) = 
    if (diff_a + diff_b > 2) then 
        (diff_c = 3) /\ (dvalue_c = -2)
    elseif (diff_a + diff_b = 1) then
        (diff_c = 1) /\ (dvalue_c = dvalue_a + dvalue_b)
    elseif ((diff_a == 0) /\ (diff_b = 0)) then
        (diff_c = 0) /\ (dvalue_c = 0)
    elseif (dvalue_a + dvalue_b < 0) then
        (diff_c = 2) /\ (dvalue_c = -1)
    elseif (dvalue_a == dvalue_b) then
        (diff_c = 0) /\ (dvalue_c = 0)
    else
        (diff_c = 1) /\ 
        dvalue_c = (bool2int((dvalue_a mod 2) != (dvalue_b mod 2)) + 
        bool2int(((dvalue_a div 2) mod 2) != ((dvalue_b div 2) mod 2)) * 2 + 
        bool2int(((dvalue_a div 4) mod 2) != ((dvalue_b div 4) mod 2)) * 4 +
        bool2int(((dvalue_a div 8) mod 2) != ((dvalue_b div 8) mod 2)) * 8)
    endif
;

predicate mix_column_forward(var 0..3: diff_in1, var -2..15: dvalue_in1,
                             var 0..3: diff_in2, var -2..15: dvalue_in2,
                             var 0..3: diff_in3, var -2..15: dvalue_in3,
                             var 0..3: diff_in4, var -2..15: dvalue_in4,
                             var 0..3: diff_out1, var -2..15: dvalue_out1,
                             var 0..3: diff_out2, var -2..15: dvalue_out2,
                             var 0..3: diff_out3, var -2..15: dvalue_out3,
                             var 0..3: diff_out4, var -2..15: dvalue_out4) =
    % the second row
    diff_out2 = diff_in1 /\
    dvalue_out2 = dvalue_in1
    /\
    % the third row
    xor_operation(diff_in2, dvalue_in2, diff_in3, dvalue_in3, diff_out3, dvalue_out3)
    /\
    % the fourth row
    xor_operation(diff_in1, dvalue_in1, diff_in3, dvalue_in3, diff_out4, dvalue_out4)
    /\
    % the first row
    xor_operation(diff_out4, dvalue_out4, diff_in4, dvalue_in4, diff_out1, dvalue_out1)
;

predicate mix_column_backward(var 0..3: diff_in1, var -2..15: dvalue_in1,
                              var 0..3: diff_in2, var -2..15: dvalue_in2,
                              var 0..3: diff_in3, var -2..15: dvalue_in3,
                              var 0..3: diff_in4, var -2..15: dvalue_in4,
                              var 0..3: diff_out1, var -2..15: dvalue_out1,
                              var 0..3: diff_out2, var -2..15: dvalue_out2,
                              var 0..3: diff_out3, var -2..15: dvalue_out3,
                              var 0..3: diff_out4, var -2..15: dvalue_out4) =
    
    % the first row
    diff_out1 = diff_in2  /\
    dvalue_out1 = dvalue_in2
    /\
    % the thrid row
    xor_operation(diff_in2, dvalue_in2, diff_in4, dvalue_in4, diff_out3, dvalue_out3)
    /\
    % the fourth row
    xor_operation(diff_in1, dvalue_in1, diff_in4, dvalue_in4, diff_out4, dvalue_out4)
    /\
    % the second row
    xor_operation(diff_out3, dvalue_out3, diff_in3, dvalue_in3, diff_out2, dvalue_out2)
;
