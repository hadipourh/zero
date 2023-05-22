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
int: RB;
int: RU;
int: RL;
int: RF;
int: Nd;
int: Nr;
int: offset;
int: cell_size;
int: block_size;
Nd = RU + RL;
Nr = RB + RU + RL + RF;
cell_size = 4;
block_size = 64;

constraint assert(RB >= 1,"Invalid value for RB: " ++
                "RB must be greater than or equal to 1");

constraint assert(RU >= 1,"Invalid value for RU: " ++
                "RU must be greater than or equal to 1");

constraint assert(RL >= 1,"Invalid value for RL: " ++
                "RL must be greater than or equal to 1");

constraint assert(RF >= 1,"Invalid value for RF: " ++
                "RF must be greater than or equal to 1");

% define the log2(x) - 0.53 function
array[1..384, 1..2] of int: log2_minus_053_times_1000_lookup_table = array2d(1..384, 1..2, [1, -530, 2, 470, 3, 1054, 4, 1470, 5, 1791, 6, 2054, 7, 2277, 8, 2469, 9, 2639, 10, 2791, 11, 2929, 12, 3054, 13, 3170, 14, 3277, 15, 3376, 16, 3469, 17, 3557, 18, 3639, 19, 3717, 20, 3791, 21, 3862, 22, 3929, 23, 3993, 24, 4054, 25, 4113, 26, 4170, 27, 4224, 28, 4277, 29, 4327, 30, 4376, 31, 4424, 32, 4470, 33, 4514, 34, 4557, 35, 4599, 36, 4639, 37, 4679, 38, 4717, 39, 4755, 40, 4791, 41, 4827, 42, 4862, 43, 4896, 44, 4929, 45, 4961, 46, 4993, 47, 5024, 48, 5054, 49, 5084, 50, 5113, 51, 5142, 52, 5170, 53, 5197, 54, 5224, 55, 5251, 56, 5277, 57, 5302, 58, 5327, 59, 5352, 60, 5376, 61, 5400, 62, 5424, 63, 5447, 64, 5470, 65, 5492, 66, 5514, 67, 5536, 68, 5557, 69, 5578, 70, 5599, 71, 5619, 72, 5639, 73, 5659, 74, 5679, 75, 5698, 76, 5717, 77, 5736, 78, 5755, 79, 5773, 80, 5791, 81, 5809, 82, 5827, 83, 5845, 84, 5862, 85, 5879, 86, 5896, 87, 5912, 88, 5929, 89, 5945, 90, 5961, 91, 5977, 92, 5993, 93, 6009, 94, 6024, 95, 6039, 96, 6054, 97, 6069, 98, 6084, 99, 6099, 100, 6113, 101, 6128, 102, 6142, 103, 6156, 104, 6170, 105, 6184, 106, 6197, 107, 6211, 108, 6224, 109, 6238, 110, 6251, 111, 6264, 112, 6277, 113, 6290, 114, 6302, 115, 6315, 116, 6327, 117, 6340, 118, 6352, 119, 6364, 120, 6376, 121, 6388, 122, 6400, 123, 6412, 124, 6424, 125, 6435, 126, 6447, 127, 6458, 128, 6470, 129, 6481, 130, 6492, 131, 6503, 132, 6514, 133, 6525, 134, 6536, 135, 6546, 136, 6557, 137, 6568, 138, 6578, 139, 6588, 140, 6599, 141, 6609, 142, 6619, 143, 6629, 144, 6639, 145, 6649, 146, 6659, 147, 6669, 148, 6679, 149, 6689, 150, 6698, 151, 6708, 152, 6717, 153, 6727, 154, 6736, 155, 6746, 156, 6755, 157, 6764, 158, 6773, 159, 6782, 160, 6791, 161, 6800, 162, 6809, 163, 6818, 164, 6827, 165, 6836, 166, 6845, 167, 6853, 168, 6862, 169, 6870, 170, 6879, 171, 6887, 172, 6896, 173, 6904, 174, 6912, 175, 6921, 176, 6929, 177, 6937, 178, 6945, 179, 6953, 180, 6961, 181, 6969, 182, 6977, 183, 6985, 184, 6993, 185, 7001, 186, 7009, 187, 7016, 188, 7024, 189, 7032, 190, 7039, 191, 7047, 192, 7054, 193, 7062, 194, 7069, 195, 7077, 196, 7084, 197, 7092, 198, 7099, 199, 7106, 200, 7113, 201, 7121, 202, 7128, 203, 7135, 204, 7142, 205, 7149, 206, 7156, 207, 7163, 208, 7170, 209, 7177, 210, 7184, 211, 7191, 212, 7197, 213, 7204, 214, 7211, 215, 7218, 216, 7224, 217, 7231, 218, 7238, 219, 7244, 220, 7251, 221, 7257, 222, 7264, 223, 7270, 224, 7277, 225, 7283, 226, 7290, 227, 7296, 228, 7302, 229, 7309, 230, 7315, 231, 7321, 232, 7327, 233, 7334, 234, 7340, 235, 7346, 236, 7352, 237, 7358, 238, 7364, 239, 7370, 240, 7376, 241, 7382, 242, 7388, 243, 7394, 244, 7400, 245, 7406, 246, 7412, 247, 7418, 248, 7424, 249, 7430, 250, 7435, 251, 7441, 252, 7447, 253, 7452, 254, 7458, 255, 7464, 256, 7470, 257, 7475, 258, 7481, 259, 7486, 260, 7492, 261, 7497, 262, 7503, 263, 7508, 264, 7514, 265, 7519, 266, 7525, 267, 7530, 268, 7536, 269, 7541, 270, 7546, 271, 7552, 272, 7557, 273, 7562, 274, 7568, 275, 7573, 276, 7578, 277, 7583, 278, 7588, 279, 7594, 280, 7599, 281, 7604, 282, 7609, 283, 7614, 284, 7619, 285, 7624, 286, 7629, 287, 7634, 288, 7639, 289, 7644, 290, 7649, 291, 7654, 292, 7659, 293, 7664, 294, 7669, 295, 7674, 296, 7679, 297, 7684, 298, 7689, 299, 7694, 300, 7698, 301, 7703, 302, 7708, 303, 7713, 304, 7717, 305, 7722, 306, 7727, 307, 7732, 308, 7736, 309, 7741, 310, 7746, 311, 7750, 312, 7755, 313, 7760, 314, 7764, 315, 7769, 316, 7773, 317, 7778, 318, 7782, 319, 7787, 320, 7791, 321, 7796, 322, 7800, 323, 7805, 324, 7809, 325, 7814, 326, 7818, 327, 7823, 328, 7827, 329, 7831, 330, 7836, 331, 7840, 332, 7845, 333, 7849, 334, 7853, 335, 7858, 336, 7862, 337, 7866, 338, 7870, 339, 7875, 340, 7879, 341, 7883, 342, 7887, 343, 7892, 344, 7896, 345, 7900, 346, 7904, 347, 7908, 348, 7912, 349, 7917, 350, 7921, 351, 7925, 352, 7929, 353, 7933, 354, 7937, 355, 7941, 356, 7945, 357, 7949, 358, 7953, 359, 7957, 360, 7961, 361, 7965, 362, 7969, 363, 7973, 364, 7977, 365, 7981, 366, 7985, 367, 7989, 368, 7993, 369, 7997, 370, 8001, 371, 8005, 372, 8009, 373, 8013, 374, 8016, 375, 8020, 376, 8024, 377, 8028, 378, 8032, 379, 8036, 380, 8039, 381, 8043, 382, 8047, 383, 8051, 384, 8054]);
% define the ceil(log2(x) - 0.53) function
array[1..256, 1..2] of int: log2_minus_053_table = array2d(1..256, 1..2, [1, 0, 2, 1, 3, 2, 4, 2, 5, 2, 6, 3, 7, 3, 8, 3, 9, 3, 10, 3, 11, 3, 12, 4, 13, 4, 14, 4, 15, 4, 16, 4, 17, 4, 18, 4, 19, 4, 20, 4, 21, 4, 22, 4, 23, 4, 24, 5, 25, 5, 26, 5, 27, 5, 28, 5, 29, 5, 30, 5, 31, 5, 32, 5, 33, 5, 34, 5, 35, 5, 36, 5, 37, 5, 38, 5, 39, 5, 40, 5, 41, 5, 42, 5, 43, 5, 44, 5, 45, 5, 46, 5, 47, 6, 48, 6, 49, 6, 50, 6, 51, 6, 52, 6, 53, 6, 54, 6, 55, 6, 56, 6, 57, 6, 58, 6, 59, 6, 60, 6, 61, 6, 62, 6, 63, 6, 64, 6, 65, 6, 66, 6, 67, 6, 68, 6, 69, 6, 70, 6, 71, 6, 72, 6, 73, 6, 74, 6, 75, 6, 76, 6, 77, 6, 78, 6, 79, 6, 80, 6, 81, 6, 82, 6, 83, 6, 84, 6, 85, 6, 86, 6, 87, 6, 88, 6, 89, 6, 90, 6, 91, 6, 92, 6, 93, 7, 94, 7, 95, 7, 96, 7, 97, 7, 98, 7, 99, 7, 100, 7, 101, 7, 102, 7, 103, 7, 104, 7, 105, 7, 106, 7, 107, 7, 108, 7, 109, 7, 110, 7, 111, 7, 112, 7, 113, 7, 114, 7, 115, 7, 116, 7, 117, 7, 118, 7, 119, 7, 120, 7, 121, 7, 122, 7, 123, 7, 124, 7, 125, 7, 126, 7, 127, 7, 128, 7, 129, 7, 130, 7, 131, 7, 132, 7, 133, 7, 134, 7, 135, 7, 136, 7, 137, 7, 138, 7, 139, 7, 140, 7, 141, 7, 142, 7, 143, 7, 144, 7, 145, 7, 146, 7, 147, 7, 148, 7, 149, 7, 150, 7, 151, 7, 152, 7, 153, 7, 154, 7, 155, 7, 156, 7, 157, 7, 158, 7, 159, 7, 160, 7, 161, 7, 162, 7, 163, 7, 164, 7, 165, 7, 166, 7, 167, 7, 168, 7, 169, 7, 170, 7, 171, 7, 172, 7, 173, 7, 174, 7, 175, 7, 176, 7, 177, 7, 178, 7, 179, 7, 180, 7, 181, 7, 182, 7, 183, 7, 184, 7, 185, 8, 186, 8, 187, 8, 188, 8, 189, 8, 190, 8, 191, 8, 192, 8, 193, 8, 194, 8, 195, 8, 196, 8, 197, 8, 198, 8, 199, 8, 200, 8, 201, 8, 202, 8, 203, 8, 204, 8, 205, 8, 206, 8, 207, 8, 208, 8, 209, 8, 210, 8, 211, 8, 212, 8, 213, 8, 214, 8, 215, 8, 216, 8, 217, 8, 218, 8, 219, 8, 220, 8, 221, 8, 222, 8, 223, 8, 224, 8, 225, 8, 226, 8, 227, 8, 228, 8, 229, 8, 230, 8, 231, 8, 232, 8, 233, 8, 234, 8, 235, 8, 236, 8, 237, 8, 238, 8, 239, 8, 240, 8, 241, 8, 242, 8, 243, 8, 244, 8, 245, 8, 246, 8, 247, 8, 248, 8, 249, 8, 250, 8, 251, 8, 252, 8, 253, 8, 254, 8, 255, 8, 256, 8]);

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

