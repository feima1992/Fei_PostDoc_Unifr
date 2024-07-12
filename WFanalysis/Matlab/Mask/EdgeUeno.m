classdef EdgeUeno < handle
    % EdgeUeno class for real coordinates (unit mm) of sensory and motor regions in Ueno et al. 2018
    % MaskUeno class for mask of sensory and motor in a 512x512 matrix in Ueno et al. 2018
    properties
        coordsSensory
        coordsAvgMotor
    end

    methods

        function obj = EdgeUeno()

            % overlay the region of sensory and motor cortex
            googleSheetId = '1-XTF4-4M5bmvE0f--Af_9g4OFYRJFnMmkXPPNAn1L6c';
            googleSheetBook = 'Coord';
            coords = readGoogleSheet(googleSheetId, googleSheetBook);
            % group data and calculate mask for each region
            [gIdx, coordsTable] = findgroups(coords(:, {'Region', 'Innervation'}));

            for n = 1:length(unique(gIdx))
                coordsNow = coords(gIdx == n, :);
                coordsNowXy = [coordsNow.CoordX, coordsNow.CoordY];
                coordsNowXy(end + 1, :) = coordsNowXy(1, :); %#ok<AGROW>
                coordsTable.Coords{n} = coordsNowXy;
            end

            % mask of sensory region
            coordsTableSensory = coordsTable(strcmp(coordsTable.Region, 'Sensory'), :);
            obj.coordsSensory = coordsTableSensory.Coords{1};
            % mask of motor region
            coordsTableMotor = coordsTable(strcmp(coordsTable.Region, 'Motor'), :);
            maxVertices = max(cellfun(@(x) size(x, 1), coordsTableMotor.Coords));
            % interpolate coordinates to have same number of vertices
            coordsTableMotor.Coords = cellfun(@(x) interp1(1:size(x, 1), x, linspace(1, size(x, 1), maxVertices)), coordsTableMotor.Coords, 'UniformOutput', false);
            % calculate mean coordinates of motor region
            coordsMotor = cat(3, coordsTableMotor.Coords{:});
            obj.coordsAvgMotor = mean(coordsMotor, 3);
        end

        function result = WithinSensory(obj, xys, plotFlag)
            % check if the points provided are within the sensory region

            if nargin < 3
                plotFlag = false;
            end

            result = inpolygon(xys(:, 1), xys(:, 2), obj.coordsSensory(:, 1), obj.coordsSensory(:, 2));

            if plotFlag
                figure('Color', 'w', 'Position', [100, 100, 800, 800]);
                plot(polyshape(obj.coordsSensory(:, 1), obj.coordsSensory(:, 2)), 'FaceColor', 'none', 'EdgeColor', 'r');
                hold on;
                plot(xys(result, 1), xys(result, 2), 'r.');
                xlim([-4.5, 0.5]);
                ylim([-2.5, 2.5]);
                axis equal;
            end

        end

        function result = WithinMotor(obj, xys, plotFlag)
            % check if the points provided are within the motor region

            if nargin < 3
                plotFlag = false;
            end

            result = inpolygon(xys(:, 1), xys(:, 2), obj.coordsAvgMotor(:, 1), obj.coordsAvgMotor(:, 2));

            if plotFlag
                figure('Color', 'w', 'Position', [100, 100, 800, 800]);
                plot(polyshape(obj.coordsAvgMotor(:, 1), obj.coordsAvgMotor(:, 2)), 'FaceColor', 'none', 'EdgeColor', 'r');
                hold on;
                plot(xys(result, 1), xys(result, 2), 'r.');
                xlim([-4.5, 0.5]);
                ylim([-2.5, 2.5]);
                axis equal;
            end

        end

    end

end
