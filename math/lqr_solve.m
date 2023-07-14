% Octave
pkg load symbolic;
pkg load control;

syms P Q R t positive

Pp = solve(P^2 - Q*P - R*Q/t^2 == 0, P)

A = 1
B = t

% DARE
P = solve(P == A*P*A - (A*P*B)^2/(R + B*P*B) + Q, P)

% P1 = P(1);
P2 = P(2);

% G1 = simplify(-1./(R + B*P1*B)*B*A.*P1)
G2 = simplify(1./(R + B*P2*B)*B*A.*P2)

Q = 1
R = 1
t = 0.1

% G1 = eval(subs(G1, [Q,R,t], [1,1,0.1]))
G2 = eval(G2)

[g, P] = dlqr(1, t, Q, R)

Pp = eval(Pp)
