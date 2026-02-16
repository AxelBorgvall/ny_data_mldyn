% plot_amp.m
% Loads ARX models and plots the evolution of Poles and Zeros.
% Color Gradient: Blue (Start/Low Amp) -> Red (End/High Amp).

clear; clc; close all;

% --- Configuration ---
loadFile = 'arx_models.mat';

% --- Load Models ---
if ~exist(loadFile, 'file')
    error('File not found: %s. Run fit_arx.m first.', loadFile);
end

load(loadFile, 'models', 'start_indices');

num_models = length(models);
if num_models == 0
    error('No models found in %s', loadFile);
end

fprintf('Loading %d models for plotting...\n', num_models);

% --- Plotting ---
figure('Name', 'Pole-Zero Evolution', 'Color', 'w', 'Position', [100, 100, 800, 600]);
hold on; grid on; axis equal;

% Plot Unit Circle
theta = linspace(0, 2*pi, 200);
plot(cos(theta), sin(theta), 'k--', 'LineWidth', 1, 'DisplayName', 'Unit Circle');

% Loop through models
for i = 1:num_models
    sys = models{i};
    
    % Calculate Color: Blue (Earliest) -> Red (Latest)
    % Linear interpolation: Blue=[0,0,1] to Red=[1,0,0]
    if num_models > 1
        alpha = (i - 1) / (num_models - 1);
    else
        alpha = 0;
    end
    color = [alpha, 0, 1 - alpha];
    
    [p, z] = pzmap(sys);
    
    % Plot Poles (x)
    if ~isempty(p)
        plot(real(p), imag(p), 'x', 'Color', color, 'MarkerSize', 8, 'LineWidth', 1.5, 'HandleVisibility', 'off');
    end
    
    % Plot Zeros (o)
    if ~isempty(z)
        plot(real(z), imag(z), 'o', 'Color', color, 'MarkerSize', 6, 'LineWidth', 1.5, 'HandleVisibility', 'off');
    end
end

% Formatting
xlabel('Real Axis');
ylabel('Imaginary Axis');
title(sprintf('Pole-Zero Evolution (N=%d Models)', num_models));
xlim([-1.5 1.5]);
ylim([-1.5 1.5]);

% Create custom colormap for the colorbar to match the plot (Blue -> Red)
map = [linspace(0, 1, 256)', zeros(256, 1), linspace(1, 0, 256)'];
colormap(map);
c = colorbar;
c.Label.String = 'Data Segment (Blue=Start, Red=End)';
c.Ticks = [0 1];
c.TickLabels = {'Start (Low Amp)', 'End (High Amp)'};