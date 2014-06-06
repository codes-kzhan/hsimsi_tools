function xy = vcLineSelect(obj,objFig)
% Select (x,y) coordinate that determines a line. 
%
%   xy = vcLineSelect(obj,[objFig])
%
%  This routine uses getpts() on the ISET window corresponding to the ISET
%  object. The legitimate objects are SCENE,OI, SENSOR, and VCIMAGE.  A
%  message is placed in the window asking the user to select points.
%
% Example:
%   xy = vcLineSelect(vcGetObject('isa'));
%
% See also:  vcPointSelect, vcLineSelect, vcROISelect, ieGetXYCoords
%
% Copyright ImagEval Consultants, LLC, 2005.

% TODO:
%  getpts() allows you to specify the axis, not just the figure.  We should
%  probably use that addressing.  We should also trap the case no points
%  returned ... is that possible?  Or out of range points?

if notDefined('obj'), error('You must define an object (isa,oi,scene ...)'); end
if notDefined('objFig'), objFig = vcGetFigure(obj); end

% Select points.  
hndl = guihandles(objFig);
msg = sprintf('Right click to select one point.');
ieInWindowMessage(msg,hndl);

[x,y] = getpts(objFig);
nPoints = length(x);
if nPoints > 1
    warning('ISET:vcLineSelect1','%.0f points selected',nPoints); 
    xy = [round(x(end-1)), round(y(end-1))];
else
    xy = [round(x), round(y)];
end

ieInWindowMessage('',hndl);

end