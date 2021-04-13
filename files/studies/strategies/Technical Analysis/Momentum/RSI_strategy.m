function [params,sig] = RSI_strategy(x,price)
%% Relative Strength Index strategy
%   With this simple steps you may use any MATLAB functions and create your own strategy. 
%   Just follow this 4 steps:
%
%   1. Function must contain input variables (price,x) and output variables [params,sig]
%   like this:
%
%      [params,sig] = mystrategy(price,x)
%
%   2. Define names and range of variables and range for optimization 
%   by setting PARAMS structure in the upper part of the code. For example:
%
%     params.var = 2:2:55;
%
%   3. Get the price data from structure PRICE and calculate what you need. For
%   example, a technical indicator;
%
%     output = indicator(price.Close,var);
%
%   4. Set signals by filling out a variable SIG. For example:
%
%     sig(output > 0) = 1
%     sig(output <= 0) = -1
%
%   Copyright 2018, https://wfatoolbox.com

%% Declare parameters and optimization range
% Here you should define names of variables and 
% range for optimization by setting PARAMS structure

% OPTIMIZATION RANGE
params.per =  [2:2:12, 15:3:35, 40:5:60];         % period
params.thresh = 0:5:30;

%% Warning! Don't change this block of code
% Keep this block of code as it is
var_names = fieldnames(params);
for i = 1:length(var_names)
    % 'x' is a vector of optimising parameters
    if ~isempty(x)
        eval([var_names{i},'=',num2str(x(i)),';']);
    else
        eval([var_names{i},'=',num2str(params.(var_names{i})(1)),';']);
    end
end
sig = zeros(length(price.Price),1);

%% Indicator calculation
% You can use any loaded data columns like:
% price.Close, price.Date, price.Volume, price.Bid etc.
% price.Price is universal and depends on
% available data column names (Close, Price, Bid)

% ROUNDING 
% is necessary for "genetic" optimization
per = round(per);

% INDICATORS
% Can be defined by you, taken from FileExchange etc.
% To get more info about what indicators are available
% enter "edit indicators" in the command window
rsi = indicators(price.Price,'rsi',per);

%% Signals calculation
% The main goal is to fill out signals variable SIG
% from state like this:

% RULES
lower_thresh = 50-thresh;
upper_thresh = 50+thresh;
for i = 2:length(price.Close)
    if rsi(i) > upper_thresh && rsi(i-1) < upper_thresh
        sig(i) = -1;
    elseif rsi(i) < lower_thresh && rsi(i-1) > lower_thresh
        sig(i) = 1;
    elseif (sig(i-1) < 0 && rsi(i) > 50) || ...
              (sig(i-1) > 0 && rsi(i) < 50)
        sig(i) = 0;
    else
        sig(i) = sig(i-1);
    end
end

