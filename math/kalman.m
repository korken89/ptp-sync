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


%
% Kalman filter
%

base_dt = 1e-3;
N = 1000;

all_K = [];

for i = 1:N
    dt = base_dt * i;

    eF = [1 dt dt^2/2; 0 1 dt; 0 0 1];

    eC = [1, 0, 0];

    Q = [dt^5/20 dt^4/8 dt^3/6;
        dt^4/8 dt^3/6 dt^2/2;
        dt^3/6 dt^2/2 dt] * 1;

    R = 4000;
    K = dlqe (eF, [], eC, Q, R);

    all_K = [all_K, K];
end


% Plotting
figure

t = linspace(base_dt, base_dt*N, N);

% plot start
step = 1;
step_sample = 25;

ns_scale = 1e9/2^32;

subplot(3,1,1);
plot(t(1:step:end), all_K(1, 1:step:end), t(1:step_sample:end), all_K(1, 1:step_sample:end))
ylabel('K_0')
legend('Original', 'Sampled')
grid on;

subplot(3,1,2);
plot(t(1:step:end), all_K(2, 1:step:end), t(1:step_sample:end), all_K(2, 1:step_sample:end))
ylabel('K_1')
legend('Original', 'Sampled')
grid on;

subplot(3,1,3);
plot(t(1:step:end), all_K(3, 1:step:end), t(1:step_sample:end), all_K(3, 1:step_sample:end))
ylabel('K_2')
legend('Original', 'Sampled')
grid on;

all_K(3, 1:step:end)

pause;
