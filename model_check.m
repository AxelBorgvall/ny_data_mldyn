% model_check.m
% Fits a model and analyzes residuals (Correlation analysis).
% Includes a visual reference bar at 0.1 for significance.

clear; clc; close all;

% --- Configuration ---
dataFile = fullfile('data', 'SNLS80mV.csv');
const_start_idx = 40650; 
const_end_idx = 60650; % Use the full constant section for the check

% Model Order (Adjust as needed)
na = 7; nb = 5; nc = 2; nk = 1;

% --- Load Data ---
if ~exist(dataFile, 'file')
    error('File not found: %s', dataFile);
end

opts = detectImportOptions(dataFile);
opts.VariableNamingRule = 'preserve';
T = readtable(dataFile, opts);

u_raw = T.V1;
y_raw = T.V2;

if any(isnan(u_raw)), u_raw = u_raw(~isnan(u_raw)); end
if any(isnan(y_raw)), y_raw = y_raw(~isnan(y_raw)); end

% Limit to constant section
N = min(length(u_raw), length(y_raw));
end_idx = min(const_end_idx, N);

u = u_raw(const_start_idx:end_idx);
y = y_raw(const_start_idx:end_idx);

% Create IDDATA and Detrend
data = iddata(y, u, 1);
data = detrend(data);

% --- Fit Model ---
% fprintf('Fitting ARMAX model...\n');
% model = armax(data, [na nb nc nk]);

fprintf('Fitting ARX model...\n');
model = arx(data, [na nb nk]);
% Display Model
present(model);

% --- Residual Analysis ---
% Get residuals (e) and input (u)
[e, ~] = resid(model, data); 
e_vec = e.OutputData;
u_vec = data.InputData;

% Calculate Correlations
max_lag = 50;
[xc_ee, lags] = xcorr(e_vec, max_lag, 'coeff'); % Auto-correlation of error
[xc_ue, ~]    = xcorr(e_vec, u_vec, max_lag, 'coeff'); % Cross-corr error vs input

% --- Plotting ---
figure('Name', 'Model Residual Check', 'Position', [100, 100, 800, 600]);

% 1. Error Autocorrelation
subplot(2, 1, 1);
stem(lags, xc_ee, 'filled', 'k'); hold on;
yline(0.1, 'b', 'LineWidth', 2, 'Label', '0.1 Threshold');
yline(-0.1, 'b', 'LineWidth', 2);
yline(0, 'k-');
title('Autocorrelation of Residuals (Output Error)');
xlabel('Lag'); ylabel('Correlation');
grid on;

% 2. Input-Error Cross-correlation
subplot(2, 1, 2);
stem(lags, xc_ue, 'filled', 'k'); hold on;
yline(0.1, 'b', 'LineWidth', 2, 'Label', '0.1 Threshold');
yline(-0.1, 'b', 'LineWidth', 2);
title('Cross-correlation: Input vs Residuals');
xlabel('Lag'); ylabel('Correlation');
grid on;