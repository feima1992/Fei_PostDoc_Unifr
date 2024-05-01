function joinedTable = leftJoin(leftTable, rightTable, varargin)
    % leftJoin while preserving the order of the left table
    [joinedTable, iLeft] = outerjoin(leftTable, rightTable, varargin{:} ,'Type','left','MergeKeys',true);
    [~, sortIdx] = sort(iLeft);
    joinedTable = joinedTable(sortIdx, :);
end
