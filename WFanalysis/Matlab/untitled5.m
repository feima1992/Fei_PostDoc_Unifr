files = findFile('Z:\users\Fei\DataAnalysis\Utilities\CoorTransform','.mat');
fileName = 's2376';
filesThisMouse = files(contains(files.path,fileName),:);
A = CoorTransform().Load(filesThisMouse.namefull{2});
A.winCenterCoorReal = [-2.25,-0.5];
A.ConvertUnit(1);
A.Save(1);

for i =3:8
    B = CoorTransform().Load(filesThisMouse.namefull{i});
    B.refPointsCoorPixel = A.refPointsCoorPixel;
    B.bregmaCoorPixel = A.bregmaCoorPixel;
    B.winCenterCoorReal = A.winCenterCoorReal;
    B.winCenterCoorPixel = A.refPointsCoorPixel;
    B.ConvertUnit(0);
    B.Save(1)
end
