%% SILVERBOX: THE FINAL COMPARISON (Linear vs Nonlinear)
clear; close all; clc;

% --- 1. Load & Preprocess Data ---
load('SNLS80mV.mat'); 
V1 = V1(:) - mean(V1); 
V2 = V2(:) - mean(V2);
fs = 10^7 / 2^14; Ts = 1/fs;

% Define Datasets
% A. Nonlinear Training Data (Multisine Section)
uTrain = V1(40650:40650+1023*4);
yTrain = V2(40650:40650+1023*4);
zTrain = iddata(yTrain, uTrain, Ts);

% B. Validation/Sweep Data (Triangular Sweep Section)
sweep_range = 1:40500;
zSweep = iddata(V2(sweep_range), V1(sweep_range), Ts);


% --- 2. DEFINE TEST WINDOWS (Low vs High Amplitude) ---
N_window = 800;

% Low Amplitude Window (Early)
start_low = 2000; 
idx_low   = start_low : (start_low + N_window - 1);
zLow      = zSweep(idx_low);

% High Amplitude Window (Late)
start_high = 35000; 
idx_high   = start_high : (start_high + N_window - 1);
zHigh      = zSweep(idx_high);


% --- 3. TRAIN THE MODELS ---
disp('Training Models...');

% A. Linear Models (Trained on specific windows)
sys_lin_low  = arx(zLow, [2 2 1]);  % Trained only on Low data
sys_lin_high = arx(zHigh, [2 2 1]); % Trained only on High data

% B. Nonlinear Model (Trained on Multisine)
% Using your verified structure: [2 5 0] with cubic lags 1, 2, 3
custom_regs = {'y1(t-1)^3', 'y1(t-2)^3', 'y1(t-3)^3'};
opt = nlarxOptions('Focus', 'simulation');
sys_nlarx = nlarx(zTrain, [2 5 0], 'linear', 'CustomRegressors', custom_regs, opt);


% --- 4. SIMULATE ALL MODELS ON FULL SWEEP ---
disp('Simulating...');
y_lin_low  = sim(sys_lin_low,  zSweep.InputData);
y_lin_high = sim(sys_lin_high, zSweep.InputData);
y_nlarx    = sim(sys_nlarx,    zSweep.InputData);

% Calculate Fits for the specific windows
% Linear Fits
fit_lin_low_on_low   = getFit(zLow.OutputData,  y_lin_low(idx_low));
fit_lin_high_on_low  = getFit(zLow.OutputData,  y_lin_high(idx_low));
fit_lin_low_on_high  = getFit(zHigh.OutputData, y_lin_low(idx_high));
fit_lin_high_on_high = getFit(zHigh.OutputData, y_lin_high(idx_high));

% Nonlinear Fits
fit_nlarx_on_low  = getFit(zLow.OutputData,  y_nlarx(idx_low));
fit_nlarx_on_high = getFit(zHigh.OutputData, y_nlarx(idx_high));


% --- 5. PLOTTING THE 5-PANEL FIGURE ---
figure('Name', 'Linear vs Nonlinear: The Definitive Comparison', 'Position', [100, 100, 1200, 800]);

% PLOT 1: Input Sweep (Spanning Top)
subplot(3, 2, 1:2);
plot(zSweep.SamplingInstants, zSweep.InputData, 'k');
ylabel('Input Voltage (V)'); title('1. Input Amplitude Sweep');
axis tight; ylim([-0.3 0.3]); hold on;
% Highlight windows
x_l = zSweep.SamplingInstants(idx_low);
x_h = zSweep.SamplingInstants(idx_high);
fill([x_l(1) x_l(end) x_l(end) x_l(1)], [-0.3 -0.3 0.3 0.3], 'b', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
fill([x_h(1) x_h(end) x_h(end) x_h(1)], [-0.3 -0.3 0.3 0.3], 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
legend('Input', 'Low Amp Window', 'High Amp Window');

% PLOT 2: Linear Models @ LOW Amp
subplot(3, 2, 3);
plot(zLow.SamplingInstants, zLow.OutputData, 'k', 'LineWidth', 1.5); hold on;
plot(zLow.SamplingInstants, y_lin_low(idx_low), 'b--');
plot(zLow.SamplingInstants, y_lin_high(idx_low), 'r--');
title({['2. Linear Models on LOW Amplitude']; ['Local Model: ' num2str(fit_lin_low_on_low,'%.1f') '% | High Model: ' num2str(fit_lin_high_on_low,'%.1f') '%']});
ylabel('Output (V)'); grid on;
legend('Measured', 'Low Model (Correct)', 'High Model (Wrong)');

% PLOT 3: Linear Models @ HIGH Amp
subplot(3, 2, 4);
plot(zHigh.SamplingInstants, zHigh.OutputData, 'k', 'LineWidth', 1.5); hold on;
plot(zHigh.SamplingInstants, y_lin_low(idx_high), 'b--');
plot(zHigh.SamplingInstants, y_lin_high(idx_high), 'r--');
title({['3. Linear Models on HIGH Amplitude']; ['Low Model: ' num2str(fit_lin_low_on_high,'%.1f') '% | Local Model: ' num2str(fit_lin_high_on_high,'%.1f') '%']});
grid on;
legend('Measured', 'Low Model (Wrong)', 'High Model (Correct)');

% PLOT 4: Nonlinear Model @ LOW Amp
subplot(3, 2, 5);
plot(zLow.SamplingInstants, zLow.OutputData, 'k', 'LineWidth', 1.5); hold on;
plot(zLow.SamplingInstants, y_nlarx(idx_low), 'g--', 'LineWidth', 1.5);
title({['4. Nonlinear Model on LOW Amplitude']; ['Fit: ' num2str(fit_nlarx_on_low,'%.1f') '%']});
xlabel('Time (s)'); ylabel('Output (V)'); grid on;
legend('Measured', 'NLARX Model');

% PLOT 5: Nonlinear Model @ HIGH Amp
subplot(3, 2, 6);
plot(zHigh.SamplingInstants, zHigh.OutputData, 'k', 'LineWidth', 1.5); hold on;
plot(zHigh.SamplingInstants, y_nlarx(idx_high), 'g--', 'LineWidth', 1.5);
title({['5. Nonlinear Model on HIGH Amplitude']; ['Fit: ' num2str(fit_nlarx_on_high,'%.1f') '%']});
xlabel('Time (s)'); grid on;
legend('Measured', 'NLARX Model');

% --- Helper Function for Fit Calculation ---
function fit = getFit(y_meas, y_sim)
    fit = (1 - norm(y_meas - y_sim) / norm(y_meas - mean(y_meas))) * 100;
end