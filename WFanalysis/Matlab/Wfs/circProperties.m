function circProps = circProperties(trigData, cNum)
    mvtDirs = (0:45:360 - 45)';
    stats = trigData.Stats{cNum};
    stats(:, 1) = stats(:, 1) - min(stats(:, 1));
    circMean = rad2deg(circ_mean(deg2rad(mvtDirs), stats(:, 1)));
    circVar = circ_var(deg2rad(mvtDirs), stats(:, 1));
    circTest = circ_rtest(deg2rad(mvtDirs), stats(:, 1));
    [~, prefDirId] = min(abs((circMean - mvtDirs)));
    prefDir = mvtDirs(prefDirId);
    circProps = [circMean, circVar, circTest, prefDir];
end
