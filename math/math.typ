#set heading(numbering: "1.")


#set align(center)
#text(17pt, "PTP time sync notes") \
#v(6pt) Emil Fresk \
#link("https://github.com/korken89")
#set align(left)
#v(12pt)
#set par(justify: true)

Here are the notes for the PTP time sync.

= Clock modeling

A clock can be represented as an autonomous system with a tick count $T$ and tick rate $accent(T,dot)$.
The tick rate of the clock, $accent(T,dot)$, is bounded to a nominal value that is scaled with an unknown error.

$ accent(T,dot) = (1+epsilon) accent(T,dot)_("nom") $

While $epsilon$ is not known, it has known bounds from the clock's datasheet and is generally specified in parts per million (ppm).
The characteristics of $epsilon$ is generally temperature and voltage dependent, however we can model $epsilon$ as a bounded random walk process for simulation purposes.

$ accent(epsilon,dot) = -alpha epsilon + cal(N)(0, sigma^2)  $

This will give a clock that has a nominal tick rate but that slowly drifts around the nominal value. The nominal tick rate for the PTP peripheral in STM32 microcontrollers is $2^32$ which is accumulated in a 64-bit register, this means that overflows can be neglected as this would overflow about once every 136 years.

Combining the above gives the system's transfer function is as follows:

$
vec(accent(T,dot), accent(epsilon,dot)) =
    mat(0, accent(T,dot)_("nom"); 0, -alpha) vec(T, epsilon)
    + vec(accent(T,dot)_("nom"), 0)
    + vec(0, cal(N)(0, sigma^2))
$

For the clock on the micro processor we can control the deviation from nominal tick rate of the PTP clock, giving the following:

$
vec(accent(T,dot), accent(epsilon,dot)) =
    mat(0, accent(T,dot)_("nom"); 0, -alpha) vec(T, epsilon)
    + vec(accent(T,dot)_("nom") + u, 0)
    + vec(0, cal(N)(0, sigma^2))
$

It's important to understand that $accent(T,dot)_("nom")$ can differ between two clocks using the same crystal due to manufacturing tolerances. As an example, below is a simulation over the Brownian motion of two clocks that includes these manufacturing tolerances. However one can move this error into $epsilon$ without issues.

#figure(
  image("brownian.svg", width: 95%),
  caption: [
    The simulated frequency error of two clocks.
  ],
)


= Measurements

In PTP we have two clocks that we want to synchronize, one that we can control $T^C$, and some other autonomous clock $T^A$. While we can observe a timestamp from either clock we can't make an observation at the same time due to time delays to send timestamps and reading them out.

This is where the PTP peripheral in the MCU comes into play, through a set of network packet transfers we can measure the offset between the clocks as

$ y_m = T^C - T^A + w $

where $w$ is some measurement noise. This means that we need to find the dynamics model of the clock offset instead of individual clocks.

= Offset modeling

From the offset

$ T^O = T^C - T^A $

we can derive the corresponding dynamics by differentiating both sides

$
accent(T, dot)^O = accent(T, dot)^C - accent(T, dot)^A
$

and then simplifying based on the tick rate equation

$
accent(T, dot)^O = (1+epsilon^C) accent(T,dot)_("nom") + u - (1+epsilon^A) accent(T,dot)_("nom") \
accent(T, dot)^O = accent(T,dot)_("nom") (epsilon^C - epsilon^A) + u.
$

This shows, as both $epsilon^C$ and $epsilon^A$ are random walk processes, that the offset will drift over time if no control action is supplied from $u$. Moreover, the bound on the drift is double that of each individual clock.

Finally, replacing the difference of Brownian motion into a new random walk process $epsilon^O$ gives the following system that we want to control:

$
vec(accent(T, dot)^O, accent(epsilon, dot)^O) = mat(0, 1; 0, -alpha) vec(T^O, epsilon^O)
 + vec(u, 0) + vec(0, cal(N)(0, 2 sigma^2))
$

However here an interesting question about our modeling comes into light. What are the actual dynamics of $epsilon^O$? Our modeling suggests that its dynamics are driven by something unknown, however in reality this will be driven mainly by temperature fluctuations and aging of the underlying clock. Both which are not random processes. This means that there are most likely hidden dynamics we have not modeled here. Now one can either go down the rabbit hole and try to model these, or go with the assumption that estimating another derivative will capture enough of the dynamics. This would give the following system:

$
vec(accent(T, dot)^O, accent(epsilon, dot)^O, accent(epsilon, dot.double)^O) = mat(0, 1, 0; 0, 0, 1; 0, 0, 0) vec(T^O, epsilon^O, accent(epsilon, dot)^O)
 + vec(u, 0, 0) + vec(0, 0, cal(N)(0, sigma^2))
$

We'll explore both and compare estimation errors.

= Estimating offset

We can estimate the current offset and the $epsilon$ states using a Kalman filter.

Lets start with the extended model model using the following discrete state space model:

