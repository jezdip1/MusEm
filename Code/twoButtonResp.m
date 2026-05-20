function [resp, rt] = twoButtonResp(params, pngFile)
% twoButtonResp  –  Two‐button choice via mouse or gamepad
%   Must move the joystick left/right at least once before confirming via gamepad.
%   Mouse still works as before (click directly on a button).

    % 1) Load & texture background
    img = imread(pngFile);
    [hImg,wImg,~] = size(img);
    tex = Screen('MakeTexture', params.win, img);

    % 2) Letterbox compute
    scrR = params.winRect; scrW = scrR(3); scrH = scrR(4);
    if scrW/scrH > wImg/hImg
        outH = scrH; outW = round(wImg/hImg*outH);
    else
        outW = scrW; outH = round(hImg/wImg*outW);
    end
    left = (scrW - outW)/2; top = (scrH - outH)/2;
    dest = [left top left+outW top+outH];

    % 3) Define button rects in image coords (tweak to your PNG)
    imgBtn1 = [950 950 1350 1200];    % left button
    imgBtn2 = [1650 950 2050 1200];   % right button

    % 4) Scale to screen coords
    btn1 = scaleRect(imgBtn1, wImg, hImg, outW, outH, left, top);
    btn2 = scaleRect(imgBtn2, wImg, hImg, outW, outH, left, top);

    % 5) Init state
    selection = 1;        % default position (but not highlighted until moved)
    prevAxis  = 0;        % for debouncing
    joyMoved  = false;    % flag: has user moved the stick?
    resp      = "";       
    t0        = GetSecs;

    % 6) Main loop
    while resp == ""
        checkAbort();
        % 6a) Draw background
        Screen('DrawTexture', params.win, tex, [], dest);

        % 6b) Highlight selection only if stick has moved (or after mouse click)
        if joyMoved
            if selection == 1
                Screen('FrameRect', params.win, [50 100 255], btn1, 5);
            else
                Screen('FrameRect', params.win, [50 100 255], btn2, 5);
            end
        end

        % 6c) Debug outlines
        if params.debugClickable
            Screen('FrameRect', params.win, [255 0 0], btn1, 3);
            Screen('FrameRect', params.win, [255 0 0], btn2, 3);
        end

        Screen('Flip', params.win);

        if isAutoPilot(params)
            WaitSecs(autoPilotDelay(params));
            selection = autoPilotChoice(params, 2);
            resp = sprintf('btn%d', selection);
            rt = autoPilotRT(params);
            break;
        end

        % 6d) Mouse input
        [mx,my,mb] = GetMouse(params.win);
        if any(mb)
            % direct mouse selection & confirm
            if IsInRect(mx,my,btn1)
                selection = 1;
                resp = 'btn1';
                rt   = GetSecs - t0;
            elseif IsInRect(mx,my,btn2)
                selection = 2;
                resp = 'btn2';
                rt   = GetSecs - t0;
            end
            % wait release
            [~,~,mb2] = GetMouse(params.win);
            while any(mb2)
                [~,~,mb2] = GetMouse(params.win);
                WaitSecs(0.01);
            end
            if resp~="", break; end
        end

        % 6e) Gamepad input
        if isfield(params,'joy') && ~isempty(params.joy)
            [axes, buttons] = read(params.joy);
            horiz = axes(1);

            % detect left/right movement
            if horiz < -0.5 && prevAxis >= -0.5
                selection = 1;
                joyMoved  = true;
            elseif horiz > 0.5 && prevAxis <= 0.5
                selection = 2;
                joyMoved  = true;
            end
            prevAxis = horiz;

            % confirm only if the stick was moved
            if joyMoved && any(buttons)
                resp = sprintf('btn%d',selection);
                rt   = GetSecs - t0;
                % wait for button release
                while true
                    [~, b2] = read(params.joy);
                    if ~any(b2), break; end
                    WaitSecs(0.01);
                end
                break;
            end
        end

        WaitSecs(0.01);
    end

    % 7) Cleanup
    Screen('Close', tex);
end
