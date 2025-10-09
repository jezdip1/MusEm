function S = doAffectTrial(params, wavPath, taskType, isPractice, Block, trialIndex, png)
% doAffectTrial  –  Dimensional-Affect trial with room-mic capture
%
% Inputs (only relevant fields shown):
%   params.audioReader   – audioDeviceReader object
%   params.pahandle      – PTB audio playback handle
%   params.samplerate    – e.g. 44100
%   params.sync          – sync device info
%   params.resultsDir    – folder to save recordings
%   params.subjID        – subject identifier
%   png.fix              – path to fix.png
%   png.re_dim           – path to re_dim.png
%
% Output:
%   S.pref, S.arousal, S.valence, S.rtDim, S.recFile

    % 1) Fixation
    showPNG(params, png.fix);
    WaitSecs(2.5);

    % 2) Load & prepare stimulus
    [y, fs] = audioread(wavPath);
    if fs~=params.samplerate
        y = resample(y, params.samplerate, fs);
    end
    if size(y,2)==1
        y = repmat(y,1,2);
    end
    % compute duration in seconds
    dur = size(y,1) / params.samplerate;

    % 3) Prepare recording buffer
    N      = ceil(dur * params.samplerate);
    recBuf = zeros(N, 1);
    idx    = 1;

    % 4) Flush any leftover mic frames
    params.audioReader();

    % 5) Fire sync-pulse & start playback
    code = find(strcmp(taskType,{'type','num','disc','dim'}));
    syncTriggerOn(params.sync, code);
    PsychPortAudio('FillBuffer', params.pahandle, y');
    PsychPortAudio('Start',      params.pahandle, 1, 0, 1);

    % 6) Capture exactly N samples, block by block
    while idx <= N
        frame = params.audioReader();          % returns up to blockSize samples
        n     = numel(frame);
        if idx + n - 1 > N
            n = N - idx + 1;                  % trim if it would overflow
        end
        recBuf(idx:idx+n-1) = frame(1:n);
        idx = idx + n;
    end

    % 7) Stop playback & lower sync-pulse
    PsychPortAudio('Stop', params.pahandle, 1);
    syncTriggerOff(params.sync);

    % 8) Save recorded audio
    if isPractice
        fname = sprintf('%s_practice_Affect_%02d_%02d_rec.wav', params.subjID, Block, trialIndex);
    else
        fname = sprintf('%s_Affect_trial_%02d_%02d_rec.wav',   params.subjID, Block, trialIndex);
    end
    recFile = fullfile(params.resultsDir, fname);
    audiowrite(recFile, recBuf, params.samplerate);

    % 9) Dimensional rating (unchanged)
    [pref, arousal, valence, rtDim] = showDimensionalScale(params, png.re_dim);

    % 10) Package outputs
    S.pref      = pref;
    S.arousal   = arousal;
    S.valence   = valence;
    S.rtDim     = rtDim;
    S.recFile   = recFile;
end
