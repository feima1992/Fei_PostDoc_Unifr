classdef MaskUeno < handle
    % EdgeUeno class for real coordinates (unit mm) of sensory and motor regions in Ueno et al. 2018
    % MaskUeno class for mask of sensory and motor in a 512x512 matrix in Ueno et al. 2018
    properties
        googleSheetId = '1-XTF4-4M5bmvE0f--Af_9g4OFYRJFnMmkXPPNAn1L6c';
        googleSheetBook = 'Coord';
        mm2pixels = 1/0.018;
        maskSensory % mask of sensory region in a 512x512 matrix
        coordsSensory % coordinates of sensory region in a 512x512 matrix
        maskMotor % mask of motor region in a 512x512 matrix
        coordsMotor % coordinates of motor region in a 512x512 matrix
        maskNotSensoryMotor % mask of not sensory and motor region in a 512x512 matrix
    end

    methods
        %% Constructor
        function obj = MaskUeno()

            % read data from google sheet
            coords = readGoogleSheet(obj.googleSheetId, obj.googleSheetBook);

            % group data and calculate mask for each region
            [gIdx, coordsTable] = findgroups(coords(:, {'Region', 'Innervation'}));

            for i = 1:length(unique(gIdx))
                coordsNow = coords(gIdx == i, :);
                coordsNowXy = [coordsNow.CoordX, coordsNow.CoordY];
                coordsNowXy(end + 1, :) = coordsNowXy(1, :); %#ok<AGROW>
                coordsNowXy = coordsNowXy * obj.mm2pixels + 256;
                coordsTable.Coords{i} = coordsNowXy;
            end

            % mask of sensory region
            coordsTableSensory = coordsTable(strcmp(coordsTable.Region, 'Sensory'), :);
            coordsSensory = coordsTableSensory.Coords{1};
            obj.maskSensory = flipud(poly2mask(coordsSensory(:, 1), coordsSensory(:, 2), 512, 512));
            obj.coordsSensory = coordsSensory;
            % mask of motor region
            coordsTableMotor = coordsTable(strcmp(coordsTable.Region, 'Motor'), :);
            maxVertices = max(cellfun(@(x) size(x, 1), coordsTableMotor.Coords));
            % interpolate coordinates to have same number of vertices
            coordsTableMotor.Coords = cellfun(@(x) interp1(1:size(x, 1), x, linspace(1, size(x, 1), maxVertices)), coordsTableMotor.Coords, 'UniformOutput', false);
            % calculate mean coordinates of motor region
            coordsMotor = cat(3, coordsTableMotor.Coords{:});
            coordsAvgMotor = mean(coordsMotor, 3);
            % calculate mask of motor region
            obj.maskMotor = flipud(poly2mask(coordsAvgMotor(:, 1), coordsAvgMotor(:, 2), 512, 512));
            obj.coordsMotor = coordsAvgMotor;
            % mask of not sensory and motor region
            obj.maskNotSensoryMotor = ~(obj.maskSensory | obj.maskMotor);
        end

    end

end
