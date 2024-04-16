APMRover2 SITL Rover

9. zigzag-north
10. random
11. north longway
12. north-east-stop
18. Move directly to east (initially facing east)
19. simple mission
20. complex mission
21.  ground
23. sand (4m/s wind)
24. grass (14m/s wind)

========= add wind air resistence ============== 
(to use the following data, uncomment the four lines (34-37) adding air disturbance in rover_m.m)

26: North with disturbance
27: star shape 20m/s wind towards south
28: zig-zag north with 20m/s wind towards south
29: for calculating L_norm, north moving, 20m/s wind

88? complex mission, square shape, with wind speed 0
119? simple mission, straight north, with wind speed 0
120: small effect, straight north, with wind speed 2
121: mid effect, straight north, with wind speed 6
122: strong effect, straight north, with wind speed 14

133: simple mission, straight north, with wind speed 0
134: strong effect, straight north, with wind speed 14

152: Zig-Zag mission, random disturbance
153: StarSix Mission, random disturbance

162: GPS spoofing, straight mission, starts at 30s, ends at 60s, scale: 2
163: 162 reference