% datacheck.m
% Script to load, normalize, and plot data from SNLS80mV.csv and Schroeder80mV.mat

clear; clc; close all;

% Define paths
baseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(baseDir, 'data');

%% 1. Process SNLS80mV.csv
csvFile = fullfile(dataDir, 'SNLS80mV.csv');

if exist(csvFile, 'file')
    fprintf('Processing %s...\n', csvFile);
    
    % Load data
    opts = detectImportOptions(csvFile);
    opts.VariableNamingRule = 'preserve';
    T_snls = readtable(csvFile, opts);
    
    % Remove columns that are purely NaN (often caused by trailing commas in CSVs)
    isAllNaN = varfun(@(x) all(isnan(x)), T_snls, 'OutputFormat', 'uniform');
    T_snls(:, isAllNaN) = [];
    
    % Convert to array and normalize
    data_snls = table2array(T_snls);
    data_snls_norm = normalize(data_snls);
    
    % Plot Input
    figure('Name', 'SNLS80mV - Input', 'NumberTitle', 'off');
    plot(data_snls_norm(:, 1));
    title('Normalized SNLS80mV Input (V1)');
    xlabel('Sample'); ylabel('Amplitude (\sigma)');
    grid on;

    % Plot Output
    figure('Name', 'SNLS80mV - Output', 'NumberTitle', 'off');
    plot(data_snls_norm(:, 2));
    title('Normalized SNLS80mV Output (V2)');
    xlabel('Sample'); ylabel('Amplitude (\sigma)');
    grid on;
else
    warning('File not found: %s', csvFile);
end

%% 2. Process Schroeder80mV.mat
% matFile = fullfile(dataDir, 'Schroeder80mV.mat');

% if exist(matFile, 'file')
%     fprintf('Processing %s...\n', matFile);
    
%     % Load data
%     data_schroeder = load(matFile);
    
%     if isfield(data_schroeder, 'V1') && isfield(data_schroeder, 'V2')
%         v1_norm = normalize(double(data_schroeder.V1));
%         v2_norm = normalize(double(data_schroeder.V2));

%         figure('Name', 'Schroeder80mV - Input', 'NumberTitle', 'off');
%         plot(v1_norm);
%         title('Normalized Schroeder80mV Input (V1)');
%         xlabel('Sample'); ylabel('Amplitude (\sigma)'); grid on;

%         figure('Name', 'Schroeder80mV - Output', 'NumberTitle', 'off');
%         plot(v2_norm);
%         title('Normalized Schroeder80mV Output (V2)');
%         xlabel('Sample'); ylabel('Amplitude (\sigma)'); grid on;
%     else
%         warning('Expected variables V1 and V2 not found in %s', matFile);
%     end
% else
%     warning('File not found: %s', matFile);
% end