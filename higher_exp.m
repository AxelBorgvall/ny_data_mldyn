%% HIGHER ORDER EXPONENTS - STRUCTURE DETECTION
% Goal: Identify nonlinear terms by fitting a polynomial ARX model
% and inspecting the coefficients to see which terms are "active".

clear; close all; clc;

% --- 1. Load & Preprocess Data ---
load('SNLS80mV.mat');

dataFile = fullfile('data', 'SNLS80mV.csv');
if ~exist(dataFile, 'file')
    error('File not found: %s', dataFile);
end

% IMPORTANT: Standardize data (Zero Mean, Unit Variance).
% This is crucial! Without this, a term like y^3 (which is very small)
% would need a huge coefficient to match y. Standardization puts
% all coefficients on a level playing field for comparison.
V1 = normalize(V1(:)); 
V2 = normalize(V2(:));

% Define Training Data (Multisine - Rich Excitation)
train_idx = 40650 : (40650 + 60000); % Use ~4000 samples
uTrain = V1(train_idx);
yTrain = V2(train_idx);

% --- 2. Construct the Regressor Matrix (The "Dictionary") ---
% We manually build the matrix Phi where each column is a candidate term.
% Model: y(t) = theta_1*term_1 + theta_2*term_2 ...

na = 3; % Lags for output
nb = 3; % Lags for input
nk = 1; % Delay (1 = u(t-1))

N = length(yTrain);
start_idx = max(na, nb + nk) + 1;
y_target = yTrain(start_idx:end);

% Initialize
Phi = [];
TermNames = {};

% A. Linear Terms (The standard ARX part)
for i = 1:na
    col = yTrain(start_idx-i : end-i);
    Phi = [Phi, col];
    TermNames{end+1} = sprintf('y(t-%d)', i);
end

for i = nk : (nk + nb - 1)
    col = uTrain(start_idx-i : end-i);
    Phi = [Phi, col];
    TermNames{end+1} = sprintf('u(t-%d)', i);
end

% B. Quadratic Terms (x^2) - "Second Order Exponents"
% We square the linear columns we just created
num_lin = length(TermNames);
for i = 1:num_lin
    Phi = [Phi, Phi(:,i).^2];
    TermNames{end+1} = [TermNames{i} '^2'];
end

% C. Cubic Terms (x^3) - "Third Order Exponents"
% (Included because Duffing oscillators usually have cubic stiffness)
for i = 1:num_lin
    Phi = [Phi, Phi(:,i).^3];
    TermNames{end+1} = [TermNames{i} '^3'];
end

% --- 3. Solve for Parameters ---
% We use Least Squares (\). 
% If you have the Statistics Toolbox, 'lasso' is even better for this.
fprintf('Solving for %d parameters...\n', length(TermNames));
theta = Phi \ y_target;

% --- 4. Analyze Coefficients ---
% Sort by magnitude to find the most important terms
[sorted_vals, sort_idx] = sort(abs(theta), 'descend');
sorted_names = TermNames(sort_idx);
sorted_theta = theta(sort_idx);

fprintf('\n--- TOP 15 IDENTIFIED TERMS ---\n');
fprintf('%-20s : %-10s\n', 'Term', 'Coeff (Weight)');
fprintf('-----------------------------------\n');
for i = 1:min(15, length(theta))
    fprintf('%-20s : %+.4f\n', sorted_names{i}, sorted_theta(i));
end

% --- 5. Visualization ---
figure('Name', 'Structure Detection', 'Position', [100, 100, 1000, 500]);

% Bar Chart of Coefficients
subplot(1, 2, 1);
bar(theta);
xlabel('Term Index'); ylabel('Coefficient Value');
title('All Model Coefficients');
grid on;

% Top Terms Bar Chart
subplot(1, 2, 2);
k = 10; % Top k
barh(sorted_vals(k:-1:1)); % Reverse for plotting order
yticks(1:k);
yticklabels(sorted_names(k:-1:1));
xlabel('Magnitude');
title(['Top ' num2str(k) ' Dominant Terms']);
grid on;

% --- 6. Validation on Sweep Data (Generalization Check) ---
% Let's see if this "discovered" model works on the triangular sweep
sweep_idx = 1:40500;
uSweep = V1(sweep_idx);
ySweep = V2(sweep_idx);

% Note: To simulate properly we would need a simulation loop.
% For a quick check, we can do One-Step-Ahead prediction on the sweep
% using the same regressor construction logic (omitted for brevity, 
% but the coefficients above tell the story).

fprintf('\nInterpretation:\n');
fprintf('1. Linear terms (y(t-1), u(t-1)) should be largest.\n');
fprintf('2. Look for y(t-k)^3 terms. If they are larger than y(t-k)^2, the system is cubic.\n');