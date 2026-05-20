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

S.ImpPracticeFixBaselineOnset=NaT;
S.ImpTrialFixBaselineOnset=NaT;
S.ImpPracticeSubQuestionNumOnset=NaT;
S.ImpPracticeSubQuestionTypeOnset=NaT;
S.ImpTrialSubQuestionNumOnset=NaT;
S.ImpTrialSubQuestionTypeOnset=NaT;
S.ImpPracticePlaySoundOnset=NaT;
S.ImpTrialPlaySoundOnset=NaT;
S.ImpPracticeStopSoundOnset=NaT;
S.ImpTrialStopSoundOnset=NaT;
S.ImpPracticeAnsweringNumOnset=NaT;
S.ImpPracticeAnsweringTypeOnset=NaT;
S.ImpTrialAnsweringNumOnset=NaT;
S.ImpTrialAnsweringTypeOnset=NaT;
S.ImpPracticeAnsweringLoadNumOnset=NaT;
S.ImpPracticeAnsweringLoadTypeOnset=NaT;
S.ImpTrialAnsweringLoadNumOnset=NaT;
S.ImpTrialAnsweringLoadTypeOnset=NaT;
%% 1) Show the question PNG first, then fixation before the stimulus.
    % This follows the current paradigm notes: question -> fixation 2500 ms -> stimulus.
    if isPractice
        if strcmp(taskType,'num')
            S.ImpPracticeSubQuestionNumOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpPracticeSubQuestionNumOnset);
        else
            S.ImpPracticeSubQuestionTypeOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpPracticeSubQuestionTypeOnset);
        end
    else
        if strcmp(taskType,'num')
            S.ImpTrialSubQuestionNumOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpTrialSubQuestionNumOnset);
        else
            S.ImpTrialSubQuestionTypeOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpTrialSubQuestionTypeOnset);
        end
    end
    qPNG = fullfile(params.pngDir, sprintf('q_%s.png',taskType));
    showPNG(params, qPNG);
    WaitSecs(params.questionDuration);

    %% 2) Fixation before playback
    if isPractice
        S.ImpPracticeFixBaselineOnset=datetime('now');
        syncTriggerOn(params.sync,TriggerCodes.ImpPracticeFixBaselineOnset);
    else
        S.ImpTrialFixBaselineOnset=datetime('now');
        syncTriggerOn(params.sync,TriggerCodes.ImpTrialFixBaselineOnset);
    end
    showPNG(params, fullfile(params.pngDir,'fix.png'));
    WaitSecs(params.fixDuration);

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
%     code = find(strcmp(taskType,{'type','num','disc','dim'}));
%     syncTriggerOn(params.sync, code);
    PsychPortAudio('FillBuffer', params.pahandle, y);
    showPNG(params, fullfile(params.pngDir,'stim.png'));
    if isPractice
        S.ImpPracticePlaySoundOnset=datetime('now');
        syncTriggerOn(params.sync,TriggerCodes.ImpPracticePlaySoundOnset);
        
    else
        S.ImpTrialPlaySoundOnset=datetime('now');
        syncTriggerOn(params.sync,TriggerCodes.ImpTrialPlaySoundOnset);
        
    end    
    PsychPortAudio('Start',      params.pahandle, 1, 0, 1);

    %% 6) Capture exactly N samples, block by block
    idx = 1;
    while idx <= N
        checkAbort();
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
%     syncTriggerOff(params.sync);
    if isPractice
        S.ImpPracticeStopSoundOnset=datetime('now');
        syncTriggerOn(params.sync,TriggerCodes.ImpPracticeStopSoundOnset);

    else
        S.ImpTrialStopSoundOnset=datetime('now');
        syncTriggerOn(params.sync,TriggerCodes.ImpTrialStopSoundOnset);
        
    end 
    %% 8) Save the room-mic recording
    if isPractice
        fname = sprintf('%s_practice_Imp_B%02d_T%02d_rec.wav', params.subjID, Block, trialIndex);
    else
        fname = sprintf('%s_Imp_B%02d_T%02d_rec.wav',           params.subjID, Block, trialIndex);
    end
    recDir = params.resultsDir;
    if isfield(params,'recordingsDir') && ~isempty(params.recordingsDir)
        recDir = params.recordingsDir;
    end
    if ~exist(recDir,'dir'), mkdir(recDir); end
    recFile = fullfile(recDir, fname);
    audiowrite(recFile, recBuf, params.samplerate);

    %% 9) Collect behavioral responses
    if isPractice
        if strcmp(taskType,'num')
            S.ImpPracticeAnsweringNumOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpPracticeAnsweringNumOnset);
            
        else
            S.ImpPracticeAnsweringTypeOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpPracticeAnsweringTypeOnset);

        end
    else
        if strcmp(taskType,'num')
            S.ImpTrialAnsweringNumOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpTrialAnsweringNumOnset);
        else
            S.ImpTrialAnsweringTypeOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpTrialAnsweringTypeOnset);
            
        end
    end    
    [resp,   rtTask]    = twoButtonResp( params, fullfile(params.pngDir, sprintf('re_%s.png',taskType)) );
    if isPractice
        if strcmp(taskType,'num')
            S.ImpPracticeAnsweringLoadNumOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpPracticeAnsweringLoadNumOnset);
            
        else
            S.ImpPracticeAnsweringLoadTypeOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpPracticeAnsweringLoadTypeOnset);
        end
    else
        if strcmp(taskType,'num')
            S.ImpTrialAnsweringLoadNumOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpTrialAnsweringLoadNumOnset);
        else
            S.ImpTrialAnsweringLoadTypeOnset=datetime('now');
            syncTriggerOn(params.sync,TriggerCodes.ImpTrialAnsweringLoadTypeOnset);
       end
    end     
    [loadRating, rtLoad] = showLoadScale( params, fullfile(params.pngDir, 're_load.png') );

    %% 10) Package outputs
    S.resp       = resp;
    S.rtTask     = rtTask;
    S.loadRating = loadRating;
    S.rtLoad     = rtLoad;
    S.recFile    = recFile;
end
