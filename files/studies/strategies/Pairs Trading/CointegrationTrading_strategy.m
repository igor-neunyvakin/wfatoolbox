function [params,sig] = CointegrationTrading_strategy(x,price)
%% Cointegration Trading strategy

%% Declare parameters and optimization range
% Here you may define names of variables and range for optimization 
% by setting PARAMS structure

params.per = 120:60:780;
params.freq = 10:20:420;
params.thresh = 1;

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

% Check for Econometric Toolbox
global start_btn
if ~exist('egcitest.m','file')
    [~,strat_name] = fileparts(mfilename('fullpath'));
    msgbox(['To run the strategy',strat_name,' you need to have Econometric Toolbox'])
    start_btn = 0;
    return
end

% Check for 2 symbols
if ~isfield(price,'symbol2')
    [~,strat_name] = fileparts(mfilename('fullpath'));
    msgbox(['To run the strategy',strat_name,' you need to load 2 symbols'])
    start_btn = 0;
    return
end

len = length(price.symbol1.Price);
s1 = zeros(len,1);
s2 = zeros(len,1);

for i = max(freq,per) : freq : len-freq
    
    % MODEL
    [h,~,~,~,reg1] = egcitest([price.symbol1.Price(i-per+1:i),price.symbol2.Price(i-per+1:i)]);
    res = price.symbol1.Close(i:i+freq-1) ...
        - (reg1.coeff(1) + reg1.coeff(2).*price.symbol2.Price(i:i+freq-1));
    spread = res/reg1.RMSE;

    % RULES
    n1 = 1;
    n2 = reg1.coeff(2)*n1;
    ss1 = zeros(length(spread)-1,1);
    ss2 = zeros(length(spread)-1,1);
    for j = 2:length(spread)
        if spread(j) > thresh
            ss1(j) = -n1;
            ss2(j) = n2;
        elseif spread(j) < -thresh
            ss1(j) = n1;
            ss2(j) = -n2;
        elseif (ss1(j-1) < 0 && spread(j) < 0) || ...
                (ss1(j-1) > 0 && spread(j) > 0)
            ss1(j) = 0;
            ss2(j) = 0;
        else
            ss1(j)  = ss1(j-1);
            ss2(j)  = ss2(j-1);
        end
    end

    s1(i:i+freq-1) = ss1;
    s2(i:i+freq-1) = ss2;
    
end

%% Signals & Cost
% To execute strategy for multiple symbols specify them like this:
% sig.symbol1 = [0 3 1.5 ... -1]; sig.symbol2 = [0 2 -1 ... 0.5] etc.

% signals
sig.symbol1 = s1;
sig.symbol2 = s2;

