bool: a = true;
bool: b = false;

var bool: c;
constraint if b then c == true endif;
constraint c == true;

solve satisfy;