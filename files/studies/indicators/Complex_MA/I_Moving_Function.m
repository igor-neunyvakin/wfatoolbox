function I_M_F = I_Moving_Function(Price_Series, Lag, Custom_Function, Extra_Input)
%I_Moving_Function computes a moving simple function with the ability to use an additional input

%   Price_Series is a vertical vector of prices (usually adjusted closing) of the underlying security
%       Price_Series may be vertical matrix, in which case each column will be smoothed
%   Lag (positive integer) specifies number of prior samples (periods)
%       Lag works better as odd number
%	Custom_Function specifies any single-argument simple function
%       It is possible to input 'mean' but more efficient to use dedicated moving mean function
%   Extra_Input (optional) allows one additional scalar for a double-argument simple function

%   I_M_F returns output vector of same size as Price_Series, with leading NaNs

%% Validate inputs
%Bypass further computation for simplest case
if Lag == 1
	I_M_F = Price_Series;
	return
end

%Check for more than 2 data points
if numel(Price_Series) <= 2
    error('Price_Series must have at least 2 data points');
end
%Convert any horizontal vector to vertical
if size(Price_Series, 1) == 1
	Price_Series = Price_Series';
    disp('Warning: horizontal vector detected and converted to vertical');
end

%Allocate constant for original number of bars
Num_Bars = size(Price_Series, 1);
%Generate column vector to screen out any leading NaN values in the price data series
%Any NaN value embedded in prices after initial leading sequence could cause unexpected errors
%   Basically, any 0 (false) in the filter column will not use that index value in the price series
NaN_Marker = ~isnan(Price_Series);
Price_Series = Price_Series(NaN_Marker);
%Number of bars will be based on Price Series with NaN filtered out
[Num_Rows, Num_Cols] = size(Price_Series);

%Check that Lag is a positive integer
if numel(Lag) ~= 1 || mod(Lag, 1) ~= 0
    error('Lag must be scalar');
elseif Lag < 1
    error('Lag must be a positive integer');
end

if ~ischar(Custom_Function)
    error('Custom_Function must be text input');
else
    if nargin < 4
        Custom_Function = str2func(['@(x)', Custom_Function, '(x)']);
    else
        Custom_Function = str2func(['@(x)', Custom_Function, '(x, ', num2str(Extra_Input), ')']);
    end
end

%% Compute output
%Pre-allocate output matrix
I_M_F = NaN(size(Price_Series));

%Insert leading NaN up to just before # Lag element of Price_Series
Price_Series = [NaN(Lag - 1, Num_Cols); Price_Series];
for Dot_Row = 1 : Num_Rows; %Compute each output row based on next Lag - 1 rows
    I_M_F(Dot_Row, :) = Custom_Function(Price_Series(Dot_Row + (0 : Lag - 1), :));
end

%Finally, fix length of result if initial NaN series removed
%NaN_Unique gives [0, 1] only if NaN first to appear; otherwise, [1] or [1, 0]
[NaN_Unique, Index_Unique] = unique(NaN_Marker, 'first');
%If initial NaN then determine length of the initial NaN sequence to replace
if NaN_Unique(1) == 0
%   Length of missing initial NaN goes to index just before first appearance of non-NaN value
    NaN_Replace = Index_Unique(2) - 1;
    I_M_F = [nan(NaN_Replace, 1); I_M_F];
end

%Fewer bars in result indicates embedded NaNs were removed; restore missing number at end but also issue warning
if Num_Bars > size(I_M_F, 1)
    disp('Warning: NaN values embedded in Price_Series have been removed');
    for Dot_Bar = 1 : Num_Bars
        if ~NaN_Marker(Dot_Bar)
            I_M_F(Dot_Bar : end + 1) = [NaN; I_M_F(Dot_Bar : end)];
        end
    end
end
end