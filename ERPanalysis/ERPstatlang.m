%{
    file_name : ERPstatlang.m
    author : Francesco Mantegna
    affiliation : Max Planck Institut for Psycholinguistics
    project : Music&Poetry
    date : 30/01/2018
%}

%% add fieldtrip path

full_path_to_fieldtrip = '/Users/francesco/Documents/MATLAB/fieldtrip-20170414';
addpath(full_path_to_fieldtrip)
ft_defaults

%% defining variables

twin         =    [-0.50 1];
inputDir     =    '/Users/francesco/Documents/MATLAB/MPI/Music&Poetry/Preprocessing/Data0.1-30POSTTGOSC';
outDir       =    '/Users/francesco/Documents/MATLAB/MPI/Music&Poetry/ERPanalysis/Results0.1-30baseline0.2';
subjnum      =    30; % subject 6 and 24 were excluded
loss         =    zeros(subjnum,4);
neighborhood =    zeros(56,1);
newGAC       =    zeros(subjnum,1501);
newGAIC      =    zeros(subjnum,1501);
newGAINT     =    zeros(subjnum,1501);

cd(inputDir)

for s = 1:subjnum
    
    %% loading pre-processed files
    
    load(['preprolangPOSTTG_SUBJ' int2str(s) '.mat'])
    
    %% exclude peripherical occipital electrodes C22 C26 C54
%     cfg                  = []; 
%     cfg.channel          = 1:56;
%     cfg.latency          = twin;
%     data_artifacts_free  = ft_selectdata(cfg, data_no_artifacts);
    
    %% preprocess raw data for ERP analysis
    
    % Baseline-correction options

%     cfg.demean          = 'yes';
%     cfg.baselinewindow  = [-0.2 0]; %[-0.2 0];
%     
%     data_artifacts_free = ft_preprocessing(cfg, data_artifacts_free);

    data_artifacts_free = data_no_artifacts;
    
    %% average across trials for each condition
    
    cfg = [];
    cfg.keeptrials = 'yes';
    cfg.trials     = find(data_artifacts_free.trialinfo==1);
    avgcond1       = ft_timelockanalysis(cfg, data_artifacts_free);

    cfg = [];
    cfg.keeptrials = 'yes';
    cfg.trials     = find(data_artifacts_free.trialinfo==2);
    avgcond2       = ft_timelockanalysis(cfg, data_artifacts_free);

    cfg = [];
    cfg.keeptrials = 'yes';
    cfg.trials     = find(data_artifacts_free.trialinfo==3);
    avgcond3       = ft_timelockanalysis(cfg, data_artifacts_free);
    
    %% save data into singular structure
    
    dataset.data_artifacts_free(s) = {data_artifacts_free};
    dataset.avgcong(s) = {avgcond1};
    dataset.avginter(s) = {avgcond2};
    dataset.avgincong(s) = {avgcond3}; 
    dataset.trlxcond(s) = {trlXcond};
    
    clearvars -except inputDir outDir subjnum twin s dataset
end

%% Estimating data loss

for s = 1:subjnum
    loss(s,1) = dataset.trlxcond{s}(1,2);
    loss(s,2) = dataset.trlxcond{s}(2,2);
    loss(s,3) = dataset.trlxcond{s}(3,2);
    loss(s,4) = 135-(loss(s,1) + loss(s,2) + loss(s,3));
end

lossperc = sum(loss(:,4))*100/(135*30);
freecond1 = mean(loss(:,1));
freecond2 = mean(loss(:,2));
freecond3 = mean(loss(:,3));
avgloss1 = 45 - mean(loss(:,1));
avgloss2 = 45 - mean(loss(:,2));
avgloss3 = 45 - mean(loss(:,3));
stdloss1 = std(loss(:,1));
stdloss2 = std(loss(:,2));
stdloss3 = std(loss(:,3));

condperc = loss(:,1:3);
[~, tbl] = anova1(condperc);

clear condperc loss

%% Grand averaged ERPs per condition

cfg = [];
cfg.channel   = 'all';
cfg.latency   = 'all';
cfg.parameter = 'avg';
GA_C          = ft_timelockgrandaverage(cfg,dataset.avgcong{:}); 
GA_INT        = ft_timelockgrandaverage(cfg,dataset.avginter{:}); 
GA_IC         = ft_timelockgrandaverage(cfg,dataset.avgincong{:});

%% multiplot over MPI 64 equidistant layout

cfg = [];
cfg.showlabels  = 'yes';
cfg.graphcolor  = 'kbr';
cfg.comment     = ' ';
cfg.xlim        = [-0.2 1];
cfg.parameter   = 'avg';
cfg.layout    	= 'mpi_customized_acticap64_fran.mat';
figure; ft_multiplotER(cfg,GA_C, GA_INT, GA_IC)

disp('###Have a look at the channel where the effect is more evident###')
disp('###Press a key to go on with the analyses###')  % Press a key here
pause;
clf
close

