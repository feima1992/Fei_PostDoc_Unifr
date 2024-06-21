files = findFile('Z:\users\Fei\DataAnalysis\Utilities\CoorTransformWF','.mat');
fileName = '2376';
filesThisMouse = files(contains(files.path,fileName),:);
A = CoorTransform().Load(filesThisMouse.namefull{1});
A.winCenterCoorReal = [-2.25,-0.5];
A.ConvertUnit("overwriteFlag",true)
A.objSelectRefPoints = [];
A.Save(1);

for i =2:height(filesThisMouse)
    B = CoorTransform().Load(filesThisMouse.namefull{i});
    B.refPointsCoorPixel = A.refPointsCoorPixel;
    B.bregmaCoorPixel = A.bregmaCoorPixel;
    B.winCenterCoorReal = A.winCenterCoorReal;
    B.winCenterCoorPixel = A.winCenterCoorPixel;
    B.objSelectRefPoints = [];
    B.Save(1)
end
