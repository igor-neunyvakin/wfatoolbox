function [params,sig] = EMAdiff_intMM_strategy(x,price)
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
params.per = [2:2:12, 15:3:20 30:5:80 90:10:150];        % period of lead moving average
params.tp = 0.001:0.003:0.5;            % take profit (% of price)
params.stl = 0.001:0.003:0.01;          % trailing stop loss (% of price)
params.k = 1:50;                               % speed of trailing stop changes

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
per = round(per);

% INDICATORS
% Can be defined by you, taken from FileExchange etc.
% To get more info about what indicators are available
% enter "edit indicators" in the command window
% ma = indicators(price.symbol2.Price,'ema',per);
ma = movavg(price.symbol2.Price,'modified',per);
dma = [0;diff(ma)];

%% Signals calculation
% The main goal is to fill out signals variable SIG
% from state like this:

% RULES
sig(dma >= 0) = 1; % buy 1 amount of asset
sig(dma < 0) = -1; % sell short 1 amount of asset

%% Money Management
sig = wfa_takeprofit(price.Price,tp,sig);
% sig = wfa_stoploss(price.Price,stl,sig);
sig = wfa_trailingstop(price.Price,stl,sig,k);