array[0..3, 0..15] of var 0..1: atbf;
constraint forall(i in 0..3, j in 0..15)
(
    if at[i, j] >= 1 then atbf[i, j] = 1 else atbf[i, j] = 0 endif
);

% single tweak setting
constraint forall(i in 0..15)(at[0, i] = 0);

%   ____                _             _       _          __              _____ _     
%  / ___|___  _ __  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | ____| |__  
% | |   / _ \| '_ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| |  _| | '_ \ 
% | |__| (_) | | | \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | |___| |_) |
%  \____\___/|_| |_|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_____|_.__/ 
% constraints for Eb

% #####################################################################
% modeling the differeence propagation and the difference cancellations
% #####################################################################

array[0..RB, 0..15] of var 0..1: axb;
array[0..RB, 0..15] of var 0..1: ayb;
array[0..RB, 0..(11 + 16)] of var 0..1: cb;
constraint forall(i in 12..27)
(
    cb[RB, i] = 0
);
array[0..RB, 0..7] of var 0..1: auxib;

% link the end of Eb to the beginning of Eu
constraint forall(i in 0..15)
(
    if ayu[0, i] >= 1 then
        ayb[RB, i] = 1
    else
        ayb[RB, i] = 0
    endif
);

constraint forall(r in 0..(RB - 1), i in 0..15)
(
    xor_with_probability_one(axb[r + 1, p_permutation[i]], atbf[(offset + RB + r) mod 4, i], ayb[r, i])
    /\
    xor_cancellation(ayb[r, i], atbf[(offset + RB + r) mod 4, i], axb[r + 1, p_permutation[i]], cb[r, 12 + i])
);

