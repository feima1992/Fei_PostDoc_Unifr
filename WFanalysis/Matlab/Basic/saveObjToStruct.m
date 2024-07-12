function saveToStruct(obj, filename)
    % Save object properties to a struct and then save the struct to a file
    % So that the object can be loaded later without the class definition
    varname = inputname(1);
    props = properties(obj);

    for p = 1:numel(props)
        s.(props{p}) = obj.(props{p});
    end

    eval([varname ' = s']);
    save(filename, varname);
end
