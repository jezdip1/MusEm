function showPNGwaitClick(params, pngPath, imgCont)
    % Displays a PNG and waits for a click (mouse or joystick)
    % inside imgCont if using the mouse, or anywhere if using the joystick.

    % 1) Load & make texture
    img = imread(pngPath);
    [imgH,imgW,~] = size(img);
    tex = Screen('MakeTexture',params.win,img);

    % 2) Letterbox compute
    scrR = params.winRect; scrW = scrR(3); scrH = scrR(4);
    if scrW/scrH > imgW/imgH
        outH = scrH; outW = round(imgW/imgH*outH);
    else
        outW = scrW; outH = round(imgH/imgW*outW);
    end
    left = (scrW-outW)/2; top = (scrH-outH)/2;
    dest = [left top left+outW top+outH];

    % 3) Scale the click‐rect
    contRect = scaleRect(imgCont, imgW,imgH, outW,outH, left,top);

    % 4) Draw & flip
    Screen('DrawTexture',params.win,tex,[],dest);
    if params.debugClickable
        Screen('FrameRect',params.win,[255 0 0],contRect,3);
    end
    Screen('Flip',params.win);
    ShowCursor('Arrow', params.win);

    if isAutoPilot(params)
        WaitSecs(autoPilotDelay(params));
        Screen('Close', tex);
        return;
    end

    % 5) Wait loop
    while true
        checkAbort();
        % mouse state
        [mx,my,mb] = GetMouse(params.win);
        mouseClick = any(mb) && IsInRect(mx,my,contRect);

        % joystick state
        joyClick = false;
        if isfield(params,'joy') && ~isempty(params.joy)
            try
                [~, buttons] = read(params.joy);
                joyClick = any(buttons);
            catch
                joyClick = false;
            end
        end

        % if mouse click inside OR any joystick press
%         if mouseClick || joyClick
%             % wait for release
%             if mouseClick
%                 while any(GetMouse(params.win)), WaitSecs(0.01); end
%             else
%                 % wait until all joystick buttons released
%                 while true
%                     [~, buttons] = read(params.joy);
%                     if ~any(buttons), break; end
%                     WaitSecs(0.01);
%                 end
%             end
%             break;
%         end
        if mouseClick || joyClick
            % wait for all mouse buttons up
            if mouseClick
                [~,~,mb] = GetMouse(params.win);
                while any(mb)
                    [~,~,mb] = GetMouse(params.win);
                    WaitSecs(0.01);
                end
            else
                % wait for all joystick buttons up
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

    % 6) Clean up
    Screen('Close', tex);
end
