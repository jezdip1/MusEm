% getClick.m
% Returns true if the user has just pressed mouse OR any gamepad button
function clicked = getClick(params)
    % 1) Mouse
    [~,~,mb] = GetMouse(params.win);
    if any(mb)
        clicked = true;
        return;
    end
    % 2) Gamepad
    if isfield(params,'joy') && ~isempty(params.joy)
        try
            [~, buttons] = read(params.joy);
            if any(buttons)
                clicked = true;
                return;
            end
        catch
            % ignore read errors
        end
    end
    clicked = false;
end
