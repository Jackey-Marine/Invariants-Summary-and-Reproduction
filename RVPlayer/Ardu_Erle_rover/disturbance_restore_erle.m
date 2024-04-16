clear;
close all;
currentFolder = pwd;
addpath('../', '-end');
model_file = strcat(currentFolder, '/model_sitl_rover.mat');
% load(model_file); % read model

%nonlinear greybox model
% present(model);
% m = model.Parameters(1).Value;
% a = model.Parameters(2).Value;
% b = model.Parameters(3).Value;
% Cx = model.Parameters(4).Value;
% Cy = model.Parameters(5).Value;
% CA = model.Parameters(6).Value; 

% m = 2.1
% a = 0.2
% b = 0.15
% Cx = 17
% Cy = 17
% CA = 0.2

m = 1.7
a = 0.5
b = 0.7
Cx = 15
Cy = 15
CA = 0.1706

% m = 2.1
% a = 0.2
% b = 0.15
% Cx = 40
% Cy = 40
% CA = 3

%%%%%
% important paraemters for compression
max_freq = 50;
sync_k = 1; %max_freq*10;     % 5 (sec)
is_lowpass = 1;
lowpass_w = 10;
adaptive_order = 1;
if is_lowpass
    load disturb_L_norm_filtered_rover.mat
else
    load disturb_L_norm_rover.mat
end

% L_norm = [0,0];

reference_motor = 0.02; % 1500 +- 40 pwm
%%%%%



