function sig = wfa_stoploss(data,stp,sig)
%% Simple Stop Loss
%
% data - historical asset time series
% stp - stop loss value
% sig - signals
%
% Copyright 2015, WFAToolbox (http://wfatoolbox.com)

ex = 0;
if ~isnan(stp) && stp ~= 0
    ds = [0; diff(sig)];
    SL = NaN;
    for i = 2:length(data)
        % set stop-loss
        if ds(i) > 0 % open long
            SL = (1-stp)*data(i);
            ex = 0;
        elseif ds(i) < 0 % open short
            SL = (1+stp)*data(i);
            ex = 0;
        end
        % execute stop-loss
        if (sig(i) > 0 && data(i) < SL) || (sig(i) < 0 && data(i) > SL) || ex == 1
            sig(i) = 0;
            ex = 1;
        end
    end % end for
end % end if