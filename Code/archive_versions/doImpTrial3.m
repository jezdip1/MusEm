function S = doImpTrial(params, wavPath, taskType, isPractice, Block, trialIndex)
% doImpTrial  –  Implicit trial + room-mic capture via audioDeviceReader
% (only the mic‐capture part is modified)

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
    y   = y';                       % channels×samples
    dur = size(y,2) / params.samplerate;

    % ——————————————————————————————————————————————
    % mic‐capture: re-init & flush reader _per trial_!
    release(params.audioReader);
    params.audioReader = audioDeviceReader( ...
        'Device',          params.micDeviceName, ...
        'SampleRate',      params.samplerate, ...
        'NumChannels',     1, ...
        'SamplesPerFrame', params.samplerate ...
    );
    params.audioReader();  % flush any old buffer
    % ——————————————————————————————————————————————

    % 4) Preallocate mic buffer
    N      = ceil(dur * params.samplerate);
    recBuf = zeros(N,1);

    % 5) Fire sync‐pulse & start playback
    code = find(strcmp(taskType,{'type','num','disc','dim'}));
    syncTriggerOn(params.sync, code);
    PsychPortAudio('FillBuffer', params.pahandle, y);
    PsychPortAudio('Start',      params.pahandle, 1, 0, 1);

    % 6) Record for exactly 'dur' seconds
    tStart = tic;
    idx    = 1;
    while toc(tStart) < dur
        frame = params.audioReader();  % ~1 s of samples
        n     = numel(frame);
        if idx + n - 1 > N
            n = N - idx + 1;
        end
        recBuf(idx:idx+n-1) = frame(1:n);
        idx = idx + n;
        if idx > N, break; end
    end

    % 7) Stop playback & drop sync
    PsychPortAudio('Stop', params.pahandle, 1);
    syncTriggerOff(params.sync);

    % 8) Save the recording
    if isPractice
        fname = sprintf('%s_practice_Imp_%02d_%02d_rec.wav', params.subjID, Block, trialIndex);
    else
        fname = sprintf('%s_Imp_trial_%02d_%02d_rec.wav',    params.subjID, Block, trialIndex);
    end
    recFile = fullfile(params.resultsDir, fname);
    audiowrite(recFile, recBuf, params.samplerate);

    % 9) Behavioral responses
    [resp, rtTask]      = twoButtonResp(params, fullfile(params.pngDir, sprintf('re_%s.png',taskType)));
    [loadRating, rtLoad] = showLoadScale(params, fullfile(params.pngDir, 're_load.png'));

    % 10) Package outputs
    S.resp       = resp;
    S.rtTask     = rtTask;
    S.loadRating = loadRating;
    S.rtLoad     = rtLoad;
    S.recFile    = recFile;
end
