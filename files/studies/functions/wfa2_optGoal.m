function output = wfa2_optGoal(data)
% Calculates goal for optimization (Sharpe Ratio by default)

% Sharpe Ratio
st = std(data, 1);
idx = max(data) == min(data);
var(idx) = NaN;
var(~idx) = 1 ./ st(~idx);
output = var .* mean(data);