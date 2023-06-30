
% Sampling rate and state space transfer matricies
dt = 1e-3;
F = [1, dt; 0, 1]
B = [dt^2/2; dt]


N = 100000; % Simulation length

% Initial conditions
t0 = 0 % stating time for first clock
t1 = 0 % stating time for second clock
tdot1 = 0.99 % starting tick rate for first clock
tdot2 = 1.01 % starting tick rate for second clock


%
% Evaluate state space for N steps
%

x0 = [t0; tdot1]
x1 = [t1; tdot2]

all_x0 = x0
all_x1 = x1

%
% Add some Brownian motion
%
c = 0.9995

sigma = 0.01

b0 = 0
b1 = 0

all_b0 = b0
all_b1 = b1

lpf0 = 0
lpf1 = 0
alpha = 0.99

for i = 1:N

    % States
    x0 = F * x0 + B * b0;
    x1 = F * x1 + B * b1; 

    all_x0 = [all_x0, x0];
    all_x1 = [all_x1, x1];
    
    % Brownian motion
    lpf0 = alpha * lpf0 + (1 - alpha) * sigma * randn;
    lpf1 = alpha * lpf1 + (1 - alpha) * sigma * randn;

    b0 = c * b0 + sigma * lpf0;
    b1 = c * b1 + sigma * lpf1;

    all_b0 = [all_b0, b0];
    all_b1 = [all_b1, b1];
end


% Plotting
figure

t = linspace(0, dt*N, N+1);

subplot(3,1,1);
plot(t, all_x0(1, :));
hold on;
plot(t, all_x1(1, :));
hold off;

title('The 2 times compared over time')
grid on;
legend('Clock 0','Clock 1')

subplot(3,1,2);
plot(t, all_x0(1, :) - all_x1(1, :));

title('Difference (offset) of the 2 clocks (clock 0 - clock 1)')
grid on;

subplot(3,1,3);
plot(t, all_x0(2, :) - all_x1(2, :));

title('Difference (tick rate) of the 2 clocks')
grid on;


figure

plot(t, all_b0(1, :));
hold on;
plot(t, all_b1(1, :));
hold off;

title('The 2 Brownian motions')
grid on;
legend('Motion for Clock 0','Motion for Clock 1')

pause;
