% testJoystick.m
clear; clc;

% 1) Check for vrjoystick
if exist('vrjoystick','file') ~= 2
    error('vrjoystick function not found. Make sure you have the VR Toolbox.');
end

% 2) Open joystick #1
try
    joy = vrjoystick(1);
    disp('Gamepad successfully opened as joystick #1.');
catch ME
    error('Failed to open joystick: %s', ME.message);
end

% 3) Poll buttons for 10 seconds
disp('Press any gamepad button—you should see the button vector appear.');
t0 = tic;
while toc(t0) < 10
    [axes, buttons, pov] = read(joy);
    if any(buttons)
        fprintf('Buttons pressed: [%s]\n', num2str(find(buttons)));
    end
    pause(0.1);
end

% 4) Clean up
clear joy
disp('Done testing.');
