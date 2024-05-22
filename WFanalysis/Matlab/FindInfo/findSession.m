function argout = findSession(argin, sFormat)

    % findMouse returns the session name from a string or cell array of strings
    %   argin: string or cell array of strings
    %   sFormat: string, 'YYYYMMDD' or 'YY-MM-DD', default 'YYMMDD'

    %   argout: string or cell array of strings


    %% Validate input
    if ischar(argin)
        argin = {argin};
    elseif ~iscellstr(argin) && ~isstring(argin)
        error('findSession:argin', 'argin must be a string or cell array of strings');
    end

    if nargin < 2
        sFormat = 'YYMMDD';
    elseif ~ismember(upper(sFormat), {'YYMMDD', 'YYYYMMDD'})
        error('findSession:sFormat', 'sFormat must be ''YYMMDD'' or ''YYYYMMDD''');
    end

    %% Main Function

    findSessionFun = @(X)regexp(X, '(?<=_)(20){0,1}2[3-9][0-1][0-9][0-3][0-9](?=_{0,1}\.{0,1})', 'match', 'once');
    argout = findSessionFun(argin);
    emptyFlag = all(cellfun(@isempty, argout));

    % if argout is empty, try again with a different sFormat
    if emptyFlag
        error('findSession:argout', 'argout is empty');
    end

    % check the current sFormat of the session name
    argoutDate = datetime(argout, 'InputFormat', 'yyyyMMdd');

    % convert to desired sFormat
    switch upper(sFormat)
        case 'YYMMDD'
            argout = cellstr(datestr(argoutDate, 'yymmdd'));
        case 'YYYYMMDD'
            argout = cellstr(datestr(argoutDate, 'yyyymmdd'));
    end

    % if output is a 1 cell array, convert to string
    if iscell(argout) && numel(argout) == 1
        argout = argout{1};
    end
end