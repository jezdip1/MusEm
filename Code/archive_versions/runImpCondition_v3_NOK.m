% runImpCondition.m
function params = runImpCondition(params)
% Runs the Imp condition, logging into params.resultsTable

    png = struct( ...
      'instr', fullfile(params.pngDir,'inst_imp.png'), ...
      'q_num', fullfile(params.pngDir,'q_num.png'), ...
      'q_type',fullfile(params.pngDir,'q_type.png'), ...
      'fix',  fullfile(params.pngDir,'fix.png'), ...
      're_num',fullfile(params.pngDir,'re_num.png'), ...
      're_type',fullfile(params.pngDir,'re_type.png'), ...
      're_load',fullfile(params.pngDir,'re_load.png'), ...
      'feedback',fullfile(params.pngDir,'feedback.png'), ...
      'break',fullfile(params.pngDir,'break.png'), ...
      'endC', fullfile(params.pngDir,'condition_end.png') ...
    );

    % 1) Practice block (4)
    for i = 1:height(params.pracTrials)
        row = params.pracTrials(i,:);
        % skip if already done
        done = params.resultsTable.isPractice & ...
               params.resultsTable.trialIndex==row.trialIndex;
        if any(done), continue; end

        S = doTrial(params, row.wavFile{1}, row.taskType{1}, true, png);
        % append to resultsTable
        newRow = table(string(params.subjID), true, string(row.wavFile), ...
                       string(row.taskType), row.trialIndex, 0, ...
                       string(S.resp), S.rtTask, S.loadRating, S.rtLoad, ...
                       datetime('now'), ...
                       'VariableNames', params.resultsTable.Properties.VariableNames);
        params.resultsTable = [params.resultsTable; newRow];
        safeSave(params);
    end

    showPNGwaitClick(params, png.feedback, [800 750 1100 820]);  % adjust rect

    % 2) Experimental blocks
    for phase = 1:2
      drawnow;  % flush UI
      showPNGwaitClick(params, png.break, [780 720 1120 800]); % pause rect
      blockRows = find(params.expTrials.block==phase);
      for j = blockRows'
        row = params.expTrials(j,:);
        done = ~params.resultsTable.isPractice & ...
               params.resultsTable.trialIndex==row.trialIndex & ...
               params.resultsTable.block==row.block;
        if any(done), continue; end

        S = doTrial(params, row.wavFile{1}, row.taskType{1}, false, png, row.block);
        newRow = table(string(params.subjID), false, string(row.wavFile), ...
                       string(row.taskType), row.trialIndex, row.block, ...
                       string(S.resp), S.rtTask, S.loadRating, S.rtLoad, ...
                       datetime('now'), ...
                       'VariableNames', params.resultsTable.Properties.VariableNames);
        params.resultsTable = [params.resultsTable; newRow];
        safeSave(params);
      end
    end

    showPNGwaitClick(params, png.endC, [800 750 1100 820]);  % adjust rect
end


%% -------------------- single trial helper ----------------------------
function S = doTrial(params, wavName, taskType, isPractice, png, block)
    if nargin<6, block = 0; end

    % 1) question
%     showPNGwaitClick(params, png.(sprintf('q_%s',taskType)), [300 700 600 780]);
    showPNG(params, png.(sprintf('q_%s',taskType)));
    WaitSecs(2.5);
    % 2) fixation
    showPNG(params, png.fix);
%     WaitSecs(2.5);

    % 3) play audio
    [y, sr] = audioread(wavName);
    if sr~=params.samplerate, y = resample(y, params.samplerate, sr); end
    if size(y,2)==1, y = repmat(y,1,2); end
    PsychPortAudio('FillBuffer',params.pahandle, y');
    PsychPortAudio('Start',params.pahandle,1,0,1);
    PsychPortAudio('Stop', params.pahandle,1);

    % 4) two-button response
    [resp, rtTask] = twoButtonResp(params, png.(sprintf('re_%s',taskType)));

    % 5) load scale
    [loadRating, rtLoad] = showLoadScale(params, png.re_load);

    % Pack results
    S = struct( ...
      'resp', resp, ...
      'rtTask', rtTask, ...
      'loadRating', loadRating, ...
      'rtLoad', rtLoad ...
    );
end


