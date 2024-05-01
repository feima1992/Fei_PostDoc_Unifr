function [tableOut, removeRows] = removeRow(tableIn, varargin)
    % the same as filterRow, but returns the removed rows instead of the kept rows
    [~, keepRows] = filterRow(tableIn, varargin{:});
    removeRows = ~keepRows;
    tableOut = tableIn(removeRows, :);
end
