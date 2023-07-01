function motion = brownian_motion(N, dt, c, sigma)

    b = 0;

    all_b = zeros(N+1, 1);

    lpf = 0;
    alpha = 0.9999;

    for i = 1:N

        % Brownian motion
        lpf = alpha * lpf + (1 - alpha) * sigma * sqrt(dt) * randn;

        b = c * b + lpf;

        all_b(i+1) = b;
    end

    motion = all_b;
end

