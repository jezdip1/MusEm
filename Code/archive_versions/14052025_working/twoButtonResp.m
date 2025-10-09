%% -------------  DVOUTLAČÍTKOVÁ odpověď  -------------------------------


function [resp, rt] = twoButtonResp(params, pngFile)

% ---- načti PNG + zjisti originální velikost -------------------------
img = imread(pngFile);
[imgH, imgW, ~] = size(img);
tex  = Screen('MakeTexture', params.win, img);

% ---- kam se PNG kreslí na monitoru (zachovat poměr stran) -----------
scrR = params.winRect;  scrW = scrR(3);  scrH = scrR(4);
if (scrW/scrH) > (imgW/imgH)      % displej širší → plná výška
    outH = scrH;  outW = round(imgW/imgH * outH);
else                               % displej užší → plná šířka
    outW = scrW;  outH = round(imgH/imgW * outW);
end
left = (scrW-outW)/2;  top = (scrH-outH)/2;
dest = [left top left+outW top+outH];

% ---- obdélníky tlačítek v OBRAZKU (doplňte svá čísla) ---------------
imgBtn1 = [950 950 1350 1200];   % příklad
imgBtn2 = [1650 950 2050 1200];   % příklad

btn1 = scaleRect(imgBtn1, imgW, imgH, outW, outH, left, top);
btn2 = scaleRect(imgBtn2, imgW, imgH, outW, outH, left, top);

% ---- kresli ----------------------------------------------------------
Screen('DrawTexture', params.win, tex, [], dest);
if params.debugClickable
    Screen('FrameRect', params.win, [255 0 0], btn1, 3);
    Screen('FrameRect', params.win, [255 0 0], btn2, 3);
end
Screen('Flip', params.win);  t0 = GetSecs;
ShowCursor('Arrow', params.win);
% ---- čekej na klik ---------------------------------------------------
resp = '';
while isempty(resp)
    [mx,my,but] = GetMouse(params.win);
    if any(but)
        if IsInRect(mx,my,btn1), resp='btn1';
        elseif IsInRect(mx,my,btn2), resp='btn2'; end
        while any(but), [~,~,but]=GetMouse(params.win); end
    end
    WaitSecs(0.01);
end
rt = GetSecs - t0;
Screen('Close', tex);
end


