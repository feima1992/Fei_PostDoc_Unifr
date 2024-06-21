A = Enrich_LimbMvt();
A.PlotActMap()
A.PlotActEdge()
A.ExportActProps()

A = Rg_LimbMvt();
A.PlotActMap()
A.PlotActEdge()
A.ExportActProps()


B = Enrich_LimbVib();
B.PlotActMap()
B.PlotActEdge()
B.ExportActProps()


%% Plot figures

% group data by mouse

[G, ID] = findgroups(A.objRegIMcorr.fileTable.mouse);
% plot for each mouse
framesAvg = cell(size(ID));
framesAvgThred = cell(size(ID));
for i = 1:length(ID)
    figure('Color', 'w', 'Name', ID{i}, "Position",[160,470,1600,540])
    thisMouse = A.objRegIMcorr.fileTable(G == i, :);
    mouse = unique(thisMouse.mouse);
    sessions = thisMouse.session;
    for j = 1:length(sessions)
        subplot(2, length(sessions)+1, j)
        thisSession = thisMouse(ismember(thisMouse.session, sessions(j)), :);
        frame = thisSession.IMcorr{1}(:,:,28);
        frameThre = max(frame(:)) * 0.5;
        frameThreEdge = bwboundaries(frame >= frameThre, 'noholes');
        imshowFrameRefBregma(frame, 'title', sprintf('%s', sessions{j}));
        hold on 
        for k = 1:length(frameThreEdge)
            boundary = frameThreEdge{k};
            plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
        end
        frameThred = Frames_IMcorr(frame).CalActMap(0.5).frameData;
        subplot(2, length(sessions)+1, j + length(sessions)+1)
        imshowFrameRefBregma(frameThred, 'title', sprintf('%s', sessions{j}));
        
    end
    frames = cellfun(@(x) x(:,:,28), thisMouse.IMcorr, 'UniformOutput', false);
    frameAvg = mean(cat(3, frames{:}), 3);
    frameAvgThre = max(frameAvg(:)) * 0.5;
    frameAvgThreEdge = bwboundaries(frameAvg >= frameAvgThre, 'noholes');
    subplot(2, length(sessions)+1, length(sessions)+1)
    imshowFrameRefBregma(frameAvg, 'title', sprintf('%s', mouse{1}));
    hold on
    for k = 1:length(frameAvgThreEdge)
        boundary = frameAvgThreEdge{k};
        plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
    end
    frameAvgThred = Frames_IMcorr(frameAvg).CalActMap(0.5).frameData;
    subplot(2, length(sessions)+1, length(sessions)*2+2)
    imshowFrameRefBregma(frameAvgThred, 'title', sprintf('%s', mouse{1}));
    exportgraphics(gcf, sprintf('%s.png', mouse{1}))
    close(gcf)
    framesAvg{i} = frameAvg;
    framesAvgThred{i} = frameAvgThred;
end

[~, ID] = findgroups(A.objRegIMcorr.fileTable(:,{'mouse','group'}));
ID.framesAvg = framesAvg; ID.framesAvgThred = framesAvgThred;

[G, idx] = findgroups(ID.group);

% plot for all mice
for i = 1:length(idx)
    thisGroup = ID(G == i,:);
    mice = thisGroup.mouse;
    figure('Color', 'w', 'Name', mice{j}, "Position",[160,470,1600,540])

    for j = 1:length(mice)
        frames = thisGroup.framesAvg{ismember(thisGroup.mouse, mice{j})};
        framesThred = thisGroup.framesAvgThred{ismember(thisGroup.mouse, mice{j})};
        framesThre = max(frames(:)) * 0.5;
        framesThreEdge = bwboundaries(frames >= framesThre, 'noholes');
        subplot(2, length(mice)+1, j)
        imshowFrameRefBregma(frames, 'title', sprintf('%s', mice{j}));
        hold on
        for k = 1:length(framesThreEdge)
            boundary = framesThreEdge{k};
            plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
        end     
        subplot(2, length(mice)+1, j + length(mice)+1)
        imshowFrameRefBregma(framesThred, 'title', sprintf('%s', mice{j}));
    end
    
    framesMiceAvg = mean(cat(3, thisGroup.framesAvg{:}), 3);
    framesMiceAvgThred = max(framesMiceAvg(:)) * 0.5;
    framesMiceAvgThredEdge = bwboundaries(framesMiceAvg >= framesMiceAvgThred, 'noholes');
    subplot(2, length(mice)+1, length(mice)+1)
    imshowFrameRefBregma(framesMiceAvg, 'title', sprintf('%s', thisGroup.group{1}));
    hold on
    for k = 1:length(framesMiceAvgThredEdge)
        boundary = framesMiceAvgThredEdge{k};
        plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
    end
    framesMiceAvgThred = Frames_IMcorr(framesMiceAvg).CalActMap(0.5).frameData;
    subplot(2, length(mice)+1, length(mice)*2+2)
    imshowFrameRefBregma(framesMiceAvgThred, 'title', sprintf('%s', thisGroup.group{1}));
    exportgraphics(gcf, sprintf('%s.png', thisGroup.group{1}))
    close(gcf)
end