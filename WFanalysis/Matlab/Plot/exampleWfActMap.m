files = findFile('D:\WF\WF_M122X\TrialAll\MvtDir0\ActMap\Raw',{'m1221','.mat'});
avgAct = cell(1,height(files));
for i = 1:height(files)
    data = load(files.path{i});
    avgAct{i} = data.IMcorr(:,:,28);
end
avgAct = mean(cat(3,avgAct{:}),3);
mask = imread("Z:\users\Fei\DataAnalysis\Utilities\ABMtemplate - Copy.tif");
frames = Frames(avgAct);
frames.ApplyGaussLowPass(2);
frames.ApplyMask(mask);
thre = max(avgAct(:))*0.5;
threEdge = bwboundaries(frames.frameData >= thre, 'noholes');
frames.ImShowFrame()
hold on
[~,idx] = max(cellfun(@(X)size(X,1),threEdge));

boundary = threEdge{idx};
plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 3)