%% ------------ reusable UIs with scaled click-rects ------------------
function showPNGwaitClick(params, pngPath, imgRect)
    % imgRect = [x1 y1 x2 y2] in original-image coords
    img = imread(pngPath);
    [imgH,imgW,~] = size(img);
    tex = Screen('MakeTexture',params.win,img);

    % compute letterboxed dest:
    scrR = params.winRect; scrW=scrR(3); scrH=scrR(4);
    if scrW/scrH > imgW/imgH
      outH = scrH; outW = round(imgW/imgH*outH);
    else
      outW = scrW; outH = round(imgH/imgW*outW);
    end
    left=(scrW-outW)/2; top=(scrH-outH)/2;
    dest=[left top left+outW top+outH];

    % scale the click-rect
    scaleX = outW / imgW; scaleY = outH / imgH;
    scrRect = [imgRect([1 2])*[scaleX;scaleY] + [left;top]' , ...
               imgRect([3 4])*[scaleX;scaleY] + [left;top]'];

    % draw & flip
    Screen('DrawTexture',params.win,tex,[],dest);
    if params.debugClickable
        Screen('FrameRect',params.win,[255 0 0],scrRect,3);
    end
    Screen('Flip',params.win);

    % wait for click in scrRect
    while true
      [mx,my,buttons] = GetMouse(params.win);
      if any(buttons) && IsInRect(mx,my,scrRect)
        while any(buttons)
          [~,~,buttons] = GetMouse(params.win);
        end
        break
      end
      WaitSecs(0.01);
    end
    Screen('Close',tex);
end

function showPNG(params,pngPath)
    tex = Screen('MakeTexture',params.win,imread(pngPath));
    Screen('DrawTexture',params.win,tex,[],params.winRect);
    Screen('Flip',params.win);
    Screen('Close',tex);
end


%% ------------- two-button response (scaled) ---------------------------
function [resp, rt] = twoButtonResp(params, pngPath)
    img = imread(pngPath);
    [imgH,imgW,~] = size(img);
    tex = Screen('MakeTexture',params.win,img);

    % letterbox
    scrR = params.winRect; scrW=scrR(3); scrH=scrR(4);
    if scrW/scrH > imgW/imgH
      outH = scrH; outW = round(imgW/imgH*outH);
    else
      outW = scrW; outH = round(imgH/imgW*outW);
    end
    left=(scrW-outW)/2; top=(scrH-outH)/2;
    dest=[left top left+outW top+outH];

    % define image-coords of btn1/btn2
    imgBtn1 = [300 700 600 780];
    imgBtn2 = [680 700 980 780];
    scaleX = outW/imgW; scaleY = outH/imgH;
    btn1 = [imgBtn1(1)*scaleX+left, imgBtn1(2)*scaleY+top, ...
            imgBtn1(3)*scaleX+left, imgBtn1(4)*scaleY+top];
    btn2 = [imgBtn2(1)*scaleX+left, imgBtn2(2)*scaleY+top, ...
            imgBtn2(3)*scaleX+left, imgBtn2(4)*scaleY+top];

    % draw & flip
    Screen('DrawTexture',params.win,tex,[],dest);
    if params.debugClickable
        Screen('FrameRect',params.win,[255 0 0],btn1,3);
        Screen('FrameRect',params.win,[255 0 0],btn2,3);
    end
    Screen('Flip',params.win);
    t0 = GetSecs;

    resp = "";
    while resp==""
        [mx,my,btn] = GetMouse(params.win);
        if any(btn)
            if IsInRect(mx,my,btn1), resp = "btn1";
            elseif IsInRect(mx,my,btn2), resp="btn2"; end
            while any(btn), [~,~,btn] = GetMouse(params.win); end
        end
        WaitSecs(0.01);
    end
    rt = GetSecs - t0;
    Screen('Close',tex);
end


%% ------------- interactive 1–9 scale (scaled) ------------------------
function [rating, rt] = showLoadScale(params,pngPath)
    img = imread(pngPath);
    [imgH,imgW,~] = size(img);
    tex = Screen('MakeTexture',params.win,img);

    scrR = params.winRect; scrW=scrR(3); scrH=scrR(4);
    if scrW/scrH > imgW/imgH
      outH = scrH; outW = round(imgW/imgH*outH);
    else
      outW = scrW; outH = round(imgH/imgW*outW);
    end
    left=(scrW-outW)/2; top=(scrH-outH)/2;
    dest=[left top left+outW top+outH];

    % image-coords for ticks & continue
    for k=1:9
        imgTick{k} = [260+140*(k-1) 560 340+140*(k-1) 640];
    end
    imgCont = [780 720 1120 800];

    scaleX = outW/imgW; scaleY = outH/imgH;
    for k=1:9
        tick{k} = [imgTick{k}(1)*scaleX+left, imgTick{k}(2)*scaleY+top, ...
                   imgTick{k}(3)*scaleX+left, imgTick{k}(4)*scaleY+top];
    end
    contRect = [imgCont(1)*scaleX+left, imgCont(2)*scaleY+top, ...
                imgCont(3)*scaleX+left, imgCont(4)*scaleY+top];

    rating = NaN;
    tStart = GetSecs;
    while true
        Screen('DrawTexture',params.win,tex,[],dest);
        if ~isnan(rating)
            Screen('FillRect',params.win,[50 100 255 150],tick{rating});
        end
        if params.debugClickable
            for k=1:9, Screen('FrameRect',params.win,[0 255 0],tick{k},2); end
            Screen('FrameRect',params.win,[255 0 0],contRect,3);
        end
        Screen('Flip',params.win);

        [mx,my,btn] = GetMouse(params.win);
        if any(btn)
            for k=1:9
                if IsInRect(mx,my,tick{k}), rating=k; end
            end
            if IsInRect(mx,my,contRect) && ~isnan(rating)
                while any(btn), [~,~,btn]=GetMouse(params.win); end
                break;
            end
            while any(btn), [~,~,btn]=GetMouse(params.win); end
        end
        WaitSecs(0.01);
    end
    rt = GetSecs - tStart;
    Screen('Close',tex);
end