%% Move to output directory

cd(outDir)

%% topoplot for different time windows of interest

% cfg              = [];
% cfg.method       = 'spline'; % surface Laplacian on a triangulated sphere
% cfg.degree       = 14; % 64 electrodes
% load ('fran_59CH_elec')
% %cfg.elecfile    = 'fran_59CH_elec'; % string file containing the electrode definition
% cfg.elec         = elec; % structure with electrode definition
% cfg.trials       = 'all';
% GA_Cscd = ft_scalpcurrentdensity(cfg, GA_Cinter);
% GA_INTscd = ft_scalpcurrentdensity(cfg, GA_INTinter);
% GA_ICscd = ft_scalpcurrentdensity(cfg, GA_ICinter);

for fig=1:3
    cfg = [];
    cfg.layout = 'mpi_customized_acticap64_fran.mat'; 
    cfg.comment = ' ';
    cfg.channel = 'all';
    cfg.zlim = [-20e-1 20e-1]; 
%     cfg.highlightchannel       = 27;
%     cfg.highlight              = 'on';
%     cfg.highlightsymbol        = '.';
%     cfg.highlightcolor         = 'k';
%     cfg.highlightsize          = 30;
    cfg.parameter              = 'avg'; % the default 'avg' is not present in the data
    cfg.renderer               = 'painters';
    cfg.style                  = 'straight';
    cfg.gridscale              = 250; 
    set(gca,'FontSize',17);
    ft_hastoolbox('brewermap', 1);         % ensure this toolbox is on the path
    colormap(flipud(brewermap(64,'RdBu'))) % change the colormap red blue
%     cfg.colormap = jet(148);
    if fig <= 3
       cfg.xlim = [0.1 0.2];
       timewin = '100-200 ms';
       filename = 'topoplotN1Language.png';
    elseif fig >= 4 && fig <= 6
       cfg.xlim = [0.2 0.3];
       timewin = '200-300 ms';
       filename = 'topoplotP2Language.png';
    elseif fig >= 7 && fig <= 9
       cfg.xlim = [0.3 0.5];
       timewin = '300-500 ms';
       filename = 'topoplotN4Language.png';
    elseif fig >= 10 && fig <= 12
       cfg.xlim = [0.8 1];
       timewin = '800-1000 ms';
       filename = 'topoplotLPCLanguage.png';
    end
    if fig == 1 || fig == 4 || fig == 7 || fig == 10 
        h1 = subplot(1,3,1); ft_topoplotER(cfg,GA_C);
        originalSize1 = get(gca, 'Position');
        set(h1, 'Position', originalSize1);
        title({timewin,'\color{black}congruent'})
    elseif fig == 2 || fig == 5 || fig == 8 || fig == 11
        h2 = subplot(1,3,2); ft_topoplotER(cfg,GA_INT);
        originalSize2 = get(gca, 'Position');
        set(h2, 'Position', originalSize2);
        title({timewin,'\color{blue}intermediate'})
    elseif fig == 3 || fig == 6 || fig == 9 || fig == 12  
        h3 = subplot(1,3,3); ft_topoplotER(cfg,GA_IC);
        originalSize3 = get(gca, 'Position');
        c = colorbar;
        c.Label.String = '\muV';
        c.Label.FontSize = 12;
        set(c,'YTick', -2:2:2);
        if fig == 3 || fig == 6
            c.Location = 'EastOutside';
            set(c,'position',[.96 .36 .02 .31]);
        elseif fig == 9 || fig == 12
            c.Location = 'WestOutside';
            set(c,'position',[.05 .36 .02 .31]);
        end    
        set(h3, 'Position', originalSize3);
        set(gca,'FontSize',17);
        title({timewin,'\color{red}incongruent'})
        disp('###Press a key to go on with the next plot###')  % Press a key here
        pause;
        print(filename, '-dpng')
        clf
        close
    end

end

%% define neighbouring sensors

cfgneigh = [];
cfgneigh.neighbourdist = 59; 
cfgneigh.layout = 'mpi_customized_acticap64_fran';
cfgneigh.method = 'distance';
neighbours = ft_prepare_neighbours(cfgneigh, GA_C);

for i=1:length(neighbours)
    neighborhood(i,:) = size(neighbours(i).neighblabel,1);
end

mean(neighborhood)

