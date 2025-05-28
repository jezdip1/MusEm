function S = doImpTrial(params, wavPath, taskType, isPractice, Block,trialIndex)
% doImpTrial  –  Implicit trial + room-mic capture via audioDeviceReader

    % 1) Show question
    showPNG(params, fullfile(params.pngDir, sprintf('q_%s.png',taskType)));
    WaitSecs(2.5);

    % 2) Show fixation
    showPNG(params, fullfile(params.pngDir, 'fix.png'));

    % 3) Load & prep stimulus
    [y, fs] = audioread(wavPath);
    if fs~=params.samplerate
        y = resample(y, params.samplerate, fs);
    end
    if size(y,2)==1
        y = repmat(y,1,2);
    end
    y = y';  % channels×samples
    dur = size(y,2) / params.samplerate;

    % 4) Preallocate mic buffer
    N     = ceil(dur * params.samplerate);
    recBuf = zeros(N,1);
    idx   = 1;

    % 5) Raise sync‐pulse & start playing
    code = find(strcmp(taskType,{'type','num','disc','dim'}));
    syncTriggerOn(params.sync, code);
    PsychPortAudio('FillBuffer', params.pahandle, y);
    PsychPortAudio('Start',      params.pahandle, 1, 0, 1);

    % 6) In parallel: pull mic frames until we've got dur seconds
    tStart = tic;
    while idx <= N
        frame = params.audioReader();  % blocking ~1s or less
        n     = size(frame,1);
        stopIdx = min(idx+n-1, N);
        recBuf(idx:stopIdx) = frame(1:(stopIdx-idx+1));
        idx = idx + n;
        % If we somehow overshoot because playback ended early:
        if toc(tStart) > dur + 1
            break;
        end
    end

    % 7) Stop playback & sync‐pulse
    PsychPortAudio('Stop',       params.pahandle, 1);
    syncTriggerOff(params.sync);

    % 8) Save mic recording
    if isPractice
        fname = sprintf('%s_practice_Imp_%02d_%02d_rec.wav', params.subjID, Block,trialIndex);
    else
        fname = sprintf('%s_Imp_trial_%02d_%02d_rec.wav',    params.subjID,Block, trialIndex);
    end
    recFile = fullfile(params.resultsDir, fname);
    audiowrite(recFile, recBuf, params.samplerate);

    % 9) Behavioral responses
    [resp,   rtTask]   = twoButtonResp( params, fullfile(params.pngDir, sprintf('re_%s.png',taskType)) );
    [loadRating, rtLoad] = showLoadScale( params, fullfile(params.pngDir, 're_load.png') );

    % 10) Package outputs
    S.resp        = resp;
    S.rtTask      = rtTask;
    S.loadRating  = loadRating;
    S.rtLoad      = rtLoad;
    S.recFile     = recFile;
end
