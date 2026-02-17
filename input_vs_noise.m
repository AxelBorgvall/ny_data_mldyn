% input_vs_noise.m
% Analyzes how much of the output dynamics can be explained by the input
% (Linearity) vs Noise/Non-linearities using Coherence.

clear; clc; close all;

% --- Configuration ---
dataFile = fullfile('data', 'SNLS80mV.csv');
% Guessing indices for the "constant amplitude" part. 
% ADJUST THESE based on your visual inspection of the plot!
const_start_idx = 40650; 
const_end_idx = 127200; 

% --- Load Data ---
if ~exist(dataFile, 'file')
    error('File not found: %s', dataFile);
end

opts = detectImportOptions(dataFile);
opts.VariableNamingRule = 'preserve';
T = readtable(dataFile, opts);


u_raw = T.V1; % Input
y_raw = T.V2; % Output

% Handle potential NaNs at the end of CSVs
if any(isnan(u_raw)), u_raw = u_raw(~isnan(u_raw)); end
if any(isnan(y_raw)), y_raw = y_raw(~isnan(y_raw)); end

% Ensure we don't exceed bounds
N = min(length(u_raw), length(y_raw));
const_end_idx = min(const_end_idx, N);

% Extract the constant amplitude section for analysis
u = u_raw(const_start_idx:const_end_idx);
y = y_raw(const_start_idx:const_end_idx);

% Remove mean (Detrend)
u = u - mean(u);
y = y - mean(y);

% --- 1. Time Domain Inspection ---
figure('Name', 'Selected Data Section');
subplot(2,1,1); plot(u); title('Input (V1) - Constant Section'); grid on;
subplot(2,1,2); plot(y); title('Output (V2) - Constant Section'); grid on;

% --- 2. Coherence Analysis ---
% Coherence Cxy(f) = |Pxy(f)|^2 / (Pxx(f) * Pyy(f))
% 1 = Perfect Linear Relationship
% < 1 = Noise or Non-Linear distortion

windowSize = 1024; % Window size for Welch's method
overlap = 512;
nfft = 2048;
fs = 10^7 / 2^14; % Sampling frequency (~610 Hz)

% Calculate PSDs for comparison
[Pxx, f_pxx] = pwelch(u, window(@hann, windowSize), overlap, nfft, fs);
[Pyy, f_pyy] = pwelch(y, window(@hann, windowSize), overlap, nfft, fs);

figure('Name', 'Frequency Domain Analysis');

% Plot 1: Power Spectra (Input vs Output)
subplot(2,1,1);
plot(f_pxx, 10*log10(Pxx), 'LineWidth', 1.2, 'DisplayName', 'Input PSD (u)'); hold on;
plot(f_pyy, 10*log10(Pyy), 'LineWidth', 1.2, 'DisplayName', 'Output PSD (y)');
title('Power Spectral Density (dB)');
xlabel('Frequency (Hz)'); ylabel('Power (dB)');
legend('Location', 'best'); grid on;

% Plot 2: Coherence
subplot(2,1,2);
[Cxy, f] = mscohere(u, y, window( @hann, windowSize), overlap, nfft, fs);
plot(f, Cxy, 'LineWidth', 1.5);
title('Magnitude-Squared Coherence Estimate');
xlabel('Frequency (Hz)');
ylabel('Coherence (0 to 1)');
grid on;
ylim([0 1.1]);

fprintf('Average Coherence: %.4f\n', mean(Cxy));
disp('Note: Deviations from 1.0 indicate Noise OR Non-linearities.');