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

int: RU;
int: RL;
int: RD;
bool: skip_first_sbox_layer;
RD = RU + RL;

constraint assert(RU >= 1, "Invalid value for RU: " ++
                  "RU must be greater than or equal to 1");

constraint assert(RL >= 1, "Invalid value for RL: " ++
                  "RL must be greater than or equal to 1");

% skinny round permutation
array[0..15] of int: round_permutation = array1d(0..15, [0, 1, 2, 3, 7, 4, 5, 6, 10, 11, 8, 9, 13, 14, 15, 12]);

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

% mix_column
constraint forall(r in 0..(RU - 1), i in 0..3)
(
    mix_column_forward(AYU[r, round_permutation[i]], DYU[r, round_permutation[i]],
                       AYU[r, round_permutation[i + 4]], DYU[r, round_permutation[i + 4]],
                       AYU[r, round_permutation[i + 8]], DYU[r, round_permutation[i + 8]],
                       AYU[r, round_permutation[i + 12]], DYU[r, round_permutation[i + 12]],
                       AXU[r + 1, i], DXU[r + 1, i],
                       AXU[r + 1, i + 4], DXU[r + 1, i + 4],
                       AXU[r + 1, i + 8], DXU[r + 1, i + 8],
                       AXU[r + 1, i + 12], DXU[r + 1, i + 12])
);

% exclude all-zero input difference
constraint sum(i in 0..15)(AXU[0, i]) != 0;

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

% mix-column and shift-rows
constraint forall(r in 0..(RL - 1), i in 0..3)
(
    mix_column_backward(AXL[r + 1, i], DXL[r + 1, i],
                        AXL[r + 1, i + 4], DXL[r + 1, i + 4],
                        AXL[r + 1, i + 8], DXL[r + 1, i + 8],
                        AXL[r + 1, i + 12], DXL[r + 1, i + 12],
                        AYL[r, round_permutation[i]], DYL[r, round_permutation[i]],
                        AYL[r, round_permutation[i + 4]], DYL[r, round_permutation[i + 4]],
                        AYL[r, round_permutation[i + 8]], DYL[r, round_permutation[i + 8]],
                        AYL[r, round_permutation[i + 12]], DYL[r, round_permutation[i + 12]])
);

% S-box
constraint forall(r in 0..(RL - 1), i in 0..15)
(
    sbox(AYL[r, i], AXL[r, i])
);

