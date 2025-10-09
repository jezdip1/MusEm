function showPNGwaitClick(params, pngPath, imgCont)
% showPNGwaitClick  –  zobrazí PNG a čeká na klik v button‑rectu
%   imgCont  –  [x1 y1 x2 y2] v souřadnicích originálního obrázku

% ---------- načti PNG + zjisti velikost -------------------------------
img  = imread(pngPath);
[imgH,imgW,~] = size(img);
tex  = Screen('MakeTexture', params.win, img);

% ---------- urči, kam se PNG vykreslí (letterbox/pillarbox) -----------
scrR = params.winRect;  scrW = scrR(3);  scrH = scrR(4);
if (scrW/scrH) > (imgW/imgH)        % displej širší -> plná výška
    outH = scrH;             outW = round(imgW/imgH * outH);
else                                 % displej užší -> plná šířka
    outW = scrW;             outH = round(imgH/imgW * outW);
end
left = (scrW - outW)/2;   top = (scrH - outH)/2;
dest = [left top left+outW top+outH];

% ---------- přepočítej klikací rect na Screen‑coords ------------------
contRect = scaleRect(imgCont, imgW, imgH, outW, outH, left, top);

% ---------- vykresli ---------------------------------------------------
Screen('DrawTexture', params.win, tex, [], dest);
if params.debugClickable
    Screen('FrameRect', params.win, [255 0 0], contRect, 3);
end
Screen('Flip', params.win);
ShowCursor('Arrow', params.win);
% ---------- čekej na klik uvnitř obdélníku ----------------------------
while true
    [mx,my,but] = GetMouse(params.win);
    if any(but) && IsInRect(mx,my,contRect)
        while any(but)      % vyčkej na uvolnění tlačítka
            [~,~,but] = GetMouse(params.win);
        end
        break;              % potvrzeno
    end
    WaitSecs(0.01);
end
Screen('Close', tex);
end