%  load ('fran_59CH_elec')
%     interpolation = true;
%     prompt1       = {'Enter the number of the channels that you want to interpolate'};
%     prompt2       = {'Do you want to go on with this channel? (1=yes, 0=no)'};
%     name          = 'Topographic Interpolation';
%     while interpolation
%         for i = 1:3
%             candidate = inputdlg(prompt1,name);
%             if  isnan(str2double(candidate)) | i == 6
%                 interpolation = false;
%                 break
%             end
%             disp('###Have a look at the layout neighborhood first###')
%             neighborhood(str2double(candidate))
%             answer = inputdlg(prompt2,name);
% %             if  answer{1} == '0'
% %                 break
% %             elseif answer{1} == '1'
% %                 if ismember(str2double(candidate),[22 26 54])
% %                     disp('###Do not interpolate occipital channels!###')
% %                     disp('###Press a key to go on with the next channel###')
% %                     pause;
% %                 else
%             ch = str2double(candidate);
%             cfginter = [];
%             cfginter.badchannel = ['C' int2str(ch)]; % channel name
%             cfginter.neighbours = neighbours;
%             cfginter.method = 'spline';
%             cfginter.elec = elec;
%             GA_INTinter = ft_channelrepair(cfginter, GA_INT);
%         end
%     end
%     

%% cluster based permutation test

toi1            = [0.1 0.2];
toi2            = [0.2 0.3];
toi3            = [0.3 0.5];
toi4            = [0.8 1];

cfg                  = [];
cfg.channel          = 'C*';
cfg.neighbours       = neighbours; % defined as above
cfg.avgovertime      = 'yes';
cfg.parameter        = 'avg';
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.alpha            = 0.05;
cfg.correctm         = 'cluster';
cfg.correcttail      = 'alpha';
cfg.numrandomization = 1000;

cfg.design(1,1:2*subjnum)  = [ones(1,subjnum) 2*ones(1,subjnum)];
cfg.design(2,1:2*subjnum)  = [1:subjnum 1:subjnum];
cfg.ivar                   = 1; % the 1st row in cfg.design contains the independent variable
cfg.uvar                   = 2; % the 2nd row in cfg.design contains the subject number
    
for tid = 3
cfg.latency = eval(['toi',num2str(tid)]);
    for cid = 1:3
        if cid ==1 && tid ==1
            stat_HCLC100200 = ft_timelockstatistics(cfg,dataset.avgcong{:}, dataset.avginter{:});
        elseif cid ==2 && tid ==1
            stat_HCIC100200 = ft_timelockstatistics(cfg,dataset.avgcong{:},dataset.avgincong{:});
        elseif cid ==3 && tid ==1
            stat_LCIC100200 = ft_timelockstatistics(cfg,dataset.avginter{:},dataset.avgincong{:});
        elseif cid ==1 && tid ==2
            stat_LCHC200300 = ft_timelockstatistics(cfg,dataset.avginter{:},dataset.avgcong{:});
        elseif cid ==2 && tid ==2
            stat_ICHC200300 = ft_timelockstatistics(cfg,dataset.avgincong{:},dataset.avgcong{:});
        elseif cid ==3 && tid ==2
            stat_ICLC200300 = ft_timelockstatistics(cfg,dataset.avgincong{:},dataset.avginter{:});
        elseif cid ==1 && tid ==3
            stat_LCHC300500 = ft_timelockstatistics(cfg,dataset.avginter{:},dataset.avgcong{:});
        elseif cid ==2 && tid ==3
            stat_ICHC300500 = ft_timelockstatistics(cfg,dataset.avgincong{:},dataset.avgcong{:});
        elseif cid ==3 && tid ==3
            stat_ICLC300500 = ft_timelockstatistics(cfg,dataset.avgincong{:},dataset.avginter{:});
        elseif cid ==1 && tid ==4
            stat_LCHC8001000 = ft_timelockstatistics(cfg,dataset.avginter{:},dataset.avgcong{:});
        elseif cid ==2 && tid ==4
            stat_ICHC8001000 = ft_timelockstatistics(cfg,dataset.avgincong{:},dataset.avgcong{:});
        elseif cid ==3 && tid ==4
            stat_ICLC8001000 = ft_timelockstatistics(cfg,dataset.avgincong{:},dataset.avginter{:});
        end
    end
end

for cid = 1:12 
    if cid ==1
        condlabel = 'stat_HCLC100200';
    elseif cid == 2
        condlabel = 'stat_HCIC100200';
    elseif cid == 3
        condlabel = 'stat_LCIC100200';
    elseif cid == 4
        condlabel = 'stat_LCHC200300';
    elseif cid == 5
        condlabel = 'stat_ICHC200300';
    elseif cid == 6
        condlabel = 'stat_ICLC200300';
    elseif cid == 7
        condlabel = 'stat_LCHC300500';
    elseif cid == 8
        condlabel = 'stat_ICHC300500';
    elseif cid == 9
        condlabel = 'stat_ICLC300500';
    elseif cid == 10
        condlabel = 'stat_LCHC8001000';
    elseif cid == 11
        condlabel = 'stat_ICHC8001000';
    elseif cid == 12
        condlabel = 'stat_ICLC8001000';
    end
    p_min = min(min(min(eval([condlabel, '.prob']))));
    fprintf('In the following contrast: %s the lowest pvalue observed was: %f \n', condlabel(6:end), p_min);
    if p_min < 0.025
        fprintf('There was ##SOME## significant effect in %s \n', condlabel)
    else
        fprintf('There was ##NO## significant effect in %s \n', condlabel)
    end
