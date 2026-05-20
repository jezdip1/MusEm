function params = configurePaths(params, baseDir)
% configurePaths  Rebuild machine-specific runtime paths from the project root.
% Safe to call both at fresh start and after loading a resumed params struct.

    params.baseDir       = baseDir;
    params.pngDir        = fullfile(baseDir,'PNG');
    params.stimDirImp    = fullfile(baseDir,'Stimuli','Imp');
    params.stimDirAffect = fullfile(baseDir,'Stimuli','Affect_Em');
    params.stimDirEm     = fullfile(baseDir,'Stimuli','Affect_Em');
    params.stimVolTest   = fullfile(baseDir,'Stimuli','Volume test');
    params.resultsDir    = fullfile(baseDir,'Results');
    if ~exist(params.resultsDir,'dir'), mkdir(params.resultsDir); end

    params.recordingsDir = fullfile(params.resultsDir,'Recordings', char(params.subjID));
    if ~exist(params.recordingsDir,'dir'), mkdir(params.recordingsDir); end

    params.dataFile = fullfile(params.resultsDir, sprintf('%s.mat', char(params.subjID)));

    if isfield(params,'masterSchedule')
        params.masterSchedule = rebaseStimulusPaths(params.masterSchedule, baseDir);
    end
    if isfield(params,'resultsTable')
        params.resultsTable = rebaseStimulusPaths(params.resultsTable, baseDir);
    end
end
