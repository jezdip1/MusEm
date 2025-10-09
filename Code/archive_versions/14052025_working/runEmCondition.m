%% runEmCondition.m
function params = runEmCondition(params)
% runEmCondition  –  Discrete Emotion task

% PNG paths
P           = params.pngDir;
png.instr   = fullfile(P,'inst_em.png');
png.fix     = fullfile(P,'fix.png');
png.re_em   = fullfile(P,'re_dis.png');
png.feedback= fullfile(P,'feedback.png');
png.break   = fullfile(P,'break.png');
png.endC    = fullfile(P,'condition_end.png');

% Filter only Em rows
sched = params.masterSchedule(strcmp(params.masterSchedule.Condition,'Em'),:);
runatleastonce=0;
for i = 1:height(sched)
    r = sched(i,:);
    % Skip if done
    done = strcmp(params.resultsTable.WavPath, r.WavPath) & ...
           params.resultsTable.TrialIndex==r.TrialIndex & ...
           strcmp(params.resultsTable.Condition,'Em');
    if any(done)
        continue;
    end
    % Instructions
    if i==1
        showPNGwaitClick(params,png.instr,[1060 1668 1956 1912]);
    end

    % Run trial
    S = doEmTrial(params, r.WavPath{1}, r.IsPractice,png);
    % Append
    newRow = { 'Em', r.IsPractice, r.WavPath{1}, r.TaskType{1}, ...
               r.TrialIndex, r.Block, '', 0, 0, 0, ... % resp/rtTask/load unused
               NaN, NaN, NaN, S.emotion, NaN, S.rtEm, datetime('now') };
    params.resultsTable = [params.resultsTable; newRow];
    safeSave(params);
    % Practice feedback
    if r.IsPractice && r.TrialIndex==params.nPracticeEm 
        showPNGwaitClick(params,png.feedback,[1060 1668 1956 1912]);
    end
    % Block break
    if ~r.IsPractice && r.TrialIndex==params.nPerBlock && r.Block<params.nBlocks && runatleastonce>0
        showPNGwaitClick(params,png.break,[1060 1668 1956 1912]);
    end
    runatleastonce=1;
end
if runatleastonce>0
    showPNGwaitClick(params,png.endC,[1060 1668 1956 1912]);
end
end
