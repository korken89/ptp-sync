set(0, "defaulttextfontsize", 32)  % title
set(0, "defaultaxesfontsize", 24)  % axes labels

set(0, "defaultlinelinewidth", 2)

pkg load control;


% Sampling rate and state space transfer matricies
dt = 1e-1;
B = [dt^2/2;
     dt];


N = 10000; % Simulation length

% Initial conditions
t0 = 0; % stating time for first clock
t1 = 0; % stating time for second clock
tdot1 = 2^32; % starting tick rate for first clock
tdot2 = 2^32; % starting tick rate for second clock


%
% Evaluate state space for N steps
%

x0 = [t0; tdot1];
x1 = [t1; tdot2];

all_x0 = x0;
all_x1 = x1;

%
% Add some Brownian motion
%
c = 0.9995

sigma = 0.2;

b0 = brownian_motion(N, dt, c, sigma);
b1 = brownian_motion(N, dt, c, sigma);

% Acceleration model
e = [0; 0; 0];
all_e = e;

eF = [1 dt dt^2/2; 0 1 dt; 0 0 1];

eC = [1, 0, 0];

Q = [dt^5/20 dt^4/8 dt^3/6;
    dt^4/8 dt^3/6 dt^2/2;
    dt^3/6 dt^2/2 dt];

% Velocity only model
% e = [0; 0];
% all_e = e;
%
% eF = [1 dt; 0 1];
%
% eC = [1, 0];
%
% Q = [dt^3/6 dt^2/2;
%     dt^2/2 dt];


R = 1000
[K, P] = dlqe (eF, [], eC, Q, R)

S = eC * P * eC' + R


for i = 1:N
    b_mul = 1 + b0(i)/1e6;
    F = [1, dt ;
         0, 1 ];

    % States
    x0 = F * x0;
    x0(2) = tdot1 * b_mul;

    b_mul = 1 + b1(i)/1e6;
    F = [1, dt ;
         0, 1 ];

    x1 = F * x1;
    x1(2) = tdot2 * b_mul;

    all_x0 = [all_x0, x0];
    all_x1 = [all_x1, x1];

    % Est
    e = eF * e;
    err = x0(1) - x1(1);
    e = e +  K * (err - eC * e);
    all_e = [all_e, e];
end


% Plotting
figure

t = linspace(0, dt*N, N+1);


subplot(2,1,1);
plot(t, all_x0(1, :) - all_x1(1, :));
hold on;
plot(t, all_e(1, :));
hold off;

title('Difference (offset) of the 2 clocks (clock 0 - clock 1)')
grid on;
legend('True offset','Estimated offset')

subplot(2,1,2);
plot(t, all_x0(2, :) - all_x1(2, :));
hold on;
plot(t, all_e(2, :));
hold off;

title('Difference (tick rate) of the 2 clocks')
grid on;
legend('True tick rate','Estimated tick rate')

figure

plot(all_e(3, :));
title('Estimated acceleration (ticks)')
grid on;

% Plot estimation error
figure

subplot(2,1,1);
plot(t, all_e(1, :) - (all_x0(1, :) - all_x1(1, :)));
title('Error Estimated offset (ticks)')
grid on;

subplot(2,1,2);
plot(t, all_e(2, :) - (all_x0(2, :) - all_x1(2, :)));
title('Error Estimated offset speed (tick rate)')
grid on;


figure;

plot(t, b0);
hold on;
plot(t, b1);
hold off;

title('The 2 Brownian motions')
grid on;
legend('Motion for Clock 0','Motion for Clock 1')

pause;
