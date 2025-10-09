function runImpCondition(params)
% =======================  IMP – Non podmínka  ===========================
if ~isfield(params,'debugClickable'), params.debugClickable = false; end
if ~isfield(params,'results'),        params.results = struct; end
if ~isfield(params.results,'logImp'), params.results.logImp = []; end

try
% ---------- PNG cesty (pole i názvy jsou 1-1) --------------------------
files  = { 'inst_imp'      , 'q_num' , 'q_type', 'fix', ...
           're_num'         , 're_type', 're_load', ...
           'feedback'       , 'break'  , 'condition_end' };

fields = { 'instr'          , 'q_num' , 'q_type', 'fix', ...
           're_num'         , 're_type', 're_load', ...
           'feedback'       , 'break'  , 'condition_end' };

png = struct();
for k = 1:numel(fields)
    png.(fields{k}) = fullfile(params.pngDir, [files{k} '.png']);
end


    %% ------- načtení seznamu stimulů -----------------------------------
    % (Zde ilustrativně náhodně – ve skutečnosti použijte vaši tabulku)
    pracDir  = fullfile(params.stimDirImp,'Practice - wav');
    stimDir  = fullfile(params.stimDirImp,'Subset Imp - wav');

    pracFiles   = {dir(fullfile(pracDir,'*.wav')).name};
    pracFiles   = pracFiles(randperm(4));
    pracTask    = repmat({'num','type'},1,2); pracTask = pracTask(randperm(4));

    stimFiles   = {dir(fullfile(stimDir,'*.wav')).name};
    idx         = randperm(40); stimFiles = stimFiles(idx);
    taskFull    = [repmat({'num'},1,20) repmat({'type'},1,20)]; taskFull = taskFull(idx);

%     block1      = struct('wav',stimFiles(1:20),'task',taskFull(1:20));
%     block2      = struct('wav',stimFiles(21:40),'task',taskFull(21:40));
% správně – scalar struct se dvěma cell-políčky
block1.wav  = stimFiles(1:20);
block1.task = taskFull(1:20);

block2.wav  = stimFiles(21:40);
block2.task = taskFull(21:40);

    %% ------- sekvence --------------------------------------------------
    ShowCursor('Arrow', params.win);
 
  % Souřadnice tlačítka v originálním PNG
    imgCont = [1060 1668 1956 1912];     
    showPNGwaitClick(params, png.instr, imgCont);  
    
    
%    showPNGwaitClick(params,png.instr);

    for t=1:2 %4
        doTrial(params,fullfile(pracDir,pracFiles{t}),pracTask{t},true,png);
    end
%     showPNGwaitClick(params,png.feedback);
    imgCont = [1060 1668 1956 1912];     
    showPNGwaitClick(params, png.feedback, imgCont);  

    for t=1:2 %20
        doTrial(params,fullfile(stimDir,block1.wav{t}),block1.task{t},false,png);
    end
%     showPNGwaitClick(params,png.break);
    imgCont = [1060 1668 1956 1912];     
    showPNGwaitClick(params, png.break, imgCont);  

    for t=1:2 %20
        doTrial(params,fullfile(stimDir,block2.wav{t}),block2.task{t},false,png);
    end
%     showPNGwaitClick(params,png.condition_end);
    imgCont = [1060 1668 1956 1912];     
    showPNGwaitClick(params, png.condition_end, imgCont);  

catch ME
    safeSave(params);         % uloží dosud odehrané trialy
    sca;  rethrow(ME);        % vyhodí chybu dál
end
end
% =======================  KONEC main funkce =============================



%% ------------------  1 IMP trial ---------------------------------------
function doTrial(params,wavPath,taskType,isPractice,png)

% ---------- otázka ----------
showPNG(params, png.(['q_' taskType]));
WaitSecs(2.5);

% ---------- fixace ----------
showPNG(params,png.fix); WaitSecs(2.5);

