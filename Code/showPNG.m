
function showPNG(params,pngPath)
tex=Screen('MakeTexture',params.win,imread(pngPath));
Screen('DrawTexture',params.win,tex,[],params.winRect);
Screen('Flip',params.win); Screen('Close',tex);
end
