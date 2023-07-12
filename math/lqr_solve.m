% Octave
pkg load symbolic;

syms P Q R t positive

A = t
B = 1

% DARE
s = solve(0 == P*A + A*P - P*B/R*B*P + Q, P)
P = solve(P == A*P*A - (A*P*B)^2/(R + B*P*B) + Q, P)

P1 = P(1);
P2 = P(2);

G1 = simplify(-1./(R + B*P1*B)*B*A.*P1)
G2 = simplify(-1./(R + B*P2*B)*B*A.*P2)

g = simplify(-1/R*B*s)