% ---------- audio ----------
[y,sr] = audioread(wavPath);
if sr~=params.samplerate, y = resample(y,params.samplerate,sr); end
if size(y,2)==1, y=repmat(y,1,2); end
PsychPortAudio('FillBuffer',params.pahandle,y');
PsychPortAudio('Start',params.pahandle,1,0,1);
PsychPortAudio('Stop', params.pahandle,1);

% ---------- odpověď 2-btn ----------
[resp, rtTask] = twoButtonResp(params, png.(sprintf('re_%s',taskType)));

% ---------- stupnice náročnosti ----------
[loadRating, rtLoad] = showLoadScale(params, png.re_load);

% ---------- LOG ----------
S = struct('subj',params.subjID,'practice',isPractice,'wav',wavPath,...
           'task',taskType,'resp',resp,'rtTask',rtTask,...
           'load',loadRating,'rtLoad',rtLoad,'time',datestr(now));
params.results.logImp = [params.results.logImp; S];

safeSave(params);              % průběžný zápis
end



%% -------------  interaktivní stupnice 1-9 ------------------------------

function [rating, rt] = showLoadScale(params,pngFile)

img  = imread(pngFile);
[imgH,imgW,~] = size(img);
tex  = Screen('MakeTexture',params.win,img);

scrR = params.winRect; scrW=scrR(3); scrH=scrR(4);
if (scrW/scrH) > (imgW/imgH), outH=scrH; outW=round(imgW/imgH*outH);
else,                          outW=scrW; outH=round(imgH/imgW*outW);
end
left=(scrW-outW)/2; top=(scrH-outH)/2; dest=[left top left+outW top+outH];

% ------------ obdélníky ticků A Continue v OBRAZKU -------------------
for k=1:9
%     imgTick{k} = [260+140*(k-1) 560 340+140*(k-1) 640];   % PŘÍKLAD
    imgTick{k} = [128+336*(k-1) 960 205+336*(k-1) 1030];   % PŘÍKLAD
end
% imgCont = [780 720 1120 800];                             % PŘÍKLAD
imgCont = [1060 1668 1956 1912];                             % PŘÍKLAD

for k=1:9, tick{k}=scaleRect(imgTick{k},imgW,imgH,outW,outH,left,top); end
contRect = scaleRect(imgCont ,imgW,imgH,outW,outH,left,top);

rating = NaN;   tStart = GetSecs;

while true
    % -- překresli PNG + případné zvýraznění zvoleného tikku ----------
    Screen('DrawTexture',params.win,tex,[],dest);
    if ~isnan(rating)
        Screen('FillRect',params.win,[50 100 255 150],tick{rating});
    end
    if params.debugClickable
        for k=1:9, Screen('FrameRect',params.win,[0 255 0],tick{k},2); end
        Screen('FrameRect',params.win,[255 0 0],contRect,3);
    end
    Screen('Flip',params.win);

    [mx,my,but] = GetMouse(params.win);
    if any(but)
        for k=1:9
            if IsInRect(mx,my,tick{k}), rating=k; end
        end
        if IsInRect(mx,my,contRect) && ~isnan(rating)
            while any(but), [~,~,but]=GetMouse(params.win); end
            break;                      % potvrzení
        end
        while any(but), [~,~,but]=GetMouse(params.win); end
    end
    WaitSecs(0.01);
end
rt = GetSecs - tStart;
Screen('Close',tex);
end


%% -------------  DVOUTLAČÍTKOVÁ odpověď  -------------------------------


function [resp, rt] = twoButtonResp(params, pngFile)

% ---- načti PNG + zjisti originální velikost -------------------------
img = imread(pngFile);
[imgH, imgW, ~] = size(img);
tex  = Screen('MakeTexture', params.win, img);

% ---- kam se PNG kreslí na monitoru (zachovat poměr stran) -----------
scrR = params.winRect;  scrW = scrR(3);  scrH = scrR(4);
if (scrW/scrH) > (imgW/imgH)      % displej širší → plná výška
    outH = scrH;  outW = round(imgW/imgH * outH);
else                               % displej užší → plná šířka
    outW = scrW;  outH = round(imgH/imgW * outW);
end
left = (scrW-outW)/2;  top = (scrH-outH)/2;
dest = [left top left+outW top+outH];

% ---- obdélníky tlačítek v OBRAZKU (doplňte svá čísla) ---------------
imgBtn1 = [950 950 1350 1200];   % příklad
imgBtn2 = [1650 950 2050 1200];   % příklad

btn1 = scaleRect(imgBtn1, imgW, imgH, outW, outH, left, top);
btn2 = scaleRect(imgBtn2, imgW, imgH, outW, outH, left, top);

% ---- kresli ----------------------------------------------------------
Screen('DrawTexture', params.win, tex, [], dest);
if params.debugClickable
    Screen('FrameRect', params.win, [255 0 0], btn1, 3);
    Screen('FrameRect', params.win, [255 0 0], btn2, 3);
end
Screen('Flip', params.win);  t0 = GetSecs;

% ---- čekej na klik ---------------------------------------------------
resp = '';
while isempty(resp)
    [mx,my,but] = GetMouse(params.win);
    if any(but)
        if IsInRect(mx,my,btn1), resp='btn1';
        elseif IsInRect(mx,my,btn2), resp='btn2'; end
        while any(but), [~,~,but]=GetMouse(params.win); end
    end
    WaitSecs(0.01);
end
rt = GetSecs - t0;
Screen('Close', tex);
end


%% ------------------  util – uložení -----------------------------------
function safeSave(params)
try
    save(params.dataFile,'params','-v7');   % jediný příkaz navíc
catch ME
    warning('Uložení se nezdařilo: %s',ME.message);
end
end



% %% ------------------  util screenshot PNG wait click -------------------
% function showPNGwaitClick(params,pngPath)
% tex = Screen('MakeTexture',params.win,imread(pngPath));
% Screen('DrawTexture',params.win,tex,[],params.winRect);
% Screen('Flip',params.win);
% while ~any(GetMouse(params.win)), WaitSecs(0.01); end  % čekej na klik
% Screen('Close',tex);
% end

function showPNGwaitClick(params, pngPath, imgCont)
% showPNGwaitClick  –  zobrazí PNG a čeká na klik v button‑rectu
%   imgCont  –  [x1 y1 x2 y2] v souřadnicích originálního obrázku

% ---------- načti PNG + zjisti velikost -------------------------------
img  = imread(pngPath);
[imgH,imgW,~] = size(img);
tex  = Screen('MakeTexture', params.win, img);

% ---------- urči, kam se PNG vykreslí (letterbox/pillarbox) -----------
scrR = params.winRect;  scrW = scrR(3);  scrH = scrR(4);
if (scrW/scrH) > (imgW/imgH)        % displej širší -> plná výška
    outH = scrH;             outW = round(imgW/imgH * outH);
else                                 % displej užší -> plná šířka
    outW = scrW;             outH = round(imgH/imgW * outW);
end
left = (scrW - outW)/2;   top = (scrH - outH)/2;
dest = [left top left+outW top+outH];

% ---------- přepočítej klikací rect na Screen‑coords ------------------
contRect = scaleRect(imgCont, imgW, imgH, outW, outH, left, top);

% ---------- vykresli ---------------------------------------------------
Screen('DrawTexture', params.win, tex, [], dest);
if params.debugClickable
    Screen('FrameRect', params.win, [255 0 0], contRect, 3);
end
Screen('Flip', params.win);

% ---------- čekej na klik uvnitř obdélníku ----------------------------
while true
    [mx,my,but] = GetMouse(params.win);
    if any(but) && IsInRect(mx,my,contRect)
        while any(but)      % vyčkej na uvolnění tlačítka
            [~,~,but] = GetMouse(params.win);
        end
        break;              % potvrzeno
    end
    WaitSecs(0.01);
end
Screen('Close', tex);
end



function showPNG(params,pngPath)
tex=Screen('MakeTexture',params.win,imread(pngPath));
Screen('DrawTexture',params.win,tex,[],params.winRect);
Screen('Flip',params.win); Screen('Close',tex);
end
