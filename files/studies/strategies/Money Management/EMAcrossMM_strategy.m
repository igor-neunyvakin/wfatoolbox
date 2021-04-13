function [params,sig] = EMAcrossMM_strategy(x,price)
%% Exponential Moving Averages crossover strategy + Money Management
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
params.lead = [2:2:12, 15:3:20 30:5:80];        % period of lead moving average
params.lag =  [1:1:12, 15:3:25 30:5:80];         % period of lag moving average
params.tp = 0.001:0.003:0.5;            % take profit (% of price)
params.stl = 0.001:0.003:0.01;          % trailing stop loss (% of price)
params.k = 1:10;                               % speed of trailing stop changes

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
lead = round(lead);
lag = round(lag);

% INDICATORS
% Can be defined by you, taken from FileExchange etc.
% To get more info about what indicators are available
% enter "edit indicators" in the command window
lead_ma = indicators(price.Price,'sma',lead);
lag_ma = indicators(price.Price,'sma',lead+lag);

%% Signals calculation
% The main goal is to fill out signals variable SIG
% from state like this:

% RULES
sig(lead_ma >= lag_ma) = 2; % buy 1 amount of asset
sig(lead_ma < lag_ma) = -2; % sell short 1 amount of asset

%% Money Management
sig = wfa_takeprofit(price.Price,tp,sig);
% sig = wfa_stoploss(price.Price,stl,sig);
sig = wfa_trailingstop(price.Price,stl,sig,k);
