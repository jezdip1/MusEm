function S = doImpTrial(params, wavPath, taskType, isPractice, Block, trialIndex)
% doImpTrial  –  Implicit (Non-emotional) trial with room-mic capture via audioDeviceReader
%
% Inputs:
%   params      – struct with fields:
%                   .pahandle      PTB audio playback handle
%                   .audioReader   audioDeviceReader object
%                   .samplerate    e.g. 44100
%                   .sync          sync device info
%                   .resultsDir    folder to save recordings
%                   .subjID        subject identifier string
%   wavPath     – full path to the stimulus .wav
%   taskType    – 'num' or 'type'
%   isPractice  – logical, true for practice trials
%   Block       – block number
%   trialIndex  – index within the block
%
% Output:
%   S struct with fields:
%     resp, rtTask, loadRating, rtLoad, recFile

    %% 1) Show the question PNG
    qPNG = fullfile(params.pngDir, sprintf('q_%s.png',taskType));
    showPNG(params, qPNG);
    WaitSecs(2.5);

    %% 2) Fixation
    showPNG(params, fullfile(params.pngDir,'fix.png'));

    %% 3) Load & prepare stimulus
    [y, fs] = audioread(wavPath);
    if fs~=params.samplerate
        y = resample(y, params.samplerate, fs);
    end
    if size(y,2)==1
        y = repmat(y,1,2);        % mono→stereo
    end
    y   = y';                     % [channels×samples]
    dur = size(y,2) / params.samplerate;

    %% 4) Preallocate mic buffer & flush old samples
    N      = ceil(dur * params.samplerate);
    recBuf = zeros(N,1);
    params.audioReader();         % drop any leftover

    %% 5) Start sync‐pulse & playback
    code = find(strcmp(taskType,{'type','num','disc','dim'}));
    syncTriggerOn(params.sync, code);
    PsychPortAudio('FillBuffer', params.pahandle, y);
    PsychPortAudio('Start',      params.pahandle, 1, 0, 1);

    %% 6) Capture exactly N samples, block by block
    idx = 1;
    while idx <= N
        frame = params.audioReader();  % returns up to SamplesPerFrame
        n     = numel(frame);
        if idx + n - 1 > N
            n = N - idx + 1;          % avoid overflow
        end
        recBuf(idx:idx+n-1) = frame(1:n);
        idx = idx + n;
    end

    %% 7) Stop playback & clear sync‐pulse
    PsychPortAudio('Stop', params.pahandle, 1);
    syncTriggerOff(params.sync);

    %% 8) Save the room-mic recording
    if isPractice
        fname = sprintf('%s_practice_Imp_B%02d_T%02d_rec.wav', params.subjID, Block, trialIndex);
    else
        fname = sprintf('%s_Imp_B%02d_T%02d_rec.wav',           params.subjID, Block, trialIndex);
    end
    recFile = fullfile(params.resultsDir, fname);
    audiowrite(recFile, recBuf, params.samplerate);

    %% 9) Collect behavioral responses
    [resp,   rtTask]    = twoButtonResp( params, fullfile(params.pngDir, sprintf('re_%s.png',taskType)) );
    [loadRating, rtLoad] = showLoadScale( params, fullfile(params.pngDir, 're_load.png') );

    %% 10) Package outputs
    S.resp       = resp;
    S.rtTask     = rtTask;
    S.loadRating = loadRating;
    S.rtLoad     = rtLoad;
    S.recFile    = recFile;
end
