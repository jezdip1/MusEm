function tf = isAutoPilot(params)
% isAutoPilot  True when automated test mode is enabled.
%
% This is deliberately separate from debugClickable. DebugClickable only draws
% clickable rectangles; autoPilot actually advances screens and produces
% synthetic responses for end-to-end smoke testing.

    tf = false;
    if nargin < 1 || isempty(params)
        return;
    end
    if isfield(params,'autoPilot') && ~isempty(params.autoPilot)
        tf = logical(params.autoPilot);
    end
end
