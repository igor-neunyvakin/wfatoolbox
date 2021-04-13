function U_P2R = U_Price2Return(Price_Series, Multiplier)
%U_Price2Return converts a price series (single vector, not table) from spot prices to percentage returns

%   Price_Series is a vertical vector of spot prices of the underlying security
%   Multiplier simulates leverage, using a factor per provided bar (usually daily)
%       Given availability, -3 to +3 is the usual range (but not 0)
%       Default (if not specified) is +1

%% Check input arguments
%Check to make sure Price_Series is a vector (not table)
if ~iscolumn(Price_Series) || istable(Price_Series)
    error('Price_Series must be a vertical vector');
end

%Check that Price_Series must have bare minimum length of 2 rows
if size(Price_Series, 1) < 2
    error('Price_Series has fewer than 2 rows of data');
end

%Check Multiplier and supply default if not specified
if nargin < 2
    Multiplier = +1;
else
    if Multiplier < -3 || Multiplier > +3
        error('Multiplier must be >= -3 and <= +3');
    elseif Multiplier == 0
        error('Multiplier must be non-zero number');
    end
end

%% Compute returns
%Divisor is Price_Series shifted all forward by 1 row
%   Subtract 1 to standardise gain factor to raw return versus 0
U_P2R = (Price_Series ./ circshift(Price_Series, 1) - 1) * Multiplier;
%   First value divided by invalid datum is reset to NaN
U_P2R(1) = NaN;
%   Remove any division by zero
U_P2R(isinf(U_P2R)) = NaN;
end