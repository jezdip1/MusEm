function showWelcomeScreen(params)
    % showWelcomeScreen Zobrazí obrázek welcome_page.png (zachová poměr stran)
    % a čeká na klik na "Pokračovat" tlačítko, definované v souřadnicích obrázku.

    % 1) Načtení obrázku
    welcomeImgPath = fullfile(params.pngDir, 'welcome_page.png');
    if ~exist(welcomeImgPath, 'file')
        error('Obrázek nenalezen: %s', welcomeImgPath);
    end
    welcomeImg = imread(welcomeImgPath);

    % Získáme šířku/výšku v pixelech
    [imgH, imgW, ~] = size(welcomeImg);  % Pozor: size je [rows, cols], tedy [height, width]

    % Vytvoříme Psychtoolbox texturu
    texWelcome = Screen('MakeTexture', params.win, welcomeImg);

    % 2) Stanovíme, jak obrázek vykreslit na obrazovku se zachováním poměru stran.
    screenRect = params.winRect;
    screenW = screenRect(3) - screenRect(1);
    screenH = screenRect(4) - screenRect(2);

    % Poměr stran obrázku:
    aspectImg = imgW / imgH;
    % Poměr stran displeje:
    aspectScr = screenW / screenH;

    % Chceme-li zachovat poměr stran, porovnáme:
    %  - jestli je obrazovka širší nebo užší než obrázek
    %  - a podle toho roztáhneme obrázek "nadoraz" v jedné dimenzi
    %    a druhá se dopočítá.

    if aspectScr > aspectImg
        % Displej je relativně "širší" než obrázek -> roztáhneme obrázek na plnou VÝŠKU
        outH = screenH; 
        outW = round(aspectImg * outH);
    else
        % Displej je relativně "užší" (nebo stejně) -> roztáhneme obrázek na plnou ŠÍŘKU
        outW = screenW;
        outH = round(outW / aspectImg);
    end

    % Vypočítáme, kam to vykreslit = vycentrujeme do středu obrazovky
    left   = (screenW - outW)/2;
    top    = (screenH - outH)/2;
    right  = left + outW;
    bottom = top + outH;

    % posuneme na souřadnice Screen
    destRect = [left, top, right, bottom];

    % 3) Definice klikací oblasti (v souřadnicích obrázku!)
    %    Předpokládejme, že jste v editoru (Gimp/Photoshop) změřili,
    %    že tlačítko "Pokračovat" je v obdélníku [x1, y1, x2, y2]
    %    v pixelech obrázku. Např.:
    imgButtonRect = [1300, 1670, 2200, 1910]; 
    %  Tady jen jako PŘÍKLAD. 
    %  - x = 800..1000
    %  - y = 760..820
    %  Je nutné nalézt reálné hodnoty pro "welcome_page.png".

    % 4) Převedeme souřadnice z "img coords" do "screen coords"
    %    Protože obrázek se škáluje a posouvá, tak:
    scaleX = outW / imgW;
    scaleY = outH / imgH;

    % Vynásobíme x-souřadnice scaleX, y-souřadnice scaleY
    % a pak přičteme offset (left, top).
    screenButtonRect = [
        (imgButtonRect(1) * scaleX) + left, ...
        (imgButtonRect(2) * scaleY) + top,  ...
        (imgButtonRect(3) * scaleX) + left, ...
        (imgButtonRect(4) * scaleY) + top
    ];

    % 5) Vykreslíme texturu
    Screen('DrawTexture', params.win, texWelcome, [], destRect);

    % Volitelně si můžeme pro ladění vykreslit rámeček kolem tlačítka (červený):
    % Screen('FrameRect', params.win, [255 0 0], screenButtonRect, 3);

    Screen('Flip', params.win);

    % 6) Čekání na klik myší ve screenButtonRect
    ShowCursor('Arrow', params.win);
    buttons = 0;
    while 1
        [mx, my, buttons] = GetMouse(params.win);
        if any(buttons)  
            if IsInRect(mx, my, screenButtonRect)
                % Klik je uvnitř tlačítka
                break;
            else
                % Klik mimo tlačítko – počkáme, až uvolní, aby se dalo klikat znovu
                while any(buttons)
                    [~, ~, buttons] = GetMouse(params.win);
                    WaitSecs(0.01);
                end
            end
        end

        % Možnost stisknout ESC pro přerušení
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(KbName('ESCAPE'))
            sca;
            error('Experiment přerušen uživatelem (ESC).');
        end
        WaitSecs(0.01);
    end

    % Skryjeme kurzor (pokud tak děláte standardně v experimentech)
    HideCursor(params.win);

    % 7) Uklid
    Screen('Close', texWelcome);
end