end

%{

In the following contrast: HCLC100200 the lowest pvalue observed was: 0.170829 
There was ##NO## significant effect in stat_HCLC100200 
In the following contrast: HCIC100200 the lowest pvalue observed was: 0.100899 
There was ##NO## significant effect in stat_HCIC100200 
In the following contrast: LCIC100200 the lowest pvalue observed was: 1.000000 
There was ##NO## significant effect in stat_LCIC100200 
In the following contrast: LCHC200300 the lowest pvalue observed was: 1.000000 
There was ##NO## significant effect in stat_LCHC200300 
In the following contrast: ICHC200300 the lowest pvalue observed was: 0.018981 
There was ##SOME## significant effect in stat_ICHC200300 
In the following contrast: ICLC200300 the lowest pvalue observed was: 0.039960 
There was ##NO## significant effect in stat_ICLC200300 
In the following contrast: LCHC300500 the lowest pvalue observed was: 0.003996 
There was ##SOME## significant effect in stat_LCHC300500 
In the following contrast: ICHC300500 the lowest pvalue observed was: 0.000999 
There was ##SOME## significant effect in stat_ICHC300500 
In the following contrast: ICLC300500 the lowest pvalue observed was: 0.020979 
There was ##SOME## significant effect in stat_ICLC300500  
In the following contrast: LCHC8001000 the lowest pvalue observed was: 0.125874 
There was ##NO## significant effect in stat_LCHC8001000 
In the following contrast: ICHC8001000 the lowest pvalue observed was: 0.004995 
There was ##SOME## significant effect in stat_ICHC8001000 
In the following contrast: ICLC8001000 the lowest pvalue observed was: 0.012987 
There was ##SOME## significant effect in stat_ICLC8001000

tvalue N4 2.5

tvalue N1 4.1
tvalue P2 N4 3.75
tvalue LPC 2.3
%}

%% contrasts between conditions

cfg = [];
cfg.parameter    = 'avg';
cfg.operation    = '(x1-x2)';
GA_LCvsHC       = ft_math(cfg, GA_INT, GA_C); 
GA_ICvsHC       = ft_math(cfg, GA_IC, GA_C); 
GA_ICvsLC       = ft_math(cfg, GA_IC, GA_INT);
GA_HCvsLC       = ft_math(cfg, GA_C, GA_INT);
GA_HCvsIC       = ft_math(cfg, GA_C, GA_IC);
GA_LCvsIC       = ft_math(cfg, GA_INT, GA_IC);

%% topoplot contrasts

% surface Laplacian (FT_SCALPCURRENTDENSITY)
% will increase topographical localization and highlight local spatial features.
% cfg              = [];
% cfg.method       = 'spline'; % surface Laplacian on a triangulated sphere
% cfg.degree       = 14; % 64 electrodes
% load ('fran_59CH_elec')
% %cfg.elecfile     = 'fran_59CH_elec'; % string file containing the electrode definition
% cfg.elec         = elec; % structure with electrode definition
% cfg.trials       = 'all';
% GA_LCvsHCscd = ft_scalpcurrentdensity(cfg, GA_LCvsHC);
% GA_ICvsHCscd = ft_scalpcurrentdensity(cfg, GA_ICvsHC);
% GA_ICvsLCscd = ft_scalpcurrentdensity(cfg, GA_ICvsLC);
% GA_HCvsLCscd = ft_scalpcurrentdensity(cfg, GA_HCvsLC);
% GA_HCvsICscd = ft_scalpcurrentdensity(cfg, GA_HCvsIC);
% GA_LCvsICscd = ft_scalpcurrentdensity(cfg, GA_LCvsIC);

