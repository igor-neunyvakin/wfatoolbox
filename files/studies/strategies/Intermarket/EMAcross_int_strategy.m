function [params,sig] = EMAcross_int_strategy(x,price)
%% Exponential Moving Averages crossover strategy
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
params.lead = [2:2:12, 15:5:35, 40:10:50];        % period of lead moving average
params.lag =  [5:2:12, 15:5:50, 60:10:100];       % period of lag moving average
    
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

% Check for 2 symbols
global start_btn
if ~isfield(price,'symbol2')
    [~,strat_name] = fileparts(mfilename('fullpath'));
    msgbox(['To run the strategy',strat_name,' you need to load 2 symbols'])
    start_btn = 0;
    return
end

% ROUNDING 
% is necessary for "genetic" optimization
lead = round(lead);
lag = round(lag);

% INDICATORS
% Can be defined by you, taken from FileExchange etc.
% To get more info about what indicators are available
% enter "edit indicators" in the command window
lead_ma = indicators(price.symbol2.Price,'ema',lead,0.7);   % lead MA of price 2
lag_ma = indicators(price.symbol2.Price,'ema',lag,0.7);       % lag MA of price 2

%% Signals calculation
% The main goal is to fill out signals variable SIG
% from state like this:

% RULES
sig(lead_ma >= lag_ma) = -1; % buy 1 amount of asset
sig(lead_ma < lag_ma) = 1; % sell short 1 amount of asset

