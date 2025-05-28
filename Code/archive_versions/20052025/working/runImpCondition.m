%% runImpCondition.m
function params = runImpCondition(params)
% runImpCondition  –  Non‐emotional Implicit task
%   Uses params.masterSchedule and params.resultsTable

% PNG paths
P         = params.pngDir;
png.instr = fullfile(P,'inst_imp.png');
png.fix   = fullfile(P,'fix.png');
png.q_num = fullfile(P,'q_num.png');
png.q_type= fullfile(P,'q_type.png');
png.re_num= fullfile(P,'re_num.png');
png.re_type=fullfile(P,'re_type.png');
png.re_load=fullfile(P,'re_load.png');
png.feedback=fullfile(P,'feedback.png');
png.break = fullfile(P,'break.png');
png.endC  = fullfile(P,'condition_end.png');

% Filter only Imp rows
sched = params.masterSchedule(strcmp(params.masterSchedule.Condition,'Imp'),:);
runatleastonce=0;
% Loop through schedule
for i = 1:height(sched)
    r = sched(i,:);
    % Skip if already done
    done = strcmp(params.resultsTable.WavPath, r.WavPath) & ...
           params.resultsTable.TrialIndex==r.TrialIndex & ...
           strcmp(params.resultsTable.Condition,'Imp');
    if any(done)
        continue;
    end
    % Show instructions on first practice trial
    if i==1
        showPNGwaitClick(params,png.instr,[1060 1668 1956 1912]);
    end

    % Execute one trial
    S = doImpTrial(params, r.WavPath{1}, r.TaskType{1}, r.IsPractice);
    % Append to unified results table
    newRow = { 'Imp', r.IsPractice, r.WavPath{1}, r.TaskType{1}, ...
               r.TrialIndex, r.Block, S.resp, S.rtTask, S.loadRating, S.rtLoad, ...
               NaN, NaN, NaN, "", NaN, NaN, datetime('now') };
    params.resultsTable = [params.resultsTable; newRow];
    safeSave(params);
    % On practice feedback
    if r.IsPractice && r.TrialIndex==params.nPracticeImp
        % Placeholder rect
        showPNGwaitClick(params,png.feedback,[1060 1668 1956 1912]);
    end
    % Block break
    if ~r.IsPractice && r.TrialIndex==params.nPerBlock && r.Block<params.nBlocks
        showPNGwaitClick(params,png.break,[1060 1668 1956 1912]);
    end
    runatleastonce=1;
end
% End of condition
if runatleastonce>0
    showPNGwaitClick(params,png.endC,[1060 1668 1956 1912]);
end
end
