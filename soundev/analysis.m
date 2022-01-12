% Matlab script built by Pavlo Bazilinksyy and Roberto Merino <p.bazilinskyy@tudelft.nl>
clear all;close all;clc; %#ok<*CLALL>

%% ************************************************************************
%% Load config
%% ************************************************************************
config = jsondecode(fileread('../config'));

%% Consts
SHOW_OUTPUT = true;         % flag for figures and console output
FIGURE_OUTPUT = 'figures';  % path for the output of figures
CLOSE_AFTER_SAVING = false;  % close all figures afterexporting

Vol=[   0.0328606932453326          0.33331298828125          30.0332480411388
        0.073496973751555          0.33331298828125          22.2423957973793
        0.0581930806908868         0.333343505859375          23.3432334334153
        0.0544878021627238         0.333343505859375          24.6335053263284
        0.0546693753601746         0.333343505859375          28.8122725087942
        0.0182522736823146          0.33331298828125          26.6773224314811
        0.0432766372284751          0.33331298828125            22.30932152563
        0.0439408049547024          0.33331298828125          27.1181018226818
        0.0438228923791487          0.33331298828125          28.7723505342991
        0.0432652310888083          0.33331298828125          32.6544445880941
        0.0448908731916202          0.32928466796875          33.5386231478166
        0.0813485820484228          0.33331298828125          22.6643904765983
        0.0776686324475091          0.33331298828125          26.7451922048525
        0.0744605158380378          0.33331298828125          28.4860377320983
        0.0712633351510727          0.33331298828125          32.6791813414875
        0.0761190702010706                         1          39.0160541977957
         0.225863964900771                         1          35.1186483548727
           0.1848174732063         0.999969482421875          36.0475428958101
         0.171850024860129         0.999969482421875          35.1625755735403
         0.174002699262407         0.999969482421875          40.7319438245245
        0.0507447114624049         0.999969482421875          46.6699798164081
         0.126775164931835         0.999969482421875          30.1179458893278
         0.127358701141095                         1          35.2678883795507
         0.126850673192366         0.999969482421875          35.5967570270217
         0.125287907324179         0.999969482421875          41.2889254251968
        0.0496197364548449         0.474761962890625          37.3082611557063
         0.255271672749738         0.999969482421875           36.672026575302
         0.253611372631971                         1          42.1715864649137
         0.252922212811759         0.999969482421875           42.751937553847
         0.249879121838513         0.999969482421875          49.1960773970861]; % volume data (mean in 4-8 s interval, max in 4-8 s interval, perceive louadness)
%% Import data
[numbers, sound_info, everything]  = xlsread(config.mapping,'A2:D31');    % Import Excel file with FigureEight data (crowd study)
load(config.estimated_annoyance);  % Load values for estimated annoyance from the model

%% Process appen and heroku data from experiment
% indices to traverse in appen data
appen_indices = [17,... % 1. Instructions understood
                 34,... % 2. Gender
                 33,... % 3. Age
                 15,... % 4. Age of obtaining driver's license
                 35,... % 5. Primary mode of transportation
                 30,... % 6. How many times in past 12 months did you drive a vehicle
                 13,... % 7. Mileage
                 18,... % 8. Number of accidents
                 9,...  % 9. Country
                 19,... % 10. DBQ1
                 20,... % 11. DBQ2
                 21,... % 12. DBQ3
                 22,... % 13. DBQ4
                 23,... % 14. DBQ5
                 24,... % 15. DBQ6
                 25,... % 16. DBQ7
                 4,...  % 17. Start
                 2,...  % 18. End
                 8,...  % 19. Worker id
                 32,... % 20. worker_code
                 14,... % 21. Are you using headphones
                 16,... % 22. Problems with hearing
                 12];   % 23. IP
