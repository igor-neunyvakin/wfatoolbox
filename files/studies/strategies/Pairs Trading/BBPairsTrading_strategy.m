function [params,sig] = BBPairsTrading_strategy(x,price)
%% Bollinger Bands Pairs Trading strategy

%% Declare parameters and optimization range
% Here you may define names of variables and range for optimization 
% by setting PARAMS structure

params.per = 100:30:200;    % period of detrending
params.bbper =  [4:2:12, 15:5:35, 40:10:50];    % period of detrending

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

%% Indicator calculation
% To use price time series of other symbols you can get them as follow: 
% price.symbol1.Price, price.symbol1.High, price.symbol2.Close etc.
% Also you can specify the exact symbol like this: 
% price.AAPL.Close, price.IBM.Volume etc.

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
    
% MODEL
% normalize
price1 = [0;diff(price.symbol1.Price)]./price.symbol1.Price;
price2 = [0;diff(price.symbol2.Price)]./price.symbol2.Price;

% remove trend
if length(price1) <= per
    per = length(price1);
end
ma1 = indicators(price1,'sma',per);
ma2 = indicators(price2,'sma',per);
price1d = price1-ma1;
price2d = price2-ma2;
spread = price1d - price2d;

% bollinger bands
output= indicators(spread,'boll',bbper,1,2);
middle = output(:,1);
upper = output(:,2);
lower = output(:,3);

%% Signals & Cost
% To execute strategy for multiple symbols specify them like this:
% sig.symbol1 = [0 3 1.5 ... -1]; sig.symbol2 = [0 2 -1 ... 0.5] etc.

% RULES
n1 = 1;
ss1 = zeros(length(spread),1);
ss2 = zeros(length(spread),1);
for j = 2:length(spread)
    n2 = price.symbol1.Price(j)/price.symbol2.Price(j);
    if spread(j) > upper(j)
        ss1(j) = -n1;
        ss2(j) = n2;
    elseif spread(j) < lower(j)
        ss1(j) = n1;
        ss2(j) = -n2;
    elseif (ss1(j-1) < 0 && middle(j) < 0) || ...
            (ss1(j-1) > 0 && middle(j) > 0)
        ss1(j) = 0;
        ss2(j) = 0;
    else
        ss1(j)  = ss1(j-1);
        ss2(j)  = ss2(j-1);
    end
end
    
% signals
sig.symbol1 = ss1;
sig.symbol2 = ss2;

