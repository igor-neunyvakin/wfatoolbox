function [pnl,sh] = wfa2_performance_formula(price,sig,cost,scaling)
% Function for calculating performance

% calculate
data = price.Price;                                             % using Close data
ret  = [0; sig(1:end-1).*diff(data) ...                    % calcualte return
    - (abs(diff(sig))/2).*(cost*data(2:end)/100)];    % calculate transaction cost
sh = scaling*wfa2_optGoal(ret);                             % goal for optimization (Sharpe Ratio by default)
pnl = cumsum(ret);                                             % profit and losses
