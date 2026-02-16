%% Parametric Method Evaluation: ARX vs ARMAX vs OE
clear; close all; clc;

% 1. Setup Data
load('SNLS80mV.mat');

% Pre-processing
V1 = V1 - mean(V1); 
V2 = V2 - mean(V2);

% Define full training set (Using 4 periods as per your edited code)
% Note: Removed the transpose ' assuming V1/V2 are columns. 
% If errors occur, put them back: V1(...) -> V1(...)'
uFull = V1(40650:40650+1023*4);
yFull = V2(40650:40650+1023*4);

plot(V1)
figure
plot(V2)

% Quick visual check of raw data
figure('Name', 'Raw Data Check');
subplot(2,1,1); plot(uFull); title('Input (u)'); grid on;
subplot(2,1,2); plot(yFull); title('Output (y)'); grid on;

% Define Validation set (The period AFTER the training set)
% FIXED INDEXING: Ensure validation follows training contiguously
% Training ends at 40650 + 1023*4 = 44742
start_valid = 1;
uValid = V1(start_valid : 40500);
yValid = V2(start_valid : 40500);

zValid = iddata(yValid', uValid');

% Settings for the loop
data_lengths = 50:50:1024*4; 
num_steps = length(data_lengths);

% Storage
fits_arx   = zeros(num_steps, 1);
fits_armax = zeros(num_steps, 1);
fits_oe    = zeros(num_steps, 1);
wn_arx     = zeros(num_steps, 1);
wn_oe      = zeros(num_steps, 1);

%% 2. Iterative Evaluation Loop
disp('Comparing ARX, ARMAX, and OE methods...');

best_fit_val = -Inf;     
best_model   = [];       
best_method  = '';       
best_N       = 0;        

for k = 1:num_steps
    N = data_lengths(k);
    
    % Create subset of training data 
    z_sub = iddata(yFull(1:N)', uFull(1:N)');
    
    % --- Model 1: ARX ---
    m_arx = arx(z_sub, [2 2 1]); 
    
    % --- Model 2: Output Error (OE) ---
    m_oe = oe(z_sub, [2 2 1]);
    
    % --- Model 3: ARMAX ---
    m_armax = armax(z_sub, [2 2 2 1]);
    
    % --- Evaluate on Validation Data ---
    [~, fit1, ~] = compare(zValid, m_arx);
    [~, fit2, ~] = compare(zValid, m_oe);
    [~, fit3, ~] = compare(zValid, m_armax);
    
    % Store fits
    fits_arx(k)   = fit1;
    fits_oe(k)    = fit2;
    fits_armax(k) = fit3;
    
    % --- LOGIC: CHECK FOR NEW BEST MODEL ---
    current_models = {m_arx, m_oe, m_armax};
    current_fits   = [fit1, fit2, fit3];
    current_names  = {'ARX', 'OE', 'ARMAX'};
    
    [max_fit_iter, idx] = max(current_fits);
    
    if max_fit_iter > best_fit_val
        best_fit_val = max_fit_iter;
        best_model   = current_models{idx};
        best_method  = current_names{idx};
        best_N       = N;
    end
    
    % Track Natural Frequency
    [w_a, ~] = damp(m_arx); wn_arx(k) = w_a(1);
    [w_o, ~] = damp(m_oe);  wn_oe(k)  = w_o(1);
end

%% 3. Save and Report Results
fprintf('\n--- WINNER FOUND ---\n');
fprintf('Best Method: %s\n', best_method);
fprintf('Best Fit:    %.2f%%\n', best_fit_val);
fprintf('Data Used:   %d points\n', best_N);

save('BestSilverboxModel.mat', 'best_model');
disp('Model saved to BestSilverboxModel.mat');

%% 4. Visualization: Convergence and Stability
figure('Name', 'Parametric Method Comparison');

subplot(2,1,1);
plot(data_lengths, fits_arx, 'b-o', 'LineWidth', 1.5); hold on;
plot(data_lengths, fits_oe, 'r-s', 'LineWidth', 1.5);
plot(data_lengths, fits_armax, 'g-d', 'LineWidth', 1.5);
grid on;
legend('ARX', 'OE', 'ARMAX', 'Location', 'SouthEast');
ylabel('Validation Fit (%)');
title('Convergence Speed (Fit % on Validation Data)');

subplot(2,1,2);
plot(data_lengths, wn_arx, 'b--'); hold on;
plot(data_lengths, wn_oe, 'r-', 'LineWidth', 2);
grid on;
ylabel('Natural Frequency (rad/s)');
xlabel('Data Length (N)');
legend('ARX Pole', 'OE Pole');
title('Parameter Stability');

%% 5. NEW: Residual Analysis (The "Litmus Test")
% This checks if the model captured all dynamics.
figure('Name', 'Residual Analysis of Best Model');

% "resid" plots the autocorrelation of residuals and cross-corr with input
resid(zValid, best_model); 

title(['Residuals for Best Model (' best_method ')']);

% EXPLANATION FOR THE USER:
% Top Plot (Autocorrelation): 
% If the blue line stays inside the shaded confidence region, 
% the residuals are "white noise" (random). This is GOOD.
% If it spikes outside, your model missed some dynamics (likely nonlinear).
%
% Bottom Plot (Cross-correlation):
% Checks if residuals are correlated with the input.
% Spikes here mean the model missed some causal relationship.

