% twoButtonResp.m
% Allows the user to select between two buttons either by mouse-clicking
% directly on them or by using the gamepad’s left/right axis + confirm button.
% Highlights the currently selected button when using the gamepad.
function [resp, rt] = twoButtonResp(params, pngFile)
    % Read & texture the background PNG
    img = imread(pngFile);
    [hImg,wImg,~] = size(img);
    tex = Screen('MakeTexture', params.win, img);

    % Letterbox compute
    scrR = params.winRect; scrW = scrR(3); scrH = scrR(4);
    if scrW/scrH > wImg/hImg
        outH = scrH; outW = round(wImg/hImg*outH);
    else
        outW = scrW; outH = round(hImg/wImg*outW);
    end
    left = (scrW - outW)/2; top = (scrH - outH)/2;
    dest = [left top left+outW top+outH];

    % Define button rects in IMAGE coords (replace with your measured values)
    imgBtn1 = [950 950 1350 1200];    % e.g. left button
    imgBtn2 = [1650 950 2050 1200];   % e.g. right button

    % Scale into SCREEN coords
    btn1 = scaleRect(imgBtn1, wImg, hImg, outW, outH, left, top);
    btn2 = scaleRect(imgBtn2, wImg, hImg, outW, outH, left, top);

    % Initial selection: 1 = left, 2 = right
    selection = 1;
    prevAxis = 0;  % for debouncing the stick

    % Draw initial screen
    Screen('DrawTexture', params.win, tex, [], dest);
    Screen('Flip', params.win);
    t0 = GetSecs;

    resp = "";
    rt   = NaN;

    while resp == ""
        % Redraw with highlight on current selection
        Screen('DrawTexture', params.win, tex, [], dest);
        if selection == 1
            Screen('FrameRect', params.win, [50 100 255 120], btn1);
        else
            Screen('FrameRect', params.win, [50 100 255 120], btn2);
        end
        if params.debugClickable
            Screen('FrameRect',params.win,[255 0 0],btn1,3);
            Screen('FrameRect',params.win,[255 0 0],btn2,3);
        end
        Screen('Flip', params.win);

        % --- Mouse input ---
        [mx,my,mb] = GetMouse(params.win);
        if any(mb)
            if IsInRect(mx,my,btn1)
                selection = 1;
                resp = 'btn1';
                rt   = GetSecs - t0;
            elseif IsInRect(mx,my,btn2)
                selection = 2;
                resp = 'btn2';
                rt   = GetSecs - t0;
            end
            % wait for release
            while any(mb)
                [~,~,mb] = GetMouse(params.win);
                WaitSecs(0.01);
            end
            if resp ~= ""; break; end
        end

        % --- Gamepad input ---
        if isfield(params,'joy') && ~isempty(params.joy)
            [axes, buttons] = read(params.joy);
            horiz = axes(1);  % left stick horizontal

            % change selection on stick left/right crossing threshold
            if horiz < -0.5 && prevAxis >= -0.5
                selection = max(1,selection-1);
            elseif horiz >  0.5 && prevAxis <=  0.5
                selection = min(2,selection+1);
            end
            prevAxis = horiz;

            % confirm with any gamepad button
            if any(buttons)
                resp = sprintf('btn%d',selection);
                rt   = GetSecs - t0;
                % wait for all buttons up
                while any(buttons)
                    [~,buttons] = read(params.joy);
                    WaitSecs(0.01);
                end
                break;
            end
        end

        WaitSecs(0.01);
    end

    Screen('Close', tex);
end