for fig=7:9
    
    cfg = [];
    
    if fig <= 3
       cfg.xlim = toi1;
    elseif fig >= 4 && fig <= 6
       cfg.xlim = toi2;
    elseif fig >= 7 && fig <= 9
       cfg.xlim = toi3;
    elseif fig >= 10 && fig <= 12
       cfg.xlim = toi4;
    elseif fig >= 13 && fig <= 15
       cfg.xlim = toi5;
    end
    
    if     fig == 1 
        contrast = 'HCLC';
        diff1     = 'CONGRUENT';
        diff2     = 'INTERMEDIATE';
    elseif fig == 2 
        contrast = 'HCIC';
        diff1     = 'CONGRUENT';
        diff2     = 'INCONGRUENT';
    elseif fig == 3 
        contrast = 'LCIC';
        diff1     = 'INTERMEDIATE';
        diff2     = 'INCONGRUENT';
    elseif fig == 4 || fig == 7 || fig == 10 || fig == 13
         contrast = 'LCHC';
         diff1     = 'INTERMEDIATE';
         diff2     = 'CONGRUENT';
    elseif fig == 5 || fig == 8 || fig == 11 || fig == 14
         contrast = 'ICHC';
         diff1     = 'INCONGRUENT';
         diff2     = 'CONGRUENT';
    elseif fig == 6 || fig == 9 || fig == 12 || fig == 15
         contrast = 'ICLC';
         diff1     = 'INCONGRUENT';
         diff2     = 'INTERMEDIATE';
    end
    
    %cfg.marker                = 'on';  
    cfg.layout                 = 'mpi_customized_acticap64_fran.mat';
    cfg.highlight              = 'on';
    cfg.highlightsymbol        = '*';
    cfg.highlightcolor         = 'k';
    cfg.highlightsize          = 15;
    cfg.highlightfontsize      = 15;
    cfg.comment                = ' ';
    cfg.renderer               = 'painters';
    cfg.style                  = 'straight';
    cfg.gridscale              = 250; 
    cfg.zlim                   = [-20e-1 20e-1]; 
    cfg.fontsize               = 20;
    cfg.parameter              = 'avg'; % the default 'avg' is not present in the data
    ft_hastoolbox('brewermap', 1);         % ensure this toolbox is on the path
    colormap(flipud(brewermap(64,'RdBu'))) % change the colormap red blue
    %cfg.colormap               = jet(148);
    for i = 1:56
    testch = abs(eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.stat(i)']))>2.5;
    if true(testch); ch(i,1) = i; else ch(i,1) = 0; end
    end
     if fig >= 4 && fig<=6 || fig>=10 && fig<=12
      if isfield((eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000)])),'posclusters')
         if ~isempty(eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.posclusters']))
            if eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.posclusters.prob'])<0.025
                  cfg.highlightchannel       =  ch(find(ch~=0));
    %             cfg.highlightchannel       =  find(eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.posclusterslabelmat']));
    %%%           cfg.highlightchannel       = find(eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.mask']));
            else 
                  cfg.highlightchannel       = zeros(56,1);
            end
         else
             cfg.highlightchannel       = zeros(56,1);
         end
       else
          cfg.highlightchannel       = zeros(56,1);
      end
     else
      if isfield((eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000)])),'negclusters')
        if ~isempty(eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.negclusters']))
            if eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.negclusters.prob'])<0.025
                  cfg.highlightchannel       =  ch(find(ch~=0));
    %             cfg.highlightchannel       =  find(eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.negclusterslabelmat']));
    %%%           cfg.highlightchannel       = find(eval(['stat_', contrast, num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), '.mask']));
            else
                cfg.highlightchannel       = zeros(56,1);
            end
        else
            cfg.highlightchannel       = zeros(56,1);
        end
      else
          cfg.highlightchannel       = zeros(56,1);
      end
    end
    filename = (['contrastlang', num2str(cfg.xlim(1)*1000), num2str(cfg.xlim(2)*1000), 'ms.png']);
    timewin = ([num2str(cfg.xlim(1)*1000),'-',num2str(cfg.xlim(2)*1000),' ms']);
    
    if fig == 1
        h1 = subplot(1,3,1); ft_topoplotER(cfg,GA_HCvsLC);
        originalSize1 = get(gca, 'Position');
        set(h1, 'Position', originalSize1);
        set(h1,'FontSize',12);
        title({diff1,'vs',diff2})
    elseif fig == 2
        h2 = subplot(1,3,2); ft_topoplotER(cfg,GA_HCvsIC);
        originalSize2 = get(gca, 'Position');
        set(h2, 'Position', originalSize2);
        set(h2,'FontSize',12);
        title({diff1,'vs',diff2})
    elseif fig == 3
        h3 = subplot(1,3,3); ft_topoplotER(cfg,GA_LCvsIC);
        originalSize3 = get(gca, 'Position');
        c = colorbar;
        c.Label.String = '\muV';
        c.Label.FontSize = 12;
        set(c,'YTick', -2:2:2);
        c.Location = 'EastOutside';
        set(c,'position',[.96 .36 .02 .31]);
        set(h3, 'Position', originalSize3);
        set(h3,'FontSize',12);
        title({diff1,'vs',diff2})
        disp('###Press a key to go on with the next plot###')  % Press a key here
        pause;
        print(filename, '-dpng')
        clf
        close
        break
    elseif fig == 4 || fig == 7 || fig == 10 || fig == 13
        h1 = subplot(1,3,1); ft_topoplotER(cfg,GA_LCvsHC);
        originalSize1 = get(gca, 'Position');
        set(h1, 'Position', originalSize1);
        set(h1,'FontSize',12);
        title({diff1,'vs',diff2})
    elseif fig == 5 || fig == 8 || fig == 11 || fig == 14
        h2 = subplot(1,3,2); ft_topoplotER(cfg,GA_ICvsHC);
        originalSize2 = get(gca, 'Position');
        set(h2, 'Position', originalSize2);
        set(h2,'FontSize',12);
        title({diff1,'vs',diff2})
    elseif fig == 6 || fig == 9 || fig == 12 || fig == 15  
        h3 = subplot(1,3,3); ft_topoplotER(cfg,GA_ICvsLC);
        originalSize3 = get(gca, 'Position');
        c = colorbar;
        c.Label.String = '\muV';
        c.Label.FontSize = 18;
        set(c,'YTick', -2:2:2);
        if fig == 3 || fig == 6 
            c.Location = 'EastOutside';
            set(c,'position',[.96 .36 .02 .31]);
        elseif fig == 9 || fig == 12 || fig == 15
            c.Location = 'WestOutside';
            set(c,'position',[.05 .36 .02 .31]);
        end    
        set(h3, 'Position', originalSize3);
        set(h3,'FontSize',12);
        title({diff1,'vs',diff2})
        disp('###Press a key to go on with the next plot###')  % Press a key here
        pause;
        print(filename, '-dpng')
        clf
        close
    end
end

%% main channel plot
figure
cfg = [];
cfg.layout                 = 'mpi_customized_acticap64_fran.mat';
cfg.highlight              = 'on';
cfg.highlightsymbol        = '.';
cfg.highlightcolor         = 'r';
cfg.highlightsize          = 40;
cfg.comment                = ' ';
cfg.style                  = 'blank';
cfg.gridscale              = 250; 
% cfg.parameter              = 'pow';%'avg';
cfg.highlightchannel       = {'C28', 'C41', 'C35', 'C48', 'C36', 'C42'}; %54
% set(gca,'FontSize',17);
% title('Channel C58')
ft_topoplotTFR(cfg, GTFAL_ALL);% GA_HCvsIC);

