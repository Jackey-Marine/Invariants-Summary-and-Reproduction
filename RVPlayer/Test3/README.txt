https://www.notion.so/bobcheng/Drone-Dynamic-Data-ac40c247bdb94e3680b487a2919866c3

190: north-east with instant wind while turning
194: instant wind while turning south
195: instant wind while turning south
209：simple mission
210: complex mission
211: weak wind
212: normal wind
213: strong wind
221： parameter attack with wind on turning param equal to 9
223： same as 221 but with param equal to 8
224： no parameter attack but just wind
246： simple north without wind case 1
247： case 2
255:   case 4
256： case 3
259： case 4: time realigned
260： case 4: adaptive log
264:  case 4: adaptive log with disturbance low pass filter, window: 10
265:  case 4: adaptive log with disturbance  low pass filter, window: 5
268: syn first 3 states every 5s, disturbance  low pass window 5
269: syn first 6 states every 5s, disturbance  low pass window 10
270: syn first 6 states every 1s, disturbance  low pass window 10
271: syn all 12 states every 1s, disturbance  low pass window 10
272: syn first 3 states every 1s, disturbance  low pass window 10
275: simple task, recollect data, north and land
276: 275-offline reproduce
279: complex task, 14m/s wind towards south
280: 279-offline reproduce
282：complex task No wind
283: weak wind, complex task 2m/s wind towards south
284: weak wind, complex task 6m/s wind towards south
285-287： offline reproduce 282-284

290: GPS stealthy attack trace, no attack
291: GPS stealthy attack trace, attack on within trace at around 20s
293：Inter-sample attack. no attack. reference.
294:  Inter-sample attack. attack launched

430: simQuad, StarSix mission, random disturbance (bad)
431: simQuad, StarSix mission, random disturbance 
435: simQuad, Zig-Zag mission, random disturbance 
453: split-second attack, simulation

463: accel attack simulation, scale 2, duration 2s
464: accel attack simulation, scale 1, duration 4s

483: accel attack simulation, scale 1, duration 5s
487: accel attack reference, no attack, just wind
488: accel & GPS attack. scale 1 and 2, back and forth
491: accel & GPS attack. scale 1 and 2, straight line
494: accel & GPS attack. scale 0.5 and 2, straight line

528: gradual gyro attack, scale 0.05, lasts 6s.

============== param tampering attack ==================
542: param tampering attack, PSC_VELXY_P scale 30, start 15s.
548: param tampering attack, PSC_VELXY_P scale 10, start when pitch change while turning.
552: param tampering attack, PSC_VELXY_P scale 10, set before mission
557: param tampering attack, ATC_RAT_RLL_P scale 1, set when pitch change while turning.
=========================================================

560: zig zag PSC_VELXY_P scale 10, start when second pitch change while turning.
563: zig zag ATC_RAT_RLL_P scale 1, start when second pitch change while turning.
567: zig-zag drift-away wind
568: zig-zag oscillate wind
569: square drift-away wind
570: square oscillate wind
577: square (what-if square) ATC_RAT_PIT_I = 10 ATC_RAT_PIT_FF = 6.5, multi-param attack
578: zigzag ATC_RAT_PIT_I = 10 ATC_RAT_PIT_FF = 6.5, multi-param attack

592: acc and gyro gradual attack together
597: gyro gradual attack scale: 0.01
598: gyro gradual attack scale: 0.02

631: data with raw_acc
632: GPS spoofing with GPS speed spoofing
633: square mission to test IMU-replay


634: GPS spoofing plan without attack
635: GPS spoofing plan with attack, start at 20s, scale: 2
638: GPS spoofing plan with attack, start at 20s, scale: 2, with GSP data

639: GPS spoofing plan without attack, diagnal plan
640: GPS spoofing plan with attack, start at 20s, scale: 2, diagnal plan

639: GPS spoofing plan without attack, square plan
640: GPS spoofing plan with attack, start at 20s, scale: 2, square plan