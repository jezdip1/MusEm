%% runImpCondition.m
function params = runImpCondition(params)
    % Paths to PNG
    P = params.pngDir;
    png = struct(...
      'instr', fullfile(P,'inst_imp.png'),...
      'q_num', fullfile(P,'q_num.png'),...
      'q_type',fullfile(P,'q_type.png'),...
      'fix',  fullfile(P,'fix.png'),...
      're_num',fullfile(P,'re_num.png'),...
      're_type',fullfile(P,'re_type.png'),...
      're_load',fullfile(P,'re_load.png'),...
      'feedback',fullfile(P,'feedback.png'),...
      'break',fullfile(P,'break.png'),...
      'endC', fullfile(P,'condition_end.png')...
    );
%     imgCont = [1060 1668 1956 1912];     
    showPNGwaitClick(params, png.instr, [1060 1668 1956 1912]);
    % 1) Practice
    for i=1:height(params.pracTrials)
        row = params.pracTrials(i,:);
        done = params.resultsTable.isPractice & params.resultsTable.trialIndex==row.trialIndex;
        if any(done), continue; end
        S = doTrial(params, row.wavPath{1}, row.taskType{1}, true);
        newRow = table(string(params.subjID), true, string(row.wavPath), ...
            string(row.taskType), row.trialIndex, 0, string(S.resp), S.rtTask, ...
            S.loadRating, S.rtLoad, datetime('now'), ...
            'VariableNames', params.resultsTable.Properties.VariableNames);
        params.resultsTable = [params.resultsTable; newRow];
        safeSave(params);
    end
    showPNGwaitClick(params, png.feedback, [1060 1668 1956 1912]);

    % 2) Experimental blocks
    for b = 1:params.nBlocks
        showPNGwaitClick(params, png.break, [1060 1668 1956 1912]);
        rows = find(params.expTrials.block==b);
        for j=rows'
            row = params.expTrials(j,:);
            done = ~params.resultsTable.isPractice & ...
                   params.resultsTable.trialIndex==row.trialIndex & ...
                   params.resultsTable.block==row.block;
            if any(done), continue; end
            S = doTrial(params, row.wavPath{1}, row.taskType{1}, false);
            newRow = table(string(params.subjID), false, string(row.wavPath), ...
                string(row.taskType), row.trialIndex, row.block, string(S.resp), ...
                S.rtTask, S.loadRating, S.rtLoad, datetime('now'), ...
                'VariableNames', params.resultsTable.Properties.VariableNames);
            params.resultsTable = [params.resultsTable; newRow];
            safeSave(params);
        end
    end
    showPNGwaitClick(params, png.endC, [1060 1668 1956 1912]);
%         showPNGwaitClick(params, png.endC, [800 750 1100 820]);
end


%% single trial helper
function S = doTrial(params, wavPath, taskType, isPractice)
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
    PsychPortAudio('Start',params.pahandle,1,0,1);
    PsychPortAudio('Stop', params.pahandle,1);
    % 4) two-button
    [resp, rtTask] = twoButtonResp(params, [params.pngDir , filesep , sprintf('re_%s.png',taskType)]);
    % 5) load scale
    [loadRating, rtLoad] = showLoadScale(params, [params.pngDir , filesep , 're_load.png']);
    % collect
    S = struct('resp',resp,'rtTask',rtTask,'loadRating',loadRating,'rtLoad',rtLoad);
end
