function params = ensureDefaultParams(params)
% ensureDefaultParams  Add current default settings if they are missing.
% This is deliberately conservative: existing values from a resumed session are
% preserved, missing fields are filled in.

    defaults.nPracticeImp     = 4;
    defaults.nPracticeAffect  = 2;
    defaults.nPracticeEm      = 2;
    defaults.nPerBlock        = 20;
    defaults.nBlocks          = 2;
    defaults.fixDuration      = 2.5;
    defaults.questionDuration = 2.5;
    defaults.autoPilot        = false;
    defaults.autoPilotDelay   = 0.15;
    defaults.autoPilotRT      = 0.20;
    defaults.autoPilotRTJitter= 0.05;
    defaults.autoPilotRandomize = true;

    f = fieldnames(defaults);
    for i = 1:numel(f)
        if ~isfield(params, f{i}) || isempty(params.(f{i}))
            params.(f{i}) = defaults.(f{i});
        end
    end
end
