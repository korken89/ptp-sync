#set heading(numbering: "1.")


#set align(center)
#text(17pt, "PTP time sync notes") \
#v(6pt) Emil Fresk \
#link("https://github.com/korken89")
#set align(left)
#v(12pt)
#set par(justify: true)

Here are the notes for the PTP time sync.

= Clock modelling

A clock can be represented as an autonomouse system with a tick count $T$ and tick rate $accent(T,dot)$, with the following state space representation.

$ 
vec(accent(T,dot), accent(T,dot.double)) = 
mat(0, 1; 0, 0) vec(T, accent(T,dot)) 
$

The tickrate of the clock, $accent(T,dot)$, is bounded to a nominal value that is scaled with an unknown error.

$ accent(T,dot) = (1+epsilon) accent(T,dot)_("nom") $

While $epsilon$ is not known, it has known bounds from the clock's datasheet and is generally specified in parts per million (ppm).
The characteristics of $epsilon$ is generally temperature and voltage dependent, however we can model $epsilon$ as a bounded random walk process for simulation purposes.

$ accent(epsilon,dot) = -alpha epsilon + cal(N)(0, sigma^2)  $

This will give a clock that has a nominal tick rate but that slowly drifts around the nominal value. The nominal tick rate for a the PTP peripheral in STM32 microcontrollers is $2^32$ which is accumulated in a 64-bit register, this means that overflows can be neglected as this would overflow about once every 136 years.

= Measurements

In PTP we have two clocks that we want to synchronize, one that we can control $T^C$, and some other autonomous clock $T^A$. While we can observe a timestamp from either clock we can't make an observation at the same time due to time delays to send timestamps and reading them out. 

This is where the PTP peripheral in the MCU comes into play, through a set of network packet transfers we can measure the offset between the clocks as

$ y_m = T^C - T^A + w $

where $w$ is some measurement noise.


= MCU PTP clock 

$ 
vec(T^C_(k+1), accent(T,dot)^C_(k+1)) = 
mat(1, Delta t; 0, 0) vec(T^C_k, accent(T,dot)^C_k) +
vec(0, 1) u^C_k
$
