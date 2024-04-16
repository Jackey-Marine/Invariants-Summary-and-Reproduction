clear;
close all;

%%Input Data: 
%motors
%states ["x(east)", "y(north)", "z(up)", "roll", "pitch", "yaw", "vx", "vy", "vz", "p", "q", "r"]; 
%timestamps
% 
% load('sample_data.mat');

% % parameter attack case replay simulation
% frame='drone';
% test_data = csvread('Test5_rerun/00000375.csv', 1, 0); %parameter attack
% view_angle = [30, 25];

% % physical attack case replay simulation
% frame='drone';
% test_data = csvread('Test5_rerun/00000349.csv', 1, 0); 

% % gps attack case replay simulation
frame='drone';
test_data = csvread('Test5_rerun/00000382.csv', 1, 0); 
view_angle = [30, 40];
% xmin = -15; xmax = 15;
% ymin = -1; ymax = 30;
% zmin = -1; zmax = 6;

% % split second attack case replay simulation
% frame='drone';
% test_data = csvread('Test5_rerun/00000352.csv', 1, 0);
% view_angle = [145, 25];


% % rover resisence case replay simulation
% frame = 'rover';
% test_data = csvread('Test8_rerun/157.csv', 1, 0);
% view_angle = [-90, 90];
% xmin = -1; xmax = 25;
% ymin = -10; ymax = 10;
% zmin = -1; zmax = 6;
% test_data = csvread('Test8/00000264.csv', 1, 0); % original trace


% combine = test_data;
% combine(:, 7)= combine(:, 7) + deg2rad(15);
% T = array2table(combine);
% T.Properties.VariableNames(1:17) = {'Time_us','x','y', 'z', 'roll', 'pitch', 'yaw',...
%     'V_x', 'V_y', 'V_z', 'Gyro_x', 'Gyro_y', 'Gyro_z', 'M1', 'M2', 'M3', 'M4'};
% 
% writetable(T,['Test8_rerun/157.csv']);


if strcmp(frame, 'rover')
    max_freq = 50;
else
    max_freq = 400;
end


% test_data = csvread('Test5/189.csv', 1, 0);
% max_freq = 100;

reference_motor = 0.3;

refer_idx = find(test_data(:, 14) >= reference_motor, 1);
reference_time = test_data(refer_idx, 1); % test_data(1, 1)
test_data(:, 1) = test_data(:, 1)-reference_time; % reset start time
%trim data (remove unnecessary parts)
    isp = refer_idx ;
    iep = find(test_data(:, 14) >= reference_motor,1,'last') - 2 * max_freq;
    test_data = test_data(isp:iep, :);

NX = 12;    
NY = 12;
NU = 4;
raw_timestamps = test_data(:,1) * 1e-6;    %(s)    time vector
time_us = test_data(:,1);
raw_states = test_data(:,2:13);            % array of state vector: 12 states
raw_motors = (((test_data(:,14:17)*1000)+1000)-1100)/900;   %SITL: (((0.5595*1000)+1000)-1100)/900=0.51
N = size(test_data,1);                 % size of samples
%========== to ENU ==============
% x <-> y, vx <-> vy
temp = raw_states(:,1); 
raw_states(:,1) = raw_states(:,2);
raw_states(:,2) = temp;
temp = raw_states(:,7); 
raw_states(:,7) = raw_states(:,8);
raw_states(:,8) = temp;
% z <-> -z, vz <-> -vz
raw_states(:,3) = -raw_states(:,3);
raw_states(:,9) = -raw_states(:,9);
% pitch <-> -pitch yaw = (-yaw + pi/2)
raw_states(:,5) = -raw_states(:,5);
raw_states(:,6) = mod(-raw_states(:,6)+pi/2, 2*pi);
raw_states(:,6) = wrapToPi(raw_states(:,6));
% q <-> -q r <-> -r
raw_states(:,11) = -raw_states(:,11);
raw_states(:,12) = -raw_states(:,12);
%================================

timestamps = raw_timestamps';
states = raw_states';
motors = raw_motors';


%% Split-second attack 
% load('CaseStudies/159.mat');      % original
% load('CaseStudies/00000352.mat'); % reproduced




Ts = 1/max_freq;
pos = states(1:3,:);
ang = states(4:6,:);
ang(3, :) = ang(3, :);
vel = states(7:9,:);
angvel = states(10:12,:);
time = timestamps;

struct_data =  struct('x', pos, 'theta', ang, 'vel', vel, 'angvel', angvel, 't', ...
    time, 'dt', Ts, 'frame', frame, 'viewAngle', view_angle);
%3D-animation
%Note: adjust a scale of xyz axises for a better look in animate() of visualize.m
visualize(struct_data);


