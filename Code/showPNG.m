function showPNG(params,pngPath)
% showPNG  Draw a PNG without waiting, preserving aspect ratio.
    if ~exist(pngPath,'file')
        error('PNG not found: %s', pngPath);
    end

    img = imread(pngPath);
    [imgH,imgW,~] = size(img);
    tex = Screen('MakeTexture',params.win,img);

    scrR = params.winRect;
    scrW = scrR(3)-scrR(1);
    scrH = scrR(4)-scrR(2);
    if scrW/scrH > imgW/imgH
        outH = scrH;
        outW = round(imgW/imgH*outH);
    else
        outW = scrW;
        outH = round(imgH/imgW*outW);
    end
    left = scrR(1) + (scrW-outW)/2;
    top  = scrR(2) + (scrH-outH)/2;
    dest = [left top left+outW top+outH];

    Screen('DrawTexture',params.win,tex,[],dest);
    Screen('Flip',params.win);
    Screen('Close',tex);
end
