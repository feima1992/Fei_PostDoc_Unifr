function obj = restoreObjFromStruct(obj, S)
    % restore object properties from a struct
    props = properties(obj);
    for p = 1:numel(props)
        try
            obj.(props{p}) = S.(props{p});
        catch
            warning(['Property ' props{p} ' not found in the struct']);
        end
    
end