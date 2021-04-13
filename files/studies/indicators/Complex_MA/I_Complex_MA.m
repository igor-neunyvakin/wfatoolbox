function [I_C_MA, TRIX] = I_Complex_MA(Indicator, Price_Series, Lag, Factor)
%I_Complex_MA outputs the specified type of moving average
%   
%   Indicator is char (not case sensitive) that specifies which indicator
%       'DEMA' computes Mulloy double exponential MA
%       'TEMA' computes Mulloy triple exponential MA
%       'EHMA' computes Hull MA (exponential)
%       'WHMA' computes Hull MA (weighted)
%       'TRIX' computes three-times exponential MA
%       'T3'   computes Tillson T3 MA
%       'KMA'  computes Kaufman adaptive MA
%   Price_Series is a vertical vector of prices (usually adjusted close) of the underlying security
%   Lag (positive integer) specifies number of prior samples (bars)
%       Only for Kaufman, 3 integers are required (efficiency lag, recent/fast index, distant/slow index)
%           Original description specifies [10, 2, 30]
%   Factor (optional) specifies factor for T3
%       Default is 0.7; otherwise factor should be between 0 and 1
%       Minimum factor of 0 reduces to TRIX, but some leading bars will be lost
%       Maximum factor of 1 reduces to DEMA thrice

%   I_C_MA outputs a vector of values for the specified moving average
%       Initial values of output vector will be NaN
%       Intervening NaN values in input Price_Series will be reconstructed
%   TRIX (optional) outputs the formal indicator, which is the 1-bar return

%   Reference: Mulloy, Patrick
%              Technical Analysis of Stocks and Commodities 1994
%              Hull, Alan
%              Hull Moving Average 2005
%              Tillson, Tim
%              Better Moving Averages 1998

%   Requires function I_Moving_Function, U_Price2Return

warning off

%% Validate inputs
%Check to make sure Price_Series is a column vector
if ~isvector(Price_Series) || ~iscolumn(Price_Series)
    error(message('Price_Series must be vertical column'));
end

%Allocate constant to original length of Price_Series
Num_Bars = size(Price_Series, 1);

%Generate column vector to screen out any leading NaN values in the price data series
%   Any NaN value embedded in prices after initial leading sequence could cause unexpected errors
NaN_Marker   = ~isnan(Price_Series);
Price_Series = Price_Series(NaN_Marker);

%Check data sufficiency using number of bars with NaN filtered out
if size(Price_Series, 1) < 10
    error('Price_Series must have at least 10 bars of available data');
end

%Check Indicator against possible valid inputs
if any(strcmpi(Indicator, {'DEMA', 'TEMA', 'EHMA', 'WHMA', 'TRIX', 'T3', 'KMA'}))
    Indicator = upper(Indicator); %Standardise to uppercase
else
    error('Invalid Indicator type input');
end

if ~strcmp(Indicator, 'TRIX') && nargout > 1
    error('Second output variable only valid for TRIX MA');
end

if strcmp(Indicator, 'T3')
    if nargin < 4
        Factor = 0.7;
    else
        if numel(Factor) ~= 1
            error('Factor must be scalar');
        elseif Factor < 0 || Factor > 1
            error('Factor must be between 0 and 1 (inclusive)');
        end
    end
end

if strcmp(Indicator, 'KMA')
    %Check that Lag has 3 positive integers for Kaufman MA
    if numel(Lag) ~= 3 || any(mod(Lag, 1) ~= 0)
        error('Lag must be 3 integers');
    elseif any(Lag < 1) || any(Lag >= Num_Bars)
        error('Lag must be positive and less than total number of bars');
    end
    Fast_Smooth = 2 / (Lag(2) + 1); %Convert to individual exponential weight
    Slow_Smooth = 2 / (Lag(3) + 1); %Convert to individual exponential weight
    if Fast_Smooth < Slow_Smooth
        error('Recent/fast lag must be smaller index than distant/slow lag');
    end
    Lag = Lag(1); %Lookback period for efficiency ratio
end

%Check that Lag is a positive integer
if numel(Lag) ~= 1 || mod(Lag, 1) ~= 0
    error('Lag must be scalar integer');
elseif Lag < 1 || Lag >= Num_Bars
    error('Lag must be positive and less than total number of bars');
end

%If specified, set Lag to entire available data (without NaN)
if Lag == 1
    Lag = size(Price_Series, 1) - 1;
end

%% Calculate the specified moving average
if strcmp(Indicator, 'WHMA')
    Linear_Weights = (1 : 1 : Lag) / sum(1 : 1 : Lag); %Linear from 1 to Lag
    WMA_Once = tsmovavg(Price_Series, 'w', Linear_Weights, 1);
    
    Linear_Weights = (1 : 1 : floor(Lag / 2)) / sum(1 : 1 : floor(Lag / 2)); %Linear from 1 to half Lag
    WMA_Half_Lag = tsmovavg(Price_Series, 'w', Linear_Weights, 1);
    
    Linear_Weights = (1 : 1 : floor(sqrt(Lag))) / sum(1 : 1 : floor(sqrt(Lag))); %Linear from 1 to square root of Lag
    I_C_MA = tsmovavg((2 * WMA_Half_Lag - WMA_Once), 'w', Linear_Weights, 1); %Final result for weighted Hull MA
