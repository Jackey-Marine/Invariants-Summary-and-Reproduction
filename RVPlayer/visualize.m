% Visualize the quadcopter simulation as an animation of a 3D quadcopter.
% data =  struct('x', pos', 'theta', ang', 'vel', vel', 'angvel', angvel', 't', time', 'dt', Ts);%, 'input', u);
function h = visualize(data)
    % Create a figure with three parts. One part is for a 3D visualization,
    % and the other two are for running graphs of angular velocity and displacement.
%     figure; plots = [subplot(4, 2, 1:4), subplot(4, 2, 5), subplot(4, 2, 6), subplot(4, 2, 7), subplot(4, 2, 8)];
%     figure; plots = [subplot(3, 2, 1:4), subplot(3, 2, 5), subplot(3, 2, 6)];
figure; plots = [subplot(4, 2, 1:4), subplot(4, 2, 7), subplot(4, 2, 8)];
    subplot(plots(1));
    
    %pause;

    % Create the quadcopter object. Returns a handle to
    % the quadcopter itself as well as the thrust-display cylinders.
    if strcmp(data.frame, 'rover')
        [t] = rover;
    else
        [t] = quadcopter;
    end
    

    % Set axis scale and labels.
    axis([-3 3 -3 3 0 5]);
    zlabel('Height (m)');
    xlabel('x (m)');
    ylabel('y (m)');
%     title('Quadcopter Flight Simulation');
    grid on
%     set(gca,'Ydir','reverse');

    % Animate the quadcopter with data from the simulation.
    animate(data, t, plots);
end

% Animate a quadcopter in flight, using data from the simulation.
function animate(data, model, plots)
    % Show frames from the animation. However, in the interest of speed,
    % skip some frames to make the animation more visually appealing.
        
    for t = 1:floor((1/data.dt)/4):length(data.t)
        
        if data.x(3,t) < 0
            data.x(3,t) = 0;
        end
        
        
        % The first, main part, is for the 3D visualization.
        subplot(plots(1));
        view(data.viewAngle(1), data.viewAngle(2));
        % Compute translation to correct linear position coordinates.
        dx = data.x(:, t);
        move = makehgtform('translate', dx);

        % Compute rotation to correct angles. Then, turn this rotation
        % into a 4x4 matrix represting this affine transformation.
        angles = data.theta(:, t);
        rotate = rotation(angles);
        rotate = [rotate zeros(3, 1); zeros(1, 3) 1];

        % Move the quadcopter to the right place, after putting it in the correct orientation.
        set(model,'Matrix', move * rotate);

        % Compute scaling for the thrust cylinders. The lengths should represent relative
        % strength of the thrust at each propeller, and this is just a heuristic that seems
        % to give a good visual indication of thrusts.
%         scales = exp(data.input(:, t) / min(abs(data.input(:, t))) + 5) - exp(6) +  1.5;
%         for i = 1:4
%             % Scale each cylinder. For negative scales, we need to flip the cylinder
%             % using a rotation, because makehgtform does not understand negative scaling.
%             s = scales(i) / 30;
%             if s < 0
%                 scalez = makehgtform('yrotate', pi)  * makehgtform('scale', [1, 1, abs(s)]);
%             elseif s > 0
%                 scalez = makehgtform('scale', [1, 1, s]);
%             end
% 
%             % Scale the cylinder as appropriate, then move it to
%             % be at the same place as the quadcopter propeller.
%             set(thrusts(i), 'Matrix', move * rotate * scalez);
%         end
        
        num = 30;
        if t > num
%             plot3(data.x(1,t-num:t), data.x(2,t-num:t), data.x(3,t-num:t), 'r-', 'LineWidth',1);
            plot3(data.x(1,1:t), data.x(2,1:t), data.x(3,1:t), 'r-', 'LineWidth',1);
        end
%         plot3(data.x(1,t-num:t), data.x(2,t-num:t), data.x(3,t-num:t), 'r-');

        %==========================================
        % Update the drawing. (dynamic axis)     
        if data.x(1,t) > 0
            xmin = -3;
            xmax = data.x(1,t)+3;
        else 
            xmin = data.x(1,t)-3;
            xmax = 3;
        end
        
        if data.x(2,t) > 0
            ymin = -3;
            ymax = data.x(2,t)+3;
        else
            ymin = data.x(2,t)-3;
            ymax = 3;
        end        
        zmin = 0;
        zmax = data.x(3,t)+5;
        
        %fixed xyz axis
        xmin = -15; xmax = 15;
        ymin = -1; ymax = 30;
        zmin = -1; zmax = 6;
        %==========================================
        
        axis([xmin xmax ymin ymax zmin zmax]);
%         drawnow limitrate
        drawnow

        % Use the bottom two parts for angular velocity and displacement.
%         subplot(plots(2));
%         multiplot(data, rad2deg(data.angvel), t, -25, 25);
%         xlabel('Time (s)');
%         ylabel('Angular Velocity (deg/s)');
%         legend('roll', 'pitch', 'yaw');
%         title('Angular Velocity');

%         subplot(plots(3));
%         multiplot(data, data.vel, t, -30,30);
%         xlabel('Time (s)');
%         ylabel('Linear Velocity (m/s)');
%         legend('x', 'y', 'z');
%         title('Linear Velocity');
        
        % Use the bottom two parts for angular and linear displacement.
        subplot(plots(2));
        multiplot(data, rad2deg(data.theta), t);
        xlabel('Time (s)');
        ylabel('Angular Position (deg)');
        legend('roll', 'pitch', 'yaw');
        title('Angular Position');
                
        subplot(plots(3));
        multiplot(data, data.x, t);
        xlabel('Time (s)');
        ylabel('Linear Position (m)');
        legend('x', 'y', 'z')
        title('Linear Poistion');
    end
%     drawnow
end

% Plot three components of a vector in RGB.
function multiplot(data, values, ind)
    % Select the parts of the data to plot.
    times = data.t(:, 1:ind);
    values = values(:, 1:ind);

    % Plot in RGB, with different markers for different components.
    plot(times, values(1, :), 'r-', times, values(2, :), 'g.', times, values(3, :), 'b-.');
    
    % Set axes to remain constant throughout plotting.
    xmin = min(data.t);
    xmax = max(data.t);
    
    ymin = 1.1 * min(min(values));
    ymax = 1.1 * max(max(values));
    if ymin == 0 && ymax == 0
        ymax = 1;
    end
    axis([xmin xmax ymin ymax]);
end

function [h] = rover()

    a = 1;      %upper
    b = 1;      %lower 
    B = 0.6;      %width
    w = B/2;    %half width
    l = 1;      %height
    p1 = [-w, -b, 0];
    p2 = [w, -b, 0];
    p3 = [w, a, 0];
    p4 = [-w, a, 0];
    p5 = [-w, -b, l];
    p6 = [w, -b, l];
    p7 = [w, a, l];
    p8 = [-w, a, l];
    
    p1 = [-b, -w, 0];
    p2 = [b, -w, 0];
    p3 = [a, w, 0];
    p4 = [-a, w, 0];
    p5 = [-b, -w, l];
    p6 = [b, -w, l];
    p7 = [a, w, l];
    p8 = [-a, w, l];
    
    x = [p1(1) p2(1) p3(1) p4(1)];
    y = [p1(2) p2(2) p3(2) p4(2)];
    z = [p1(3) p2(3) p3(3) p4(3)];
    h(1) = fill3(x,y,z,1);hold on;
    
    x = [p5(1) p6(1) p7(1) p8(1)];
    y = [p5(2) p6(2) p7(2) p8(2)];
    z = [p5(3) p6(3) p7(3) p8(3)];
    h(2) = fill3(x, y, z, 2);hold on; 
    
    x = [p2(1) p6(1) p7(1) p3(1)];
    y = [p2(2) p6(2) p7(2) p3(2)];
    z = [p2(3) p6(3) p7(3) p3(3)];
    h(3) = fill3(x, y, z, 3);hold on; 
 

    x = [p1(1) p5(1) p8(1) p4(1)];
    y = [p1(2) p5(2) p8(2) p4(2)];
    z = [p1(3) p5(3) p8(3) p4(3)];
    h(4) = fill3(x, y, z, 4);hold on; 
    
    x = [p1(1) p2(1) p6(1) p5(1)];
    y = [p1(2) p2(2) p6(2) p5(2)];
    z = [p1(3) p2(3) p6(3) p5(3)];
    h(5) = fill3(x, y, z, 5);hold on; 
    
    x = [p4(1) p3(1) p7(1) p8(1)];
    y = [p4(2) p3(2) p7(2) p8(2)];
    z = [p4(3) p3(3) p7(3) p8(3)];
    h(6) = fill3(x, y, z, 6);hold on; 

    set(h,'FaceAlpha',0.3) ;
       
    
    radius_rotor = l*0.4;
    [x y z] = sphere;
    x = radius_rotor * x;
    y = y*0.2;
    z = radius_rotor * z;
    h(7) = surf(x + a*0.7, y + w, z+l/2, 'EdgeColor', 'none', 'FaceColor', 'b');
    h(8) = surf(x - b*0.7, y - w, z+l/2, 'EdgeColor', 'none', 'FaceColor', 'k');
    h(9) = surf(x + a*0.7, y - w, z+l/2, 'EdgeColor', 'none', 'FaceColor', 'b');
    h(10) = surf(x - b*0.7, y + w, z+l/2, 'EdgeColor', 'none', 'FaceColor', 'k');
    alpha(h(5:8),.3)
    
    
    
    t = hgtransform;
    set(h, 'Parent', t);
    h = t;
end

% Draw a quadcopter. Return a handle to the quadcopter object
% and an array of handles to the thrust display cylinders. 
% These will be transformed during the animation to display
% relative thrust forces.
function [h thrusts] = quadcopter()
    % Draw arms.
%     h(1) = prism(-5, -0.25, -0.25, 10, 0.5, 0.5);
%     h(2) = prism(-0.25, -5, -0.25, 0.5, 10, 0.5);
    
    Xf = 0.1422*1.5;
    Xb = 0.155*1.5;
    Yf = 0.2505*1.5;
    Yb = 0.232*1.5;
    h(1) = iris_arm(Xf, Yf);
    h(2) = iris_arm(-Xb, -Yb);
    h(3) = iris_arm(Xf, -Yf);
    h(4) = iris_arm(-Xb, Yb);

    % Draw bulbs representing propellers at the end of each arm.
%     [x y z] = sphere;
%     x = 0.5 * x;
%     y = 0.5 * y;
%     z = 0.5 * z;
%     h(5) = surf(x - 5, y, z, 'EdgeColor', 'none', 'FaceColor', 'b');
%     h(6) = surf(x + 5, y, z, 'EdgeColor', 'none', 'FaceColor', 'k');
%     h(7) = surf(x, y - 5, z, 'EdgeColor', 'none', 'FaceColor', 'k');
%     h(8) = surf(x, y + 5, z, 'EdgeColor', 'none', 'FaceColor', 'k');
    radius_rotor = 0.15;
    [x y z] = sphere;
    x = radius_rotor * x;
    y = radius_rotor * y;
    z = radius_rotor * z / 1.8;
    h(5) = surf(x + Xf, y + Yf, z+0.03, 'EdgeColor', 'none', 'FaceColor', 'b');
    h(6) = surf(x - Xb, y - Yb, z+0.03, 'EdgeColor', 'none', 'FaceColor', 'k');
    h(7) = surf(x + Xf, y - Yf, z+0.03, 'EdgeColor', 'none', 'FaceColor', 'b');
    h(8) = surf(x - Xb, y + Yb, z+0.03, 'EdgeColor', 'none', 'FaceColor', 'k');
    alpha(h(5:8),.3)
    %body
%     h(9) = prism(-0.02, -0.02, -0.03, 0.04, 0.04, 0.2);
    

    % Draw thrust cylinders.
%     [x y z] = cylinder(0.03, 15);
%     thrusts(1) = surf(x + Xf, y + Yf, z, 'EdgeColor', 'none', 'FaceColor', 'y');
%     thrusts(2) = surf(x - Xb, y - Yb, z, 'EdgeColor', 'none', 'FaceColor', 'b');
%     thrusts(3) = surf(x + Xf, y - Yf, z, 'EdgeColor', 'none', 'FaceColor', 'y');
%     thrusts(4) = surf(x - Xb, y + Yb, z, 'EdgeColor', 'none', 'FaceColor', 'b');

    % Create handles for each of the thrust cylinders.
    for i = 1:4
        x = hgtransform;
%         set(thrusts(i), 'Parent', x);
%         thrusts(i) = x;
    end

    % Conjoin all quadcopter parts into one object.
    t = hgtransform;
    set(h, 'Parent', t);
    h = t;
end

function h = iris_arm(x, y)
    %h = plot3([0,x], [0,y], [0,0]);hold on;
    
    m = 0.02;
    X = [0 0 0 0 x x x x];
    Y = [-m -m m m y-m y-m y+m y+m];
    Z = [-m m -m m -m m -m m];
    
    faces(1, :) = [4 2 1 3];
    faces(2, :) = [4 2 1 3] + 4;
    faces(3, :) = [4 2 6 8];
    faces(4, :) = [4 2 6 8] - 1;
    faces(5, :) = [1 2 6 5];
    faces(6, :) = [1 2 6 5] + 2;

    for i = 1:size(faces, 1)
        h(i) = fill3(X(faces(i, :)), Y(faces(i, :)), Z(faces(i, :)), 'k'); hold on;
    end
    alpha(h,.5);
    
    t = hgtransform;
    set(h, 'Parent', t);
    h = t;
end

% Draw a 3D prism at (x, y, z) with width w,
% length l, and height h. Return a handle to
% the prism object.
function h = prism(x, y, z, w, l, h)
    [X Y Z] = prism_faces(x, y, z, w, l, h);

    faces(1, :) = [4 2 1 3];
    faces(2, :) = [4 2 1 3] + 4;
    faces(3, :) = [4 2 6 8];
    faces(4, :) = [4 2 6 8] - 1;
    faces(5, :) = [1 2 6 5];
    faces(6, :) = [1 2 6 5] + 2;

    for i = 1:size(faces, 1)
        h(i) = fill3(X(faces(i, :)), Y(faces(i, :)), Z(faces(i, :)), 'k'); hold on;
    end

    % Conjoin all prism faces into one object.
    t = hgtransform;
    set(h, 'Parent', t);
    h = t;
end

% Compute the points on the edge of a prism at
% location (x, y, z) with width w, length l, and height h.
function [X Y Z] = prism_faces(x, y, z, w, l, h)
    X = [x x x x x+w x+w x+w x+w];
    Y = [y y y+l y+l y y y+l y+l];
    Z = [z z+h z z+h z z+h z z+h];
end


% Compute rotation matrix for a set of angles.
function R = rotation(angles)
    phi = angles(3);
    theta = angles(2);
    psi = angles(1);

    R = zeros(3);
    R(:, 1) = [
        cos(phi) * cos(theta)
        cos(theta) * sin(phi)
        - sin(theta)
    ];
    R(:, 2) = [
        cos(phi) * sin(theta) * sin(psi) - cos(psi) * sin(phi)
        cos(phi) * cos(psi) + sin(phi) * sin(theta) * sin(psi)
        cos(theta) * sin(psi)
    ];
    R(:, 3) = [
        sin(phi) * sin(psi) + cos(phi) * cos(psi) * sin(theta)
        cos(psi) * sin(phi) * sin(theta) - cos(phi) * sin(psi)
        cos(theta) * cos(psi)
    ];
end