% process data for Experiment 2
number_stimuli = 30;  % number of stimuli shown
repetition = 2;  % number of repetitions for stimuli
[X, ...
Country, ...
RT, ...
Keys, ...
Sliders, ...
SoundIDs] = process_experiment(1, ...                 % ID of experiment
                               false, ...             % flag for saving data as mat file
                               true, ...              % flag for loading data as mat file
                               config.data_file, ...  % file with saved data
                               config.file_appen, ... % file with appen data
                               appen_indices, ...     % indeces in appen data
                               config.files_heroku, ...  % files with heroku data
                               'sounds/sound_', ...      % prefix for sound stimuli
                               number_stimuli * repetition, ...     % number of stimuli
                               5, ...                 % number of stimuli per block
                               'R7\d+\s?CM\d+\s?8J'); % regex pattern for worker_code

[X_lab, ...
Country_lab, ...
RT_lab, ...
Keys_lab, ...
Sliders_lab, ...
SoundIDs_lab] = process_experiment(2, ...                 % ID of experiment
                                   false, ...             % flag for saving data as mat file
                                   true, ...              % flag for loading data as mat file
                                   config.data_file_lab, ...    % file with saved data
                                   config.file_appen_lab, ...   % file with appen data
                                   appen_indices, ...     % indeces in appen data
                                   config.files_heroku_lab, ...  % files with heroku data
                                   'sounds/sound_', ...   % prefix for sound stimuli
                                   number_stimuli * repetition, ...     % number of stimuli
                                   5, ...                 % number of stimuli per block
                                   'R7\d+\s?CM\d+\s?8J'); % regex pattern for worker_code

%% ************************************************************************
%% Postprocessing of raw data
%% ************************************************************************

%% Transform to key_presses to key_pressesf0, containing the key press data in 0.1-s increments
key_pressesf = NaN(size(RT,1),number_stimuli,200);
NumberofSoundsPlayed = NaN(size(RT,1),number_stimuli);
for i = 1:size(RT, 1) % loop over participants
    for j = 1:size(RT, 2) % loop over stimuli
        if SoundIDs(i,j)>=1  % fix for checking video_id (different than older studies)
            temp = squeeze(RT(i,j,:))/(1000);
            temp(isnan(temp)) = [];
            if max(temp)>15 % if there is more than 15 seconds of data, then the trial must be invalid.
                temp=[];
            end
            if length(temp)>=2 % fill data gap for first half a second (0.5 s) of holding the key
                if (temp(2)-temp(1)>0.475 && temp(2)-temp(1)<0.525) % if 'exactly' 0.5 seconds between the first and second press
                    temp=[temp(1);transpose(temp(1)+0.04:0.04:temp(2));temp(2:end)]; % fill with button press data
                elseif temp(1) > 0.475 && temp(1) < 0.525 % if the first button press is 'exactly' at 0.5 seconds
                    temp=[transpose(0.04:0.04:temp(1));temp(2:end)];
                end
            end
            O = 10 * unique(round(temp,1));  % indices where button is pressed (in 0.1-second increments)
            if isnan(key_pressesf(i,SoundIDs(i,j),1))
                key_pressesf(i,SoundIDs(i,j),:) = 0;
                O(O==0) = [];
                key_pressesf(i,SoundIDs(i,j),O) = key_pressesf(i,SoundIDs(i,j),O) + 1;
                NumberofSoundsPlayed(i,SoundIDs(i,j))=1;
            else
                O(O==0) = [];
                key_pressesf(i,SoundIDs(i,j),O) = key_pressesf(i,SoundIDs(i,j),O) + 1;
                % cater for 2+ repetitions
                NumberofSoundsPlayed(i,SoundIDs(i,j)) = NumberofSoundsPlayed(i,SoundIDs(i,j)) + 1;
            end
        end
    end
end
% divide key presses by the number of times the video was played
for i = 1:size(RT, 1) % loop over participants
    for j = 1:number_stimuli % loop over stimuli
        key_pressesf(i,j,:)=key_pressesf(i,j,:)./NumberofSoundsPlayed(i,j);
    end
end

