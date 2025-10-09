function S = doEmTrial(params, wavPath, taskType, isPractice, Block, trialIndex, png)
% doEmTrial  –  Discrete‐Emotion trial with room‐mic capture via audioDeviceReader
%
% Inputs:
%   params      – struct with fields:
%                   .pahandle      PTB audio playback handle
%                   .audioReader   audioDeviceReader object
%                   .samplerate    e.g. 44100
%                   .sync          sync device info
%                   .resultsDir    folder to save recordings
%                   .subjID        subject identifier
%   wavPath     – full path to the stimulus .wav
%   taskType    – expected to be 'disc'
%   isPractice  – logical, true for practice trials
%   Block       – block number
%   trialIndex  – index within the block
%   png         – struct with fields:
%                   .fix     (path to fix.png)
%                   .re_em   (path to re_em.png)
%
% Output S with fields:
%   .pref, .emotion, .rtPref, .rtEm, .recFile

    %% 1) Fixation
    showPNG(params, png.fix);
    WaitSecs(2.5);

    %% 2) Load & prepare stimulus
    [y, fs] = audioread(wavPath);
    if fs~=params.samplerate
        y = resample(y, params.samplerate, fs);
    end
    if size(y,2)==1
        y = repmat(y,1,2);
    end
    y   = y';                     % [channels × samples]
    dur = size(y,2) / params.samplerate;

    %% 3) Prepare room‐mic capture
    N      = ceil(dur * params.samplerate);
    recBuf = zeros(N,1);
    % flush any leftover frames
    params.audioReader();

    %% 4) Start sync‐pulse & playback
    code = find(strcmp(taskType,{'type','num','disc','dim'}));
    syncTriggerOn(params.sync, code);
    PsychPortAudio('FillBuffer', params.pahandle, y);
    PsychPortAudio('Start',      params.pahandle, 1, 0, 1);

    %% 5) Capture exactly N samples, block by block
    idx = 1;
    while idx <= N
        frame = params.audioReader();        % up to SamplesPerFrame samples
        n     = numel(frame);
        if idx + n - 1 > N
            n = N - idx + 1;               % trim if overflow
        end
        recBuf(idx:idx+n-1) = frame(1:n);
        idx = idx + n;
    end

    %% 6) Stop playback & drop sync‐pulse
    PsychPortAudio('Stop',       params.pahandle, 1);
    syncTriggerOff(params.sync);

    %% 7) Save the room‐mic recording
    if isPractice
        recName = sprintf('%s_practice_Em_%02d_%02d_rec.wav', params.subjID, Block, trialIndex);
    else
        recName = sprintf('%s_Em_trial_%02d_%02d_rec.wav',    params.subjID, Block, trialIndex);
    end
    recFile = fullfile(params.resultsDir, recName);
    audiowrite(recFile, recBuf, params.samplerate);

    %% 8) Rating preference + discrete emotion (unchanged)
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

    %% 9) Package outputs
    S.pref      = pref;
    S.emotion   = emotion;
    S.rtPref    = rtPref;
    S.rtEm      = rtEm;
    S.recFile   = recFile;
end
