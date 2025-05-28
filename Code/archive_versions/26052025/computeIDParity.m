function isOddID = computeIDParity(subjID)
% computeIDParity – return true if subjID is “odd”, false if “even”
%   Uses trailing digits if they exist, otherwise sums char codes.

    % 1) Try to grab a run of digits at the end of the string
    tokens = regexp(subjID,'(\d+)$','tokens','once');
    if ~isempty(tokens)
        n = str2double(tokens{1});
        isOddID = mod(n, 2) == 1;
    else
        % 2) No digits: fall back on a simple hash of the letters
        % e.g. sum of all character codes mod 2
        vals     = double(subjID);
        isOddID  = mod(sum(vals), 2) == 1;
    end
end
