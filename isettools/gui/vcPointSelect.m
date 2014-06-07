function pointLoc = vcPointSelect(obj,nPoints,msg)
% Select point locations from an ISET window. 
%
%   pointLoc = vcPointSelect(obj,[nPoints = 1],[msg])
%
%  pointLoc: Returns the (x,y) = (col,row) values. During the point
%  selection process.  The upper left is (1,1).
%
%      left click is used to choose a point, 
%      backspace deletes the previous point, 
%      right click indicates done.
%
%  If nPoints is not specified, then nPoints = 1 is assumed.  In that case,
%  a single right click is all that is required. 
%
%  In general, the number of points is checked and a message is printed if
%  it is incorrect.  But the pointLoc values are still returned.
%
% Example:
%   pointLoc = vcPointSelect(vcGetObject('OI'))
%   pointLocs = vcPointSelect(vcGetObject('OI'),3)
%   pointLoc = vcPointSelect(vcGetObject('sensor'),3,'Help me')
%
% Copyright ImagEval Consultants, LLC, 2005.

if notDefined('obj'), error('Object is required (isa,oi,scene ...)'); end
if notDefined('nPoints'), nPoints = 1; end
if notDefined('msg')
    msg = sprintf('Right click to select point');
end

objFig = vcGetFigure(obj); 

% Select points.  
hndl = guihandles(objFig);
ieInWindowMessage(msg,hndl);

[y,x] = getpts(objFig);
x = round(x); y = round(y);
ieInWindowMessage('',hndl);

if length(x) < nPoints
    pointLoc = [];
    warning('ISET:vcPointSelect1','Returning only %.0f points',length(x));
    list = (1:length(x));
elseif length(x) > (nPoints) 
    warning('ISET:vcPointSelect2','Returning first of %.0f points',nPoints);
    list = (1:nPoints);
else
    list = (1:nPoints);
end

pointLoc(:,1) = y(list);
pointLoc(:,2) = x(list);

end