function stackTable = hCombineTable(table1, table2, varargin)
    % parse inputs
    p = inputParser;
    addRequired(p, 'table1', @istable);
    addRequired(p, 'table2', @istable);
    parse(p, table1, table2, varargin{:});
    table1 = p.Results.table1;
    table2 = p.Results.table2;

    % check if tables are compatible
    if any(ismember(table1.Properties.VariableNames, table2.Properties.VariableNames))
        warning('Tables have overlapping variable names, cannot be combined');
        stackTable = table1;
    else
        % combine tables
        [idx1, idx2] = ndgrid(1:height(table1), 1:height(table2));
        stackTable = [table1(idx1(:), :), table2(idx2(:), :)];
    end
end