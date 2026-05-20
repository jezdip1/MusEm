function params = applyAutoPilotSettings(params)
% applyAutoPilotSettings  Read optional environment variables for smoke tests.
%
% Supported variables:
%   MUSEM_AUTOPILOT=1              Enable automated responses.
%   MUSEM_AUTOPILOT_DELAY=0.15     Seconds to keep response screens visible.
%   MUSEM_AUTOPILOT_RT=0.20        Synthetic RT written to result tables.
%   MUSEM_AUTOPILOT_RT_JITTER=0.05 Random RT jitter.
%   MUSEM_AUTOPILOT_RANDOMIZE=0/1  Random synthetic responses; 0 = neutral/central.

    if ~isfield(params,'autoPilot') || isempty(params.autoPilot)
        params.autoPilot = false;
    end
    if ~isfield(params,'autoPilotDelay') || isempty(params.autoPilotDelay)
        params.autoPilotDelay = 0.15;
    end
    if ~isfield(params,'autoPilotRT') || isempty(params.autoPilotRT)
        params.autoPilotRT = 0.20;
    end
    if ~isfield(params,'autoPilotRTJitter') || isempty(params.autoPilotRTJitter)
        params.autoPilotRTJitter = 0.05;
    end
    if ~isfield(params,'autoPilotRandomize') || isempty(params.autoPilotRandomize)
        params.autoPilotRandomize = true;
    end

    v = getenv('MUSEM_AUTOPILOT');
    if ~isempty(v)
        params.autoPilot = any(strcmpi(strtrim(v), {'1','true','yes','on','auto'}));
    end

    v = getenv('MUSEM_AUTOPILOT_DELAY');
    if ~isempty(v)
        x = str2double(v);
        if ~isnan(x), params.autoPilotDelay = max(0,x); end
    end

    v = getenv('MUSEM_AUTOPILOT_RT');
    if ~isempty(v)
        x = str2double(v);
        if ~isnan(x), params.autoPilotRT = max(0,x); end
    end

    v = getenv('MUSEM_AUTOPILOT_RT_JITTER');
    if ~isempty(v)
        x = str2double(v);
        if ~isnan(x), params.autoPilotRTJitter = max(0,x); end
    end

    v = getenv('MUSEM_AUTOPILOT_RANDOMIZE');
    if ~isempty(v)
        params.autoPilotRandomize = any(strcmpi(strtrim(v), {'1','true','yes','on','random'}));
    end
end
