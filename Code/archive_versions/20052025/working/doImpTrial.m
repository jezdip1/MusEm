function S = doImpTrial(params, wavPath, taskType, isPractice)
    % 1) question
%     rectQ = [300 700 600 780];
    showPNG(params, [params.pngDir , filesep , sprintf('q_%s.png',taskType)]);
    WaitSecs(2.5);
    % 2) fixation
    showPNG(params, [params.pngDir , filesep , 'fix.png']);
%     WaitSecs(2.5);
    % 3) audio
    [y,sr] = audioread(wavPath);
    if sr~=params.samplerate, y=resample(y,params.samplerate,sr); end
    if size(y,2)==1, y=repmat(y,1,2); end
    PsychPortAudio('FillBuffer',params.pahandle,y');
%         PsychPortAudio('Start', params.recHandle, 0, 0, 1);
%     starttime=PsychPortAudio('Start', params.recHandle,1,0,0,inf,0);
    PsychPortAudio('Start',params.pahandle,1,0,1);
    PsychPortAudio('Stop', params.pahandle,1);
%     PsychPortAudio('Stop', params.recHandle);
%     recData = PsychPortAudio('GetAudioData', params.recHandle);
%     if isPractice
%         fn = fullfile(params.resultsDir, sprintf('%s_practice_%02d_rec.wav', params.subjID, params.trialIndex));
%     else
%         fn = fullfile(params.resultsDir, sprintf('%s_trial_%02d_rec.wav', params.subjID, params.trialIndex));
%     end
%     audiowrite(fn, recData, params.samplerate);
    % 4) two-button
    [resp, rtTask] = twoButtonResp(params, [params.pngDir , filesep , sprintf('re_%s.png',taskType)]);
    % 5) load scale
    [loadRating, rtLoad] = showLoadScale(params, [params.pngDir , filesep , 're_load.png']);
    % collect
    S = struct('resp',resp,'rtTask',rtTask,'loadRating',loadRating,'rtLoad',rtLoad);
end
