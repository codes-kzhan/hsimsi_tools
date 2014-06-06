function figHdl = vcNewGraphWin(figHdl, fType, varargin)
% Open a window for plotting
%
%    figHdl = vcNewGraphWin([fig handle],[figure type],varargin)
%
% A graph window figure handle is returned and stored in the currernt
% vcSESSION.GRAPHWIN entry.
%
% The varargin is a set of (param,val) pairs that can be used for
% set(gcf,param,val);
%
% A few figure shapes can be defaulted
%   fType:  Default - Matlab normal figure position
%           upper left    Simple
%           tall          (for 2x1 format)
%           wide          (for 1x2 format)
%           upperleftbig  (for 2x2 format)
%   This list may grow.
%
% Examples
%  vcNewGraphWin;
%  vcNewGraphWin([],'upper left')   
%  vcNewGraphWin([],'tall')
%  vcNewGraphWin([],'wide')
%  vcNewGraphWin([],'upper left big')   
%
%  vcNewGraphWin([],'wide','Color',[0.5 0.5 0.5])
%
% See also:
%
%
% PROGRAMMING TODO:
%    Add more default position options
%
% Copyright ImagEval Consultants, LLC, 2005.

if notDefined('figHdl'), figHdl = figure; end
if notDefined('fType'),  fType = 'upper left'; end

set(figHdl,'Name','ISET GraphWin','NumberTitle','off');
set(figHdl,'CloseRequestFcn','ieCloseRequestFcn');
set(figHdl,'Color',[1 1 1]);

% Position the figure
fType = ieParamFormat(fType);
switch(fType)
    case 'upperleft'
        set(figHdl,'Units','normalized','Position',[0.007 0.55  0.28 0.36]);
    case 'tall'
        set(figHdl,'Units','normalized','Position',[0.007 0.055 0.28 0.85]);
    case 'wide'
        set(figHdl,'Units','normalized','Position',[0.007 0.62  0.7  0.3]);
    case 'upperleftbig'
        % Like upperleft but bigger
        set(figHdl,'Units','normalized','Position',[0.007 0.40  0.40 0.50]);

    otherwise % Matlab default
end

%% Parse the varargin arguments
if ~isempty(varargin)
    n = length(varargin);
    if ~mod(n,2)
        for ii=1:2:(n-1)
            set(figHdl,varargin{ii},varargin{ii+1});
        end
    end
end

%% Store some information.  Not sure it is needed; not much used.
ieSessionSet('graphwinfigure',figHdl);
ieSessionSet('graphwinhandle',guidata(figHdl));

end