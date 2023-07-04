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

It's important to understand that $accent(T,dot)_("nom")$ can differ between two clocks using the same crystal due to manufacturing tolerances. As an example, below is a simulation over the Brownian motion of two clocks that includes these manufacturing tolerances.

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

= Control aim

The main reason for offset drift is that the effects from the random walk processes cannot be eliminated, hence a controller is needed.
Given that we can estimate $T^O$ and $epsilon^O$, we can formulate a state feedback regulator that drives the offset to 0.

That is, find a state feedback controller

$ u = -g dot vec(T^O, epsilon^O) $

such that

$ T^O -> 0. $

= Estimating offset

We can estimate the current offset and its derivative using a Kalman filter, however the question is what model should we use for the estimator?
As the underlying drivers for the random walk is mostly temperature, this means that changes in temperature will cause an increase or decrease in tick rate. Moreover we can assume that the change in tick rate is continuous. This indicates that either a velocity model or acceleration model should be a good fit for the problem.

Lets start with an acceleration model using the following state space model:

$
vec(T^O, accent(T, dot)^O, accent(T, dot.double)^O)_(k+1) =
mat(1, Delta t, Delta t^2/2; 0, 1, Delta t; 0, 0, 1)
vec(T^O, accent(T, dot)^O, accent(T, dot.double)^O)_k +
vec(0, u_k, 0) + cal(N)(0, bold(Q))
$

$
y_k = mat(1, 0, 0)
vec(T^O, accent(T, dot)^O, accent(T, dot.double)^O)_k + cal(N)(0, R)
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
