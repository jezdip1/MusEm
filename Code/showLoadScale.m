function [rating, rt] = showLoadScale(params,pngFile)
    % showLoadScale  –  Interactive 1–9 scale with mouse OR gamepad control
    %   params.joy must be a vrjoystick object or []
    %   pngFile = full path to the PNG background

    %% 1) Load & texture
    img = imread(pngFile);
    [imgH,imgW,~] = size(img);
    tex = Screen('MakeTexture',params.win,img);

    %% 2) Letterbox compute
    scrR = params.winRect; scrW=scrR(3); scrH=scrR(4);
    if scrW/scrH > imgW/imgH
        outH = scrH; outW = round(imgW/imgH*outH);
    else
        outW = scrW; outH = round(imgH/imgW*outW);
    end
    left = (scrW-outW)/2; top = (scrH-outH)/2;
    dest = [left top left+outW top+outH];

    %% 3) Define & scale tick rects + continue rect
    % Image coords (replace with your measured values)
    for k=1:9
        imgTick{k} = [128+336*(k-1), 960, 205+336*(k-1), 1030];
    end
    imgCont = [1060 1668 1956 1912];

    for k=1:9
        tick{k} = scaleRect(imgTick{k},imgW,imgH,outW,outH,left,top);
    end
    contRect = scaleRect(imgCont, imgW,imgH,outW,outH,left,top);

    %% 4) Initialize selection & timing
    selection = 5;            % 1–9; start at neutral as requested
    prevAxis  = 0;            % for debouncing stick
    tStart    = GetSecs;

    %% 5) Main loop
    while true
        checkAbort();
        % — draw background
        Screen('DrawTexture',params.win,tex,[],dest);

        % — highlight current selection
        if ~isnan(selection)
            % outline selected tick
            Screen('FrameRect', params.win, [50 100 255], tick{selection}, 4);
        end

        % — debug outlines
        if params.debugClickable
            for k=1:9
                Screen('FrameRect',params.win,[0 255 0],tick{k},2);
            end
            Screen('FrameRect',params.win,[255 0 0],contRect,3);
        end

        Screen('Flip',params.win);
        ShowCursor('Arrow',params.win);

        if isAutoPilot(params)
            WaitSecs(autoPilotDelay(params));
            rating = autoPilotChoice(params, 9);
            rt = autoPilotRT(params);
            break;
        end

        % — read inputs
        [mx,my,mb] = GetMouse(params.win);
        jButtons = [];
        horiz    = 0;
        if isfield(params,'joy') && ~isempty(params.joy)
            try
                [axes, buttons] = read(params.joy);
                horiz    = axes(1);
                jButtons = buttons;
            catch
                % ignore
            end
        end

        % 5a) Mouse: select tick directly
        if any(mb)
            for k=1:9
                if IsInRect(mx,my,tick{k})
                    selection = k;
                end
            end
            % mouse confirm
            if IsInRect(mx,my,contRect) && ~isnan(selection)
                % wait for release
                while any(mb)
                    [~,~,mb] = GetMouse(params.win);
                    WaitSecs(0.01);
                end
                rt = GetSecs - tStart;
                rating = selection;
                break;
            end
            % release before continuing
            while any(mb)
                [~,~,mb] = GetMouse(params.win);
                WaitSecs(0.01);
            end
        end

        % 5b) Gamepad stick: change selection
        if ~isempty(params.joy)
            if horiz < -0.5 && prevAxis >= -0.5
                selection = max(1,selection-1);
            elseif horiz > 0.5 && prevAxis <= 0.5
                selection = min(9,selection+1);
            end
            prevAxis = horiz;

            % gamepad confirm
            if any(jButtons) && ~isnan(selection)
                % wait for release
                while any(jButtons)
                    [~, jButtons] = read(params.joy);
                    WaitSecs(0.01);
                end
                rt = GetSecs - tStart;
                rating = selection;
                break;
            end
        end

        WaitSecs(0.01);
    end

    %% 6) Clean up
    Screen('Close',tex);
end