%% Read test data
% 267, 266, 264, 265, 269
filename = '../Test8/00000286.csv';
test_data = csvread(filename, 2, 0);
refer_idx = find(abs(test_data(:, 16)-0.5) >= reference_motor, 1);
reference_steering = test_data(find(abs(test_data(:, 14))>0.5,1), 14) - 0.5;
reference_time = test_data(refer_idx, 1); % test_data(1, 1)
test_data(:, 1) = test_data(:, 1)-reference_time; % reset start time
%trim data (remove unnecessary parts with starting point (s) and end point (s)
    isp = refer_idx + 1 * max_freq;
    iep = find(abs(test_data(:, 16)-0.5) >= reference_motor,1,'last');
    test_data = test_data(isp:iep, :);

NX = 6;    
NY = 6;
NU = 2;
raw_timestamps = test_data(:,1) * 1e-6;    %(s)    time vector
time_us = test_data(:,1);

test_data(:, [2,3]) = test_data(:, [2,3]) - test_data(1, [2,3]); %reset x, y reference
raw_states = test_data(:,2:13);            % array of state vector: 12 states

raw_motors = test_data(:,14:17);
raw_motors(:, 1) = raw_motors(:, 1) - reference_steering; % reset steering reference.

N = size(test_data,1);                 % size of samples

% extract 6 states  [x y yaw vx vy r]
raw_states(:,1) = raw_states(:,1);
raw_states(:,2) = raw_states(:,2);
raw_states(:,3) = raw_states(:,6);
raw_states(:,4) = raw_states(:,7);
raw_states(:,5) = raw_states(:,8);
raw_states(:,6) = raw_states(:,12);
raw_states(:,7:12) = [];

raw_states(:,3) = wrapTo2Pi(raw_states(:,3));

% convert input signals
% steering (motor1) : 0-0.5 is left turn, 0.5-1 is right turn. => pi
% [-0.5...0.5] *
% throttle (motor3):  
raw_motors(:,1) = (raw_motors(:,1)-0.5)*pi/2;   
raw_motors(:,2) = raw_motors(:,3)-0.5;
raw_motors(:,3:4) = [];

timestamps = raw_timestamps';
states = raw_states';
motors = raw_motors';

%========== add acceleration AND disturbance data ============
N = N-1;
accel_states = (states(4:6, 2:end)-states(4:6, 1:end-1))./(timestamps(2:end) - timestamps(1:end-1));

% accel_states_bf = [accel_states(1,:) .* cos(states(3,:)) + accel_states(2,:).* sin(states(3,:));...
%     -accel_states(1,:) .* sin(states(3,:)) + accel_states(2,:).* cos(states(3,:));...
%     accel_states(3, :)];
% accel_states = accel_states_bf;
vel_states = states(4:6, :);
vel_states_bf = [vel_states(1,:) .* cos(states(3,:)) + vel_states(2,:).* sin(states(3,:));...
    -vel_states(1,:) .* sin(states(3,:)) + vel_states(2,:).* cos(states(3,:));...
    vel_states(3, :)];

accel_states_bf = (vel_states_bf(:, 2:end) - vel_states_bf(:, 1:end-1)) ./ (timestamps(2:end) - timestamps(1:end-1));
accel_states = accel_states_bf;

vel_states_bf = vel_states_bf(:, 1:end-1);
states = states(:, 1:end-1);
timestamps = timestamps(1:end-1);
time_us = time_us(1:end-1);
motors = motors(:, 1:end-1);
% wind_window = [86066393, 90298866] - reference_time;


origin_disturb = zeros(4, N);
lowpass_disturb = zeros(4, N);

%========================================

title_name = ["x(north)", "y(east)", "yaw", "vx", "vy", "yaw_rate"]; 
% t, x, y, u
t = timestamps;
x = zeros(NX,N);  %  x(1:12,1) = states(:,1);

%set initial value
x([1:3, 6], 1) = states([1:3, 6], 1);
ef2bf_m = [cos(x(3, 1)), sin(x(3, 1));
        -sin(x(3, 1)), cos(x(3, 1))];
x(4:5, 1) = ef2bf_m * states(4:5, 1);

y = zeros(NY,N);    %model output
y_accel = zeros(3, N);
u = motors;
dx = zeros(NX,N);
accel_log_record = zeros(2, N);
last_log_time = ones(2, 1);
last_log_time(:, 1) = t(1);

for n=1:N-1
    dt = t(n+1) - t(n);
    [dx(:,n),y(:,n)] = rover_m(t(n), x(:,n), u(:,n), m,a,b,Cx,Cy,CA);
    y_accel(:, n) = dx(4:6, n); % record y_accel (body frame).
    disturb_accel = accel_states(:, n) - y_accel(:, n);
    origin_disturb(:, n+1) = [time_us(n+1); disturb_accel];
    %low_pass filtered disturbance
    avg_accel = mean(origin_disturb(2:4, max(1, n+2-lowpass_w):n+1), 2);
    lowpass_disturb(:, n+1) = [time_us(n+1); avg_accel];
    if is_lowpass
       log_reference =  avg_accel;
    else
        log_reference =  disturb_accel;
    end
%     lin_acc = norm(log_reference(1:2));
    lin_acc = abs(log_reference(1));
    rot_acc = abs(log_reference(3));
    is_log = islog_disturb(lin_acc, rot_acc ,L_norm, adaptive_order, max_freq, last_log_time, t(n+1));
    accel_log_record(:, n+1) = is_log';
    for i = 1:2
        if is_log(i)
            last_log_time(i) = t(n+1);
        end
    end
    x(:,n+1) = x(:,n) + dx(:,n) * dt; 
    x(3,n+1) = wrapTo2Pi(x(3,n+1)); % wrap yaw to [0,2pi)
    
    if abs(x(4,n+1)) > 30
        x(4,n+1) = sign(x(4,n+1)) * 30;
    end
    
    if abs(x(6,n+1)) > 5
        x(6,n+1) = sign(x(6,n+1)) * 5;
    end
    
%     if n*dt < 2
%           x([1:3, 6], n+1) = states([1:3, 6], n+1);
%           ef2bf_m = [cos(x(3, n+1)), sin(x(3, n+1));
%                     -sin(x(3, n+1)), cos(x(3, n+1))];
%           x(4:5, n+1) = ef2bf_m * states(4:5, n+1);
%     end
    
    
%     k-step ahead estiamtion (sync at every-k loop)
    k = sync_k;
    if mod(n, k) == 0
          x([1:3, 6], n+1) = states([1:3, 6], n+1);
          ef2bf_m = [cos(x(3, n+1)), sin(x(3, n+1));
                    -sin(x(3, n+1)), cos(x(3, n+1))];
          x(4:5, n+1) = ef2bf_m * states(4:5, n+1);
    end

end

%%
% full_disturb = [time_us'; accel_states-y_accel]';
if is_lowpass
    full_disturb = lowpass_disturb';
else
    full_disturb =  origin_disturb';
end
% line_acc_norm = vecnorm(full_disturb(: , 2:3)');
line_acc_norm = abs(full_disturb(: , 2)');
rot_acc_norm = abs(full_disturb(:, 4)');
acc_norms = [line_acc_norm; rot_acc_norm]';

actual_log_freqs = zeros(2, N);
w_sz = max_freq;
for i = 1:N
    actual_log_freqs(:, i) = sum(accel_log_record(:, max(1, i-w_sz/2+1):min(i+w_sz/2, N)), 2) / w_sz * max_freq;
end

% L_norm = [max(line_acc_norm), max(rot_acc_norm)]; % save norm
% save('disturb_L_norm.mat', 'L_norm')
% save('disturb_L_norm_filtered_rover.mat', 'L_norm')
%% plot
figure;
for n=1:NY
    if NY > 1
        subplot(NY/3, 3, n);
    end    
    yyaxis left
    plot(timestamps, states(n,:),'k-');     %truth
    hold on;
    plot(t, y(n,:), 'b--');                  %model prediction
    hold on;
    yyaxis right
    area(t, abs(states(n,:)-y(n,:)), 'FaceAlpha', 0.8, 'EdgeColor', 'none');    % deviation
    legend('State', 'Model prediction',  'Error');
end

% return;


figure;

for n=1:2
    subplot(1,2,n);
    plot(t, acc_norms(:, n));
    hold on;
    plot (t, ones(size(t)) * L_norm(n));
    yyaxis right
    plot (t, actual_log_freqs(n, :));
end

figure;
for n=1:6
    subplot(3, 3, n);
    if n <= 3
        plot(t, states(n,:), 'k-');  
    else
        plot(t, vel_states_bf(n-3, :), 'k-');
    end
    hold on;
    plot(timestamps, x(n,:),'b--');
    legend('State', 'Model prediction')
end


for n=1:3
    subplot(3,3, 6+n);
    yyaxis left
    plot(timestamps, accel_states(n,:),'k-');     %truth
    hold on;
    plot(t, y_accel(n,:), 'b--');                  %model prediction
    hold on;
    yyaxis right
    area(t, accel_states(n,:)-y_accel(n,:), 'FaceAlpha', 0.8, 'EdgeColor', 'none');    % deviation
    legend('State', 'Model prediction',  'Error');
end

% for i=1:3
%     subplot(3,3,i+6);
%     plot(timestamps, dx(i+3,:),'r.-');
%     hold on;
% %     plot(t, x(n,:), 'b-');  
%     legend('body State');
% end


% return;

%% write data

sync_log_k = max_freq;
sync_data = test_data(1:end, [1:3, 7:9, 13]); % NED frame
T_syn = array2table(sync_data);
% T_syn.Properties.VariableNames(1:13) = {'Time_us','x','y', 'z', 'roll', 'pitch', 'yaw',...
%     'V_x', 'V_y', 'V_z', 'Gyro_x', 'Gyro_y', 'Gyro_z'};
T_syn.Properties.VariableNames(1:7) = {'Time_us','x','y', 'yaw', 'V_x', 'V_y', 'Gyro_z'};

writetable(T_syn,[filename(1: end-4) '_syn.csv']);

% %==========from ENU to NED=============
% %body: y = -y, z = -z
% full_disturb(:, [6,7]) = -full_disturb(:, [6,7]);
% 
% %world x <-> y, z = -z
% full_disturb(:, 4) = -full_disturb(:, 4); %z
% temp = full_disturb(:, 2);
% full_disturb(:, 2) = full_disturb(:, 3); %x
% full_disturb(:, 3) = temp; %y
% %=====================================

T_disturb_lin = array2table(full_disturb(logical(accel_log_record(1, :)'), [1, 2:3]));
T_disturb_rot = array2table(full_disturb(logical(accel_log_record(2, :)'), [1, 4]));

T_disturb_lin.Properties.VariableNames(1:3) = {'Time_us','accel_x','accel_y'};
T_disturb_rot.Properties.VariableNames(1:2) = {'Time_us','angl_accel_z'};

writetable(T_disturb_lin,[filename(1: end-4) '_disturb_lin.csv']);
writetable(T_disturb_rot,[filename(1: end-4) '_disturb_rot.csv']);

%% Statistical calculation
kbps2gbpd = 0.0864;
main_data_rate = 80 * max_freq / 1000 * kbps2gbpd %gb/d
% other_data_rate = 14.583; %kb/s
% all_data_rate = main_data_rate + other_data_rate
logged_data_size =4*(sum(sum(accel_log_record)) * 1 + size(sync_data, 1) / max_freq * (2 + 6)); %Bytes
total_time = N / max_freq; %s
processed_data_rate = logged_data_size / total_time  / 1000 * kbps2gbpd %gb/d
% final_data_rate = processed_data_rate + other_data_rate
% compression_rate = final_data_rate / all_data_rate
main_data_compression_rate = processed_data_rate / main_data_rate


%%
disp('========= v2 logging rate =============');
new_adaptive_rate = kbps2gbpd * 4*(sum(sum(accel_log_record)) * (1+1)) / total_time / 1000; %GB/s
regular_Hz = 4;
previous_regular_rate = kbps2gbpd * (2+6) * 4 /1000; %GB/s
new_regular_rate = kbps2gbpd * regular_Hz * (1 + 2 + 2 + 1) * 4 / 1000; %GB/s
disp(['previous regular rate: ' num2str(previous_regular_rate) 'GB/s, new regular rate: ' num2str(new_regular_rate) 'GB/s']);
new_overall_logging_rate = new_adaptive_rate + new_regular_rate;
new_compression_ratio = new_overall_logging_rate / (main_data_rate);
disp(['v2 logging rate in GB/s: ' num2str(new_overall_logging_rate)]);
disp(['v2 log compression ratio:' num2str(new_compression_ratio)]);