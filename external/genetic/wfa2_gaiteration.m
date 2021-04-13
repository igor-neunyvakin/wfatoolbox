function wfa2_gaiteration(gaDat)
%  Optional user task executed at the end of each iteration

% stop if pushed
global start_btn
if start_btn == 0
    return
end

% get params
i = gaDat.gen;
len = gaDat.MAXGEN;
handles = gaDat.handles;
steps = gaDat.steps;
strat_num = gaDat.strat_num;

% change progressbar
if strat_num.num == 1
    chunk_num = i;
else
    iter_len = strat_num.all;
    chunk_num = i+sum(iter_len(1:strat_num.num-1));
end
chunk_len = sum(strat_num.all);
wfa2_changeProgressbar(handles,chunk_num,chunk_len,steps)



