function S = doEmTrial(params, wavPath, isPractice, png)
    % 1) fixation
    showPNG(params, png.fix); WaitSecs(2.5);
    % 2) play audio
    [y,sr] = audioread(wavPath);
    if sr~=params.samplerate, y = resample(y, params.samplerate, sr); end
    if size(y,2)==1, y = repmat(y,1,2); end
    PsychPortAudio('FillBuffer',params.pahandle, y');
    PsychPortAudio('Start',params.pahandle,1,0,1);
    PsychPortAudio('Stop', params.pahandle,1);
    % 3) rating preference + discrete emotion
    for k=1:9
%     imgTick{k} = [260+140*(k-1) 560 340+140*(k-1) 640];   % PŘÍKLAD
    imgPref{k} = [128+336*(k-1) 670 205+336*(k-1) 740];   % PŘÍKLAD
    end
%     imgPref = {[260 560 340 640], [400 560 480 640], [540 560 620 640], [680 560 760 640], [820 560 900 640], [960 560 1040 640], [1100 560 1180 640], [1240 560 1320 640], [1380 560 1460 640]};
    imgEmot = {[1540 1230 1540+350 1230+60],[1540 1085 1540+350 1085+60], [1065 1230 1065+350 1230+60], [1065 1085 1065+350 1085+60] , [1065 1380 1065+350 1380+60]};
    imgCont = [1060 1668 1956 1912];
    [pref, emotion, rtPref, rtEm] = showEmRating(params, png.re_em, imgPref, imgEmot, imgCont);
    S = struct('pref',pref,'emotion',emotion,'rtPref',rtPref,'rtEm',rtEm);
end