%% Slider question data
% slider_q = NaN(size(Sliders,1),number_stimuli,size(Sliders,3));
% for i = 1:size(Sliders, 1)
%     for j = 1:size(Sliders,2)
%         for k = 1:size(Sliders, 3)
%             if SoundIDs(i,j)>=1
%                 if isnan(slider_q(i,SoundIDs(i,j),k))
%                     slider_q(i,SoundIDs(i,j),k) = Sliders(i,j,k)/repetition;
%                 else
%                     slider_q(i,SoundIDs(i,j),k) = slider_q(i,SoundIDs(i,j),k) + Sliders(i,j,k)/repetition;
%                 end
%             end
%         end
%     end
% end

slider_q = NaN(size(Sliders,1),number_stimuli,size(Sliders,3));
for question=1:3
    questiondata=squeeze(Sliders(:,:,question));
    for i=1:size(Sliders, 1)
        for i2=1:number_stimuli
            indexes=find(SoundIDs(i,:)==i2);
            slider_q(i,i2,question)=nanmean(questiondata(i,indexes));
        end
    end
end

% Correct for the typo that sound file 28 (tone_500Hz) is actually file 29 (tone_1000Hz)
dummy = slider_q (:,28,:);
slider_q(:,28,:) = slider_q(:,29,:);
slider_q(:,29,:) = dummy; clear dummy

%% Transform to key_presses to key_pressesf0, containing the key press data in 0.1-s increments
key_pressesf_lab = NaN(size(RT_lab,1),number_stimuli,200);
NumberofSoundsPlayed_lab = NaN(size(RT_lab,1),number_stimuli);
for i = 1:size(RT_lab, 1) % loop over participants
    for j = 1:size(RT_lab, 2) % loop over stimuli
        if SoundIDs_lab(i,j)>=1  % fix for checking video_id (different than older studies)
            temp = squeeze(RT_lab(i,j,:))/(1000);
            temp(isnan(temp)) = [];
            if max(temp)>15 % if there is more than 15 seconds of data, then the trial must be invalid.
                temp=[];
            end
            if length(temp)>=2 % fill data gap for first half a second (0.5 s) of holding the key
                if (temp(2)-temp(1)>0.475 && temp(2)-temp(1)<0.525) % if 'exactly' 0.5 seconds between the first and second press
                    temp=[temp(1);transpose(temp(1)+0.04:0.04:temp(2));temp(2:end)]; % fill with button press data
                elseif temp(1) > 0.475 && temp(1) < 0.525 % if the first button press is 'exactly' at 0.5 seconds
                    temp=[transpose(0.04:0.04:temp(1));temp(2:end)];
                end
            end
            O = 10 * unique(round(temp,1));  % indices where button is pressed (in 0.1-second increments)
            if isnan(key_pressesf_lab(i,SoundIDs_lab(i,j),1))
                key_pressesf_lab(i,SoundIDs_lab(i,j),:) = 0;
                O(O==0) = [];
                key_pressesf_lab(i,SoundIDs_lab(i,j),O) = key_pressesf_lab(i,SoundIDs_lab(i,j),O) + 1;
                NumberofSoundsPlayed_lab(i,SoundIDs_lab(i,j))=1;
            else
                O(O==0) = [];
                key_pressesf_lab(i,SoundIDs_lab(i,j),O) = key_pressesf_lab(i,SoundIDs_lab(i,j),O) + 1;
                % cater for 2+ repetitions
                NumberofSoundsPlayed_lab(i,SoundIDs_lab(i,j)) = NumberofSoundsPlayed_lab(i,SoundIDs_lab(i,j)) + 1;
            end
        end
    end
end
% divide key presses by the number of times the video was played
for i = 1:size(RT_lab, 1) % loop over participants
    for j = 1:number_stimuli % loop over stimuli
        key_pressesf_lab(i,j,:)=key_pressesf_lab(i,j,:)./NumberofSoundsPlayed_lab(i,j);
    end
end

%% Slider question data
slider_q_lab = NaN(size(Sliders_lab,1),number_stimuli,size(Sliders_lab,3));
for question=1:3
    questiondata_lab=squeeze(Sliders_lab(:,:,question));
    for i=1:size(Sliders_lab, 1)
        for i2=1:number_stimuli
            indexes=find(SoundIDs_lab(i,:)==i2);
            slider_q_lab(i,i2,question)=nanmean(questiondata_lab(i,indexes));
        end
    end
