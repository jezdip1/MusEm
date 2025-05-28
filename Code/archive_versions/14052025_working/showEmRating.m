function [pref, emotion, rtPref, rtEm] = showEmRating(params, pngPath, imgPref, imgEmot, imgCont)
    img = imread(pngPath);
    [hImg,wImg,~] = size(img);
    tex = Screen('MakeTexture', params.win, img);
    % letterbox
    scrR = params.winRect; scrW = scrR(3); scrH = scrR(4);
    if scrW/scrH > wImg/hImg
        outH = scrH; outW = round(wImg/hImg*outH);
    else
        outW = scrW; outH = round(hImg/wImg*outW);
    end
    left = (scrW-outW)/2; top = (scrH-outH)/2;
    dest = [left top left+outW top+outH];
    % scale rects
    for k = 1:numel(imgPref)
        tick{k} = scaleRect(imgPref{k}, wImg, hImg, outW, outH, left, top);
    end
    for k = 1:numel(imgEmot)
        emoRect{k} = scaleRect(imgEmot{k}, wImg, hImg, outW, outH, left, top);
    end
    contRect = scaleRect(imgCont, wImg, hImg, outW, outH, left, top);
    % init
    pref = NaN; emotion = ''; rtPref = NaN; rtEm = NaN; time0 = GetSecs;
    % interactive multi-select
    while true
        Screen('DrawTexture', params.win, tex, [], dest);
        if ~isnan(pref), Screen('FillRect', params.win, [100 100 255 150], tick{pref}); end
        if ~isempty(emotion)
            emList = {'joy','fear','sad','tender','neutral'};
%             emList = {'tender','sad','neutral','fear','joy'};
            ei = find(strcmp(emList, emotion));
            if ~isempty(ei), Screen('FrameRect', params.win, [255 0 0], emoRect{ei}, 3); end
        end
        if params.debugClickable
            for k=1:numel(tick), Screen('FrameRect', params.win, [0 255 0], tick{k}, 2); end
            for k=1:numel(emoRect), Screen('FrameRect', params.win, [255 0 0], emoRect{k}, 2); end
            Screen('FrameRect', params.win, [255 255 0], contRect, 3);
        end
        Screen('Flip', params.win);
        [mx,my,btn] = GetMouse(params.win);
        if any(btn)
            for k=1:numel(tick)
                if IsInRect(mx,my,tick{k})
                    if isnan(pref), rtPref = GetSecs - time0; end
                    pref = k;
                end
            end
            for k=1:numel(emoRect)
                if IsInRect(mx,my,emoRect{k})
                    if isempty(emotion), rtEm = GetSecs - time0; end
                    emotions = {'joy','fear','sad','tender','neutral'};
                    emotion = emotions{k};
                end
            end
            if ~isnan(pref) && ~isempty(emotion) && IsInRect(mx,my,contRect)
                while any(btn), [~,~,btn]=GetMouse(params.win); end
                break;
            end
            while any(btn), [~,~,btn]=GetMouse(params.win); end
        end
        WaitSecs(0.01);
    end
    Screen('Close',tex);
end

