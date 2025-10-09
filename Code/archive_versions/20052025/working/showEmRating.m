function [pref, emotion, rtPref, rtEm] = showEmRating(params, pngPath, imgPref, imgEmot, imgCont)
% showEmRating  –  Interactive preference (1–9) + discrete emotion + Continue
% Supports mouse & gamepad.

    %% 1) Load & make texture
    img = imread(pngPath);
    [hImg,wImg,~] = size(img);
    tex = Screen('MakeTexture',params.win,img);

    %% 2) Letterbox
    scrR = params.winRect; scrW = scrR(3); scrH = scrR(4);
    if scrW/scrH > wImg/hImg
        outH = scrH; outW = round(wImg/hImg*outH);
    else
        outW = scrW; outH = round(hImg/wImg*outW);
    end
    left = (scrW-outW)/2; top = (scrH-outH)/2;
    dest = [left top left+outW top+outH];

    %% 3) Scale all click‐rects
    for k=1:numel(imgPref)
        pr{k}  = scaleRect(imgPref{k},  wImg,hImg,outW,outH,left,top);
    end
    for k=1:numel(imgEmot)
        emo{k} = scaleRect(imgEmot{k},  wImg,hImg,outW,outH,left,top);
    end
    contRect = scaleRect(imgCont, wImg,hImg,outW,outH,left,top);

    %% 4) Init
    pref     = NaN;
    emotion  = "";
    rtPref   = NaN;
    rtEm     = NaN;
    t0       = GetSecs;
    active   = 1;     % 1 = pref, 2 = emotion
    prevHor  = 0;
    prevVer  = 0;

    % Pull out emotion labels once
%     emList = {'joy','fear','sad','tender','neutral'};
    emList = {'tender','fear','sad','joy','neutral'};


    %% 5) Main loop
    while true
        % --- draw background ---
        Screen('DrawTexture',params.win,tex,[],dest);

        % --- highlight selected pref tick ---
        if ~isnan(pref)
            Screen('FillRect',params.win,[50 100 255 120],pr{pref});
        end
        % --- highlight selected emotion icon ---
        if strlength(emotion)>0
            ei = find(strcmp(emList,emotion),1);
            if ~isempty(ei)
                Screen('FrameRect',params.win,[255 0 0],emo{ei},3);
            end
        end

        % --- debug outlines ---
        if params.debugClickable
            for k=1:numel(pr)
                Screen('FrameRect',params.win,[0 255 0],pr{k},2);
            end
            for k=1:numel(emo)
                Screen('FrameRect',params.win,[255 0 0],emo{k},2);
            end
            Screen('FrameRect',params.win,[255 255 0],contRect,3);
        end

        Screen('Flip',params.win);
        ShowCursor('Arrow',params.win);

        % --- read mouse & joystick ---
        [mx,my,mb] = GetMouse(params.win);
        horiz=0; vert=0; joyB=[];
        if isfield(params,'joy') && ~isempty(params.joy)
            try
                [axes, buttons] = read(params.joy);
                horiz = axes(1); vert = axes(2); joyB = buttons;
            catch
            end
        end

        % --- mouse interaction ---
        if any(mb)
            % select pref
            for k=1:numel(pr)
                if IsInRect(mx,my,pr{k})
                    if isnan(pref), rtPref = GetSecs - t0; end
                    pref = k;
                end
            end
            % select emotion
            for k=1:numel(emo)
                if IsInRect(mx,my,emo{k})
                    if strlength(emotion)==0, rtEm = GetSecs - t0; end
                    emotion = emList{k};
                end
            end
            % confirm
            if IsInRect(mx,my,contRect) && ~isnan(pref) && strlength(emotion)>0
                while any(mb)
                    [~,~,mb] = GetMouse(params.win);
                    WaitSecs(0.01);
                end
                break;
            end
            while any(mb)
                [~,~,mb] = GetMouse(params.win);
                WaitSecs(0.01);
            end
        end

        % --- gamepad navigation: up/down switch domain ---
        if vert < -0.5 && prevVer >= -0.5
            active = max(1,active-1);
        elseif vert > 0.5 && prevVer <= 0.5
            active = min(2,active+1);
        end
        prevVer = vert;

        % --- gamepad navigation: left/right adjust selection ---
        if horiz < -0.5 && prevHor >= -0.5
            if active==1
                if isnan(pref)
                    rtPref = GetSecs - t0; pref=1;
                else
                    pref = max(1,pref-1);
                end
            else
                if strlength(emotion)==0
                    rtEm = GetSecs - t0; emotion=emList{1};
                else
                    idx = find(strcmp(emList,emotion),1);
                    idx = max(1,idx-1);
                    emotion = emList{idx};
                end
            end
        elseif horiz > 0.5 && prevHor <= 0.5
            if active==1
                if isnan(pref)
                    rtPref = GetSecs - t0; pref=1;
                else
                    pref = min(9,pref+1);
                end
            else
                if strlength(emotion)==0
                    rtEm = GetSecs - t0; emotion=emList{1};
                else
                    idx = find(strcmp(emList,emotion),1);
                    idx = min(numel(emList),idx+1);
                    emotion = emList{idx};
                end
            end
        end
        prevHor = horiz;

        % --- gamepad confirm ---
        if ~isempty(joyB) && any(joyB) && ~isnan(pref) && strlength(emotion)>0
            % wait for release
            while true
                [~, buttons] = read(params.joy);
                if ~any(buttons), break; end
                WaitSecs(0.01);
            end
            break;
        end

        WaitSecs(0.01);
    end

    %% 6) Clean up
    Screen('Close',tex);
end