end
% Correct for the typo that sound file 28 (tone_500Hz) is actually file 29 (tone_1000Hz)
dummy = slider_q_lab (:,28,:);
slider_q_lab(:,28,:) = slider_q_lab(:,29,:);
slider_q_lab(:,29,:) = dummy; clear dummy

key_pressesf_combined=key_pressesf;
key_pressesf_combined(size(key_pressesf,1)+1:size(key_pressesf,1)+size(key_pressesf_lab,1),:,:)=key_pressesf_lab;

slider_q_combined=slider_q;
slider_q_combined(size(slider_q,1)+1:size(slider_q,1)+size(slider_q_combined,1),:,:)=slider_q_combined;

if SHOW_OUTPUT
    %% ************************************************************************
    %% OUTPUT
    %% ************************************************************************
    
    time = (0.05:0.1:size(key_pressesf,3)/10)'; % Time vector
    V=1:10:141;
    
    %% Most common countries (after filtering)
    [~, ~, ub] = unique(Country);
    test2counts = histcounts(ub, 'BinMethod','integers');
    [B,I] = maxk(test2counts,10);
    country_unique = unique(Country);
    if (size(country_unique,1) > 0)
        disp('Most common countries (after filtering) = ')
        disp(country_unique(I)')
        disp(B)
    end
    
    %% All sounds - online
    opengl hardware
    figure;
    hold on;
    grid on;
    box on
    stats_pp = zeros(number_stimuli, size(key_pressesf_combined,1));
    cm = colormap(jet(number_stimuli/2));
    for i=1:number_stimuli
        if i <= number_stimuli/2
            line_type = '-';
            colour_i = i;
        else
            line_type = ':';
            colour_i = i - number_stimuli/2;
        end
        V = 100 * squeeze(nanmean(nanmean(key_pressesf_combined(:,i,:),2),1));
        stats_pp(i,:)=100 * nanmean(nanmean(key_pressesf_combined(:,i,41:80),3),2);
        plot(time,V,line_type,'Linewidth',2, 'color', cm(colour_i,:));
    end
    xlabel('Time (s)')
    ylabel('Percentage of participants pressing response key')
    set(gca,'LooseInset',[0.01 0.01 0.01 0.01],'xlim',[0 12],'xtick',1:14,'ylim',[0 100])
    % build legend
    legend_text = strings(1, number_stimuli);
    for i=1:number_stimuli
        legend_text(i) = [char(sound_info(i,4)) ' (\itM\rm = ' sprintf('%0.1f',nanmean(stats_pp(i,:))) '%, \itSD\rm = ' sprintf('%0.1f',nanstd(stats_pp(i,:))) '%)'];
    end
    legend(legend_text,'NumColumns', 1, 'Position',[0.63 0.567 0.5 0.0869]);
    pos=get(gca,'position');  % retrieve the current values
    pos(3)=0.75*pos(3);        % reduce width
    set(gca,'position',pos);  % write the new values
    h=findobj('FontName','Helvetica'); set(h,'FontSize',16,'Fontname','Arial')
    % maximise and export as eps and jpg
    export_figure(gcf, [config.path_output filesep 'keypress-online'], 'epsc')
    export_figure(gcf, [config.path_figures filesep 'keypress-online'], 'jpg')
    
    %% Background noise - combined
    v1=1:15;  % background noise
    v2=16:30; % no background noise
    opengl hardware
    figure;
    hold on;
    grid on;
    box on
    %     title('Background noise - online')
    V1 = 100 * squeeze(nanmean(nanmean(key_pressesf_combined(:,v1,:),2),1)); % Background noise
    V2 = 100 * squeeze(nanmean(nanmean(key_pressesf_combined(:,v2,:),2),1)); % No background noise
    v1p=100 * nanmean(nanmean(key_pressesf_combined(:,v1,:),3),2);
    v2p=100 * nanmean(nanmean(key_pressesf_combined(:,v2,:),3),2);
    plot(time,V1,'-','Linewidth',5,'color',[0 0 0]);
    plot(time,V2,':','Linewidth',5,'color',[0 0 0]);
    xlabel('Time (s)')
    ylabel('Percentage of participants pressing response key')
    set(gca,'LooseInset',[0.01 0.01 0.01 0.01],'xlim',[0 14],'xtick',1:14,'ylim',[0 100])
    legend(['With background noise (' num2str(length(v1)) ' samples per participant, \itM\rm = ' sprintf('%0.1f',nanmean(v1p)) '%, \itSD\rm = ' sprintf('%0.1f',nanstd(v1p)) '%)'], ...
        ['Without background noise (' num2str(length(v2)) ' samples per participant, \itM\rm = ' sprintf('%0.1f',nanmean(v2p)) '%, \itSD\rm = ' sprintf('%0.1f',nanstd(v2p)) '%)'], ...
        'autoupdate','off');
    clear pgroup1 pgroup2
    %     for i=1:length(V)
    %         [~,pgroup1(i)]=ttest2(nanmean(nanmean(key_pressesf(:,v1,V(i):V(i)+9),3),2),nanmean(nanmean(key_pressesf(:,v1,V(i):V(i)+9),3),2),'vartype','unequal');
    %         [~,pgroup2(i)]=ttest2(nanmean(nanmean(key_pressesf(:,v2,V(i):V(i)+9),3),2),nanmean(nanmean(key_pressesf(:,v2,V(i):V(i)+9),3),2),'vartype','unequal');
    %         if pgroup1(i)<0.005
    %             text(i-0.5,4,'D','horizontalalignment','center','color','b')
    %         end
    %         if pgroup2(i)<0.005
    %             text(i-0.5,4,'ND','horizontalalignment','center','color','b')
    %         end
    %     end
    set(gca,'xlim',[0 12])
    h=findobj('FontName','Helvetica');
    set(h,'FontSize',24,'Fontname','Arial')
    % maximise and export as eps and jpg
    export_figure(gcf, [config.path_output filesep 'keypress-online-noise'], 'epsc')
    export_figure(gcf, [config.path_figures filesep 'keypress-online-noise'], 'jpg')
    
    %% Bar plot for slider questions - online
    % data = nanmean(slider_q(:,:,1));
    % legend('This vehicle sound was easy to notice (0=not easy to notice, 10=easy to notice)', ...
    %      'This sound gave me enough information to realise that a vehicle was approaching (0=not enough information, 10=enough information)', ...
    %       'This vehicle sound was annoying (0=not annoying, 10=extremely annoying)', ...
    %        'NumColumns', 1, ...
    %         'location', 'northwest');
    
    %%
    close all
    
    X=[100-nanmean(stats_pp,2) squeeze(nanmean(slider_q_combined)) Vol];
    disp(corr(X))

    %% Volume/annoyance
    figure
    for i=1:30
        if i<=15
            scatter1=scatter(X(i,7),X(i,4),200,'markerfacecolor',cm(i,:),'markeredgecolor',cm(i,:));hold on;grid on
        else
            scatter1=scatter(X(i,7),X(i,4),200,'markerfacecolor','w','markeredgecolor',cm(i-15,:),'linewidth',3);hold on;grid on
        end
        scatter1.MarkerFaceAlpha = .8;
        text(X(i,7)+0.003,X(i,4),char(sound_info(i,4)),'horizontalalignment','left')
    end
    set(gca,'fontsize',20)
    axis square
    xlabel('Volume','fontsize',20)
    ylabel('Annoying (0-10)','fontsize',20)

    %% Easy to notice/enough information
    figure
    for i=1:30
        if i<=15
            scatter1=scatter(X(i,2),X(i,3),200,'markerfacecolor',cm(i,:),'markeredgecolor',cm(i,:));hold on;grid on
        else
            scatter1=scatter(X(i,2),X(i,3),200,'markerfacecolor','w','markeredgecolor',cm(i-15,:),'linewidth',3);hold on;grid on
        end
        scatter1.MarkerFaceAlpha = .8;
        text(X(i,2)+0.02,X(i,3),char(sound_info(i,4)),'horizontalalignment','left')
    end
    set(gca,'fontsize',20)
    axis square
    xlabel('Easy to notice (0-10)','fontsize',20)
    ylabel('Gave enough information (0-10)','fontsize',20)
    
    figure
    for i=1:30
        if i<=15
            scatter1=scatter(X(i,2),X(i,4),200,'markerfacecolor',cm(i,:),'markeredgecolor',cm(i,:));hold on;grid on
        else
            scatter1=scatter(X(i,2),X(i,4),200,'markerfacecolor','w','markeredgecolor',cm(i-15,:),'linewidth',3);hold on;grid on
        end
        scatter1.MarkerFaceAlpha = .8;
        text(X(i,2)+0.02,X(i,4),char(sound_info(i,4)),'horizontalalignment','left')
    end
    set(gca,'fontsize',20)
    axis square
    xlabel('Easy to notice (0-10)','fontsize',20)
    ylabel('Annoying (0-10)','fontsize',20)
    
    
    figure
    for i=1:30
        if i<=15
            scatter1=scatter(X(i,4),X(i,1),200,'markerfacecolor',cm(i,:),'markeredgecolor',cm(i,:));hold on;grid on
        else
            scatter1=scatter(X(i,4),X(i,1),200,'markerfacecolor','w','markeredgecolor',cm(i-15,:),'linewidth',3);hold on;grid on
        end
        scatter1.MarkerFaceAlpha = .8;
        text(X(i,4)+0.02,X(i,1),char(sound_info(i,4)),'horizontalalignment','left')
    end
    set(gca,'fontsize',20)
    axis square
    xlabel('Annoying (0-10)','fontsize',20)
    ylabel('Button-press performance (%)','fontsize',20)
    
end


function varargout = barvalues(h,precision)
% barvalues(h,precision)
% t = barvalues(h,precision)
% barvalues;
%
% Display bar values ontop of bars in bar plot.
%
% h - figure, axes or bar object (optional).
% precision - Decimal precision to display (0-10),
%             or 'formatSpec' as in num2str  (optional).
% t - handles to the text objects.

%Author: Elimelech Schreiber, 11/2017

    if nargin>1 && ~isempty(precision) % Parse precision
        if isnumeric(precision) && precision >=0 && precision <=10
            precision =['% .',int2str(precision),'f'];
        elseif ~ischar(precision) && ~isstring(precision)
            error('Precision format unsupported.');
        end
    else
        precision='% .0f';
    end

    if nargin<1 || isempty(h)   % parse h (handle)
        h=gca;
    elseif isaType(h,'figure')
        B=findobj(h,'type','bar'); % apply to multiple axes in figure.
        hT=[];
        for b=B.'
            hT = [hT; {barvalues(b,precision)}]; % array of text objects for each bar plot.
        end
        if nargout>0
            varargout{1}=hT;
        end
        return;
    end
    if isaType(h,'axes')
        h =findobj(h,'type','bar');
        if isempty(h)
            return; % silently. to support multiple axes in figure.
        end
    end
    if ~isaType(h,'bar')
        error('Cannot find bar plot.');
    end

    axes(ancestor(h(1),'axes'));                    % make intended axes curent.
    hT=[];                                          % placeholder for text object handles
    for i=1:length(h)                               % work on all bars found
        hT=[hT text(h(i).XData+h(i).XOffset,h(i).YData,...  %position
            strsplit(num2str(h(i).YData,precision)),...    %text to display
            'HorizontalAlignment','center','VerticalAlignment','bottom', ...
            'FontSize',16,'Fontname','Arial')];
    end
    if nargout>0
        varargout{1}=hT.';
    end
end

function flag =isaType(h,type)
    try
        flag=all(strcmp(get(h, 'type'), type));
    catch
        flag =false;
    end
end
