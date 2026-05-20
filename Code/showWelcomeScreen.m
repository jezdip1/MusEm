function showWelcomeScreen(params)
% showWelcomeScreen  –  Display welcome_page.png and wait for “Continue”
%                     via mouse click or joystick button.
%                     Highlights the button rect if debugClickable is on.

    %% 1) Load image & create texture
    imgPath = fullfile(params.pngDir,'welcome_page.png');
    if ~exist(imgPath,'file')
        error('Welcome image not found: %s',imgPath);
    end
    img = imread(imgPath);
    [imgH,imgW,~] = size(img);
    tex = Screen('MakeTexture',params.win,img);

    %% 2) Compute letterbox destination
    scrR  = params.winRect; 
    scrW  = scrR(3)-scrR(1); 
    scrH  = scrR(4)-scrR(2);
    aspectImg = imgW / imgH;
    aspectScr = scrW / scrH;
    if aspectScr > aspectImg
        outH = scrH; outW = round(aspectImg * outH);
    else
        outW = scrW; outH = round(outW / aspectImg);
    end
    left   = (scrW - outW)/2;
    top    = (scrH - outH)/2;
    dest   = [left, top, left+outW, top+outH];

    %% 3) Define the “Continue” button in image coords
    % (Replace these with your actual measurements)
    imgBtn = [1300, 1670, 2200, 1910];

    %% 4) Scale button to screen coords
    contRect = scaleRect(imgBtn, imgW, imgH, outW, outH, left, top);

    %% 5) Draw once
    Screen('DrawTexture',params.win,tex,[],dest);
    if params.debugClickable
        Screen('FrameRect',params.win,[255 0 0],contRect,3);
    end
    Screen('Flip',params.win);
    ShowCursor('Arrow',params.win);

    if isAutoPilot(params)
        WaitSecs(autoPilotDelay(params));
        Screen('Close',tex);
        HideCursor(params.win);
        return;
    end

    %% 6) Wait for click (mouse inside rect OR any joystick button)
    while true
        % 6a) Mouse state
        [mx,my,mb] = GetMouse(params.win);
        mouseClick = any(mb) && IsInRect(mx,my,contRect);

        % 6b) Joystick state
        joyClick = false;
        if isfield(params,'joy') && ~isempty(params.joy)
            try
                [~, buttons] = read(params.joy);
                joyClick = any(buttons);
            catch
                joyClick = false;
            end
        end

        % 6c) ESC to abort
        [keyIsDown,~,keyCode] = KbCheck;
        if keyIsDown && keyCode(KbName('ESCAPE'))
            sca;
            error('Experiment aborted by user (ESC).');
        end

        % 6d) If click, wait for release then break
        if mouseClick || joyClick
            if mouseClick
                % wait mouse release only
                [~,~,mb] = GetMouse(params.win);
                while any(mb)
                    [~,~,mb] = GetMouse(params.win);
                    WaitSecs(0.01);
                end
            else
                % wait joystick release only
                while true
                    [~, buttons] = read(params.joy);
                    if ~any(buttons), break; end
                    WaitSecs(0.01);
                end
            end
            break;
        end

        WaitSecs(0.01);
    end

    %% 7) Cleanup
    Screen('Close',tex);
    HideCursor(params.win);
end
