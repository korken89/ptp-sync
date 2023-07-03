function motion = brownian_motion(N, dt, c, sigma, ppm_limit)

    b = 0;

    all_b = zeros(N, 1);

    for i = 1:N
        % Brownian motion
        b = c * b + sigma * sqrt(dt) * randn;

        all_b(i) = b;
    end

    base_ppm = 2*ppm_limit * rand - ppm_limit
    motion = all_b + base_ppm;
end

