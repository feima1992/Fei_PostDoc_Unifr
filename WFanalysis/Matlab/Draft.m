A = WFS();

A.fileTableExp = A.fileTableExp(A.fileTableExp.goodResp==2,:);

centers = [A.fileTableExp.centerX, - A.fileTableExp.centerY];

B = EdgeUeno();

A.fileTableExp.withinSensory = B.WithinSensory(centers);
A.fileTableExp.withinMotor = B.WithinMotor(centers);

% A.fileTableExp = A.fileTableExp(A.fileTableExp.withinMotor==1,:);
% 
% A.PlotSpatialFootprints("respScoreThresh",1,"plotNoResp",true)

tbSensory = A.fileTableExp(A.fileTableExp.withinSensory==1,:);
tbMotor = A.fileTableExp(A.fileTableExp.withinMotor==1,:);
tbNotSensorimotor = A.fileTableExp(A.fileTableExp.withinSensory==0 & A.fileTableExp.withinMotor==0,:);




pd1 = A.gaussianPD;
pdw1 = A.gaussianWidth;
pd1(isnan(pd1))=[];
pdw1(isnan(pdw1)) = [];
pd1 = wrapTo360(pd1);

circ_rtest(deg2rad(pd1))
circ_rtest(deg2rad(pd2))

circ_var(deg2rad(pd1))
circ_var(deg2rad(pd2))


circ_wwtest(deg2rad(pd1),deg2rad(pd2))

median(pdw1)
median(pdw2)

ranksum(pdw1,pdw2)


