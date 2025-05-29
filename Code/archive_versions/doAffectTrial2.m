function S = doAffectTrial(params, wavPath, taskType, isPractice,Block, trialIndex, png)
% doAffectTrial  –  Dimensional‐Affect trial with room‐mic capture via audioDeviceReader
%
% Inputs:
%   params      – struct with fields:
%                   .pahandle      (PTB audio playback handle)
%                   .audioReader   (audioDeviceReader object)
%                   .samplerate    (e.g. 44100)
%                   .sync          (sync device info)
%                   .resultsDir    (where to save recordings)
%                   .subjID        (subject ID string)
%   wavPath     – full path to the stimulus WAV
%   taskType    – should be 'dim' for Affect
%   isPractice  – logical, true for practice trials
%   trialIndex  – numeric index of this trial
%   png         – struct with fields:
%                   .fix     (path to fix.png)
%                   .re_dim  (path to re_dim.png)
%
% Output S with fields:
%   .pref, .arousal, .valence, .rtDim, .recFile

    % 1) Fixation
    showPNG(params, png.fix);
    WaitSecs(2.5);

    % 2) Load & prep the stimulus
    [y, fs] = audioread(wavPath);
    if fs~=params.samplerate
        y = resample(y, params.samplerate, fs);
    end
    if size(y,2)==1
        y = repmat(y,1,2);
    end
    y    = y';                     % [channels × samples]
    dur  = size(y,2) / params.samplerate;

    % 3) Prepare for room‐mic capture
    N      = ceil(dur * params.samplerate);
    recBuf = zeros(N,1);
    idx    = 1;

    % 4) Fire sync‐pulse & start playback
    code = find(strcmp(taskType,{'type','num','disc','dim'}));
    syncTriggerOn(params.sync, code);
    PsychPortAudio('FillBuffer', params.pahandle, y);
    PsychPortAudio('Start',      params.pahandle, 1, 0, 1);

    % 5) In parallel, read from the mic until we've got dur seconds
    tStart = tic;
    while idx <= N
        frame = params.audioReader();       % blocks ~1 s
        n     = numel(frame);
        stopIdx = min(idx+n-1, N);
        recBuf(idx:stopIdx) = frame(1:(stopIdx-idx+1));
        idx = idx + n;
        if toc(tStart) > dur + 1
            break;  % safety in case playback ends early
        end
    end

    % 6) Stop playback & drop sync‐pulse
    PsychPortAudio('Stop',       params.pahandle, 1);
    syncTriggerOff(params.sync);

    % 7) Save the room‐mic recording
    if isPractice
        fname = sprintf('%s_practice_Affect_%02d_%02d_rec.wav', params.subjID,Block, trialIndex);
    else
        fname = sprintf('%s_Affect_trial_%02d_%02d_rec.wav',   params.subjID,Block, trialIndex);
    end
    recFile = fullfile(params.resultsDir, fname);
    audiowrite(recFile, recBuf, params.samplerate);

    % 8) Dimensional rating (unchanged)
    [pref, arousal, valence, rtDim] = showDimensionalScale(params, png.re_dim);

    % 9) Package results
    S.pref      = pref;
    S.arousal   = arousal;
    S.valence   = valence;
    S.rtDim     = rtDim;
    S.recFile   = recFile;
end
