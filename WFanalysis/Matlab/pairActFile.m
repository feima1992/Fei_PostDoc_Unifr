function filePair = pairActFile(fileTable, varargin)
    %% parse inputs
    p = inputParser;
    addRequired(p, 'fileTable', @istable);
    addParameter(p, 'pairMethod', 'training-baseline', @(X)ismember(X, {'training-baseline', 'all-random'}));
    parse(p, fileTable, varargin{:});
    fileTable = p.Results.fileTable;
    pairMethod = p.Results.pairMethod;

    %% pair files

    switch pairMethod
        case 'training-baseline'
            % pair training and baseline files
            fileTable1 = filterRow(fileTable, 'phase', 'Baseline');
            fileTable2 = removeRow(fileTable, 'phase', 'Baseline');
            filePair = outerjoin(fileTable1, fileTable2, 'Keys', {'mouse', 'folder', 'group', 'mvtDir', 'actType'}, 'MergeKeys', true);
            filePair = varNameRep(filePair, {'_fileTable1', '_fileTable2'}, {'1', '2'});
            filePair.pairType = repmat({'training-baseline'}, height(filePair), 1);

        case 'all-random'
            % pair all files randomly
            % first randomly half of the fileTable
            index = randperm(height(fileTable), floor(height(fileTable) / 2));
            fileTable1 = fileTable(index, :);
            fileTable2 = fileTable(setdiff(1:height(fileTable), index), :);
            filePair = outerjoin(fileTable1, fileTable2, 'Keys', {'mouse', 'folder','group', 'mvtDir', 'actType'}, 'MergeKeys', true);
            filePair = varNameRep(filePair, {'_fileTable1', '_fileTable2'}, {'1', '2'});
            filePair.pairType = repmat({'random pair'}, height(filePair), 1);
    end

end
