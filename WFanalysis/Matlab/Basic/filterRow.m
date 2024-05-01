function [tableOut, keepRows] = filterRow(tableIn, varargin)
    % function to filterName rows of a table, alternative to rowfilter in Matlab2023
    % filterName rows of a table based on variable-filterName pairs
    % tableIn: table to be filtered
    % varargin: variable-filterName pairs, e.g. 'Var1', 'Filter1', 'Var2', 'Filter2'
    %           Var: variable name or cell array of variable names
    %                if variable name
    %                   Filter can be a value, a cell array of values, or a function handle
    %                       if Filter is a function handle, the function should take a value as input and return a logical value
    %                       if Filter is a cell array of values, the function will return true if the value is in the cell array
    %                       if Filter is a value, the function will return true if the value is equal to the Filter
    %                   example: filterRow(tableIn, 'Var1', 1, 'Var2', @(x) x>2, 'Var3', {'a', 'b'})
    %                   filterName tableIn to keep rows where Var1 == 1, Var2 > 2, Var3 is either 'a' or 'b'
    %               if cell array of variable names
    %                  Filter can also be a function handle, in which case the function should take n values as input and return a logical value, where n is the length of the variable name cell array
    %                   example: filterRow(tableIn, {'Var1', 'Var2'}, @(x, y) x==1 & y>2)

%% validate inputs
    if ~istable(tableIn)
        error('tableIn must be a table')
    end
    if mod(length(varargin), 2) ~= 0
        error('varargin must be a series of variable-filterName pairs')
    end

%% filterName rows
    % get row indices to keep
    keepRows = true(height(tableIn), 1);
    for i = 1:2:length(varargin)
        % get variable name
        varName = varargin{i};
        % get filterName
        filterName = varargin{i+1};
        if iscell(filterName) && all(cellfun(@isnumeric, filterName))
            filterName = cell2mat(filterName);
        end
        % skip if variable not found in table
        if ~ all(ismember(varName, tableIn.Properties.VariableNames))
            warning('variable %s not found in table', varName)
            continue
        end
        % apply filterName to variable according to type of variable and filterName

        if ischar(varName)
            if isa(filterName, 'function_handle')
                try
                    keepRows = keepRows & filterName(tableIn{:, varName});
                catch ME
                    error('filterRow:%s', ME.message)
                end
            elseif isvector(filterName)
                try
                    keepRows = keepRows & ismember(tableIn{:, varName}, filterName);
                catch ME
                    error('filterRow:%s', ME.message)
                end
            else
                try
                    keepRows = keepRows & tableIn{:, varName} == filterName;
                catch ME
                    error('filterRow:%s', ME.message)
                end
            end
        elseif iscell(varName)
            if isa(filterName, 'function_handle')
                if nargin(filterName) ~= length(varName)
                    error('number of inputs to filterName function must match number of variables')
                else
                    try
                        inputArgs = cell(1, length(varName));
                        for j = 1:length(varName)
                            inputArgs{j} = tableIn{:, varName{j}};
                        end
                        keepRows = keepRows & filterName(inputArgs{:});
                    catch ME
                        error('filterRow:%s', ME.message)
                    end
                end
            else
                error('filterName must be a function handle if variable name is a cell array')
            end
        else
            error('variable name must be a value or a cell array of values')
        end    
    end
    % filterName table
    tableOut = tableIn(keepRows, :);
end
