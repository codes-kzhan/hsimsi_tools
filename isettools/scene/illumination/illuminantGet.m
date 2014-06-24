function val = illuminantGet(il,param,varargin)
% Get parameter value from an illuminant structure
%
%  val = illuminantGet(il,param,varargin)
%
% Illuminant structures are being developed with richer features.  Thus, we
% have implemented a set/get/create suite of routines.  This is the 'get'
% feature.
%
% Illuminants have a variety of formats.
%
%  spectral - a single vector of wavelength that is applied to the entire
%             scene.   
%  spatial spectral - a 3D representation of the illuminant (r,c,wave)
%
% You can assess the illuminant format of a 'scene', as in
%      sceneGet(scene,'illuminant format')
% You can also assess the illuminant format here as in
%      illuminantGet(il,'illuminant format')
%
%
% il: illuminant structure.
%  This structure contains a range of information about the illuminant,
%  including the wavelength samples and spectral power distribution.  The
%  illuminant spectral power distribution is stored in ieCompressData
%  format (32 uint bits).
%
% Parameter list:
%   name - A useful description, hopefully
%   type (always illuminant)
%
% Can be spectral or spatial spectral
%   photons   - Stored in photons
%   energy    - Calculated from photons
%   wave      - Wavelength samples (nm)
%
%   comment   -
%   luminance - 
%   size      - spatial/spectral or 1
%   cct       - Correlated color temperature
%   illuminant format - spectral or 'spatial spectral'
%
% See also:  illuminantCreate, illuminantSet
%
% Examples:
%   il = illuminantCreate('blackbody',400:10:700,5000,200);
%
%   illuminantGet(il,'luminance')
%   illuminantGet(il,'name')
%   illuminantGet(il,'type')
%   e = illuminantGet(il,'energy')
%   p = illuminantGet(il,'photons')
%
% (c) Imageval Consulting, LLC, 2012

%% Parameter checking
if ~exist('il','var') || isempty(il), error('illuminant required'); end
if ~exist('param','var') || isempty(param), error('param required'); end

val = [];

%% Main switch statement
param = ieParamFormat(param);
switch param
    case 'name'
        val = il.name;
    case 'type'
        % Should always be 'illuminant'
        val = il.type;
    
    case {'datamin'}
        if checkfields(il, 'data', 'photons')
            val = min(il.data.photons(:));
        end
    case {'datamax'}
        if checkfields(il, 'data', 'photons')
            val = max(il.data.photons(:));
        end
    case 'photons'
        % illuminantGet(il,'photons')
        % Would be nice to have:  illuminantGet(il,'photons',wave);
        
        % We handle the spectral and spatial spectral the same way.
        if checkfields(il,'data','photons')
            val = il.data.photons;
        end
        if isvector(val), val = val(:); end

    case 'energy'
        % This has to work for spatial spectral and pure spectral
        
        % Get the illuminant as photons and convert to energy
        p =  illuminantGet(il,'photons');
        if ndims(p) == 3
            % We manage the spatial spectral case
            [p,r,c] = RGB2XWFormat(p);
            val = Quanta2Energy(illuminantGet(il,'wave'),p);
            val = XW2RGBFormat(val,r,c);
        else
            % This is the spectral vector case
            val = Quanta2Energy(illuminantGet(il,'wave'),p(:)')';
        end
        if isvector(val), val = val(:); end
        
    case 'wave'
        % illuminantGet(il,'wave');
        % illuminantGet(il,'wave',scene);
        %
        % If an illuminant, it has its own spectrum.
        % If it is part of a scene, it may not have a spectrum and so we
        % use the scene spectrum, I guess.
        if isfield(il,'spectrum'), val = il.spectrum.wave;
        elseif ~isempty(varargin), val = sceneGet(varargin{1},'wave');
        end
        if isvector(val), val = val(:); end
        
    case 'nwave'
        % nWave = illuminantGet(il,'n wave');
        % Number of wavelength samples
        
        val = length(illuminantGet(il,'wave'));
        
    case 'luminance'
        % Return luminance in cd/m2
        e = illuminantGet(il,'energy');
        wave = illuminantGet(il,'wave');
        val = ieLuminanceFromEnergy(e(:)',wave);
        if isvector(val), val = val(:); end
    case 'spatialsize'
        % Needs to be worked out properly ... not working yet ...
        if ~checkfields(il,'data','photons'), val = []; return; end
        val = size(il.data.photons);
        
    case 'comment'
        val = il.comment;
        
    case 'illuminantformat'
        % illuminantGet(il,'illuminant format') Returns: spectral, spatial
        % spectral, or empty. In more recent Matlab versions, we can use
        % isvector, ismatrix functions.
        sz = illuminantGet(il,'spatial size');
        if length(sz) < 3
            if prod(sz) == illuminantGet(il,'nwave');
                val = 'spectral';
            end
        else
            if sz(3) == illuminantGet(il,'nwave')
                val = 'spatial spectral';
            end
        end
        
    otherwise
        error('Unknown illuminant parameter %s\n',param)
end

end