$
vec(T^O, epsilon^O, accent(epsilon, dot)^O)_(k+1) =
mat(1, Delta t, (Delta t^2)/2; 0, 1, Delta t; 0, 0, 1)
vec(T^O, epsilon^O, accent(epsilon, dot)^O)_k +
vec(Delta t, 0, 0) u_k + cal(N)(0, bold(Q))
$

$
y_k = mat(1, 0, 0)
vec(T^O, epsilon^O, accent(epsilon, dot)^O)_k + cal(N)(0, R)
$

Where the process covariance matrix is:

$
bold(Q) = mat((Delta t^5)/20, (Delta t^4)/8, (Delta t^3)/6;
              (Delta t^4)/8,  (Delta t^3)/6, (Delta t^2)/2;
              (Delta t^3)/6,  (Delta t^2)/2,  Delta t) sigma^2
$

and $R$ is determined by measurement noise from a data set. Finally, the aggressiveness of the model can be tuned by varying $sigma$, until desired responsiveness is found on a collected data set.

To reject outliers a Mahalanobis gating test will be added, it's simple but effective. However it's not suitable for initial convergence. Even more so, a Kalman Filter needs help with initial convergence to get good startup performance. Hence the initial $T^O$ and $epsilon^O$ will be estimated using least squares on a small initial sample set.

= Control aim

The main reason for offset drift is that the effects from the random walk processes cannot be eliminated, hence a controller is needed.
Given that we can estimate $T^O$ and $epsilon^O$, we can formulate a state feedback regulator that drives the offset to 0.

That is, find a state feedback controller

$ u = -bold(g) dot vec(T^O, epsilon^O, accent(epsilon, dot)^O) $

such that

$ T^O -> 0. $

Looking at the dynamics we can by inspection see that the full state space is uncontrollable, as the control signal has no interaction with any $epsilon^O$ states. However as we only want to control $T^O$ we can see that this state is indeed controllable. Which is good, else this would have all been a waste of time.

To make this work with available LQR methodologies (Octave/Matlab) we need to have a controllable system, and to this end we need to eliminate the uncontrollable state. In our case this will be trivial by looking at the evolution of $T^O_k$:

$ T^O_k = T^O_(k+1) + Delta t epsilon^O_k + (Delta t^2)/2 accent(epsilon, dot)^O_k + Delta t u_k $

Lets rearrange:

$ T^O_k = T^O_(k+1) + Delta t (epsilon^O_k + (Delta t)/2 accent(epsilon, dot)^O_k + u_k) $

And define a new control signal:

$ accent(u, tilde)_k = epsilon^O_k + (Delta t)/2 accent(epsilon, dot)^O_k + u_k $

This will give us a new state space system of a single dimension:

$ T^O_(k+1) = T^O_k + Delta t accent(u, tilde)_k $

where the inverse transform of the control signal is

$ u_k = accent(u, tilde)_k - epsilon^O_k - (Delta t)/2 accent(epsilon, dot)^O_k. $

This is also logical as with this controls signal tranformation eliminate the uncontrolable states. Finally we can apply the LQR methodology to control the system, i.e. find the first element in $bold(g)$, where the final $bold(g)$ will be:

$ bold(g) = mat(g_0, 1, (Delta t)/2). $

To find $g_0$ we need to solve the Discrete Algebraic Riccatti Equation by finding $P$ in:

$
P = A P A^T - (A^T P B)(R + B^T P B)^(-1)(B^T P A) + Q
$

and finally find $g_0$ as

$
g_0 = (R + B^T P B)^(-1) B^T P A
$

where $A = 1$ and $B = Delta t$. Solving for the positive definite form of $P$ (it has 2 solutions) gives:

$
P = Q/2 + sqrt(Q^2/4 + (R Q)/t^2).
$

Which gives $g_0$ as follows:

$
g_0 = frac(sqrt(Q^2 Delta t^2 + 4 R Q) + Q Delta t, 2R + Delta t (sqrt(Q^2 Delta t^2 + 4 R Q) + Q Delta t)),
$

and the final state feedback gain as:

$
bold(g) = mat(frac(sqrt(Q^2 Delta t^2 + 4 R Q) + Q Delta t, 2R + Delta t (sqrt(Q^2 Delta t^2 + 4 R Q) + Q Delta t)), 1, (Delta t)/2).
$

== Simulation results (acceleration model)

#figure(
  image("acc_model/brownian.svg", width: 95%),
  caption: [
    The simulated frequency error of the two clocks.
  ],
)

#figure(
  image("acc_model/tracking.svg", width: 95%),
  caption: [
    The tracking of the Kalman filter overlayed with true values.
  ],
)

#figure(
  image("acc_model/error.svg", width: 95%),
  caption: [
    The tracking error of the Kalman filter.
  ],
)

#figure(
  image("acc_model/acc_est.svg", width: 95%),
  caption: [
    The estimated acceleration of the Kalman filter.
  ],
)
