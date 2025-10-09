%% -------------  interaktivní stupnice 1-9 ------------------------------

function [rating, rt] = showLoadScale(params,pngFile)

img  = imread(pngFile);
[imgH,imgW,~] = size(img);
tex  = Screen('MakeTexture',params.win,img);

scrR = params.winRect; scrW=scrR(3); scrH=scrR(4);
if (scrW/scrH) > (imgW/imgH), outH=scrH; outW=round(imgW/imgH*outH);
else,                          outW=scrW; outH=round(imgH/imgW*outW);
end
left=(scrW-outW)/2; top=(scrH-outH)/2; dest=[left top left+outW top+outH];

% ------------ obdélníky ticků A Continue v OBRAZKU -------------------
for k=1:9
%     imgTick{k} = [260+140*(k-1) 560 340+140*(k-1) 640];   % PŘÍKLAD
    imgTick{k} = [128+336*(k-1) 960 205+336*(k-1) 1030];   % PŘÍKLAD
end
% imgCont = [780 720 1120 800];                             % PŘÍKLAD
imgCont = [1060 1668 1956 1912];                             % PŘÍKLAD

for k=1:9, tick{k}=scaleRect(imgTick{k},imgW,imgH,outW,outH,left,top); end
contRect = scaleRect(imgCont ,imgW,imgH,outW,outH,left,top);

rating = NaN;   tStart = GetSecs;

while true
    % -- překresli PNG + případné zvýraznění zvoleného tikku ----------
    Screen('DrawTexture',params.win,tex,[],dest);
    if ~isnan(rating)
        Screen('FillRect',params.win,[50 100 255 150],tick{rating});
    end
    if params.debugClickable
        for k=1:9, Screen('FrameRect',params.win,[0 255 0],tick{k},2); end
        Screen('FrameRect',params.win,[255 0 0],contRect,3);
    end
    Screen('Flip',params.win);
    ShowCursor('Arrow', params.win);
    [mx,my,but] = GetMouse(params.win);
    if any(but)
        for k=1:9
            if IsInRect(mx,my,tick{k}), rating=k; end
        end
        if IsInRect(mx,my,contRect) && ~isnan(rating)
            while any(but), [~,~,but]=GetMouse(params.win); end
            break;                      % potvrzení
        end
        while any(but), [~,~,but]=GetMouse(params.win); end
    end
    WaitSecs(0.01);
end
rt = GetSecs - tStart;
Screen('Close',tex);
end