constraint forall(r in 0..RB, i in 0..3)
(
    mix_column_backward_with_probability_one_diff(
        ayb[r, i], ayb[r, i + 4], ayb[r, i + 8], ayb[r, i + 12],
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
array[0..(RB - 1), 0..15] of var 0..1: kdzb;
array[0..RB, 0..15] of var 0..1: kxb;
array[0..RB, 0..15] of var 0..1: kyb;

% link the end of Eb to the beginning of Eu
constraint forall(i in 0..15)
(
    if ayu[0, i] == 1 then
        kdyb[RB, i] = 1
        /\
        kyb[RB, i] = 1
    else
        kdyb[RB, i] = 0
        /\
        kyb[RB, i] = 0
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
    if cb[r, 3*i] == 1 then (kdxb[r, i] = axb[r, i] /\ kdxb[r, i + 8] = axb[r, i + 8]) endif
    /\
    if cb[r, 3*i + 1] == 1 then (kdxb[r, i] = axb[r, i] /\ kdxb[r, i + 8] = axb[r, i + 8] /\ kdxb[r, i + 12] = axb[r, i + 12]) endif
    /\
    if cb[r, 3*i + 2] == 1 then (kdxb[r, i + 4] = axb[r, i + 4] /\ kdxb[r, i + 12] = axb[r, i + 12]) endif
);

constraint forall(r in 0..(RB - 1), i in 0..15)
(
    kdyb[r, i] >= kdzb[r, i]
    /\
    if cb[r, 12 + i] == 1 then kdyb[r, i] = ayb[r, i] endif
);

constraint forall(r in 0..(RB - 1), i in 0..15)
(
    sb_operation_value_diff(kdxb[r + 1, i], kxb[r + 1, i], kyb[r, p_permutation[i]])
    /\
    kdzb[r, p_permutation[i]] = kdxb[r + 1, i]
);

constraint forall(r in 0..(RB - 1), i in 0..15)
(
    kdyb[r, i] <= ayb[r, i]
    /\
    kdxb[r, i] <= axb[r, i]
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
constraint forall(r in 0..(RU - 1), i in 0..15)(link_pattern_to_value(ayu[r, i], dyu[r, i]));

array[0..(RU - 1), 0..15] of var 0..3: azu;
array[0..(RU - 1), 0..15] of var -2..15: dzu;
constraint forall(r in 0..(RU - 1), i in 0..15)(link_pattern_to_value(azu[r, i], dzu[r, i]));

array[0..(RU - 1), 0..3] of var 0..3: dummy_au;
array[0..(RU - 1), 0..3] of var -2..15: dummy_du;
constraint forall(r in 0..(RU - 1), i in 0..3)(link_pattern_to_value(dummy_au[r, i], dummy_du[r, i]));

% Exclude all-zero input difference
var 0..96: inputdiff_distinguisher;
constraint inputdiff_distinguisher = sum(i in 0..15)(ayu[0, i]) + sum(i in 0..15)(at[0, i]);
constraint inputdiff_distinguisher != 0;

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

% AddTweakey
constraint forall(r in 0..(RU - 1), i in 0..15)
(
    xor_operation(ayu[r, i], dyu[r, i], at[(offset + RB + r) mod 4, i], dt[(offset + RB) mod 4, i], azu[r, i], dzu[r, i])
);

% S-box
constraint forall(r in 0..(RU - 1), i in 0..15)
(
    sb_operation(azu[r, p_permutation[i]], axu[r + 1, i])
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

array[0..(RL - 1), 0..15] of var 0..3: azl;
array[0..(RL - 1), 0..15] of var -2..15: dzl;
constraint forall(r in 0..(RL - 1), i in 0..15)(link_pattern_to_value(azl[r, i], dzl[r, i]));


array[0..(RL - 1), 0..3] of var 0..3: dummy_al;
array[0..(RL - 1), 0..3] of var -2..15: dummy_dl;
constraint forall(r in 0..(RL - 1), i in 0..3)(link_pattern_to_value(dummy_al[r, i], dummy_dl[r, i]));

% Exclude all-zero output difference
var 0..96: outputdiff_distinguisher;
constraint outputdiff_distinguisher = sum(i in 0..15)(ayl[RL - 1, i])  + sum(i in 0..15)(at[0, i]);
constraint outputdiff_distinguisher != 0;

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

% AddTweakey
constraint forall(r in 0..(RL - 1), i in 0..15)
(
    xor_operation(azl[r, i], dzl[r, i], at[(offset + RB + RU + r) mod 4, i], dt[(offset + RB + RU + r) mod 4, i], ayl[r, i], dyl[r, i])
);

% S-box
constraint forall(r in 0..(RL - 2), i in 0..15)
(
    sb_operation(axl[r + 1, i], azl[r, p_permutation[i]])
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
array[0..(RF - 1), 0..15] of var 0..1: ayf;
array[0..(RF - 1), 0..15] of var 0..1: azf;
array[0..(RF - 1), 0..(11 + 16)] of var 0..1: cf;
array[0..(RF - 1), 0..7] of var 0..1: auxif;
array[0..11] of var 0..1: cf_last_round_of_el;
array[0..7] of var 0..1: auxif_last_round_el;

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
        ayf[r, i], ayf[r, i + 4], ayf[r, i + 8], ayf[r, i + 12],
        cf[r, 3*i], cf[r, 3*i + 1], cf[r, 3*i + 2],
        auxif[r, 2*i], auxif[r, 2*i + 1])
);

constraint forall(r in 0..(RF - 1), i in 0..15)
(
    xor_with_probability_one(ayf[r, i], atbf[(offset + RB + RU + RL + r) mod 4, i], azf[r, i])
    /\
    xor_cancellation(azf[r, i], atbf[(offset + RB + RU + RL + r) mod 4, i], ayf[r, i], cf[r, 12 + i])
    /\
    azf[r, i] = axf[r + 1, p_permutation[i]]
);

constraint forall(i in 0..3)
(
    mix_column_forward_with_probability_one_diff(
    bool2int(axl[RL - 1, i] >= 1), bool2int(axl[RL - 1, i + 4] >= 1), bool2int(axl[RL - 1, i + 8] >= 1), bool2int(axl[RL - 1, i + 12] >= 1),
    bool2int(ayl[RL - 1, i] >= 1), bool2int(ayl[RL - 1, i + 4] >= 1), bool2int(ayl[RL - 1, i + 8] >= 1), bool2int(ayl[RL - 1, i + 12] >= 1),
    cf_last_round_of_el[3*i], cf_last_round_of_el[3*i + 1], cf_last_round_of_el[3*i + 2],
    auxif_last_round_el[2*i], auxif_last_round_el[2*i + 1])
);

% #######################################
% modeling the guess-and-determine
% #######################################

array[0..RF, 0..15] of var 0..1: kxf;
array[0..(RF - 1), 0..15] of var 0..1: kyf;
array[0..RF, 0..15] of var 0..1: kdxf;
array[0..(RF - 1), 0..15] of var 0..1: kdyf;
array[0..(RF - 1), 0..15] of var 0..1: kdzf;

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
    if kdxf[r, i] == 1 then (kdyf[r, i] = ayf[r, i] /\ kdyf[r, i + 8] = ayf[r, i + 8] /\ kdyf[r, i + 12] = ayf[r, i + 12]) endif
    /\
    if kdxf[r, i + 4] == 1 then (kdyf[r, i + 4] = ayf[r, i + 4] /\ kdyf[r, i + 12] = ayf[r, i + 12]) endif
    /\
    if kdxf[r, i + 8] == 1 then (kdyf[r, i + 8] = ayf[r, i + 8]) endif
    /\
    if kdxf[r, i + 12] == 1 then (kdyf[r, i + 12] = ayf[r, i + 12]) endif
    /\
    mix_column_forward_data(
        kxf[r, i], kxf[r, i + 4], kxf[r, i + 8], kxf[r, i + 12],
        kyf[r, i], kyf[r, i + 4], kyf[r, i + 8], kyf[r, i + 12]
    )
    /\
    if cf[r, 3*i] == 1 then (kdyf[r, i] = ayf[r, i] /\ kdyf[r, i + 12] = ayf[r, i + 12]) endif
    /\
    if cf[r, 3*i + 1] == 1 then (kdyf[r, i] = ayf[r, i] /\ kdyf[r, i + 8] = ayf[r, i + 8] /\ kdyf[r, i + 12] = ayf[r, i + 12]) endif
    /\
    if cf[r, 3*i + 2] == 1 then (kdyf[r, i + 4] = ayf[r, i + 4] /\ kdyf[r, i + 12] = ayf[r, i + 12]) endif
);

constraint forall(r in 0..(RF - 1), i in 0..15)
(
    kdzf[r, i] >= kdyf[r, i]
    /\
    if cf[r, 12 + i] == 1 then kdzf[r, i] = azf[r, i] endif
);

constraint forall(r in 0..(RF - 1), i in 0..15)
(
    sb_operation_value_diff(kdzf[r, p_permutation[i]], kyf[r, p_permutation[i]], kxf[r + 1, i])
    /\
    kdxf[r + 1, i] = kdzf[r, p_permutation[i]]
);

constraint forall(r in 0..(RF - 1), i in 0..15)
(
    kdxf[r, i] <= axf[r, i]
    /\
    kdyf[r, i] <= ayf[r, i]
    /\
    kdzf[r, i] <= azf[r, i]
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

%   ____          _             _       _          __              _  __            ____                                    
%  / ___|___  ___| |_ _ __ __ _(_)_ __ | |_ ___   / _| ___  _ __  | |/ /___ _   _  |  _ \ ___  ___ _____   _____ _ __ _   _ 
% | |   / _ \/ __| __| '__/ _` | | '_ \| __/ __| | |_ / _ \| '__| | ' // _ \ | | | | |_) / _ \/ __/ _ \ \ / / _ \ '__| | | |
% | |__| (_) \__ \ |_| | | (_| | | | | | |_\__ \ |  _| (_) | |    | . \  __/ |_| | |  _ <  __/ (_| (_) \ V /  __/ |  | |_| |
%  \____\___/|___/\__|_|  \__,_|_|_| |_|\__|___/ |_|  \___/|_|    |_|\_\___|\__, | |_| \_\___|\___\___/ \_/ \___|_|   \__, |
%                                                                           |___/                                     |___/ 
% constraint for key recovery

var 0..((RB + RF)*27 + 16): c_tot;
var 0..(RB*27): c_in;
var 0..(RF*27 + 12): c_out;
var 0..12: c_out_last_round_el;
constraint c_in = sum(r in 1..RB, i in 0..27)(cb[r, i]);
constraint c_out_last_round_el = sum(i in 0..11)(cf_last_round_of_el[i]);
constraint c_out = sum(r in 0..(RF - 1), i in 0..27)(cf[r, i]) + c_out_last_round_el;
constraint c_tot = c_in + c_out;

var 0..16: delta_in_weight;
var 0..16: delta_out_weight;
var 0..32: io_diff_weight;
constraint delta_in_weight = sum(i in 0..15)(ayb[0, i]);
constraint delta_out_weight = sum(i in 0..15)(axf[RF, i]);
constraint io_diff_weight = delta_in_weight + delta_out_weight;

var -530..7470: log_2_minus_053_of_g_times_1000;

var 0.0..9.0: log_2_minus_053_of_g;
% var 0..8: log_2_minus_053_of_g;

var 1..384: g;

constraint table([g, log_2_minus_053_of_g_times_1000], log2_minus_053_times_1000_lookup_table);
% constraint table([g, log_2_minus_053_of_g], log2_minus_053_table);

constraint log_2_minus_053_of_g = int2float(log_2_minus_053_of_g_times_1000) / 1000;

var 0.0..384.0: data_complexity1;
% var 0..384: data_complexity1;

var 0.0..384.0: data_complexity1_1;
% var 0..384: data_complexity1_1;

var 0.0..384.0: data_complexity1_2;
% var 0..384: data_complexity1_2;

var 0.0..384.0: data_complexity2;
% var 0..384: data_complexity2;

var 0.0..384.0: memory_complexity;
% var 0..384: memory_complexity;

constraint data_complexity1_1 = int2float(cell_size*c_in + cell_size*c_out + block_size + 1 - cell_size*delta_out_weight) / 2 + (log_2_minus_053_of_g / 2);
% constraint data_complexity1_1 = ((cell_size*c_in + cell_size*c_out + block_size - cell_size*delta_out_weight + log_2_minus_053_of_g) div 2);

constraint data_complexity1_2 = int2float(cell_size*c_in + cell_size*c_out + block_size + 1 - cell_size*delta_in_weight) / 2 + (log_2_minus_053_of_g / 2);
% constraint data_complexity1_2 = ((cell_size*c_in + cell_size*c_out + block_size - cell_size*delta_in_weight + log_2_minus_053_of_g) div 2);

constraint data_complexity1 = min(data_complexity1_1, data_complexity1_2);

constraint data_complexity2 = int2float(cell_size*c_in + cell_size*c_out + block_size + 1 - cell_size*delta_in_weight - cell_size*delta_out_weight) + log_2_minus_053_of_g;
% constraint data_complexity2 = cell_size*c_in + cell_size*c_out + block_size + 1 - cell_size*delta_in_weight - cell_size*delta_out_weight + log_2_minus_053_of_g;


array[0..3] of var 0.0..384.0: t_complexity;
% array[0..3] of var 0..384: t_complexity;

constraint t_complexity[0] = max(data_complexity1, data_complexity2);

constraint t_complexity[1] = int2float(cell_size*c_in + cell_size*c_out) + log_2_minus_053_of_g;
% constraint t_complexity[1] = cell_size*c_in + cell_size*c_out + log_2_minus_053_of_g;

constraint t_complexity[2] = int2float(cell_size*k_tot) + log_2_minus_053_of_g;
% constraint t_complexity[2] = cell_size*k_tot + log_2_minus_053_of_g;

constraint t_complexity[3] = int2float(2*block_size - g);
% constraint t_complexity[3] = 2*block_size - g;

constraint memory_complexity = min(cell_size*k_tot, t_complexity[1]);

constraint t_complexity[0] < block_size; % data complexity
constraint t_complexity[1] < 2*block_size; % second ter of time complexity
constraint t_complexity[2] < 2*block_size; % third term of time complexity
constraint t_complexity[3] < 2*block_size; % fourth term of time complexity
constraint memory_complexity < 2*block_size; % memory complexity
% constrain g
constraint g > 1;
constraint g <= cell_size*k_tot;


% var 0.0..384.0: max_term;
var 0..384: max_term;

constraint max_term = max(i in 0..3)(t_complexity[i]);
constraint max_term < 2*block_size;


% constraint forall(i in 0..15)
% (
%     ayu[0, i] != 1
% );

% constraint ayu[0, 8] = 2;

% constraint forall(i in 0..15)
% (
%     axl[RL - 1, i] != 1
% );

solve minimize max_term;
% constraint max_term <= 119;
% solve minimize t_complexity[0];


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