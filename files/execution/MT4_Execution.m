function execute = MT4_Execution(sig,symbol,lot)
%% Open/Close Order

global position order_num

% type
if sig(end) > 0
    type = 'buy';
elseif sig(end) < 0
    type = 'sell';
else
    type = 'close';
end

% execution
if ~strcmp(position,type)
    execute = true;
else
    execute = false;
end

% execution
if execute
    if ~strcmp(type,'close') 
        
        % close position
        if ~isempty(position) && ~strcmp(position,'close')
            data = wfa2_mt4_closeorder(order_num);
        end
        
        % open position 
        [order_num, data] = wfa2_mt4_marketorder(type,lot,symbol);
        position = type;
        
    else % close position
        data = wfa2_mt4_closeorder(order_num);
    end
end