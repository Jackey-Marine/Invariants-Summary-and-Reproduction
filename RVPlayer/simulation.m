clear;
close all;

%%Input Data: 
%motors
%states ["x(east)", "y(north)", "z(up)", "roll", "pitch", "yaw", "vx", "vy", "vz", "p", "q", "r"]; 
%timestamps
% 
load('sample_data.mat');
%% Split-second attack 
% load('CaseStudies/159.mat');      % original
% load('CaseStudies/00000352.mat'); % reproduced



fs = 400;
Ts = 1/fs;
pos = states(1:3,:);
ang = states(4:6,:);
vel = states(7:9,:);
angvel = states(10:12,:);
time = timestamps;

struct_data =  struct('x', pos, 'theta', ang, 'vel', vel, 'angvel', angvel, 't', time, 'dt', Ts);
%3D-animation
%Note: adjust a scale of xyz axises for a better look in animate() of visualize.m
visualize(struct_data);


