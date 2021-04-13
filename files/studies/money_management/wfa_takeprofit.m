function sig = wfa_takeprofit(data,tp,sig)
%% Simple Take Profit
%
% data - historical asset time series
% tp - take profit value
% sig - signals
%
% Copyright 2018, WFAToolbox (http://wfatoolbox.com)

extp = false;
if ~isnan(tp) && tp ~= 0
    dstp = [0; diff(sig)];
    TP = NaN;
    for i = 2:length(data)
        % set take profit
        if dstp(i)>0% open long
            TP = (1+tp)*data(i);
            extp = false;
        elseif dstp(i) < 0% open short
            TP = (1-tp)*data(i);
            extp = false;
        end
        % execute stop-loss
        if (sig(i) > 0 && data(i) > TP) ||  (sig(i) < 0 && data(i) < TP)  || extp
            sig(i) = 0;
            extp = true;
        end
    end
end