%% 95% Confidence Intervals on the most representative channel

disp('###Choose the channel where the effect is more evident###')
prompt  = {'Enter the number of the channel that you want to represent'};
name    = 'Representative Channel';
channel = inputdlg(prompt,name);

% creating a NxM matrix (N = subject number; M = averaged brain activity on C30)
for sid = 1:subjnum
    newGAC(sid,:) = dataset.avgcong{1,sid}.avg(str2double(channel{1}),:);
    newGAINT(sid,:) = dataset.avginter{1,sid}.avg(str2double(channel{1}),:);
    newGAIC(sid,:) = dataset.avgincong{1,sid}.avg(str2double(channel{1}),:);
end

% Calculating SEM and 95% CIs
N = 30; % number of subjects
M1 = mean(newGAC,1);
E1 = (std(newGAC,1)./sqrt(N))*1.96; % standard error of the mean for congruent
M2 = mean(newGAINT,1);
E2 = (std(newGAINT,1)./sqrt(N))*1.96; % standard error of the mean for C30 intermediate
M3 = mean(newGAIC,1);
E3 = (std(newGAIC,1)./sqrt(N))*1.96; % standard error of the mean for C30 incongruent

for fid = 1
    figure;

    % first axis
    ax1 = gca; % current axe
    ax1.XAxisLocation = 'origin';
    ax1_pos = ax1.Position; % position of first axes

%     % ROI rectangles and zero line
%     if fid == 1
%         r1  = rectangle('Position',[0.10 -8 0.09 15.99],'FaceColor',[0.9 0.9 0.9]);
%         toi = toi1;
%     elseif fid == 2
%         r2  = rectangle('Position',[0.20 -8 0.09 15.99],'FaceColor',[0.9 0.9 0.9]);
%         toi = toi2;
%     elseif fid == 3
%         r3  = rectangle('Position',[0.30 -8 0.20 15.99],'FaceColor',[0.9 0.9 0.9]);
%         toi = toi3;
%     elseif fid == 4
%         r4  = rectangle('Position',[0.80 -8 0.20 15.99],'FaceColor',[0.9 0.9 0.9]);
%         toi = toi4;
%     end
%     set(eval(['r', num2str(fid)]),'EdgeColor','none');
    hold on;
    
    yL = get(gca, 'YLim');
    plot([0 0], [-8 8], '--');
    hold on;
    set(gca, 'Layer', 'top');

    % figure settings
