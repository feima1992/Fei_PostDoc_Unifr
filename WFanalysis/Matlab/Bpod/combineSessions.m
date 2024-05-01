% Combine two parts of a recording session

% If the recording session is interrupted due to some reason
% this script can be used to combine the bpod data from two recoding files
% and rename the corresponding widefield tif files so that the trial numbers are aligned
% only combine the sessions without changing in the widefiled imaging settings (e.g. head fixation, focus plane, etc.)

% load the bpod data
[bpod_file1, bpod_path1] = uigetfile('*.mat', 'Select first bpod file', 'F:\users\Fei\Bpod\Bpod Local\Data');
[bpod_file2, bpod_path2] = uigetfile('*.mat', 'Select second bpod file', bpod_path1);

data1 = load(fullfile(bpod_path1, bpod_file1));
data2 = load(fullfile(bpod_path2, bpod_file2));

ntrials1 = data1.SessionData.nTrials;
ntrials2 = data2.SessionData.nTrials;

% covert the data to table
data1Table = nestStruct2table(data1);
data2Table = nestStruct2table(data2);

% preallocate the combined table
dataTable = data1Table(0:-1, :);

% for each field, combine the data
for i = 1:height(data1Table)

    fieldName1 = data1Table{i, 'fieldPath'};
    fieldName1 = fieldName1{1};

    fieldName2 = data2Table{i, 'fieldPath'};
    fieldName2 = fieldName2{1};

    if ~strcmp(fieldName1, fieldName2)
        error('Data structure not match')
    end

    value1 = data1Table{i, 'value'};
    value1 = value1{1};

    value2 = data2Table{i, 'value'};
    value2 = value2{1};

    if iscell(value1)

        if length(value1) == 10000
            value = value1;
            value(ntrials1 + 1:ntrials1 + ntrials2) = value2(1:ntrials2);
        elseif length(value1) == ntrials1

            if size(value1, 1) == ntrials1
                value = [value1; value2];
            else
                value = [value1, value2];
            end

        end

    elseif isnumeric(value1)

        if size(value1, 1) == ntrials1
            value = [value1; value2];
        elseif size(value1, 2) == ntrials1
            value = [value1, value2];
        end

    elseif isstruct(value1)
        value = [value1, value2];
    else
        value = value1;
    end

    dataTable.fieldPath{i} = fieldName1;
    dataTable.value{i} = value;
end
% convert the table back to struct
data = nestStruct2table(dataTable);
data.SessionData.nTrials = ntrials1 + ntrials2;
SessionData = data.SessionData;

% save the data
timestamp = regexp(bpod_file2, '\d{6}(?=.mat)', 'match', 'once');
timestampNew = num2str(str2double(timestamp) + 1);
bpod_file = strrep(bpod_file2, timestamp, timestampNew);
save(fullfile(bpod_path2, bpod_file), 'SessionData');

% rename corresponding wf tif files
wf_path2 = uigetdir('D:', 'Select the folder containing the wf tif files');
% scan all the tif files
tifFiles = findFile(wf_path2, 'tif');
trialStr = cellfun(@(x)regexp(x, '(?<=_)\d{4}(?=.tif)', 'match', 'once'), tifFiles.namefull, 'UniformOutput', false);
trialNum = cellfun(@str2double, trialStr);
trialNumNew = trialNum + ntrials1;
trialStrNew = cellstr(num2str(trialNumNew, '%04d'));
tifFiles.pathNew = cellfun(@(x, y,z)strrep(x, y,z), tifFiles.path, trialStr,trialStrNew, 'UniformOutput', false);
% rename the tif files
for i = 1:height(tifFiles)
    try
        movefile(tifFiles.path{i}, tifFiles.pathNew{i});
    catch
        continue
    end
end
% save the tifFiles table in case of mistake
writetable(tifFiles, fullfile(wf_path2, 'rename.txt'), 'Delimiter', '\t');