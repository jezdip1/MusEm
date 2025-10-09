function params = runEmCondition(params)
% runEmCondition  –  Discrete emotion recognition task (Em)
%   2 practice trials, feedback, 40 experimental trials in 2 blocks
%   Ratings: preference (1–9) + discrete emotion choice (5 options)

% Initialize resultsEm table if needed
if ~isfield(params,'resultsEm')
    varNames = {'subjID','isPractice','wavPath','condition', ...
                'trialIndex','block','pref','emotion','rtPref','rtEm','time'};
    varTypes = {'string','logical','string','string', ...
                'double','double','double','string','double','double','datetime'};
    params.resultsEm = table('Size',[0,numel(varNames)], ...
                             'VariableTypes',varTypes, ...
                             'VariableNames',varNames);
end

% Determine subset for Em (opposite of Affect)
idNum = str2double(params.subjID);
affOdd = mod(idNum,2)==1;
affSubset = affOdd * 1 + ~affOdd * 2;      % 1 if odd, 2 if even
emSubset  = 3 - affSubset;                  % opposite subset
% baseDir   = fileparts(mfilename('fullpath'));
emDir     = fullfile(params.stimDir,'Affect_Em',sprintf('Subset %d - 40 - wav_norm',emSubset));
pracDir   = fullfile(params.stimDir,'Affect_Em','Practice - wav_norm');

% PNG paths
P = params.pngDir;
png.instr   = fullfile(P,'inst_em.png');
png.fix     = fullfile(P,'fix.png');
png.re_em   = fullfile(P,'re_dis.png');   % discrete rating + preference scale
png.feedback= fullfile(P,'feedback.png');
png.break   = fullfile(P,'break.png');
png.endC    = fullfile(P,'condition_end.png');

% 1) Instructions
showPNGwaitClick(params, png.instr,[1060 1668 1956 1912]);  % adjust in img coords

% 2) Practice trials (2)
pfiles = dir(fullfile(pracDir,'*.wav'));
names = {pfiles.name}';
idxs  = randperm(numel(names),2);
for i=1:2
    wavPath = fullfile(pracDir,names{idxs(i)});
    doEmTrial(params, wavPath, true, 0, png);
end
showPNGwaitClick(params, png.feedback,[1060 1668 1956 1912]);

% 3) Experimental trials (40)
efiles     = dir(fullfile(emDir,'*.wav'));
enames     = {efiles.name}';           % cell array of filenames
enames     = enames(randperm(numel(enames)));  % randomize order
blocks     = repelem((1:params.nBlocks)', params.nPerBlock);
trialIdx   = repmat((1:params.nPerBlock)', params.nBlocks, 1);
for t = 1:params.nBlocks*params.nPerBlock:params.nBlocks*params.nPerBlock
    wavPath = fullfile(emDir,enames{t});
    blk = blocks(t);
    idx = trialIdx(t);
    done = strcmp(params.resultsEm.wavPath, wavPath) & params.resultsEm.block==blk;
    if any(done), continue; end
    S = doEmTrial(params, wavPath, false, blk, png);
    newRow = table(string(params.subjID), false, string(wavPath), "Em", ...
                   idx, blk, S.pref, string(S.emotion), S.rtPref, S.rtEm, ...
                   datetime('now'), 'VariableNames', params.resultsEm.Properties.VariableNames);
    params.resultsEm = [params.resultsEm; newRow];
    safeSave(params);
    if t==params.nPerBlock
        showPNGwaitClick(params, png.break, [780 720 1120 800]);
    end
end

% 4) End
showPNGwaitClick(params, png.endC,[1060 1668 1956 1912]);
end



%% Single trial for Em condition
function S = doEmTrial(params, wavPath, isPractice, block, png)
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
    imgEmot = {[1065 1085 1065+60 1085+60], [1065 1230 1065+60 1230+60], [1065 1380 1065+60 1380+60], [1540 1085 1540+60 1085+60], [1540 1230 1540+60 1230+60]};
    imgCont = [1060 1668 1956 1912];
    [pref, emotion, rtPref, rtEm] = showEmRating(params, png.re_em, imgPref, imgEmot, imgCont);
    S = struct('pref',pref,'emotion',emotion,'rtPref',rtPref,'rtEm',rtEm);
end


%% Rating UI for Em: pref(1-9) + emotion(5) + Continue
%% Rating UI for Em: pref(1-9) + emotion(5) + Continue
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

%% Utility: scaleRect ----------------------------------------
function rect = scaleRect(imgRect,wImg,hImg,outW,outH,left,top)
    sx=outW/wImg; sy=outH/hImg;
    rect=[imgRect(1)*sx+left, imgRect(2)*sy+top, imgRect(3)*sx+left, imgRect(4)*sy+top];
end

% %% Utility: showPNGwaitClick (1-button) -----------------------
% function showPNGwaitClick(params,pngPath,imgRect)
%     img = imread(pngPath); [hImg,wImg,~]=size(img);
%     tex = Screen('MakeTexture',params.win,img);
%     scrR=params.winRect; scrW=scrR(3); scrH=scrR(4);
%     if scrW/scrH > wImg/hImg, outH=scrH; outW=round(wImg/hImg*outH);
%     else,                     outW=scrW; outH=round(hImg/wImg*outW); end
%     left=(scrW-outW)/2; top=(scrH-outH)/2;
%     dest=[left top left+outW top+outH];
%     rect = scaleRect(imgRect,wImg,hImg,outW,outH,left,top);
%     Screen('DrawTexture',params.win,tex,[],dest);
%     if params.debugClickable, Screen('FrameRect',params.win,[255 0 0],rect,3); end
%     Screen('Flip',params.win);
%     while true
%         [mx,my,btn] = GetMouse(params.win);
%         if any(btn) && IsInRect(mx,my,rect)
%             while any(btn), [~,~,btn]=GetMouse(params.win); end; break;
%         end; WaitSecs(0.01);
%     end; Screen('Close',tex);
% end
% 
% %% Utility: showPNG -------------------------------------------
% function showPNG(params,pngPath)
%     tex = Screen('MakeTexture',params.win,imread(pngPath));
%     Screen('DrawTexture',params.win,tex,[],params.winRect);
%     Screen('Flip',params.win); Screen('Close',tex);
% end