%     title(['95CIs Grand Average ', channel{1},'C Language']);
    box off
    xlim([-0.20 1])
    ylim([-8 8])
    set(gca,'FontSize',16);
    set(gca,'TickDir','both');
    set(gca,'Ydir','reverse');
    set(gca,'YTick',(-8:2:8));
    set(gca,'TickLength',[0.015 0.3]);
    set(gca,'Xticklabel',[])
    set(gca,'XTick',(-0.2:0.2:1));
    ylabel('Evoked Response [\muV]')

    % Plotting CIs filled polygons
    M1 = smooth(M1,10); % smoothing the mean
    M1 = M1'; % re-transposing the mean in an horizontal vector
    p1 = patch([GA_C.time,GA_C.time(length(GA_C.time):-1:1)],[M1+E1,M1(length(GA_C.time):-1:1)-E1(length(GA_C.time):-1:1)], [0.3 0.3 0.3]); % creating a Confidence interval for MLT12 (meaningful channel)
    set(p1,'EdgeColor','none');
    alpha(p1,0.3);
    hold on
    Gavgcong = plot(GA_C.time, M1, 'k','LineWidth', 2);

    M2 = smooth(M2,10);
    M2 = M2';
    p2 = patch([GA_INT.time,GA_INT.time(length(GA_INT.time):-1:1)],[M2+E2,M2(length(GA_INT.time):-1:1)-E2(length(GA_INT.time):-1:1)], [0.2 0.4 1]); % creating a Confidence interval for MRF41 (flat channel)
    set(p2,'EdgeColor','none');
    alpha(p2,0.3);
    hold on
    Gavginter = plot(GA_INT.time, M2, 'b','LineWidth', 2);

    M3 = smooth(M3,10);
    M3 = M3';
    p3 = patch([GA_IC.time,GA_IC.time(length(GA_IC.time):-1:1)],[M3+E3,M3(length(GA_IC.time):-1:1)-E3(length(GA_IC.time):-1:1)], [1 0.3 0.3]); % creating a Confidence interval for the GApc (absolute baseline)
    set(p3,'EdgeColor','none');
    alpha(p3,0.3);
    hold on
    Gavgincong = plot(GA_IC.time, M3, 'r','LineWidth', 2);

    % Legend settings
    [legh,objh] = legend([Gavgcong,Gavginter,Gavgincong],{'congruent','intermediate','incongruent'}, 'Location', 'northeast');
    set(objh(4),'LineWidth', 1.5); %congruent
    set(objh(6),'LineWidth', 1.5); %intermediate
    set(objh(8),'LineWidth', 1.5); %incongruent
    set(objh(1),'FontSize', 13);
    set(objh(2),'FontSize', 13);
    set(objh(3),'FontSize', 13);

    % second axis
    ax2 = axes('Position',[0.1380 0.1100 0.7750 0.8150],'XAxisLocation','bottom','YAxisLocation','left','Color','none');
    axis([-0.2 1 -6 4]);
    ax2.XRuler.Axle.LineStyle = 'none';
    ax2.YRuler.Axle.LineStyle = 'none';
    set(gca,'FontSize',16);
    set(gca,'Xticklabel',(-0.2:0.2:1))
    set(gca,'TickLength',[0 0.5]);
    set(gca,'YTick',[]);
    xlabel('Time [s]');

    % print figure to .png
    disp('###Press a key to go on with the next plot###')  % Press a key here
    pause;
    print(['95CIsavg', 'C28', num2str(toi(1)*1000), num2str(toi(2)*1000),'lang.png'],'-dpng')
    clf
    close
end

for icond = 1:3
    cfg              = [];
    cfg.output       = 'pow';
    cfg.channel      = 'C*';
    cfg.method       = 'mtmconvol';
    cfg.taper        = 'hanning';
%     cfg.trials       = find(data_no_artifacts.trialinfo==icond); 
    cfg.foi          = 2:1:30;                         % analysis 2 to 30 Hz in steps of 1 Hz
    cfg.pad = ceil(max(cellfun(@numel, {GA_C.time})/1000));
    % This changes the frequencies you can estimate from your data 
    % by artificially creating longer T's (and thus changing the Rayleigh frequency). 
    % Importantly though, this does not (!) change the intrinsic frequency resolution of your data.
    cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.4;   % length of time window = 0.5 sec
    %cfg.t_ftimwin    = 3./cfg.foi; % it is recommended to not use less than 3 cycles
    cfg.toi          = -0.5:0.01:1;   % time window "slides" from -0.5 to 1.5 sec in steps of 0.01 sec (10 ms)
    if icond == 1
        ERPlowTFRhann1 = ft_freqanalysis(cfg,GA_C);
    elseif icond == 2
        ERPlowTFRhann2 = ft_freqanalysis(cfg,GA_INT);
    elseif icond == 3
        ERPlowTFRhann3 = ft_freqanalysis(cfg,GA_IC);
    end
end

 %% Multiplot TFR Low Frequencies (2-30 Hz) per condition
%     
    condname1 = 'CONGRUENT';
    condname2 = 'INTERMEDIATE';
    condname3 = 'INCONGRUENT';
    
    for icond = 1:3
        figure;
        cfg = [];
        cfg.baseline     = [-0.5 -0.15]; 
        cfg.baselinetype = 'relchange';
        cfg.colormap     = jet(148);
        cfg.zlim         = [-1 50];%'maxmin'; %[-10e-1 10e-1]; % asymmetric color scales can be used to highlight increases or decreases in activity.
        cfg.fontsize     = 12;
        cfg.showlabels   = 'yes';
        cfg.interactive  = 'yes';
        cfg.comment      = ' ';
        cfg.layout       = 'mpi_customized_acticap64_fran.mat';
        ft_multiplotTFR(cfg, eval(['ERPlowTFRhann', num2str(icond)]));
        title(['Subj', num2str(s),' TFR LF multiplot ', eval(['condname',num2str(icond)])]);
    end
    
    %% Singleplot on C30 TFR Low Frequencies (2-30 Hz) per condition
    
    figure;
    for icond = 2
        cfg = [];
        cfg.baseline     = [-0.50 -0.15];
        cfg.baselinetype = 'relchange';  
        cfg.maskstyle    = 'opacity';
