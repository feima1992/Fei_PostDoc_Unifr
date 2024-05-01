function argout = findMvtDir(argin)
    % findMouse returns the MvtDir from a string or cell array of strings
    %   argin: string or cell array of strings
    %   argout: string or cell array of strings

    %% Validate input
    if ischar(argin)
        argin = {argin};
    elseif ~iscellstr(argin) && ~isstring(argin)
        error('findMouse:argin', 'argin must be a string or cell array of strings');
    end

    %% Main Function

    % find mouse name
    findMvtDir = @(X)fillmissing(str2double(regexp(X, '(?<=MvtDir)\d{1}(?=\\)', 'match', 'once')), 'constant', 0);
    argout = findMvtDir(argin);

    % if no match raise error
    if isempty(argout)
        error('findMvtDir:argout', 'No MvtDir found in input string');
    end

end