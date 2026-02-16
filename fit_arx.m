% fit_arx.m
% Fits ARX models to sliding windows of the data to analyze dynamics over amplitude.
% Range: 0-40000 (Increasing amplitude).
% Window: 300 samples.
% Stride: Every 3rd slice (Step = 900).

clear; clc; close all;

% --- Configuration ---
dataFile = fullfile('data', 'SNLS80mV.csv');
saveFile = 'arx_models.mat';

max_idx = 40000;
slice_len = 300;
stride = 3 * slice_len; % "Every third 300 length slice" -> Step 900

% Model Order: ARX(na=2, nb=2, nk=1)
na = 2; nb = 2; nk = 1;

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

% --- Pretreatment ---
% Global detrending to match interval_eval.m
u_raw = detrend(u_raw);
y_raw = detrend(y_raw);

% Create IDDATA
Ts = 1; 
data_full = iddata(y_raw, u_raw, Ts);

% --- Fitting Loop ---
models = {};
start_indices = [];

fprintf('Fitting ARX(%d,%d,%d) models on interval 1 to %d...\n', na, nb, nk, max_idx);

current_idx = 1;

while current_idx + slice_len - 1 <= max_idx
    % Extract slice
    data_slice = data_full(current_idx : current_idx + slice_len - 1);
    
    % Fit Model
    models{end+1} = arx(data_slice, [na nb nk]); %#ok<SAGROW>
    start_indices(end+1) = current_idx; %#ok<SAGROW>
    
    % Move to next start index (Skip 2 slices, take the 3rd)
    current_idx = current_idx + stride;
end

% --- Save Results ---
save(saveFile, 'models', 'start_indices');
fprintf('Done. Fitted %d models. Saved to %s.\n', length(models), saveFile);