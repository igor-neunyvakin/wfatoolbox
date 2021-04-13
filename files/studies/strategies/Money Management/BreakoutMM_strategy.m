function [params,sig] = BreakoutMM_strategy(x,price)
%% Breakout strategy
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
params.period = [15:3:35, 40:5:60];
params.tp = 0.001:0.005:0.5;                        % take profit (% of price)
params.stl = 0.001:0.005:0.01;                      % trailing stop loss (% of price)
params.kf = 1:3:50;                                            % speed of trailing stop changes

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

% CHECK PRICE
global start_btn
if ~isfield(price,'High') || ~isfield(price,'Low')
    [~,strat_name] = fileparts(mfilename('fullpath'));
    msgbox(['To run the strategy',strat_name,' you need to load High and Low data'])
    start_btn = 0;
    return
end

% ROUNDING 
% is necessary for "genetic" optimization
period = round(period);

% INDICATORS
% Can be defined by you, taken from FileExchange etc.
% To get more info about what indicators are available
% enter "edit indicators" in the command window
output = indicators([price.High,price.Low],'hhll',period);
upper = output(:,1);
lower = output(:,2);
middle = output(:,3);

%% Signals calculation
% The main goal is to fill out signals variable SIG
% from state like this:

% RULES
for i = 2:length(price.Price)
    % sell
    if price.Price(i) < lower(i-1) && price.Price(i-1) > lower(i-2)
        sig(i) = -1;
    % buy
    elseif price.Price(i) > upper(i-1) && price.Price(i-1) < upper(i-2)
        sig(i) = 1;
    % close
    elseif (sig(i-1) < 0 && price.Price(i) > middle(i)) || ...
              (sig(i-1) > 0 && price.Price(i) < middle(i))
        sig(i) = 0;
    else
        sig(i) = sig(i-1);
    end
end

%% Money Management
sig = wfa_takeprofit(price.Price,tp,sig);
sig = wfa_trailingstop(price.Price,stl,sig,kf);