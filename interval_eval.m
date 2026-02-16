% interval_eval.m
% Evaluates how the length of the data interval affects model convergence.
% Fits ARX, ARMAX, and OE models for increasing data lengths n.

clear; clc; close all;

% --- Configuration ---
dataFile = fullfile('data', 'SNLS80mV.csv');
const_start_idx = 40650; % From input_vs_noise.m
val_start_idx = 50000;
val_end_idx = 55000;

% Interval settings
n_start = 20;
n_step = 20;
n_max = 500; % Adjust based on available data and processing time
n_values = n_start:n_step:n_max;

% Model Orders (Guessing reasonable orders, can be tuned)
na = 4; nb = 4; nk = 0; nc = 2; nf = 4;

% na = 2; nb = 2; nk = 0; nc = 2; nf = 2;
% --- Load Data ---
if ~exist(dataFile, 'file')
    error('File not found: %s', dataFile);
end

opts = detectImportOptions(dataFile);
opts.VariableNamingRule = 'preserve';
T = readtable(dataFile, opts);

u_raw = T.V1;
y_raw = T.V2;

% Handle NaNs
if any(isnan(u_raw)), u_raw = u_raw(~isnan(u_raw)); end
if any(isnan(y_raw)), y_raw = y_raw(~isnan(y_raw)); end

% Prepare Data Object
Ts = 1; % Sampling time (normalized)
data_full = iddata(y_raw, u_raw, Ts);

% Prepare Validation Data
data_val = data_full(val_start_idx : val_end_idx);
data_val = detrend(data_val);

% Preallocate results
fits_arx = zeros(length(n_values), 1);
fits_armax = zeros(length(n_values), 1);
fits_oe = zeros(length(n_values), 1);

fprintf('Starting interval evaluation...\n');

for i = 1:length(n_values)
    n = n_values(i);
    
    % Ensure we don't exceed data bounds
    if (const_start_idx + n - 1) > size(data_full, 1)
        warning('Requested interval exceeds data length. Stopping early.');
        n_values = n_values(1:i-1);
        fits_arx = fits_arx(1:i-1);
        fits_armax = fits_armax(1:i-1);
        fits_oe = fits_oe(1:i-1);
        break;
    end
    
    % Extract subset
    data_sub = data_full(const_start_idx : const_start_idx + n - 1);
    data_sub = detrend(data_sub); % Important for linear models
    
    % Fit Models
    m_arx = arx(data_sub, [na nb nk]);
    m_armax = armax(data_sub, [na nb nc nk]);
    m_oe = oe(data_sub, [nb nf nk]);
    
    % Evaluate Fit (Normalized Root Mean Squared Error or Fit %)
    % compare returns the fit percentage by default
    [~, fit_arx] = compare(data_val, m_arx);
    [~, fit_armax] = compare(data_val, m_armax);
    [~, fit_oe] = compare(data_val, m_oe);
    
    fits_arx(i) = fit_arx;
    fits_armax(i) = fit_armax;
    fits_oe(i) = fit_oe;
    
    fprintf('n = %d: ARX=%.2f%%, ARMAX=%.2f%%, OE=%.2f%%\n', n, fit_arx, fit_armax, fit_oe);
end

% Clip datapoints for readability
min_fit = -100;
fits_arx(fits_arx < min_fit) = min_fit;
fits_armax(fits_armax < min_fit) = min_fit;
fits_oe(fits_oe < min_fit) = min_fit;

% --- Plot 1: Prediction Quality vs n ---
figure('Name', 'Model Convergence vs Interval Length');
plot(n_values, fits_arx, '-o', 'LineWidth', 1.5, 'DisplayName', 'ARX'); hold on;
plot(n_values, fits_armax, '-s', 'LineWidth', 1.5, 'DisplayName', 'ARMAX');
plot(n_values, fits_oe, '-d', 'LineWidth', 1.5, 'DisplayName', 'OE');
xlabel('Interval Length (samples)');
ylabel('Fit Percentage (%)');
title('Prediction Quality vs Data Length');
legend('Location', 'Best');
grid on;

% --- Plot 2, 3, 4: Poles/Zeros with Uncertainty (for last n) ---
% Using the models from the last iteration
figure('Name', 'ARX Poles/Zeros'); iopzplot(m_arx); showConfidence(iopzplot(m_arx), 3); title(['ARX PZ Map (n=' num2str(n_values(end)) ')']);
figure('Name', 'ARMAX Poles/Zeros'); iopzplot(m_armax); showConfidence(iopzplot(m_armax), 3); title(['ARMAX PZ Map (n=' num2str(n_values(end)) ')']);
figure('Name', 'OE Poles/Zeros'); iopzplot(m_oe); showConfidence(iopzplot(m_oe), 3); title(['OE PZ Map (n=' num2str(n_values(end)) ')']);