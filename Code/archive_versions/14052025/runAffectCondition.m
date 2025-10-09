function params = runAffectCondition(params)
% runAffectCondition  –  Dimensional Affect perception task
%   2 practice trials, feedback, 40 experimental trials in 2 blocks
%   Ratings: preference (1–9), arousal (1–9), valence (1–9)
%   Logs into params.resultsAffect (table) and safe-saves params.

% Initialize results table if needed
if ~isfield(params,'resultsAffect')
    varNames = {'subjID','isPractice','wavPath','condition', ...
                'trialIndex','block','pref','arousal','valence','rtDim','time'};
    varTypes = {'string','logical','string','string', ...
                'double','double','double','double','double','double','datetime'};
    params.resultsAffect = table( ...
        'Size',[0,numel(varNames)], ...
        'VariableTypes',varTypes, ...
        'VariableNames',varNames);
end

% Determine subset based on subjID parity
idNum = str2double(params.subjID);
affDir = params.stimDirAffect;
if mod(idNum,2)==1
    subsetName = 'Subset 1 - 40 - wav_norm';
else
    subsetName = 'Subset 2 - 40 - wav_norm';
end
subsetPath = fullfile(affDir, subsetName);
practicePath = fullfile(affDir,'Practice - wav_norm');

% PNG paths
png.instr   = fullfile(params.pngDir,'inst_affect.png');
png.fix     = fullfile(params.pngDir,'fix.png');
png.stim    = fullfile(params.pngDir,'stim.png');
png.re_dim  = fullfile(params.pngDir,'re_dim.png');
png.feedback= fullfile(params.pngDir,'feedback.png');
png.break   = fullfile(params.pngDir,'break.png');
png.endCond = fullfile(params.pngDir,'condition_end.png');

% 1) Instructions
showPNGwaitClick(params,png.instr,[1060 1668 1956 1912]);  % adjust image-coords

% 2) Practice trials (2)
pracFiles = dir(fullfile(practicePath,'*.wav'));
pracNames = {pracFiles.name}';
perm = randperm(numel(pracNames),2);
for i=1:1
    wavPath = fullfile(practicePath, pracNames{perm(i)});
    doAffectTrial(params, wavPath, true, 0, png);
end
% feedback
showPNGwaitClick(params,png.feedback, [1060 1668 1956 1912]);

% 3) Experimental trials (40 in 2 blocks)
expFiles = dir(fullfile(subsetPath,'*.wav'));
expNames = {expFiles.name}';
perm = randperm(numel(expNames),40);
blocks = repelem(1:2, params.nPerBlock)';
trialIdx = repmat((1:params.nPerBlock)',2,1);

for t=1:4
    wavPath = fullfile(subsetPath, expNames{perm(t)});
    blk = blocks(t);
    idx = trialIdx(t);
    % skip if done
    done = strcmp(params.resultsAffect.wavPath, wavPath) & params.resultsAffect.block==blk;
    if any(done), continue; end
    S = doAffectTrial(params, wavPath, false, blk, png);
    newRow = table(string(params.subjID), false, string(wavPath),"Affect", ...
        idx, blk, S.pref, S.arousal, S.valence, S.rtDim, datetime('now'), ...
        'VariableNames', params.resultsAffect.Properties.VariableNames);
    params.resultsAffect = [params.resultsAffect; newRow];
    safeSave(params);
    if t==20
        showPNGwaitClick(params,png.break, [1060 1668 1956 1912]);
    end
end

% 4) End
showPNGwaitClick(params,png.endCond,[1060 1668 1956 1912]);
end


function S = doAffectTrial(params, wavPath, isPractice, block, png)
% Single trial: fixation, audio, dimensional rating
    % fixation cross
    showPNG(params,png.fix); WaitSecs(2.5);
    % play audio
    [y,sr] = audioread(wavPath);
    if sr~=params.samplerate, y=resample(y, params.samplerate, sr); end
    if size(y,2)==1, y=repmat(y,1,2); end
    PsychPortAudio('FillBuffer',params.pahandle,y');
    PsychPortAudio('Start',params.pahandle,1,0,1);
    PsychPortAudio('Stop', params.pahandle,1);
    % dimensional rating (pref, arousal, valence)
    [pref, arousal, valence, rtDim] = showDimensionalScale(params, png.re_dim);
    S = struct('pref',pref,'arousal',arousal,'valence',valence,'rtDim',rtDim);
end





%% scaleRect utility
function rect = scaleRect(imgR,wImg,hImg,outW,outH,left,top)
    sx=outW/wImg; sy=outH/hImg;
    rect=[imgR(1)*sx+left, imgR(2)*sy+top, imgR(3)*sx+left, imgR(4)*sy+top];
end
