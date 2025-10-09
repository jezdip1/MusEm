function tbl = buildSchedule(cond, stimDir, nPractice, nPerBlock, nBlocks)
    cols = {'Condition','IsPractice','WavPath','TaskType','TrialIndex','Block'};
    tbl  = table('Size',[0 numel(cols)], ...
                 'VariableTypes',{'string','logical','string','string','double','double'}, ...
                 'VariableNames',cols);

    %% ——— Practice trials —————————————————————————————————————
    pracDir   = fullfile(stimDir,'Practice - wav');
    pracFiles = dir(fullfile(pracDir,'*.wav'));
    P         = {pracFiles.name}';
    P         = P(randperm(numel(P),nPractice));

    % rozložení úkolů pro practice podle kondice
    switch cond
      case 'Imp'
        % polovina num, polovina type
        ptasks = [ repmat("num",nPractice/2,1); repmat("type",nPractice/2,1) ];
        ptasks = ptasks(randperm(nPractice));
      case 'Affect'
        ptasks = repmat("dim",nPractice,1);
      case 'Em'
        ptasks = repmat("disc",nPractice,1);
      otherwise
        error('Unknown condition %s',cond);
    end

    Tprac = table( ...
      repmat({cond},nPractice,1), ...                % Condition
      true(nPractice,1), ...                          % IsPractice
      fullfile(pracDir,P), ...                        % WavPath
      cellstr(ptasks), ...                            % TaskType
      (1:nPractice)',...%       zeros(nPractice,1), ...                         % TrialIndex
      zeros(nPractice,1), ...                         % Block
      'VariableNames', cols);

    %% ——— Experimental trials ———————————————————————————————————
    if strcmp(cond,'Imp')
        subDir = fullfile(stimDir,'Subset Imp - wav');
    else
        % pro Affect/Em se řídí counterbalancing venku, tady jen Subset 1
        subDir = fullfile(stimDir,'Subset 1 - 40 - wav');
    end
    expFiles = dir(fullfile(subDir,'*.wav'));
    E        = {expFiles.name}';
    E        = E(randperm(numel(E),nPerBlock*nBlocks));

    switch cond
      case 'Imp'
        etasks = [ repmat("num",nPerBlock,1); repmat("type",nPerBlock,1) ];
        etasks = etasks(randperm(numel(etasks)));
      case 'Affect'
        etasks = repmat("dim",nPerBlock*nBlocks,1);
      case 'Em'
        etasks = repmat("disc",nPerBlock*nBlocks,1);
    end

    blk = repelem((1:nBlocks)', nPerBlock);
    idx = repmat((1:nPerBlock)', nBlocks,1);

    Texp = table( ...
      repmat({cond},numel(E),1), ...
      false(numel(E),1), ...
      fullfile(subDir,E), ...
      cellstr(etasks), ...
      idx, blk, ...
      'VariableNames', cols);

    %% ——— spojit practice + exp —————————————————————————————
    tbl = [Tprac; Texp];
end
