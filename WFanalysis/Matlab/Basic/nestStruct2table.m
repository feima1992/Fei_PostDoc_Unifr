function outTable = nestStruct2table(nestStruct)
    % function to flatten a nested structure
    % input: nested structure
    % output: flattened structure as a table with the column names 'fieldPath' and 'value', where fieldPath is the path to the value in the nested structure
    % example: flatStruct(struct('a',1,'b',struct('c',2,'d',3)))
    %          ans =
    %          3×2 table
    %          fieldPath    value
    %          _________    _____
    %          {'a'    }    1
    %          {'b.c'  }    2
    %          {'b.d'  }    3
    
    %% Validate input
    arguments
        nestStruct struct
    end

    %% Flatten structure
    % get all field names
    filedPath = fieldPath(nestStruct);
    % initialize output table
    outTable = table(filedPath,cell(size(filedPath)),'VariableNames',{'fieldPath','value'});
    % fill output table
    for i = 1:size(outTable,1)
        outTable.value(i) = {eval(['nestStruct.' outTable.fieldPath{i}])};
    end
end