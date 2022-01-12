% Matlab script by Pavlo Bazilinskyy and Joost de Winter
% questions/comments to <pavlo.bazilinskyy@gmail.com>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process appen and heroku data for the experiment. The function needs
% to be somewhat customised for each individual stufy. The working
% principle is however translatable across studies. Output should be
% customised to cater for all questions and types of data collected in the
% particiular study.
%
%%% Naming convention:
% PP: participant
% appen: platform used to reccruit participants and ask survey questions
%        (https://appen.com)
% heroku: platform used to run the experiment and store data
%         (https://www.heroku.com)
% mongo: data is stored in the MongoDB database (https://mlab.com). Note:
%        free account there allows storing 500MB of data. For a new study,
%        we monitor the size of the DB and save data in pieces of <500MB.
%
%%% Input:
% experiment_id: ID of experiment (multiple experiments can be fetched for
%                the same study to conduct cross-experiment analysis)
% save_mat_file: bool flag for saving mat file. A list of variables to save
%                needs to be adjusted based on output of the function
% name_mat_file: name of mat file with saved data
% load_mat_file: bool flag for loading mat file. If true, no analysis will
%                be done and the file with data will be loaded instead
% appen_file: csv file with appen data
% appen_indices: indeces in appen data
% heroku_files: list of files with heroku data
% prefix_stimuli: prefix of saved location of stimuli
%                 (e.g., image/video/audio)
% num_stimuli: number of stimuli
% num_stimuli_block: number of stimuli per saved block
% code_pattern: regex pattern for worker_code
%
%%% Output:
% X: demographics and other numeric data for participants
% Country: countries of participants
% RT: reaction times/times of keypresses (legacy name 'reaction time')
% RP: data from slider/choise question (legecy name 'reaction press')
% StimuliIDs: IDs of stimuli as shown to participants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X, ...
          Country, ...
          RT, ...
          Keys, ...
          Sliders, ...
          StimulusIDs] = process_experiment(experiment_id, ...
                                            save_mat_file, ...
                                            load_mat_file, ...
                                            name_mat_file, ...
                                            appen_file, ...
                                            appen_indices, ...
                                            heroku_files, ...
                                            prefix_stimuli, ...
                                            num_stimuli, ...
                                            num_stimuli_block, ...
                                            code_pattern)

    %%% Constants
    MISTAKES_THRESHOLD = 3;  % number of allowed mistakes with test phrases
    threshold_mean  = 5; % Select the threshold difference
    threshold_max  = 9; % Select the threshold difference
    number_max_responses = 5; % Select the max number of responses with that threshold
    %%% Process data instead of loading a previously saved mat file
    if ~load_mat_file
        %%% Import data
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Processing experiment ' num2str(experiment_id)])
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Start of importing data']);
        % process multiple files with heroku data
        raw_heroku = [];  % for storing all heroku data
        for i=1:size(heroku_files, 1)
            filename = heroku_files(i,:);
            % import Excel file with leypress data
            [~,~,raw_1_file] = xlsread(filename);
            % check if big matrix with heroku data or matrix from current
            % file has more columns
            if (size(raw_1_file,2) > size(raw_heroku,2))  % matrix from current file has more columns
                % add extra columns to big matrix
                if(size(raw_heroku,1) ~= 0)
                    raw_heroku = [raw_heroku, cell(size(raw_heroku,1), ...
                        size(raw_1_file,2) - size(raw_heroku,2))];
                end
            elseif (size(raw_heroku,2) > size(raw_1_file,2))  % big matrix has more columns
                % add extra columns to matrix from current file
                raw_1_file = [raw_1_file, cell(size(raw_1_file,1), ...
                    size(raw_heroku,2) - size(raw_1_file,2))];
            end  % ignore case with equal size
            % add data from 1 file to big matrix with all data from heroku
            raw_heroku = [raw_heroku; raw_1_file];
            disp([datestr(now, 'HH:MM:SS.FFF') ' - Imported data from file with heroku data ' filename]);
        end
        % import Excel file with appen data (survey page)
        raw_appen = readtable(appen_file, 'ReadVariableNames', false);
        raw_appen = table2cell(raw_appen);  % convert to cell array for ease of checking
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Imported data from file with appen data ' appen_file]);
        disp([datestr(now, 'HH:MM:SS.FFF') ' - End of importing data']);
        %% Process appen data
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Start of processing appen data']);
        % allocate matrix to store numers answers to survey quetsions, worker
        % ID and additional data/flags
        X=NaN(size(raw_appen,1),25);
        X(:,23)=0;  % set counter of mistakes in test phrases to 0
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of respondents in appen data = ' ...
            num2str(size(raw_appen, 1))])
        % instructions understood
        found_values=raw_appen(:,appen_indices(1));
        X(:,1)=strcmp(found_values,'no')+2*strcmp(found_values,'yes');
        % gender
        found_values=raw_appen(:,appen_indices(2));
        X(:,2)=1*strcmp(found_values,'female') ...
            + 2*strcmp(found_values,'male') ...
            - 1*strcmp(found_values,'i_prefer_not_to_respond');
        % age
        found_values=raw_appen(:,appen_indices(3));
        for i=1:size(found_values,1)
            try if strcmp(found_values(i),'?')
                    X(i,3)=NaN;
                else
                    X(i,3)=cell2mat(found_values(i));
                end
            catch error
                X(i,3)=NaN;
            end
        end
        X(X(:,3)>110,3)=NaN; % people who report age greater than 110 years
        % age of obtaining driver's license
        found_values=raw_appen(:,appen_indices(4));
        for i=1:size(found_values,1)
            try if strcmp(found_values(i),'?')
                    X(i,4)=NaN;
                else
                    X(i,4)=cell2mat(found_values(i));
                end
            catch error
                X(i,4)=NaN;
            end
        end
        X(X(:,4)>110,4)=NaN; % people who report licence more than 110 years
        % primary mode of transportation
        found_values=raw_appen(:,appen_indices(5));
        X(:,5)= 1*strcmp(found_values,'private_vehicle') ...
            + 2*strcmp(found_values,'public_transportation') ...
            + 3*strcmp(found_values,'motorcycle') ...
            + 4*strcmp(found_values,'walkingcycling') ...
            + 5*strcmp(found_values,'other') ...
            - 1*strcmp(found_values,'i_prefer_not_to_respond');
        % how many times in past 12 months did you drive a vehicle
        found_values=raw_appen(:,appen_indices(6));
        X(:,6)=1*strcmp(found_values,'never') ...
            + 2*strcmp(found_values,'less_than_once_a_month') ...
            + 3*strcmp(found_values,'once_a_month_to_once_a_week') ...
            + 4*strcmp(found_values,'1_to_3_days_a_week') ...
            + 5*strcmp(found_values,'4_to_6_days_a_week') ...
            + 6*strcmp(found_values,'every_day') ...
            - 1*strcmp(found_values,'i_prefer_not_to_respond');
        % mileage
        found_values=raw_appen(:,appen_indices(7));
        X(:,7)=1*strcmp(found_values,'0_km__mi') ...
            + 2*strcmp(found_values,'1__1000_km_1__621_mi') ...
            + 3*strcmp(found_values,'5001__15000_km_3108__9321_mi') ...
            + 4*strcmp(found_values,'15001__20000_km_9322__12427_mi') ...
            + 5*strcmp(found_values,'20001__25000_km_12428__15534_mi') ...
            + 6*strcmp(found_values,'25001__35000_km_15535__21748_mi') ...
            + 7*strcmp(found_values,'35001__50000_km_21749__31069_mi') ...
            + 8*strcmp(found_values,'50001__100000_km_31070__62137_mi') ...
            + 9*strcmp(found_values,'more_than_100000_km_more_than_62137_mi') ...
            - 1*strcmp(found_values,'i_prefer_not_to_respond');
        % number of accidents
        found_values=string(raw_appen(:,appen_indices(8)));
        X(:,8)=1*strcmp(found_values,'0') ...
            + 2*strcmp(found_values,'1') ...
            + 3*strcmp(found_values,'2') ...
            + 4*strcmp(found_values,'3') ...
            + 5*strcmp(found_values,'4') ...
            + 6*strcmp(found_values,'5') ...
            + 9*strcmp(found_values,'more_than_5') ...
            - 1*strcmp(found_values,'i_prefer_not_to_respond');
        % country
        found_values=raw_appen(:,appen_indices(9));
        Country=cell(size(X,1),1);
        for i=1:size(found_values,1)
            try
                % try to extract country code
                Country(i)=unique(found_values(i));
            catch error
                Country(i)={'NaN'};
            end
        end
        % driver behaviour questionnaire (DBQ)
        found_values=raw_appen(:,appen_indices(10:16));
        X(:,9:15)=1*strcmp(found_values,'0_times_per_month') ...
            + 2*strcmp(found_values,'1_to_3_times_per_month') ...
            + 3*strcmp(found_values,'4_to_6_times_per_month') ...
            + 4*strcmp(found_values,'7_to_9_times_per_month') ...
            + 5*strcmp(found_values,'10_or_more_times_per_month')...
            - 1*strcmp(found_values,'i_prefer_not_to_respond');
        % set -1 responses (prefer not to reponsd, missing data) values to NaN
        X(X<0)=NaN;
        %%% Survey time
        for i=1:size(raw_appen, 1)
            starttime=datenum(raw_appen{i,appen_indices(17)});
            endtime=datenum(raw_appen{i,appen_indices(18)});
            X(i,16)=starttime; % save start time
            X(i,17)=endtime;  % save end time
            X(i,18)=round(2400*36*(endtime - starttime));  % survey time
        end
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Survey time mean (minutes) before filtering = ' num2str(nanmean(X(:,18)/60))]);
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Survey time median (minutes) before filtering = ' num2str(nanmedian(X(:,18)/60))]);
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Survey time SD (minutes) before filtering = ' num2str(nanstd(X(:,18)/60))]);
        disp([datestr(now, 'HH:MM:SS.FFF') ' - First survey start date before filtering = ' datestr(min(X(:,16)))]);
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Last survey end date before filtering = ' datestr(max(X(:,17)))]);
        %%% Worker id
        found_ids=raw_appen(:,appen_indices(19));
        for i=1:size(found_ids,1)
            try if strcmp(found_ids(i),'?')
                    X(i,19)=NaN;
                else
                    X(i,19)= cell2mat(found_ids(i));
                end
            catch error
                X(i,19)=NaN;
            end
        end
        % headphones
        found_values=raw_appen(:,appen_indices(21));
        X(:,20)=strcmp(found_values,'no')+2*strcmp(found_values,'yes');
        % problems with hearing
        found_values=raw_appen(:,appen_indices(22));
        X(:,21)=strcmp(found_values,'no')+2*strcmp(found_values,'yes');
        disp([datestr(now, 'HH:MM:SS.FFF') ' - End of processing appen data']);
        %%% Process keypress data
        % assumed max possible number of values for 1 stimulus
        num_in_row = 2000;
        % reaction time values for participants
        RT = NaN(size(raw_appen,1), num_stimuli, num_in_row);
        % pressed keys for participants
        Keys = NaN(size(raw_appen,1), num_stimuli, num_in_row);
        % keypress values for participants (slider questions)
        Sliders = NaN(size(raw_appen,1), num_stimuli, 3);
        % IDs of stimuli shown
        StimulusIDs = NaN(size(raw_appen,1), num_stimuli);
        % flags for blocks that were found. displaying the sate of this matrix
        % in the end of the functioncan be used to debug if all data was parsed
        % successfully
        found_values = zeros(size(raw_appen,1), num_stimuli/num_stimuli_block);
        % count people that added the same worker_code more than once
        counter_cheaters = 0;
        cheater_worker_codes=[];  % store worker_codes of cheaters
        % map of correct answers to the test phrase
        test_sounds_answers = ["", "", ""; ...  % 1 (no input)
            "oranges are orange", "orange are orange", "oranges is orange"; ...  % 2
            "lemons are yellow", "lemon is yellow", "lemons is yellow"; ...  % 3
            "cherries are red", "cherry is red", "cherries is red"; ...  % 4
            "apples are green", "apple is green", "apples is green"; ...  % 5
            "blackberries are black", "blackberry is black", "blackberries are black"; ...  % 6
            "grapes are blue", "grape is blue", "grapes is blue"  % 7
            ];
        % remove non chars (a-z) and (A-Z)
        for i=1:size(test_sounds_answers,1)
            for j=1:size(test_sounds_answers,2)
                s = test_sounds_answers{i,j};
                s(isletter(s)==0)=[];
                test_sounds_answers(i,j) = s;
            end
        end
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Start of processing heroku data']);
        for row_heroku=1:size(raw_heroku,1) % loop over rows
            if (mod(row_heroku,100)==0)
                disp([datestr(now, 'HH:MM:SS.FFF') ' - Processing row ' ...
                    num2str(row_heroku) ' in heroku data ']);
            end
            
            % store data from the current row to add to the correct place in X
            % RT values in the row. Allocate num_in_row for multiple RT values
            RT_row = zeros(num_stimuli_block,num_in_row);   % keypress values in row
            Keys_row = zeros(num_stimuli_block,num_in_row);  % pressed keys in the row
            Sliders_row = zeros(num_stimuli_block,3);  % slider values in the row
            stimuli_id_row = zeros(num_stimuli_block,1);  % stimulus ID values in row
            detected_browser = 0;  % detected browser
            extracted_row = raw_heroku(row_heroku,:);  % row of data in heroku
            counter_rt = 0;  % counter for reaction time
            counter_key = 0;  % counter for pressed keys
            counter_stimuli_id = 0;  % counter for stimuli IDs
            test_sound_detected = false;  % flag for detected test sound
            test_sound_detected_id = -1;  % id of the last detected test sound
            counter_mistakes_test_sounds = 0;  % counter number of mistakes made with test phrases
            rts_detected = false;  % flag for starting to record RTs of stimulus
            heroku_code = '';  % worker_code in heroku data
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Go over rows of heroku data. Process possible values in the cell
            % one by one and parse values in different ways. We assume that 1
            % cell can contain only 1 type of data. If the study is setup to
            % allow parsing the same cell in multiple ways, 'continue'
            % statements should be removed.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for cell_row=1:length(extracted_row)
                % work with 1 particular cell from the row of data
                cell_row=cell2mat(extracted_row(cell_row));
                % skip NaN cell
                if(isnan(cell_row))
                    continue;  % skip this cell
                end
                % skip empty cell
                if(size(cell_row,1) == 0)
                    continue;  % skip this cell
                end
                % check if keypress times for stimulus will follow
                code_regex = regexp(cell_row, 'rts:[','match');
                if size(code_regex,1) > 0 % start of rt values
                    rts_detected = true;  % flag to start recording RTs from stimulus
                    counter_rt = 0;  % recet countrer of RTs for stimulus
                    % no continue, as an rt value can follow in the cell
                end
                % keypress time
                code_regex = regexp(cell_row, '"rt"','match');
                if size(code_regex,1) > 0 && rts_detected % keypress time found
                    % Record time key press from row array into key presses
                    found_numbers = regexp(cell_row,'\d+\.?\d*','match');
                    counter_rt = counter_rt + 1;
                    if (size(found_numbers,1)) > 1  % scientific notation
                        num = str2num(string(found_numbers(1)));
                        power_of = str2num(string(found_numbers(1)));
                        RT_row(counter_stimuli_id + 1, counter_rt) = num.^power_of;
                    else  % normal float
                        RT_row(counter_stimuli_id + 1, counter_rt) = str2num(string(found_numbers(1)));
                    end
                    continue;  % only 1 item can be picked up form the cell
                end
                % pressed key for stimulus
                code_regex = regexp(cell_row, 'key:','match');
                if size(code_regex,1) > 0 && rts_detected % pressed key foudn
                    % Record time key press from row array into key presses
                    found_numbers = regexp(cell_row,'\d+\.?\d*','match');
                    counter_key = counter_key + 1;
                    Keys_row(counter_stimuli_id + 1, counter_key) = str2num(string(found_numbers(1)));
                    continue;  % only 1 item can be picked up form the cell
                end
                % sliders
                for slinder_n=1:4
                    code_regex = regexp(cell_row, ...
                        strcat('slider-', num2str(slinder_n-1)), ...
                        'match');
                    if size(code_regex,1) > 0 % responses to slider question found
                        found_numbers = regexp(cell_row,'\d+\.?\d*','match');
                        % assign 2nd found number as value (1st found value
                        % is index of the slider)
                        % divide by 10 to convert from [0,100] to [0,10]
                        Sliders_row(counter_stimuli_id + 1, slinder_n) = str2num(string(found_numbers(2))) / 10;
                        continue;  % only 1 item can be picked up form the cell
                    end
                end
                % worker code
                code_regex = regexp(cell_row, code_pattern,'match');
                if size(code_regex,1) > 0 % worker_code found
                    heroku_code = code_regex(1);
                    continue;  % only 1 item can be picked up form the cell
                end
                % stimuli ID
                if size(cell_row,2) >= 26
                    if strcmp(cell_row(1:26),strcat('stimulus:"[\"', prefix_stimuli))
                        % stimulus id found
                        rts_detected = false; % reached the end of RT values for the stimulus
                        found_numbers = regexp(cell_row,'\d+\.?\d*','match');
                        if (size(found_numbers,1)) > 0  % found numbers
                            stimuli_id_row(counter_stimuli_id + 1) = str2num(string(found_numbers(1)));
                        end
                        % detected new stimulus ID
                        counter_stimuli_id = counter_stimuli_id + 1;
                        continue;  % only 1 item can be picked up form the cell
                    end
                end
                % test phrase detected
                code_regex = regexp(cell_row, 'sound_test_','match');
                if size(code_regex,1) > 0 % keypress time found
                    found_numbers = regexp(cell_row,'\d+\.?\d*','match');
                    if (size(found_numbers,1)) > 0  % found numbers
                        % ignore the first test sound that was a song
                        if str2num(string(found_numbers(1))) ~= 1
                            % flag that test sound was detected
                            test_sound_detected = true;
                            % assign ID value
                            test_sound_detected_id = str2num(string(found_numbers(1)));
                        end
                    end
                    continue;  % only 1 item can be picked up form the cell
                end
                % input test phrase detected
                code_regex = regexp(cell_row, 'input-codeblock','match');
                % keypress time found
                if size(code_regex,1) > 0 && test_sound_detected
                    % answer given by the participant
                    given_answer = cell_row(35:length(cell_row)-4);
                    % remove non chars (a-z) and (A-Z)
                    given_answer(isletter(given_answer)==0)=[];
                    % set to lowercase
                    given_answer = lower(given_answer);
                    disp([datestr(now, 'HH:MM:SS.FFF') ...
                        ' - input for test phrase ' ...
                        num2str(test_sound_detected_id) ' - ' ...
                        given_answer]);
                    % check if given answer is in the list of correct
                    % answers for the given phrase
                    % if
                    % ~any(strcmp(test_sounds_answers(test_sound_detected_id,:),given_answer))
                    % check if at least one of the possible sentences
                    % contains a given answer
                    if ~any(contains(test_sounds_answers(test_sound_detected_id,:),given_answer),1)
                        % increase counter of mistakes
                        counter_mistakes_test_sounds = counter_mistakes_test_sounds + 1;
                        disp([datestr(now, 'HH:MM:SS.FFF') ...
                            ' - mistake for test phrase, now=' ...
                            num2str(counter_mistakes_test_sounds) ...
                            ' - input for test phrase ' ...
                            num2str(test_sound_detected_id) ' - ' ...
                            given_answer ...
                            ]);
                    else
                        disp([datestr(now, 'HH:MM:SS.FFF') ...
                            ' - test phrase matched' ...
                            ' - input for test phrase ' ...
                            num2str(test_sound_detected_id) ' - ' ...
                            given_answer ...
                            ]);
                    end
                    % uncheck flag that test sound was detected and reset
                    % id of the sound
                    test_sound_detected = false;
                    test_sound_detected_id = -1;
                    continue;  % only 1 item can be picked up form the cell
                end
                % extract browser info as stored in the javascript
                % navigator.userAgent object. List of browsers is at:
                % https://developer.mozilla.org/en-US/docs/Web/HTTP/Browser_detection_using_the_user_agent
                if size(regexp(cell_row, '^.*Firefox.*$','match'),1) > 0
                    detected_browser = 1;  % Firefox
                    continue;  % only 1 item can be picked up form the cell
                elseif size(regexp(cell_row, '^.*Seamonkey.*$','match'),1) > 0
                    detected_browser = 2;  % Seamonkey
                    continue;  % only 1 item can be picked up form the cell
                elseif size(regexp(cell_row, '^.*Safari.*$','match'),1) > 0
                    detected_browser = 3;  % Safari
                    continue;  % only 1 item can be picked up form the cell
                elseif size(regexp(cell_row, '^.*Chrome.*$','match'),1) > 0
                    detected_browser = 4;  % Chrome
                    continue;  % only 1 item can be picked up form the cell
                elseif size(regexp(cell_row, '^.*Chromium.*$','match'),1) > 0
                    detected_browser = 5;  % Chromium
                    continue;  % only 1 item can be picked up form the cell
                elseif size(regexp(cell_row, '^.*OPR.*$','match'),1) > 0
                    detected_browser = 6;  % Opera 15+ (Blink-based engine)
                    continue;  % only 1 item can be picked up form the cell
                elseif size(regexp(cell_row, '^.*Opera.*$','match'),1) > 0
                    detected_browser = 6;  % Opera 12- (Presto-based engine)
                    continue;  % only 1 item can be picked up form the cell
                elseif size(regexp(cell_row, '^.*MSIE.*$','match'),1) > 0
                    detected_browser = 7;  % Internet Explorer 10-
                    continue;  % only 1 item can be picked up form the cell
                elseif size(regexp(cell_row, '^.*Trident.*$','match'),1) > 0
                    detected_browser = 7;  % Internet Explorer 11
                    continue;  % only 1 item can be picked up form the cell
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Add data to corresponding row in X
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % find occurances of the same worker_code in appen data
            row_appen_matched=find(strcmp(heroku_code, ...
                raw_appen(:,appen_indices(20))));
            if ~isempty(row_appen_matched)
                % multiple instances of worker_code found
                if (size(row_appen_matched, 1) > 1)
                    % found a cheater
                    if ~any(strcmp(cheater_worker_codes, heroku_code))
                        % worker_code was not marked as cheater before
                        % add to the list of known cheaters
                        cheater_worker_codes = [cheater_worker_codes, ...
                            heroku_code];
                        % increase counter of cheaters
                        counter_cheaters = counter_cheaters + 1;
                    end
                end
                % for storind data, use only 1st occurance of worker_id in
                % appen data
                row_appen_matched=row_appen_matched(1);
                % check values from which block to add
                % 1st block
                if found_values(row_appen_matched,1) == 0
                    block_id = 1;
                    found_values(row_appen_matched, 1) = 1;
                    % detected browser
                    % if -1, default value was not changed hence no change in
                    % this row
                    if detected_browser ~= -1
                        % assign browser code
                        X(row_appen_matched, 22) = detected_browser;
                    end
                    % flag that row was matched
                    X(row_appen_matched, 24) = 1;
                    % not 1st block (2...n block)
                else
                    % find last processed block
                    last_block = find(found_values(row_appen_matched,:), ...
                        1, ...  % if 1, it was already processed
                        'last');  % get only last occurance of 1
                    % new block is last block + 1
                    block_id = last_block + 1;
                    % check if block_id is within allowed range
                    if (block_id > num_stimuli/num_stimuli_block)
                        continue;
                    end
                    % update cell in matrix of processed blocks
                    found_values(row_appen_matched, block_id) = 1;
                end
                % mistakes for test phrases
                X(row_appen_matched, 23) = X(row_appen_matched, 23) + counter_mistakes_test_sounds;
                % (1:values_to_save) is used for cases where more than
                % allowed number of stimuli is stored in a row in heroku.
                % it is rare but possible
                if (counter_stimuli_id < num_stimuli_block || counter_stimuli_id > num_stimuli_block)
                    % unexpected number of datapoints found
                    disp([datestr(now, 'HH:MM:SS.FFF') ...
                        ' - WARNING: ' ...
                        num2str(counter_stimuli_id) ...
                        ' values detected in row_heroku=' ...
                        num2str(row_heroku) ...
                        '; block_id=' ...
                        num2str(block_id) ...
                        '; heroku_code=' ...
                        char(heroku_code)]);
                    if (counter_stimuli_id < num_stimuli_block)
                        % fewer values than limit
                        values_to_save = counter_stimuli_id;
                    else
                        % more values than limit
                        values_to_save = num_stimuli_block;
                    end
                else  % expected number of datapoints found
                    values_to_save = counter_stimuli_id;
                end
                % index of 1st value
                start = block_id * num_stimuli_block - (num_stimuli_block - 1);
                % index of last value
                finish = start + (values_to_save - 1);
                % add RT values. hardcode number of values to save due to
                % possible artefact of having not matching number of RT and
                % Keys values in the same row
                RT(row_appen_matched, start:finish, :) = RT_row(1:values_to_save, 1:num_in_row);
                % add pressed keys
                Keys(row_appen_matched, start:finish, :) = Keys_row(1:values_to_save, 1:num_in_row);
                % add keypress values
                Sliders(row_appen_matched, start:finish, :) = Sliders_row(1:values_to_save, :);
                % add stimuli ids as shown
                StimulusIDs(row_appen_matched, start:finish) = stimuli_id_row(1:values_to_save);
            end
        end
        disp([datestr(now, 'HH:MM:SS.FFF') ' - End of processing heroku data']);
        %%% Find participants who did not meet the criteria
        % respondents who did not read instructions
        invalid1 = find(X(:,1)==1);
        % respondents who indicated they are under 18 years old
        invalid2 = find(X(:,3)<18);
        % respondents who took less than 15 min to complete
        invalid3 = find(X(:,18)<60*15);
        % respondents with no response data / match
        invalid4 = find(X(:,24)~=1);
        % Internet Explorer used despite instructions
        invalid5 = find(X(:,22)==7);
        % participants that were shown fewer than half of blocks
        invalid6 = find(sum(found_values, 2) ...
            < (num_stimuli / num_stimuli_block) / 2);
        % invalid6 = [];  % do not filter for stimuli
        %%% Find rows with identical IP addresses
        % store participants with multiple IPs
        pp_multiple_ips=NaN(size(X(:,1)));
        ip_appen=NaN(size(raw_appen,1),1);  % IP addressed in appen data
        % reduce IP addresses of appen data to a single number
        for i=1:size(raw_appen,1)
            try
                ip_appen(i)=str2double(strrep(raw_appen(i,appen_indices(23)),'.',''));
            catch
                ip_appen(i)=cell2mat(raw_appen(i,appen_indices(23)));
            end
        end
        % go over IPs in appen data
        for i=1:size(X,1)
            % IPs for the value in question
            found_ips=find(ip_appen==ip_appen(i));
            % if the IP address occurs only once
            if length(found_ips)==1
                % only IP found, so keep
                pp_multiple_ips(i)=1;
                % if the IP addres occurs more than once
            elseif length(found_ips)>1
                % keep the first survey for that IP address
                pp_multiple_ips(found_ips(1))=1;
                % no not keep the other ones
                pp_multiple_ips(found_ips(2:end))=2;
            end
        end
        % respondents who completed the survey more than once, i.e., remove
        % the doublets
        invalid7=find(pp_multiple_ips>1);
        % respondents who made more mistakes with test phrases than allowed
        invalid8 = find(X(:,23)>MISTAKES_THRESHOLD);
        
        % respondents who provided outlier results considering thresholds
        % defined by the user (mean difference and maximum difference between
        % repetitions)
        num_pax = size(Sliders, 1);
        num_cases = size(Sliders,2)/2;
        slider_1 = NaN(num_pax,num_cases,2); slider_2 = slider_1; slider_3 = slider_1;
        
        for i = 1:num_pax % For each participant
            for j = 1:num_cases % For each audio case
                indeces = find (StimulusIDs(i,:) == j);
                if numel(indeces) == 2
                    slider_1(i,j,:) = [Sliders(i,indeces(1),1) Sliders(i,indeces(2),1)];
                    slider_2(i,j,:) = [Sliders(i,indeces(1),2) Sliders(i,indeces(2),2)];
                    slider_3(i,j,:) = [Sliders(i,indeces(1),3) Sliders(i,indeces(2),3)];
                elseif numel(indeces) == 1
                    slider_1(i,j,1) = Sliders(i,indeces(1),1);
                    slider_2(i,j,1) = Sliders(i,indeces(1),2);
                    slider_3(i,j,1) = Sliders(i,indeces(1),3);
                end
            end
        end
        % Calculate absolute differences between the ratings of both repetitions
        diff_slider_1 = abs(slider_1(:,:,1)-slider_1(:,:,2));
        diff_slider_2 = abs(slider_2(:,:,1)-slider_2(:,:,2));
        diff_slider_3 = abs(slider_3(:,:,1)-slider_3(:,:,2));
        
        % Exclude those participants who presented average differences between
        % ratings of the two repetitions larger than a certain threshold in points.    
        exluded_slider_1_mean = find (nanmean(diff_slider_1,2) > threshold_mean);
        exluded_slider_2_mean = find (nanmean(diff_slider_2,2) > threshold_mean);
        exluded_slider_3_mean = find (nanmean(diff_slider_3,2) > threshold_mean);
        excluded_total_mean = unique([exluded_slider_1_mean;exluded_slider_2_mean;exluded_slider_3_mean]);
        
        % Exclude those participants who presented a maximum difference between the
        % ratings of the two repetitions larger than a certain threshold in points a certain amount of times.
        % That is, if the difference between two repeated cases (a certain amount of times) for a certain
        % participant is larger than the threshold, then that participant is
        % excluded.    
        % Sort the differences to select the threshold easily
        diff_slider_1_sorted = diff_slider_1;
        diff_slider_2_sorted = diff_slider_2;
        diff_slider_3_sorted = diff_slider_3;
        diff_slider_1_sorted(isnan(diff_slider_1_sorted)) = -Inf;
        diff_slider_2_sorted(isnan(diff_slider_2_sorted)) = -Inf;
        diff_slider_3_sorted(isnan(diff_slider_3_sorted)) = -Inf;
        diff_slider_1_sorted = sort(diff_slider_1_sorted,2,'descend');
        diff_slider_2_sorted = sort(diff_slider_2_sorted,2,'descend');
        diff_slider_3_sorted = sort(diff_slider_3_sorted,2,'descend');
        diff_slider_1_sorted(isinf(diff_slider_1_sorted)) = NaN;
        diff_slider_2_sorted(isinf(diff_slider_2_sorted)) = NaN;
        diff_slider_3_sorted(isinf(diff_slider_3_sorted)) = NaN;
        indeces_exclude = [];
        for i = 1 : num_pax
            if diff_slider_1_sorted (i,number_max_responses)> threshold_max || diff_slider_2_sorted (i,number_max_responses)> threshold_max || diff_slider_3_sorted (i,number_max_responses)> threshold_max
                indeces_exclude = [indeces_exclude; i];
            end
        end
        invalid9 = unique([excluded_total_mean; indeces_exclude]);
        
        
        %%% Remove filtered out data
        % add together all invalid rows with data
        invalid = unique([invalid1; ...
            invalid2; ...
            invalid3; ...
            invalid4; ...
            invalid5; ...
            invalid6; ...
            invalid7; ...
            invalid8; ...
            invalid9]);
        X(invalid,:)=[];  % remove invalid respondents
        Country(invalid)=[];  % remove invalid countries
        RT(invalid,:,:)=[];  % remove invalid data
        Keys(invalid,:,:)=[];  % remove invalid data
        Sliders(invalid,:,:)=[];  % remove invalid data
        StimulusIDs(invalid,:)=[];  % remove invalid data
        % Save mat file
        % check flag if mat file with all data needs to be saved
        if save_mat_file
            save(name_mat_file, ...
                'X', ...
                'Country', ...
                'RT', ...
                'Keys', ...
                'Sliders', ...
                'StimulusIDs', ...
                'invalid1', ...  % here and lower need to saved for output
                'invalid2', ...
                'invalid3', ...
                'invalid4', ...
                'invalid5', ...
                'invalid6', ...
                'invalid7', ...
                'invalid8', ...
                'invalid9', ...
                'invalid', ...
                'counter_cheaters', ...
                '-v7.3');  % to support saving file with size >2GB
            disp([datestr(now, 'HH:MM:SS.FFF') ' - Saved mat file as ' name_mat_file]);
        end
        %%% Load mat file instead of processing data
    else
        load(name_mat_file);  % load mat file in the current directory
        disp([datestr(now, 'HH:MM:SS.FFF') ' - Loaded mat file ' name_mat_file]);
    end
    %% Output with statistics and filtering information
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of respondents who inputed the same code multiple times (cheaters) = ' num2str(counter_cheaters)])
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of respondents who did not read instructions = ' num2str(length(invalid1))])
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of respondents under 18 = ' num2str(length(invalid2))])
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of respondents that took less than 300 s = ' num2str(length(invalid3))])
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of rows in keypress data not matched =  ' num2str(length(invalid4))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of responses who used Internet Explorer = ' num2str(length(invalid5))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of responses who had fewer than ' num2str(num_stimuli/2) ' stimuli = ' num2str(length(invalid6))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of responses coming from the same IP = ' num2str(length(invalid7))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of responses who made mistakes with test phrases = ' num2str(length(invalid8))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of respondents that provided outliers = ' num2str(length(invalid9))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of respondents removed = ' num2str(length(invalid))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of respondents included in the analysis =  ' num2str(size(X,1))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Number of countries included in the analysis =  ' num2str(length(unique(Country)))]);
    %% Gender, age
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Gender, male respondents = ' num2str(sum(X(:,2)==2))])
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Gender, female respondents = ' num2str(sum(X(:,2)==1))])
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Gender, I prefer not to respond = ' num2str(sum(isnan(X(:,2))))])
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Age, mean = ' num2str(nanmean(X(:,3)))])
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Age, sd = ' num2str(nanstd(X(:,3)))])
    %% Survey time
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Survey time mean (minutes) after filtering = ' num2str(nanmean(X(:,18)/60))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Survey time median (minutes) after filtering = ' num2str(nanmedian(X(:,18)/60))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Survey time SD (minutes) after filtering = ' num2str(nanstd(X(:,18)/60))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - First survey start date after filtering = ' datestr(min(X(:,16)))]);
    disp([datestr(now, 'HH:MM:SS.FFF') ' - Last survey end date after filtering = ' datestr(max(X(:,17)))]);
end
