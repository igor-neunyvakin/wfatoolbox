function [params,sig] = SVMprediction_strategy(x,price)
% Support Vector Machine forecasting strategy
% Copyright 2019, http://wfatoolbox.com

%% Declare parameters and optimization range
% Here you may define names of variables and range for optimization 
% by setting PARAMS structure

params.win = 200;
params.lead_len = 12;
params.lag_len = 25;
params.macd_len = 5;

params.pr_len = 5;
params.lagging = 2;

%% Warning! Don't change this block of code
% You may skip this block of code
var_names = fieldnames(params);
for i = 1:length(var_names)
    if ~isempty(x)
        eval([var_names{i},'=',num2str(x(i)),';']);
    else
        eval([var_names{i},'=',num2str(params.(var_names{i})(1)),';']);
    end
end
sig = zeros(length(price.Price),1);

%%vparams
% You may get any data that you've loaded with 
% 'Load Data' button in GUI by using structure PRICE

opt_params.lead_len = lead_len;
opt_params.lag_len = lag_len;
opt_params.macd_len = macd_len;

opt_params.pr_len = pr_len;
opt_params.lag = lagging;

%% MODEL
global start_btn

if ~exist('windowize.m','file') % If LSSVM Toolbox hasn't installed   
    
    % Question Dialog
    [~,strat_name] = fileparts(mfilename('fullpath'));
    choice = questdlg(['TO MAKE THE STRATEGY ',strat_name,' WORK PLEASE DOWNLOAD AND ADD TO PATH FREE LSSVM TOOLBOX FROM HERE: http://www.esat.kuleuven.be/sista/lssvmlab/'], ...
        'Additional Tolbox Needed', ...
        'Cancel','Go to the Website','Go to the Website');
    
    % Go to the website
    if strcmp(choice,'Go to the Website')
        url = 'http://www.esat.kuleuven.be/sista/lssvmlab/';
        web(url,'-browser');
    end
    
    % Stop processes
    start_btn = 0;
    return

else % If LSSVM Toolbox has installed

    % walking prediction
    sig = wfa_walking_BKSVM_fun(price.Price,win,opt_params);
    
end

function pos = wfa_walking_BKSVM_fun(price,win,opt_params)
% Support Vector Machine Prediction routine

len = length(price);
pos = zeros(len,1);

%% Testing
for i = 1:len-win-1
    disp(i)
    Pwin = price(i:win+i-1);
    
    %% Processing
    
    % params    
    lead_len = opt_params.lead_len;
    lag_len = opt_params.lag_len;
    macd_len = opt_params.macd_len;
    pr_len = opt_params.pr_len;
    lag = opt_params.lag;
    
    % Indicators
    ma_lead = indicators(Pwin,'sma',lead_len);
    ma_lead(1:lead_len) = repmat(ma_lead(lead_len),lead_len,1);
    ma_lag = indicators(Pwin,'sma',lag_len);
    ma_lag(1:lag_len) = repmat(ma_lag(lag_len),lag_len,1);
    macd = ma_lead - ma_lag;
    macd_filt = indicators(macd,'sma',macd_len);
    
    % Prediction
    X = macd_filt(lag_len+1:end);
    
    Xu = windowize(X,1:lag+1);
    Xtra = Xu(1:end-lag,1:lag); %training set
    Ytra = Xu(1:end-lag,end); %training set
    Xs = X(end-lag+1:end,1); %starting point for iterative prediction
    
    if i == 1
        % Cross-validation is based upon feedforward simulation on the validation set using the feedforwardly
        % trained model
        [gam,sig2] = tunelssvm({Xtra,Ytra,'f',[],[],'RBF_kernel'},'simplex',...
        'crossvalidatelssvm',{10,'mae'});
    end

    % predict next N points
    prediction = predict({Xtra,Ytra,'f',gam,sig2,'RBF_kernel'},Xs,pr_len);
    
    % leading indicator
    macd_pr = [macd_filt(1:end-pr_len);prediction];
    
     %% Signals
   
    %SELL
    if macd_pr(end) > macd_pr(end-1)
        pos(win+i,:) = 1;
    %BUY
    elseif macd_pr(end) < macd_pr(end-1)
        pos(win+i,:) = -1;
    %EXIT
    else
        pos(win+i,:) = pos(win+i-1,:);
    end   
end
