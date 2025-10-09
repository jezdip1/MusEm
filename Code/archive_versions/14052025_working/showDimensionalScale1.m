function [p,a,v,rt] = showDimensionalScale1(params,pngPath)
% Interactive 3×1–9 sliders + Continue
    img = imread(pngPath);
    [hImg,wImg,~] = size(img);
    % letterbox
    scrR = params.winRect; scrW=scrR(3); scrH=scrR(4);
    if scrW/scrH > wImg/hImg, outH=scrH; outW=round(wImg/hImg*outH);
    else,                      outW=scrW; outH=round(hImg/wImg*outW);
    end
    left=(scrW-outW)/2; top=(scrH-outH)/2;
    dest=[left top left+outW top+outH];
    % define image coords for each slider & Continue
    for k=1:9
        imgPref{k}    = [128+336*(k-1) 665 205+336*(k-1) 735];
        imgArousal{k} = [128+336*(k-1) 1110 205+336*(k-1) 1180];
        imgValence{k} = [128+336*(k-1) 1260 205+336*(k-1) 1330];
    end
    imgCont = [1060 1668 1956 1912];
    % scale coords
    for k=1:9
      pr{k} = scaleRect(imgPref{k},wImg,hImg,outW,outH,left,top);
      ar{k} = scaleRect(imgArousal{k},wImg,hImg,outW,outH,left,top);
      va{k} = scaleRect(imgValence{k},wImg,hImg,outW,outH,left,top);
    end
    contRect = scaleRect(imgCont,wImg,hImg,outW,outH,left,top);
    % show and interact
    p=NaN; a=NaN; v=NaN; t0=GetSecs;
    while true
        Screen('DrawTexture',params.win,Screen('MakeTexture',params.win,img),[],dest);
        if ~isnan(p), Screen('FillRect',params.win,[255 100 100],pr{p}); end
        if ~isnan(a), Screen('FillRect',params.win,[100 255 100],ar{a}); end
        if ~isnan(v), Screen('FillRect',params.win,[100 100 255],va{v}); end
        if params.debugClickable
            for k=1:9, Screen('FrameRect',params.win,[255 0 0],pr{k},2); end
            for k=1:9, Screen('FrameRect',params.win,[0 255 0],ar{k},2); end
            for k=1:9, Screen('FrameRect',params.win,[0 0 255],va{k},2); end
            Screen('FrameRect',params.win,[255 255 0],contRect,3);
        end
        Screen('Flip',params.win);
        [mx,my,btn] = GetMouse(params.win);
        if any(btn)
            for k=1:9
                if IsInRect(mx,my,pr{k}),    p=k; end
                if IsInRect(mx,my,ar{k}),    a=k; end
                if IsInRect(mx,my,va{k}),    v=k; end
            end
            if IsInRect(mx,my,contRect) && ~any(isnan([p,a,v]))
                while any(btn), [~,~,btn]=GetMouse(params.win); end
                break;
            end
            while any(btn), [~,~,btn]=GetMouse(params.win); end
        end
        WaitSecs(0.01);
    end
    rt = GetSecs - t0;
end