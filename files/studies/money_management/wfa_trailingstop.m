function sig = wfa_trailingstop(data,stp,sig,k)
%% Traling Stop
%
% data - historical asset time series
% stp - stop loss value
% k - trailing rate
% sig - signals
%
% Copyright 2018, WFAToolbox (http://wfatoolbox.com)


ex = false;
if ~isnan(stp) && stp ~= 0
    ds = [0; diff(sig)];
    SL = NaN;
    for i = 2:length(data)
        % set stop-loss
        if ds(i)>0 % open long
            SL = (1-stp)*data(i);
            ex = false;
        elseif ds(i) < 0 % open short
            SL = (1+stp)*data(i);
            ex = false;
        end
        % trailing
%         k = 1;
        if ~isnan(SL)
            d = diff(data(i-1:i));
            if sig(i) > 0 && d > 0
                SL = SL + d/k;
            elseif sig(i) < 0 && d < 0
                SL = SL - d/k;
            end
        end
        % execute stop-loss
        if (sig(i) > 0 && data(i) < SL) || (sig(i) < 0 && data(i) > SL) || ex
            sig(i) = 0;
            ex = true;
        end
    end % end for
end % end if