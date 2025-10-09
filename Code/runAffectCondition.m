%% runAffectCondition.m
function params = runAffectCondition(params)
% runAffectCondition  –  Dimensional Affect task

% PNG paths
P           = params.pngDir;
png.instr   = fullfile(P,'inst_affect.png');
png.fix     = fullfile(P,'fix.png');
png.re_dim  = fullfile(P,'re_dim.png');
png.feedback= fullfile(P,'feedback.png');
png.break   = fullfile(P,'break.png');
png.endC    = fullfile(P,'condition_end.png');

% Filter only Affect rows
sched = params.masterSchedule(strcmp(params.masterSchedule.Condition,'Affect'),:);
runatleastonce=0;
for i = 1:height(sched)
    r = sched(i,:);
    % Skip if done
    done = strcmp(params.resultsTable.WavPath, r.WavPath) & ...
           params.resultsTable.TrialIndex==r.TrialIndex & ...
           strcmp(params.resultsTable.Condition,'Affect');
    if any(done)
        continue;
    end
    % Show instructions on first practice
    if i==1
        showPNGwaitClick(params,png.instr,[1060 1668 1956 1912]);
    end

    % Run trial
    S = doAffectTrial(params, r.WavPath{1}, r.TaskType{1}, r.IsPractice,r.Block,r.TrialIndex,png);
    % Append
    newRow = {params.subjID, 'Affect', r.IsPractice, r.WavPath{1}, r.TaskType{1}, ...
               r.TrialIndex, r.Block, '', 0, 0, 0, ...  % resp/rtTask/load not used
               S.pref, S.arousal, S.valence, "", S.rtDim, NaN, datetime('now'),...
               NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,...
                S.AffPracticeFixBaselineOnset,...
                S.AffPracticePlaySoundOnset,...
                S.AffPracticeStopSoundOnset,...
                S.AffPracticeAnsweringPrefOnset,...
                S.AffPracticeAnsweringArousalOnset,... 
                S.AffPracticeAnsweringValenceOnset,...                
                S.AffTrialFixBaselineOnset,...
                S.AffTrialPlaySoundOnset,...
                S.AffTrialStopSoundOnset,...
                S.AffTrialAnsweringPrefOnset,...
                S.AffTrialAnsweringArousalOnset,... 
                S.AffTrialAnsweringValenceOnset,...
                NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT,NaT...
                };
    params.resultsTable = [params.resultsTable; newRow];
    safeSave(params);
    if r.IsPractice && r.TrialIndex==params.nPracticeAffect
        % Placeholder rect
        showPNGwaitClick(params,png.feedback,[1060 1668 1956 1912]);
    end
    % Block break
    if ~r.IsPractice && r.TrialIndex==params.nPerBlock && r.Block<params.nBlocks && runatleastonce>0
        syncTriggerOff(params.sync);
        showPNGwaitClick(params,png.break,[1060 1668 1956 1912]);
    end
    runatleastonce=1;
end
if runatleastonce>0
    showPNGwaitClick(params,png.endC,[1060 1668 1956 1912]);
end
syncTriggerOff(params.sync);

end