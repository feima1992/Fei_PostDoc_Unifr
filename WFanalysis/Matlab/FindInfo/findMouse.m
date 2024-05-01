function argout = findMouse(argin)
    % findMouse returns the mouse name from a string or cell array of strings
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
    findMouseFun = @(X)regexp(X, '[a-zA-Z]\d{4}(?=_)', 'match', 'once');
    argout = findMouseFun(argin);

    % if no match raise error
    if isempty(argout)
        error('findMouse:argout', 'No mouse name found in input string');
    end

end
