function [params,sig,cost] = CrossExchangeArbitrage(x,price)
%% Cross Exchange Arbitrage Strategy
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
%   Copyright 2019, https://wfatoolbox.com

%% Declare parameters and optimization range
% Here you can define names of variables and range for optimization
% by setting PARAMS structure

params.thresh = 1:10;

%% Warning! Don't change this block of code
% You can skip this block of code
var_names = fieldnames(params);
for i = 1:length(var_names)
if ~isempty(x)
      eval([var_names{i},'=',num2str(x(i)),';']);
   else
      eval([var_names{i},'=',num2str(params.(var_names{i})(1)),';']);
   end
end

%% Processing
% Here you can do any calculations for your strategy

% Check for 2 symbols
global start_btn
if ~isfield(price,'symbol2')
    [~,strat_name] = fileparts(mfilename('fullpath'));
    msgbox(['To run the strategy',strat_name,' you need to load 2 historical data for the same symbol from 2 exchanges'])
    start_btn = 0;
    return
end

symbol1 = price.symbol1.Price;
symbol2 = price.symbol2.Price;

arb = (symbol2 - symbol1)./symbol2;

%% Signals
% Here you can fill out signals variable SIG

thresh_buy = thresh*mean(abs(arb));
thresh_sell = -thresh_buy;

% signals
n1 = 1;
s = zeros(length(arb)-1,1);
for j = 2:length(arb)

    % buy/sell
    if arb(j) > thresh_buy
        s(j) = n1;
    elseif arb(j) < thresh_sell
        s(j) = -n1;
    elseif (arb(j) > 0 && s(j-1) < 0) || ...
            (arb(j) < 0 && s(j-1) > 0)
        s(j) = 0;
    else
        s(j)  = s(j-1);
    end
    
end

sig.symbol1 = s;
sig.symbol2 = -s;