% exclude all-zero output difference
constraint sum(i in 0..15)(AXL[RL, i]) != 0;

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
%     _                 _  _  _                       _____                     _    _                    
%    / \   _   _ __  __(_)| |(_)  __ _  _ __  _   _  |  ___|_   _  _ __    ___ | |_ (_)  ___   _ __   ___ 
%   / _ \ | | | |\ \/ /| || || | / _` || '__|| | | | | |_  | | | || '_ \  / __|| __|| | / _ \ | '_ \ / __|
%  / ___ \| |_| | >  < | || || || (_| || |   | |_| | |  _| | |_| || | | || (__ | |_ | || (_) || | | |\__ \
% /_/   \_\\__,_|/_/\_\|_||_||_| \__,_||_|    \__, | |_|    \__,_||_| |_| \___| \__||_| \___/ |_| |_||___/
%                                             |___/       
% auxiliary functions

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

predicate xor_with_probability_one(var 0..1: a, var 0..1: b, var 0..1: c) =
    c >= a
    /\ 
    c >= b
    /\ 
    c <= a + b
;

predicate xor3_with_probability_one(var 0..1: a, var 0..1: b, var 0..1: c, var 0..1: d) =
    d >= a
    /\ 
    d >= b
    /\ 
    d >= c
    /\ 
    d <= a + b + c
;

predicate mix_column_forward_with_probability_one_diff(var 0..1: diff_in1,
                                                       var 0..1: diff_in2,
                                                       var 0..1: diff_in3,
                                                       var 0..1: diff_in4,
                                                       var 0..1: diff_out1,
                                                       var 0..1: diff_out2,
                                                       var 0..1: diff_out3,
                                                       var 0..1: diff_out4) =
    % the second row
    diff_out2 = diff_in1
    /\
    % the third row
    xor_with_probability_one(diff_in2, diff_in3, diff_out3)
    /\
    % the fourth row
    xor_with_probability_one(diff_in1, diff_in3, diff_out4)
    /\
    % the first row
    xor_with_probability_one(diff_out4, diff_in4, diff_out1)
;

predicate mix_column_backward_with_probability_one_diff(var 0..1: diff_in1,
                                                        var 0..1: diff_in2,
                                                        var 0..1: diff_in3,
                                                        var 0..1: diff_in4,
                                                        var 0..1: diff_out1,
                                                        var 0..1: diff_out2,
                                                        var 0..1: diff_out3,
                                                        var 0..1: diff_out4) = 
    
    % the first row
    diff_out1 = diff_in2
    /\
    % the thrid row
    xor_with_probability_one(diff_in2, diff_in4, diff_out3)
    /\
    % the fourth row
    xor_with_probability_one(diff_in1, diff_in4, diff_out4)
    /\
    % the second row
    xor_with_probability_one(diff_out3, diff_in3, diff_out2)
;

predicate mix_column_forward_data(var 0..1: data_in1,
                                  var 0..1: data_in2,
                                  var 0..1: data_in3,
                                  var 0..1: data_in4,
                                  var 0..1: data_out1,
                                  var 0..1: data_out2,
                                  var 0..1: data_out3,
                                  var 0..1: data_out4,
                                  var 0..1: auxi_var) =
    % the first row
    data_out1 = data_in4
    /\
    % the third row
    data_out3 = data_in2
    /\
    xor_with_probability_one(data_in2, data_in3, auxi_var)
    /\
    % the second row
    xor_with_probability_one(auxi_var, data_in1, data_out2)
    /\
    % The fourth row
    xor_with_probability_one(auxi_var, data_in4, data_out4)
;

predicate mix_column_forward_diff_values(var 0..1: diff_in1,
                                         var 0..1: diff_in2,
                                         var 0..1: diff_in3,
                                         var 0..1: diff_in4,
                                         var 0..1: diff_out1,
                                         var 0..1: diff_out2,
                                         var 0..1: diff_out3,
                                         var 0..1: diff_out4,
                                         var 0..1: dv_in1,
                                         var 0..1: dv_in2,
                                         var 0..1: dv_in3,
                                         var 0..1: dv_in4,
                                         var 0..1: dv_out1,
                                         var 0..1: dv_out2,
                                         var 0..1: dv_out3,
                                         var 0..1: dv_out4,
                                         var 0..1: auxi_var,
                                         var 0..1: c1,
                                         var 0..1: c2,
                                         var 0..1: c3) = 
    if dv_in1 == 1 then dv_out2 = diff_out2 endif
    /\
    if dv_in2 == 1 then (dv_out2 = diff_out2 /\ dv_out3 = diff_out3 /\ dv_out4 >= diff_out4) endif
    /\
    if dv_in3 == 1 then (dv_out2 = diff_out2 /\ dv_out4 = diff_out4) endif
    /\
    if dv_in4 == 1 then (dv_out1 = diff_out1 /\ dv_out4 = diff_out4) endif
    /\
    if (diff_out1 + diff_out4 == 2 /\ diff_in4 == 0) then (c3 = 1 /\ dv_out1 = 1 /\ dv_out4 = 1) else c3 = 0 endif
    /\
    if (diff_out2 + diff_out4 == 2 /\ diff_in3 == 0) then (c2 = 1 /\ dv_out2 = 1 /\ dv_out4 = 1) else c2 = 0 endif
    /\
    if (diff_in3 + diff_out3 == 2 /\ diff_in2 == 0) then (c1 = 1 /\ dv_out2 = diff_out2 /\ dv_out4 = diff_out4 /\ dv_out3 = 1) else c1 = 0 endif
;

predicate mix_column_backward_data(var 0..1: data_in1,
                                   var 0..1: data_in2,
                                   var 0..1: data_in3,
                                   var 0..1: data_in4,
                                   var 0..1: data_out1,
                                   var 0..1: data_out2,
                                   var 0..1: data_out3,
                                   var 0..1: data_out4,
                                   var 0..1: auxi_var) =
    % the second row
    data_out2 = data_in3
    /\
    % the fourth row
    data_out4 = data_in1
    /\
    xor_with_probability_one(data_in1, data_in4, auxi_var)
    /\
    % the first row
    xor_with_probability_one(auxi_var, data_in2, data_out1)
    /\
    % the thrid row
    xor_with_probability_one(auxi_var, data_in3, data_out3)
;


predicate mix_column_backward_diff_values(var 0..1: diff_in1,
                                          var 0..1: diff_in2,
                                          var 0..1: diff_in3,
                                          var 0..1: diff_in4,
                                          var 0..1: diff_out1,
                                          var 0..1: diff_out2,
                                          var 0..1: diff_out3,
                                          var 0..1: diff_out4,                                            
                                          var 0..1: dv_in1,
                                          var 0..1: dv_in2,
                                          var 0..1: dv_in3,
                                          var 0..1: dv_in4,
                                          var 0..1: dv_out1,
                                          var 0..1: dv_out2,
                                          var 0..1: dv_out3,
                                          var 0..1: dv_out4,
                                          var 0..1: auxi_var,
                                          var 0..1: c1,
                                          var 0..1: c2,
                                          var 0..1: c3) = 
    if dv_in1 == 1 then (dv_out1 = diff_out1 /\ dv_out3 = diff_out3 /\ dv_out4 = diff_out4) endif
    /\
    if dv_in2 == 1 then (dv_out1 = diff_out1) endif
    /\
    if dv_in3 == 1 then (dv_out2 = diff_out2 /\ dv_out3 = diff_out3) endif
    /\
    if dv_in4 == 1 then (dv_out1 = diff_out1 /\ dv_out3 = diff_out3) endif
    /\
    if (diff_out1 + diff_out3 == 2 /\ diff_in4 == 0) then (c2 = 1 /\ dv_out1 = 1 /\ dv_out3 = 1) else c2 = 0 endif
    /\
    if (diff_out2 + diff_out3 == 2 /\ diff_in3 == 0) then (c1 = 1 /\ dv_out2 = 1 /\ dv_out3 = 1) else c1 = 0 endif
    /\
    if (diff_in4 + diff_out4 == 2 /\ diff_in1 == 0) then (c3 =1 /\ dv_out1  = diff_out1 /\ dv_out3 = diff_out3 /\ dv_out4 = 1) else c3 = 0 endif    
;