%         cfg.colormap     = jet(148);
        cfg.fontsize     = 18;
        cfg.zlim         = [-8 8]; %'maxmin'; %[-10e-1 10e-1]; % asymmetric color scales can be used to highlight increases or decreases in activity.
        cfg.channel      = {'C28', 'C41', 'C35', 'C48', 'C36', 'C42'};
        cfg.colorbar       = 'no';
        if icond == 1
              %h1 = subplot(1,3,1); ft_singleplotTFR(cfg, ERPlowTFRhann1);
              ft_singleplotTFR(cfg, ERPlowTFRhann1);
%             originalSize1 = get(gca, 'Position');
%             title({['Subj', num2str(s), ' TFR LF C35'],['\color{black}', condname1]});
        elseif icond == 2
%             h2 = subplot(1,3,2); ft_singleplotTFR(cfg, ERPlowTFRhann2);
              ft_singleplotTFR(cfg, ERPlowTFRhann2);
%             originalSize2 = get(gca, 'Position');
%             title({['Subj', num2str(s), ' TFR LF C35'],['\color{blue}', condname2]});
        elseif icond == 3
            cfg.colorbar       = 'no';
%             h3 = subplot(1,3,3); ft_singleplotTFR(cfg, ERPlowTFRhann3);
            ft_singleplotTFR(cfg, ERPlowTFRhann3);
%             originalSize3 = get(gca, 'Position');
        end
            
            c = colorbar;
            ft_hastoolbox('brewermap', 1);         % ensure this toolbox is on the path
            colormap(flipud(brewermap(64,'RdBu'))) % change the colormap red blue
            c.Label.String = 'rel. power change';
            set(c.Label,'Rotation',270);
            c.Label.FontSize = 17;
            set(c,'YTick', -8:16:8);
            a = get(gca,'YTickLabel');
            set(gca,'YTickLabel',a,'fontsize',15)
            title('ERP \color{red}CONGRUENT');
%             title({['Subj', num2str(s), ' TFR LF C35'],['\color{red}', condname3]});
%         end
        hold on;
        yL = get(gca, 'YLim');
        plot([0 0], yL, 'k-');
%         set(eval(['h',num2str(icond)]),'YTick', 5:5:30);
%         set(eval(['h',num2str(icond)]), 'Position', eval(['originalSize',num2str(icond)]));
    end
   
cfg = [];
cfg.baseline     = [-0.5 -0.15];
cfg.baselinetype = 'db';
TFRL_basC        = ft_freqbaseline(cfg, ERPlowTFRhann1);
TFRL_basINT      = ft_freqbaseline(cfg, ERPlowTFRhann2);
TFRL_basIC       = ft_freqbaseline(cfg, ERPlowTFRhann3);

for sid = 1:30
    slicedeltathetaC = mean(TFRL_basC.powspctrm([26,37,38,8], 1:4, 51:151),2);
    slicedeltathetaINT = mean(TFRL_basINT.powspctrm([26,37,38,8], 1:4, 51:151),2);
    slicedeltathetaIC = mean(TFRL_basIC.powspctrm([26,37,38,8], 1:4, 51:151),2);
    slicedeltathetaC = mean(slicedeltathetaC,1);
    slicedeltathetaINT = mean(slicedeltathetaINT,1);
    slicedeltathetaIC = mean(slicedeltathetaIC,1);
end

slicedeltathetaC = reshape(slicedeltathetaC,[101,1]);
slicedeltathetaINT = reshape(slicedeltathetaINT,[101,1]);
slicedeltathetaIC = reshape(slicedeltathetaIC,[101,1]);

% figure settings
figure;
title('Power time course in the Delta-Theta (2-5 Hz) ERPs');
box off
xlim([0 1])
% ylim([0.25 0.28])
set(gca,'FontSize',16);
set(gca,'TickDir','out');
% set(gca,'YTick',(0.2:0.01:0.28));
set(gca,'XTick',(0:0.2:1));
ylabel('Power [dB]');
xlabel('Time [s]');
hold on
theta1 = plot(TFRL_basC.time(51:151), slicedeltathetaC, 'k','LineWidth', 3);
hold on
theta2 = plot(TFRL_basINT.time(51:151), slicedeltathetaINT, 'b','LineWidth', 3);
hold on
theta3 = plot(TFRL_basIC.time(51:151), slicedeltathetaIC, 'r','LineWidth', 3);

legend([theta1,theta2,theta3],{'congruent','intermediate','incongruent'}, 'Location', 'northwest');
