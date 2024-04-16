clear;
close all;
addpath('../', '-end');
currentFolder = pwd;
model_file = strcat(currentFolder, '/model_px4.mat');
load(model_file); % read model

%nonlinear greybox model
% model = nlgr_m;
present(model);
a = model.Parameters(1).Value;
b = model.Parameters(2).Value;
c = model.Parameters(3).Value;
d = model.Parameters(4).Value;
m = model.Parameters(5).Value;
I_x = model.Parameters(6).Value; 
I_y = model.Parameters(7).Value; 
I_z = model.Parameters(8).Value; 
K_T = model.Parameters(9).Value;
K_Q = model.Parameters(10).Value;

%%%%%
% important paraemters for compression
sync_k = 0.5*100;     % 5 (sec)
max_freq = 100;
load('error_thresh.mat');
err_thresh(2) = 4;           %TODO: set the treshold for each state
err_thresh = err_thresh * 10;
%%%%%



%% Read test data
filename = '../Test4/t4.csv';
test_data = csvread(filename, 2, 0);  
test_data(:, 1) = test_data(:, 1)-test_data(1, 1); % reset start time
%trim data (remove unnecessary parts with starting point (s) and end point (s)
    sp = 1; % starting point (s)
    ep = 270; % end point (s)
    isp = find(test_data(:,1) * 1e-6 > sp, 1);
    iep = find(test_data(:,1) * 1e-6 > ep, 1);
    if isempty(iep)
        iep = size(test_data,1);
    end
    test_data = test_data(isp:iep, :);

NX = 12;    
NY = 12;
NU = 4;
raw_timestamps = test_data(:,1) * 1e-6;    %(s)    time vector
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
% q <-> -q r <-> -r
raw_states(:,11) = -raw_states(:,11);
raw_states(:,12) = -raw_states(:,12);

timestamps = raw_timestamps';
states = raw_states';
motors = raw_motors';


title_name = ["x(east)", "y(north)", "z(up)", "roll", "pitch", "yaw", "vx", "vy", "vz", "p", "q", "r"]; 
% t, x, y, u
t = timestamps;
x = zeros(NX,N);    x(1:12,1) = states(:,1);    
y = zeros(NY,N);    %model output
u = motors;
dx = zeros(NX,N);


global frame_height;
frame_height = 0.1;
for n=1:N-1
    dt = t(n+1) - t(n);
    [dx(:,n),y(:,n)] = quadrotor_m_px4(t(n), x(:,n), u(:,n), a,b,c,d, m, I_x, I_y, I_z, K_T, K_Q);
    x(:,n+1) = x(:,n) + dx(:,n) * dt; 
    x(6,n+1) = mod(x(6,n+1), 2*pi); % wrap yaw to [0,2pi)
    
    %========= on ground check ==========
    if on_ground(x(3, n+1), frame_height)
        x(3, n+1) = frame_height; % z ;
        x(4:5,n+1) = 0; % roll = pitch = 0;
        x(7:8, n+1) = 0; % vx = vy = 0;
        x(10:12, n+1) = 0; %pqr = 0;
        if x(9, n+1) < 0
            x(9, n+1) = 0; %vz = 0;
        end
    end
    if n * dt < 10
        x(10:12,n+1) = states(10:12,n+1);
        x(4:6,n+1) = states(4:6,n+1);
    end
    
    %k-step ahead estiamtion (sync at every-k loop)
    if mod(n, sync_k) == 0
        x(:,n+1) = states(:,n+1);
    end
end

%% =====================================================
th = err_thresh;   %threshold for each state

yc = nan(NY,N);       % yc: state output after compression
yo = nan(NY,N);       % yo: offline logs

err = zeros(NX, N);
desired_log_freq = ones(NX, N);
actual_log_freq = ones(NX,N);
last_log_time = ones(NX, 1);
last_log_time(:, 1) = t(1);
check_w = 200;
%
% =============== online logging
for n=1:N
    %sychronized points are always logged.
    if mod(n, sync_k) == 1 && n > 1
        last_log_time(:, 1) = t(n);
    end
    for k=1:NY
        err(k,n) = abs(states(k,n)-y(k,n));
        if err(k,n) > th(k)
            yc(k,n) = states(k,n);  % online logging (compression)
%             yo(k,n) = nan;
            desired_log_freq(k,n) = max_freq;
            last_log_time(k) = t(n);
        else
            log_hist = yc(k, max(1, n-check_w): max(1, n-1));
            [to_log, desired_log_freq(k,n)] = is_log(err(k,n), th(k), max_freq, last_log_time(k), t(n), log_hist);
%             to_log = 0;
            if to_log
                yc(k,n) = states(k,n);  % online logging (compression)
%                 yo(k,n) = nan;
                last_log_time(k) = t(n);
            else
                yc(k,n) = nan;
%                 yo(k,n) = y(k,n);   % offline reproduction
            end
        end
    end
end

%
% =============== offline regeneration
for n=1:N-1
    dt = t(n+1) - t(n);
    [dx(:,n),y2(:,n)] = quadrotor_m_px4(t(n), x(:,n), u(:,n), a,b,c,d, m, I_x, I_y, I_z, K_T, K_Q);
    x(:,n+1) = x(:,n) + dx(:,n) * dt; 
    x(6,n+1) = mod(x(6,n+1), 2*pi); % wrap yaw to [0,2pi)
    
    %========= on ground check ==========
    if on_ground(x(3, n+1), frame_height)
        x(3, n+1) = frame_height; % z ;
        x(4:5,n+1) = 0; % roll = pitch = 0;
        x(7:8, n+1) = 0; % vx = vy = 0;
        x(10:12, n+1) = 0; %pqr = 0;
        if x(9, n+1) < 0
            x(9, n+1) = 0; %vz = 0;
        end
    end
    if n * dt < 10
        x(10:12,n+1) = states(10:12,n+1);
        x(4:6,n+1) = states(4:6,n+1);
    end
    
    %sync
    for i=1:NY
        if ~(isnan(yc(i,n+1)))
            x(i,n+1) = yc(i,n+1);
        else
            yo(i,n+1) = x(i,n+1);
        end
    end
end

w = 100;
for i = 1:N
    window_yc = yc(:, max(1,i-w+1):i);
    win_size = size(window_yc,2);
    window_log_count = sum(~isnan(window_yc), 2);
    window_log_count(window_log_count == 0) = 1;
    actual_log_freq(:, i) = window_log_count/win_size*max_freq;
end



    
figure;
for n=1:NY
    if NY > 1
        subplot(NY/3, 3, n);
    end    
    yyaxis left
    plot(timestamps, states(n,:),'k-');     %truth
    hold on;
    plot(timestamps, yc(n,:), 'ro');        %logging points
    hold on;
    plot(timestamps, yo(n,:), 'b.');        %regenerated points
    hold on;
    plot(t, y(n,:), 'b--');                  %model prediction
    hold on;
    yyaxis right
    area(t, abs(states(n,:)-y(n,:)), 'FaceAlpha', 0.8, 'EdgeColor', 'none');    % deviation
    plot(t, th(n)*ones(1, length(t)), 'g');
    ylim([0,10]);
    legend('State', 'Log', 'Prediction','Model prediction',  'Error', 'Error max thres');
end
  



figure;
for n=1:NY
    if NY > 1
        subplot(NY/3, 3, n);
    end
    plot(t, desired_log_freq(n,:), 'r');
    hold on;
    plot(t, actual_log_freq(n,:), 'b');
    legend('desired log freq', 'actual log freq');
    title(title_name(n));
end
