function expendedTable = expendColumn(aTable, var)
    % expend the table by converting each element of the var to a new row
    % aTable: a table
    % var: a variable name
    % expendedTable: the expendedTable table
    % example:
    %   aTable = table([1;2;3],{'a';'b';'c'},{[1,2];[3,4];[5,6]},'VariableNames',{'A','B','C'})
    %   expendedTable = Expend(aTable,'C')
    %   expendedTable = table([1;1;2;2;3;3],{'a';'a';'b';'b';'c';'c'},{1;2;3;4;5;6},'VariableNames',{'A','B','C'})

    % validate input
    arguments
        aTable table
        var char
    end

    % check if the variable exists
    if ~any(strcmp(aTable.Properties.VariableNames, var))
        error('The variable %s does not exist in the table', var)
    end

    expendedTable = table();

    for i = 1:height(aTable)
        % for each row in the variable
        tablePart1 = aTable(i, ~ismember(aTable.Properties.VariableNames, var));
        tablePart2 = aTable{i, var};

        % hCombine
        if iscell(tablePart2)
            expendedTable = [expendedTable; hCombineTable(tablePart1, tablePart2{1})];
        elseif istable(tablePart2)
            expendedTable = [expendedTable; hCombineTable(tablePart1, tablePart2)];
        end
    end

end
