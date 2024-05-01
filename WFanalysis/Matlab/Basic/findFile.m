%% findFiles
function files = findFile(top_dir, varargin)

    %% findFiles - Find all the files in a directory tree

    % INPUTS:
    % required inputs:
    % top_dir - the top directory to start searching from

    % varargins:
    % optional inputs:
    % include -
    % a regular expression string to match files to include OR
    % a cell array of strings to match files to include
    % exclude -
    % a regular expression string to match files to exclude OR
    % a cell array of strings to match files to exclude
    % parameter variables
    % 'search_subdirs' - search subdirectories (default = true)
    % 'search_method' - 'regex' or 'strfind' (default = 'strfind')
    % 'match_scope' - 'name' or 'path' (default = 'path')
    % 'match_case' - true or false (default = true)
    % 'table_output' - true or false (default = false)
    % OUTPUTS:
    % files - a structure with the following fields:
    % path - the path to the files
    % folder - the folder containing the files
    % name - the name of the files
    % ext - the extension of the files

    %% Parse the inputs
    P = inputParser;
    P.addRequired('top_dir', @ischar);
    P.addOptional('include', '', @(x) ischar(x) || iscell(x));
    P.addOptional('exclude', '', @(x) ischar(x) || iscell(x));
    P.addParameter('search_subdirs', true, @islogical);
    P.addParameter('search_method', 'strfind', @(x) any(strcmpi(x, {'regexp', 'strfind'})));
    P.addParameter('match_scope', 'path', @(x) any(strcmpi(x, {'name', 'path'})));
    P.addParameter('match_case', true, @islogical);
    P.addParameter('table_output', true, @islogical);
    P.parse(top_dir, varargin{:});
    P = P.Results;

    % check if the top directory exists
    if ~exist(P.top_dir, 'dir')
        error('The top directory does not exist');
    end

    % set P.Results.search_method to 'regexp' if P.Results.include and P.Results.exclude both are regular expression strings
    if ischar(P.include) && ischar(P.exclude)
        P.search_method = 'regexp';
    end

    %% Find the all the files in the directory tree
    if P.search_subdirs
        files_dirs = dir(fullfile(P.top_dir, '**', '*'));
    else
        files_dirs = dir(fullfile(P.top_dir, '*'));
    end

    % remove all the directories
    file_list = files_dirs(~[files_dirs.isdir]);

    % cell array for filtering the files
    switch P.match_scope
        case 'name'
            cell_for_filtering = {file_list.name}';
        case 'path'
            cell_for_filtering = fullfile({file_list.folder}', {file_list.name}');
    end

    % filter out files that don't match the include criteria and match the exclude criteria
    switch P.search_method
        case 'strfind'
            % convert the include and exclude strings to cell arrays if they are not already
            if ischar(P.include)
                P.include = {P.include};
            end

            if ischar(P.exclude)
                P.exclude = {P.exclude};
            end

            % if include is empty cell, then include all files
            % otherwise filter out files that don't match the include criteria
            include_idx = ones(size(cell_for_filtering));

            if any(~cellfun(@isempty, P.include))

                for i = 1:numel(P.include)

                    if P.match_case
                        include_idx = include_idx & contains(cell_for_filtering, P.include{i});
                    else
                        include_idx = include_idx & contains(lower(cell_for_filtering), lower(P.include{i}));
                    end

                end

            end

            % if exclude is empty, then exclude no files
            % otherwise filter out files that match the exclude criteria
            exclude_idx = zeros(size(cell_for_filtering));

            if any(~cellfun(@isempty, P.exclude))

                for i = 1:numel(P.exclude)

                    if P.match_case
                        exclude_idx = exclude_idx | contains(cell_for_filtering, P.exclude{i});
                    else
                        exclude_idx = exclude_idx | contains(lower(cell_for_filtering), lower(P.exclude{i}));
                    end

                end

            end

        case 'regexp'
            % include and exclude muse be a regular expression string
            if ~ischar(P.include)
                error('The include parameter must be a regular expression string');
            end

            if ~ischar(P.exclude)
                error('The exclude parameter must be a regular expression string');
            end

            % if include is empty, then include all files
            include_idx = ones(size(cell_for_filtering));

            if ~isempty(P.include)

                if P.match_case
                    include_idx = cellfun(@(x) ~isempty(regexp(x, P.include, 'once')), cell_for_filtering);
                else
                    include_idx = cellfun(@(x) ~isempty(regexp(lower(x), lower(P.include), 'once')), cell_for_filtering);
                end

            end

            % if exclude is empty, then exclude no files
            exclude_idx = zeros(size(cell_for_filtering));

            if ~isempty(P.exclude)

                if P.match_case
                    exclude_idx = cellfun(@(x) ~isempty(regexp(x, P.exclude, 'once')), cell_for_filtering);
                else
                    exclude_idx = cellfun(@(x) ~isempty(regexp(lower(x), lower(P.exclude), 'once')), cell_for_filtering);
                end

            end

    end

    % filter files based on the include and exclude criteria
    file_list = file_list(include_idx & ~exclude_idx);
    % full path to the files
    full_paths = fullfile({file_list.folder}', {file_list.name}');
    % size of the files, in megabytes
    file_sizes = num2cell([file_list.bytes] / 1e6)';
    % sort full_paths in nature order with natsortfiles
    try
        full_paths = natsortfiles(full_paths);
    catch
        % warning('natsortfiles not found, sorting files in alphabetical order');
        full_paths = sort(full_paths);
        % information for downloading natsortfiles
        % fprintf('Download natsortfiles from:\nhttps://www.mathworks.com/matlabcentral/fileexchange/47434-efficient-natural-order-sort-of-cell-array-of-strings\n');
    end

    % get the file names and extensions
    [file_dirs, file_names, file_exts] = cellfun(@fileparts, full_paths, 'UniformOutput', false);
    % get the file name with the extension
    namefull = strcat(file_names, file_exts);
    % create the output structure
    files = struct('path', full_paths, 'folder', file_dirs, 'name', file_names, 'ext', file_exts, 'namefull', namefull, 'sizeMB', file_sizes);
    % convert to a table if requested
    if P.table_output && ~isempty(files)
        files = struct2table(files);
    end

    % warning if no files were found
    if isempty(files)
        warning('No files were found');
    end

end
