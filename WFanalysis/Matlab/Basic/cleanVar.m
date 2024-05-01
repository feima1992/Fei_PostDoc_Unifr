function tableOut = cleanVar(tableIn, columns, varargin)
    % function to clean the columns of a table
    % tableIn is the table to be cleaned
    % columns is a cell array of the columns to be cleaned

    %% parse inputs
    p = inputParser;
    p.addRequired('tableIn', @istable);
    p.addRequired('columns', @(X)iscellstr(X) || ischar(X) || isstring(X));
    p.addOptional('method', 'remove', @(x) any(validatestring(x, {'remove', 'keep'})));
    parse(p, tableIn, columns, varargin{:});
    tableIn = p.Results.tableIn;
    columns = p.Results.columns;
    method = p.Results.method;

    if ischar(columns) || isstring(columns)
        columns = {columns};
    end

    %% clean columns
    % filter columns that not a property of the table
    columns = columns(ismember(columns, tableIn.Properties.VariableNames));
    if isempty(columns)
        warning('the columns input is empty or does not match any of the table properties')
    end
    % clean columns of the table
    switch method
        case 'remove'
            tableOut = tableIn;
            tableOut(:, columns) = [];
        case 'keep'
            tableOut = tableIn(:, columns);
    end

end
