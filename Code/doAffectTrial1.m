function S = doAffectTrial(params, wavPath,taskType, isPractice,png)
% Single trial: fixation, audio, dimensional rating
    code = find(strcmp(taskType,{'type','num','disc','dim'}));

    showPNG(params, [params.pngDir , filesep , 'fix.png']);
    WaitSecs(2.5);
    % play audio
    [y,sr] = audioread(wavPath);
    if sr~=params.samplerate, y=resample(y, params.samplerate, sr); end
    if size(y,2)==1, y=repmat(y,1,2); end
    PsychPortAudio('FillBuffer',params.pahandle,y');
    syncTriggerOn(params.sync, code);
    PsychPortAudio('Start',params.pahandle,1,0,1);
    PsychPortAudio('Stop', params.pahandle,1);
    syncTriggerOff(params.sync);    
    % dimensional rating (pref, arousal, valence)
    [pref, arousal, valence, rtDim] = showDimensionalScale(params, png.re_dim);
    S = struct('pref',pref,'arousal',arousal,'valence',valence,'rtDim',rtDim);
end