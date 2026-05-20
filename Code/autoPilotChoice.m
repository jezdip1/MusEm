function choice = autoPilotChoice(params, nChoices)
% autoPilotChoice  Deterministic-neutral or random synthetic response.

    if nargin < 2 || isempty(nChoices)
        nChoices = 2;
    end
    useRandom = true;
    if nargin >= 1 && isfield(params,'autoPilotRandomize') && ~isempty(params.autoPilotRandomize)
        useRandom = logical(params.autoPilotRandomize);
    end

    if useRandom
        choice = randi(nChoices);
    else
        choice = ceil(nChoices/2);
    end
end
