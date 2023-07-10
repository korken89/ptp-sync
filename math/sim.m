% High DPI fixes, comment if not needed
set(0, "defaulttextfontsize", 32)  % title
set(0, "defaultaxesfontsize", 26)  % axes labels
set(0, "defaultlinelinewidth", 4)

rng(1)

% We need the `control` package, install with
% ```
% pkg install "https://github.com/gnu-octave/pkg-control/releases/download/control-3.6.0/control-3.6.0.tar.gz"
% ```
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

all_x0 = [];
all_x1 = [];

%
% Add some Brownian motion
%
c = 0.9995;
sigma = 0.05;
ppm = 5;

b0 = brownian_motion(N, dt, c, sigma, ppm);
b1 = brownian_motion(N, dt, c, sigma, ppm);

%
% Kalman filter
%

% Acceleration model
e = [0; 0; 0];
all_e = [];

eF = [1 dt dt^2/2; 0 1 dt; 0 0 1];

eC = [1, 0, 0];

Q = [dt^5/20 dt^4/8 dt^3/6;
    dt^4/8 dt^3/6 dt^2/2;
    dt^3/6 dt^2/2 dt] * 1;

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


R = 4000 % About 1us
[K, P] = dlqe (eF, [], eC, Q, R)

S = eC * P * eC' + R


%
% LQR
%

% lF = [1 dt;
%       0  1];
lF = [1 dt dt^2/2; 0 1 dt; 0 0 1];

lB = [dt; 0; 0];

lQ = [1 0 0;
      0 0 0;
      0 0 0];

lR = 100;

[g] = dlqr (lF, lB, lQ, lR)

u = [0];
all_u = [];

%
% Start estimation
%

u = 0;

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
    e = eF * e ;
    err = x0(1) - x1(1);
    e = e +  K * (err - eC * e);
    all_e = [all_e, e];

    % Control
    u = -g*e(1:2);
    all_u = [all_u, u];
end


% Plotting
figure

t = linspace(0, dt*N, N);

% plot start
ps = 200;
step = 20;

ns_scale = 1e9/2^32;

subplot(2,1,1);
plot(t(ps:step:end), all_x0(1, ps:step:end) - all_x1(1, ps:step:end));
hold on;
plot(t(ps:step:end), all_e(1, ps:step:end));
hold off;
ylabel('Offset')

title('Difference (offset) of the 2 clocks (clock 0 - clock 1)')
grid on;
legend('True offset','Estimated offset')

subplot(2,1,2);
plot(t(ps:step:end), all_x0(2, ps:step:end) - all_x1(2, ps:step:end));
hold on;
plot(t(ps:step:end), all_e(2, ps:step:end));
hold off;
xlabel('Time [s]')
ylabel('Tick rate')

title('Difference (tick rate) of the 2 clocks')
grid on;
legend('True tick rate','Estimated tick rate')

figure

plot(t(ps:step:end), all_e(3, ps:step:end) * ns_scale);
title('Estimated acceleration')
grid on;
xlabel('Time [s]')
ylabel('Acceleration error [ns/s^2]')

% Plot estimation error
figure


subplot(2,1,1);
plot(t(ps:step:end), (all_e(1, ps:step:end) - (all_x0(1, ps:step:end) - all_x1(1, ps:step:end))) * ns_scale);
title('Error in estimated offset')
grid on;
ylabel('Offset error [ns]')

subplot(2,1,2);
plot(t(ps:step:end), (all_e(2, ps:step:end) - (all_x0(2, ps:step:end) - all_x1(2, ps:step:end))) * ns_scale);
title('Error in estimated tick rate')
grid on;
xlabel('Time [s]')
ylabel('Tick rate error [ns/s]')


figure;

plot(t(ps:step:end), b0(ps:step:end));
hold on;
plot(t(ps:step:end), b1(ps:step:end));
hold off;

title('Brownian motion for two clocks')
xlabel('Time [s]')
ylabel('Tick rate deviation [ppm]')
grid on;
legend('Error for clock 1','Error for clock 2')

pause;
