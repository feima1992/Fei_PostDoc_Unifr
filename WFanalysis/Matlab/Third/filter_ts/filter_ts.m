function y = filter_ts(fil,x,numsides)
%
%	This function performs one and two-sided
% 	filtering.  Note that for a one-sided filter, the 
%	first length(fil) points are garbage, and for a two
%	sided filter, the first and last length(fil)/2 
%	points are useless.
%
%	the default value for numsides is 2.
%	for one sided filtering, this calls y=filter(fil,1,x);
%
%	USAGE	: y = filter_ts(fil,x,numsides)
%
% EJP Jan 1991
%
[ri,ci]= size(x);
if (ci > 1)
     	x = x';
end
if nargin < 3
        numsides = 2;
end
numpts = length(x);
halflen = ceil(length(fil)/2);
if numsides == 2
	x = [x ; zeros(halflen,1)];
	y = filter(fil,1,x);
	y = y(halflen:numpts + halflen - 1);
else 
	y=filter(fil,1,x);
end
if (ci > 1)
     	y = y';
end
return

