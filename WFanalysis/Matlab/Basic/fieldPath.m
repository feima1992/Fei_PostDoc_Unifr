function path = fieldPath(nestStruct)
    % generate a cell array of field paths for a nested struct with recrusive function
    % e.g. FieldPath(struct('a',struct('b',1,'c',2),'d',3))
    % returns {'a.b','a.c','d'}

    if ~isstruct(nestStruct)
        error('input must be a struct')
    end

    path = {};
    fnames = fieldnames(nestStruct);

    for i = 1:length(fnames)

        if isstruct(nestStruct.(fnames{i}))
            subpath = fieldPath(nestStruct.(fnames{i}));

            for j = 1:length(subpath)
                path{end + 1} = [fnames{i} '.' subpath{j}];
            end

        else
            path{end + 1} = fnames{i};
        end

    end
    path = reshape(path,[],1);
end