function tableOut = varNameRep(tableIn, pattern, replacePattern, varargin)
% Rename columns in a table, replacing a pattern with a new pattern
% tableIn: input table
% pattern: pattern to be replaced, can be a string or a cell array of strings (default: '')
% replacePattern: new pattern, can be a string or a cell array of strings (default: '')
% varargin: additional arguments to be passed to matlab's regexprep function
% tableOut: output table

%% Input parser
p = inputParser;
addRequired(p, 'tableIn', @istable);
addRequired(p, 'pattern', @(x) ischar(x) || isstring(x) || iscellstr(x));
addRequired(p, 'replacePattern', @(x) ischar(x) || isstring(x) || iscellstr(x));
addParameter(p, 'ignoreCase', false, @islogical);
addParameter(p, 'replaceOnce', false, @islogical);
parse(p, tableIn, pattern, replacePattern, varargin{:});
tableIn = p.Results.tableIn;
pattern = p.Results.pattern;
replacePattern = p.Results.replacePattern;
ignoreCase = p.Results.ignoreCase;
replaceOnce = p.Results.replaceOnce;

%% Rename columns
if ischar(pattern)
    pattern = {pattern};
end
if ischar(replacePattern)
    replacePattern = {replacePattern};
end
if length(pattern) ~= length(replacePattern)
    error('Number of patterns and replace patterns must be the same');
end
tableOut = tableIn;
newNames = tableIn.Properties.VariableNames;
for i = 1:length(pattern)
    if ignoreCase
        newNames = regexprep(newNames, pattern{i}, replacePattern{i}, 'ignorecase', 'once');
    else
        newNames = regexprep(newNames, pattern{i}, replacePattern{i}, 'once');
    end
    if replaceOnce
        pattern{i} = ['^' pattern{i} '$'];
    end
    tableOut.Properties.VariableNames = regexprep(tableOut.Properties.VariableNames, pattern{i}, replacePattern{i}, 'once');
end

tableOut.Properties.VariableNames = newNames;
end