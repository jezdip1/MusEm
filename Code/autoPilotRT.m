function rt = autoPilotRT(params)
% autoPilotRT  Synthetic reaction time written to results in autoPilot mode.

    baseRT = 0.20;
    jitter = 0.05;
    if nargin >= 1 && isfield(params,'autoPilotRT') && ~isempty(params.autoPilotRT)
        baseRT = double(params.autoPilotRT);
    end
    if nargin >= 1 && isfield(params,'autoPilotRTJitter') && ~isempty(params.autoPilotRTJitter)
        jitter = double(params.autoPilotRTJitter);
    end
    rt = max(0, baseRT + jitter * randn);
end
