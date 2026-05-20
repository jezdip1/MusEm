function d = autoPilotDelay(params)
% autoPilotDelay  Delay used to keep automated screens briefly visible.

    d = 0.15;
    if nargin >= 1 && isfield(params,'autoPilotDelay') && ~isempty(params.autoPilotDelay)
        d = params.autoPilotDelay;
    end
    d = max(0, double(d));
end
