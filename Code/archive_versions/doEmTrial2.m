function S = doEmTrial(params, wavPath, taskType, isPractice,Block,trialIndex, png)
    % 1) fixation
    code = find(strcmp(taskType,{'type','num','disc','dim'}));
    showPNG(params, png.fix);
    WaitSecs(2.5);

    % 2) load & prepare the stimulus
    [y,sr] = audioread(wavPath);
    if sr~=params.samplerate
        y = resample(y, params.samplerate, sr);
    end
    if size(y,2)==1
        y = repmat(y,1,2);
    end
    y = y';                              % channels × samples
    dur = size(y,2) / params.samplerate;

    % 3) preallocate room-mic buffer
    N      = ceil(dur * params.samplerate);
    recBuf = zeros(N,1);
    idx    = 1;

    % 4) fire sync‐pulse and play
    syncTriggerOn(params.sync, code);
    PsychPortAudio('FillBuffer', params.pahandle, y);
    PsychPortAudio('Start',      params.pahandle, 1, 0, 1);

    % 5) in parallel, pull in mic frames until dur seconds captured
    while idx <= N
        frame = params.audioReader();    % blocks for a small chunk
        n     = numel(frame);
        stopIdx = min(idx+n-1, N);
        recBuf(idx:stopIdx) = frame(1:(stopIdx-idx+1));
        idx = idx + n;
    end

    % 6) stop playback & clear sync
    PsychPortAudio('Stop',       params.pahandle, 1);
    syncTriggerOff(params.sync);

    % 7) save the captured buffer to disk
    if isPractice
        recName = sprintf('%s_practice_Em_%02d_%02d_rec.wav', params.subjID, Block,trialIndex);
    else
        recName = sprintf('%s_Em_trial_%02d_%02d_rec.wav',   params.subjID,Block, trialIndex);
    end
%     recName = sprintf('%s_Em_%s_rec.wav', params.subjID, taskType);
    recFile = fullfile(params.resultsDir, recName);
    audiowrite(recFile, recBuf, params.samplerate);

    % 8) rating preference + discrete emotion (UNCHANGED)
    for k=1:9
        imgPref{k} = [128+336*(k-1) 670 205+336*(k-1) 740];
    end
    imgEmot = {
        [1065 1085 1415 1145],
        [1540 1085 1890 1145],
        [1065 1230 1415 1290],
        [1540 1230 1890 1290],
        [1065 1380 1415 1440]
    };
    imgCont = [1060 1668 1956 1912];

    [pref, emotion, rtPref, rtEm] = ...
        showEmRating(params, png.re_em, imgPref, imgEmot, imgCont);

    % 9) package outputs
    S = struct( ...
        'pref',      pref, ...
        'emotion',   emotion, ...
        'rtPref',    rtPref, ...
        'rtEm',      rtEm, ...
        'recFile',   recFile ...
    );
end