elseif strcmp(Indicator, 'KMA')
    K_Change = [NaN(Lag, 1); abs(Price_Series(Lag + 1 : end) - Price_Series (1 : end - Lag))];
    K_Vol    = [NaN; I_Moving_Function(abs(Price_Series(2 : end) - Price_Series(1 : end - 1)), Lag, 'sum')];
    K_Eff_R  = K_Change ./ K_Vol;
    
    Smooth = (K_Eff_R * (Fast_Smooth - Slow_Smooth) + Slow_Smooth) .^ 2;
    I_C_MA = nan(numel(Smooth), 1); %Initialise output variable
    I_C_MA(Lag) = Price_Series(Lag); %Set first value of indicator to first price
    for Dot_Bar = Lag + 1 : numel(Smooth)
        I_C_MA(Dot_Bar) = I_C_MA(Dot_Bar - 1) + Smooth(Dot_Bar) .* (Price_Series(Dot_Bar) - I_C_MA(Dot_Bar - 1)); %Final result for Kaufman MA
    end
else %Compute indicators requiring EMA at least once
%   Obtain initial exponential moving average
    EMA_Once = tsmovavg(Price_Series, 'e', Lag, 1);
    if strcmp(Indicator, 'EHMA')
        EMA_Half_Lag = tsmovavg(Price_Series, 'e', floor(Lag / 2), 1);
        
        Temp_Series = 2 * EMA_Half_Lag - EMA_Once;
%       EMA does not tolerate NaN series, requiring computation from Lag to end and manual reinsertion of leading NaNs
        I_C_MA = [nan(Lag - 1, 1); tsmovavg(Temp_Series(Lag : end, 1), 'e', floor(sqrt(Lag)), 1)]; %Final result for exponential Hull MA
    else %Compute indicators requiring EMA at least twice
%       Apply EMA second time to initial EMA_Once series
%           First several (Lag - 1) values are NaN and must be avoided
        EMA_Twice = tsmovavg(EMA_Once(Lag : end, 1), 'e', Lag, 1);
        if strcmp(Indicator, 'DEMA')
%           Assign first term (2 x EMA) to output variable
            I_C_MA = 2 * EMA_Once;
%           Subtract second term (twice-averaged EMA) but only for values from index Lag onward
            I_C_MA(Lag : end, 1) = I_C_MA(Lag : end, 1) - EMA_Twice; %Final result for DEMA
        else %Compute remaining indicators requiring EMA at least thrice
%           Apply EMA third time to twice-averaged EMA_Temp series
%               Again, first several (Lag) values are NaN and must be avoided
            EMA_Thrice = tsmovavg(EMA_Twice(Lag : end, 1), 'e', Lag, 1);
            if     strcmp(Indicator, 'TEMA')
%               Assign first term (3 x EMA) to output variable
                I_C_MA = 3 * EMA_Once;
%               Subtract second term (3 x twice-averaged EMA) but only for values from index Lag onward
                I_C_MA(Lag : end, 1) = I_C_MA(Lag : end, 1) - (3 * EMA_Twice);
%               Add second term (thrice-averaged EMA) but only for values from index 2 * Lag - 1 onward
                I_C_MA(2 * Lag - 1 : end, 1) = I_C_MA(2 * Lag - 1 : end, 1) + EMA_Thrice; %Final result for TEMA
            elseif strcmp(Indicator, 'TRIX')
                I_C_MA = [nan(2 * Lag - 2, 1); EMA_Thrice];
                TRIX = U_Price2Return(I_C_MA); %Numerous interspersed NaN will degrade validity of TRIX returns
            elseif strcmp(Indicator, 'T3')
                Vol_Square = Factor ^ 2;
                Vol_Cube   = Factor ^ 3;
%               Compute 6 recursive layers (alternately, 3 layers of double EMA)
                EMA_4 = tsmovavg(EMA_Thrice(Lag : end, 1), 'e', Lag, 1);
                EMA_5 = tsmovavg(EMA_4     (Lag : end, 1), 'e', Lag, 1);
                EMA_6 = tsmovavg(EMA_5     (Lag : end, 1), 'e', Lag, 1);
                
%               Multiply by factors when expanded out and replace leading NaNs
                EMA_3 = (Vol_Cube + 3 * Vol_Square + 3 * Factor + 1)  * [nan(2 * Lag - 2, 1); EMA_Thrice];
                EMA_4 = (-3 * Vol_Cube - 6 * Vol_Square - 3 * Factor) * [nan(3 * Lag - 3, 1); EMA_4];
                EMA_5 = (3 * Vol_Cube + 3 * Vol_Square)               * [nan(4 * Lag - 4, 1); EMA_5];
                EMA_6 = (-1 * Vol_Cube)                               * [nan(5 * Lag - 5, 1); EMA_6];
                
                I_C_MA = EMA_6 + EMA_5 + EMA_4 + EMA_3; %Final result for T3
            end
        end
    end
end

%Finally, fix length of result if initial NaN series removed
%   NaN_Unique gives [0, 1] only if NaN first to appear; otherwise, [1] or [1, 0]
[NaN_Unique, Index_Unique] = unique(NaN_Marker, 'first');

%If initial NaN then determine length of the initial NaN sequence to replace
if NaN_Unique(1) == 0
%   Length of missing initial NaN goes to index just before first appearance of non-NaN value
    NaN_Replace = Index_Unique(2) - 1;
    I_C_MA = [nan(NaN_Replace, 1); I_C_MA];
end

%Fewer bars in result indicates embedded NaNs were removed; restore missing number at end but also issue warning
if Num_Bars > size(I_C_MA, 1)
    disp('Warning: NaN values embedded in Price_Series have been removed');
    for Dot_Bar = 1 : Num_Bars
        if ~NaN_Marker(Dot_Bar)
            I_C_MA(Dot_Bar : end + 1) = [NaN; I_C_MA(Dot_Bar : end)];
            if strcmp(Indicator, 'TRIX') %Could also replace with 0 for return rather than NaN
                TRIX(Dot_Bar : end + 1) = [NaN; TRIX(Dot_Bar : end)];
            end
        end
    end
end
end