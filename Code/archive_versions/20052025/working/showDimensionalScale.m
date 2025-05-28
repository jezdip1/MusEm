function [p,a,v,rt] = showDimensionalScale(params,pngPath)
% showDimensionalScale  –  Interactive 3×1–9 sliders + Continue
%   Supports mouse or gamepad control:
%     • Mouse: click on a tick or Continue
%     • Gamepad: 
%         – Up/Down: select slider (Preference → Arousal → Valence)
%         – Left/Right: change value 1–9 on the active slider
%         – Any button: confirm once all three sliders have a value

    %% 1) Load & make texture once
    img = imread(pngPath);
    [hImg,wImg,~] = size(img);
    tex = Screen('MakeTexture', params.win, img);

    %% 2) Compute letterboxed dest rect
    scrR  = params.winRect; scrW = scrR(3); scrH = scrR(4);
    if scrW/scrH > wImg/hImg
        outH = scrH; outW = round(wImg/hImg*outH);
    else
        outW = scrW; outH = round(hImg/wImg*outW);
    end
    left = (scrW-outW)/2; top = (scrH-outH)/2;
    dest = [left top left+outW top+outH];

    %% 3) Define image‐coords and scale to screen‐coords
    % Image‐coords for ticks (replace with your actual values)
    for k=1:9
        imgPref{k}    = [128+336*(k-1), 665, 205+336*(k-1), 735];
        imgArousal{k} = [128+336*(k-1),1110,205+336*(k-1),1180];
        imgValence{k} = [128+336*(k-1),1260,205+336*(k-1),1330];
    end
    imgCont = [1060 1668 1956 1912];

    for k=1:9
        pr{k} = scaleRect(imgPref{k},   wImg,hImg,outW,outH,left,top);
        ar{k} = scaleRect(imgArousal{k},wImg,hImg,outW,outH,left,top);
        va{k} = scaleRect(imgValence{k},wImg,hImg,outW,outH,left,top);
    end
    contRect = scaleRect(imgCont, wImg,hImg,outW,outH,left,top);

    %% 4) Initialize
    p = NaN; a = NaN; v = NaN;      % slider values
    active = 1;                     % 1=pref,2=arousal,3=valence
    prevHor = 0; prevVer = 0;       % for debouncing axes
    tStart  = GetSecs;

    %% 5) Main loop
    while true
        % — Draw background
        Screen('DrawTexture', params.win, tex, [], dest);

        % — Highlight current values
        if ~isnan(p), Screen('FillRect',params.win,[255 100 100 150],pr{p}); end
        if ~isnan(a), Screen('FillRect',params.win,[100 255 100 150],ar{a}); end
        if ~isnan(v), Screen('FillRect',params.win,[100 100 255 150],va{v}); end

        % — Outline active slider’s current tick
        switch active
          case 1
            if ~isnan(p), Screen('FrameRect',params.win,[255 255   0],pr{p},4); end
          case 2
            if ~isnan(a), Screen('FrameRect',params.win,[255 255   0],ar{a},4); end
          case 3
            if ~isnan(v), Screen('FrameRect',params.win,[255 255   0],va{v},4); end
        end

        % — Debug outlines
        if params.debugClickable
            for k=1:9
                Screen('FrameRect',params.win,[255 0 0],pr{k},2);
                Screen('FrameRect',params.win,[0 255 0],ar{k},2);
                Screen('FrameRect',params.win,[0 0 255],va{k},2);
            end
            Screen('FrameRect',params.win,[255 255   0],contRect,3);
        end

        Screen('Flip', params.win);
        ShowCursor('Arrow', params.win);

        % — Read inputs
        [mx,my,mb] = GetMouse(params.win);
        horiz = 0; vert = 0; joyB = [];
        if isfield(params,'joy') && ~isempty(params.joy)
            try
                [axes, buttons] = read(params.joy);
                horiz = axes(1);    % left/right
                vert  = axes(2);    % up/down
                joyB  = buttons;
            catch
                % ignore
            end
        end

        % 5a) Mouse selection
        if any(mb)
            for k=1:9
                if IsInRect(mx,my,pr{k}),    p=k; end
                if IsInRect(mx,my,ar{k}),    a=k; end
                if IsInRect(mx,my,va{k}),    v=k; end
            end
            % mouse confirm
            if IsInRect(mx,my,contRect) && ~any(isnan([p,a,v]))
                while any(mb), [~,~,mb]=GetMouse(params.win); WaitSecs(0.01); end
                rt = GetSecs - tStart;
                break;
            end
            while any(mb), [~,~,mb]=GetMouse(params.win); WaitSecs(0.01); end
        end

        % 5b) Gamepad navigation
        % — switch active slider with up/down
        if vert < -0.5 && prevVer >= -0.5
            active = max(1,active-1);
        elseif vert >  0.5 && prevVer <=  0.5
            active = min(3,active+1);
        end
        prevVer = vert;

        % — adjust value with left/right
        if horiz < -0.5 && prevHor >= -0.5
            switch active
              case 1
                if isnan(p), p=1; else p=max(1,p-1); end
              case 2
                if isnan(a), a=1; else a=max(1,a-1); end
              case 3
                if isnan(v), v=1; else v=max(1,v-1); end
            end
        elseif horiz > 0.5 && prevHor <= 0.5
            switch active
              case 1
                if isnan(p), p=1; else p=min(9,p+1); end
              case 2
                if isnan(a), a=1; else a=min(9,a+1); end
              case 3
                if isnan(v), v=1; else v=min(9,v+1); end
            end
        end
        prevHor = horiz;

%         % — gamepad confirm when all three set
%         if ~isempty(joyB) && any(joyB) && ~any(isnan([p,a,v]))
%             % wait until released
%             while any(read(params.joy))
%                 WaitSecs(0.01);
%             end
%             rt = GetSecs - tStart;
%             break;
%         end
% -- gamepad confirm when all three set
        if ~isempty(joyB) && any(joyB) && ~any(isnan([p,a,v]))
            % wait for release of **all** click sources
            while getClick(params)
                WaitSecs(0.01);
            end
            rt = GetSecs - tStart;
            break;
        end

        WaitSecs(0.01);
    end

    %% 6) Clean up
    Screen('Close',tex);
end
