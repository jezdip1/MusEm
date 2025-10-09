% seznam názvů
names = { ...
    'ImpPracticeFixBaselineOnset','ImpPracticeSubQuestionNumOnset', ...
    'ImpPracticeSubQuestionTypeOnset','ImpPracticePlaySoundOnset', ...
    'ImpPracticeStopSoundOnset','ImpPracticeAnsweringNumOnset', ...
    'ImpPracticeAnsweringTypeOnset','ImpTrialFixBaselineOnset', ...
    'ImpTrialSubQuestionNumOnset','ImpTrialSubQuestionTypeOnset', ...
    'ImpTrialPlaySoundOnset','ImpTrialStopSoundOnset', ...
    'ImpTrialAnsweringNumOnset','ImpTrialAnsweringTypeOnset', ...
    'ImpPracticeAnsweringLoadNumOnset','ImpPracticeAnsweringLoadTypeOnset', ...
    'ImpTrialAnsweringLoadNumOnset','ImpTrialAnsweringLoadTypeOnset', ...  
    'AffPracticeFixBaselineOnset','AffPracticePlaySoundOnset', ...
    'AffPracticeStopSoundOnset','AffPracticeAnsweringPrefOnset', ...
    'AffPracticeAnsweringArousalOnset','AffPracticeAnsweringValenceOnset', ...
    'AffTrialFixBaselineOnset','AffTrialPlaySoundOnset', ...
    'AffTrialStopSoundOnset','AffTrialAnsweringPrefOnset', ...
    'AffTrialAnsweringArousalOnset','AffTrialAnsweringValenceOnset', ...                
    'EmPracticeFixBaselineOnset','EmPracticePlaySoundOnset', ...
    'EmPracticeStopSoundOnset','EmPracticeAnsweringPrefOnset', ...
    'EmPracticeAnsweringEmotionOnset','EmTrialFixBaselineOnset', ...
    'EmTrialPlaySoundOnset','EmTrialStopSoundOnset', ...
    'EmTrialAnsweringPrefOnset','EmTrialAnsweringEmotionOnset' ...
};

N = numel(names);
rawCodes = round(linspace(1,250,N));   % např. [1,7,14,…,244,250]
disp(rawCodes);

%%
classdef TriggerCodes
    % TRIGGERCODES
    %  Symbolické konstanty pro jednorázové 1-bytové kódy (uint8),
    %  rovnoměrně rozprostřené mezi 1 a 250.

    properties (Constant)
        ImpPracticeFixBaselineOnset       = uint8(  1);
        ImpPracticeSubQuestionNumOnset    = uint8(  7);
        ImpPracticeSubQuestionTypeOnset   = uint8( 14);
        ImpPracticePlaySoundOnset         = uint8( 20);
        ImpPracticeStopSoundOnset         = uint8( 27);
        ImpPracticeAnsweringNumOnset      = uint8( 33);
        ImpPracticeAnsweringTypeOnset     = uint8( 39);
        ImpTrialFixBaselineOnset          = uint8( 46);
        ImpTrialSubQuestionNumOnset       = uint8( 52);
        ImpTrialSubQuestionTypeOnset      = uint8( 58);
        ImpTrialPlaySoundOnset            = uint8( 65);
        ImpTrialStopSoundOnset            = uint8( 71);
        ImpTrialAnsweringNumOnset         = uint8( 78);
        ImpTrialAnsweringTypeOnset        = uint8( 84);
        ImpPracticeAnsweringLoadNumOnset  = uint8( 90);
        ImpPracticeAnsweringLoadTypeOnset = uint8( 97);
        ImpTrialAnsweringLoadNumOnset     = uint8(103);
        ImpTrialAnsweringLoadTypeOnset    = uint8(110);
        AffPracticeFixBaselineOnset       = uint8(116);
        AffPracticePlaySoundOnset         = uint8(122);
        AffPracticeStopSoundOnset         = uint8(129);
        AffPracticeAnsweringPrefOnset     = uint8(135);
        AffPracticeAnsweringArousalOnset  = uint8(141);
        AffPracticeAnsweringValenceOnset  = uint8(148);
        AffTrialFixBaselineOnset          = uint8(154);
        AffTrialPlaySoundOnset            = uint8(161);
        AffTrialStopSoundOnset            = uint8(167);
        AffTrialAnsweringPrefOnset        = uint8(173);
        AffTrialAnsweringArousalOnset     = uint8(180);
        AffTrialAnsweringValenceOnset     = uint8(186);
        EmPracticeFixBaselineOnset        = uint8(193);
        EmPracticePlaySoundOnset          = uint8(199);
        EmPracticeStopSoundOnset          = uint8(205);
        EmPracticeAnsweringPrefOnset      = uint8(212);
        EmPracticeAnsweringEmotionOnset   = uint8(218);
        EmTrialFixBaselineOnset           = uint8(224);
        EmTrialPlaySoundOnset             = uint8(231);
        EmTrialStopSoundOnset             = uint8(237);
        EmTrialAnsweringPrefOnset         = uint8(244);
        EmTrialAnsweringEmotionOnset      = uint8(250);
    end
end
