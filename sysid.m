%% SILVERBOX SYSTEM IDENTIFICATION - FROM SCRATCH
clear; close all; clc;

% --- 1. Load & Preprocess Data ---
% The website says V1=Input, V2=Output.
load('SNLS80mV.mat'); % Ensure you have the full dataset loaded

V1 = V1(:) - mean(V1); 
V2 = V2(:) - mean(V2);
fs = 10^7 / 2^14; Ts = 1/fs;

% Training Data (First Period)
N = 1024;
uFull = V1(40650:40650+1023*4);
yFull = V2(40650:40650+1023*4);
zTrain = iddata(yFull, uFull);
uValid = V1(1 : 40500);
yValid = V2(1 : 40500);
zValid = iddata(yValid, uValid);

% 2. DEFINE CUSTOM REGRESSORS (The "Widened" Nonlinearity)
% We add cubic terms for lags 1, 2, and 3 to capture the full "smeared" effect.
custom_regs = {'y1(t-1)^3', 'y1(t-2)^3', 'y1(t-3)^3'};

% 3. CONFIGURE MODEL STRUCTURE
% na = 2 (Keep as 2nd order poles)
% nb = 5 (INCREASED: Capture inputs u(t) down to u(t-4) to fix XCorr spikes)
% nk = 0 (Keep Direct Feedthrough)
orders = [2 5 0]; 

% 4. TRAIN
opt = nlarxOptions('Focus', 'simulation');
sys_refined = nlarx(zTrain, orders, 'linear', ...
                    'CustomRegressors', custom_regs, opt);

% 5. VALIDATE
fprintf('Training Complete. Checking Residuals...\n');

% Residuals
figure('Name', 'Refined Residuals');
resid(zValid, sys_refined); 
title('Refined Model: Did nb=5 kill the spikes?');

% Fit Check
figure('Name', 'Final Fit');
compare(zValid, sys_refined);

% 6. LOOK AT THE COEFFICIENTS
fprintf('\nIdentified Terms:\n');
getreg(sys_refined)

% Compare the size of the Signal vs. the Residuals
figure('Name', 'Magnitude Check');
subplot(2,1,1);
plot(zValid.OutputData(1:200)); 
title('Real Output (Signal)'); grid on;

subplot(2,1,2);
resid_data = resid(zValid, sys_refined);
plot(resid_data.OutputData(1:200)); 
title('Residuals (Error)'); grid on;

% Calculate Variance Accounted For (VAF)
vaf_score = (1 - var(resid_data.OutputData) / var(zValid.OutputData)) * 100;
fprintf('Variance Accounted For: %.4f%%\n', vaf_score);