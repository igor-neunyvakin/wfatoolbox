function sig = wfa_timestop(data,bars,sig)
%% Time Stop
%
% data - historical asset time series
% bars - number of bars
% sig - signals
%
% Copyright 2015, WFAToolbox (http://wfatoolbox.com)

count = -1;
ex = false;
if ~isnan(bars) && bars ~= 0
    ds = [0; diff(sig)];
    for i = 2:length(data)
        % algorithm
        if ds(i)~=0 % open position
            ex = false;
        end
        if ex == false
            count = count + 1;
        end
        % execute timestop
        if count == bars || ex
            sig(i) = 0;
            count = -1;
            ex = true;
        end
    end % end for
end % end if