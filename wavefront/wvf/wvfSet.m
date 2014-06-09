function wvf = wvfSet(wvf,parm,val,varargin)
% wvf = wvfSet(wvf,parm,val,varargin)
% Set wavefront parameters to use for calculations
%
%     wvf = wvfSet(wvf,parm,val,varargin)
%
% Key wavefront properties are stored as parameters here.  Many other
% properties are computed from these identifiable parameters using other
% functions, such as wvfGet.
%
% Parameter names can be written with spaces and upper/lower case.  The
% strings are converted to lower case and all the spaces are removed by
% this routine.
%
% When parameters that influence the pupil function are changed,
% wvf.PUPILFUNCTION_STALE is set too true.
%
% Examples:
%   wvf = wvfSet(wvf,'measured pupil',8);
%   wvf = wvfSet(wvf,'stiles crawford',sce);
%   wvf = wvfSet(wvf,'name','test wvf');
%   wvf = wvfSet(wvf,'zcoeffs',z);
%
% Parameters:
%
% Bookkeeping
%   'name' - Name of this object
%   'type' - Type of this object, should always be 'wvf'
%
% Measured data - calculations are derived from these values
%   'measured pupil size' - Pupil size for measured wavefront aberration (mm)
%   'measured wave' - Wavefront aberration measurement wavelength (nm)
%   'measured optical axis' - Measured optical axis (deg)
%   'measured observer accommodation' -
%       Observer accommodation at aberration measurement time (diopters)
%   'measured observer focus correction' -
%       Focus correction added for observer at measurement time (diopters)
%
%  Spatial sampling parameters
%    'sample interval domain' -
%       Which domain has sample interval held constant with 
%       wavelength ('psf', 'pupil')
%    'number spatial samples' -
%        Number of spatial samples (pixel) for pupil function and psf
%    'ref pupil plane size' -
%        Size of sampled pupil plane at measurement wavelength (mm)
%    'ref pupil plane sample interval' -
%        Pixel sample interval in pupil plane at measurement wavelength (mm)
%    'ref psf sample interval' -
%        Sampling interval for psf at measurment wavelength (arcminute/pixel)
%
%  Calculation parameters
%     'zcoeffs' - Zernike coefficients, OSA standard numbering/coords
%     'calc pupil size'   - Pupil size for calculation (mm,*)
%     'calc optical axis' - Optical axis to compute for (deg)
%     'calc observer accommodation' -
%          Observer accommodation at calculation time (diopters)
%     'calc observer focus correction' -
%          Focus correction added optically for observer at calculation time (diopters)
%     'calc wave'          -  Wavelengths to calculate over (nm,*)
%     'calc cone psf info' -
%         Structure with cone sensitivities and weighting spectrum for
%         computing cone psfs.
%
% Stiles Crawford Effect
%     'sce params' - The Stiles-Crawford Effect  structure
%
% See also: wvfGet, wvfCreate, wvfComputePupilFunction, wvfComputePSF,
%           sceCreate, sceGet
%
% Notes:
%   5/17/12  dhb  When we pass fewer than 65 coefficients, should we zero
%                 out the higher order ones, or leave them alone?  The
%                 current code leaves them alone, which seems a little
%                 dangerous.
%            dhb  There are two underlying field sizes, one in the pupil
%                 plane and one in the plane of the retina.  The pixel
%                 dimensions are implicitly linked by the conversion between
%                 pf and psf, and our conversion code uses the same number
%                 of pixels in each representation.  One could get fancier
%                 and explicitly specify the units of each representation,
%                 and appropiately convert.  An important consideration is
%                 for the dimensions to be chosen so that both pupile
%                 function and psf are adequately sampled.
%
% (DHB/BW) (c) Wavefront Toolbox Team 2011, 2012

% Programming Notes
%   The Strehl ratio, http://en.wikipedia.org/wiki/Strehl_ratio

% Arg checks and parse.
%
% The switch on what we're setting is broken out into several pieces
% below to allow use of cells, and so that autoindent does something
% reasonable with our block comment style.
if ~exist('parm','var') || isempty(parm), error('Parameter must be defined'); end
if ~exist('val','var'), error('val must be defined'); end

parm = ieParamFormat(parm);

%% Set the parameters in a big case statement
switch parm
    
    %% Bookkeeping
    case 'name'
        % This specific object's name
        wvf.name = val;
        
    case 'type'
        % Type should always be 'wvf'
        if (~strcmp(val,'wvf'))
            error('Can only set type of wvf structure to ''wvf''');
        end
        wvf.type = val;
        
        %% The measured values
        % These are the values that describe the assumed measurement
        % conditions for the zernicke coefficients.
        %
        % When we perform a calculation, we may adjust some of the
        % parameters (say the wavelength) and derive the prediction
        % correcting for these background assumptions and the calculation.
        % For example, the wavelength at calculation might differ from the
        % measured wavelength.  We add a chromatic abberration correction.
        % Or the pupil size of the calculation might differ, and we account
        % for that.
        %
        % The differences are accounted for in the
        % wvfComputePupilFunction, mainly.  It is possible that there are
        % other functions or scripts that compare the data as well.
        % 
    case {'measuredpupilsize', 'measuredpupil', 'measuredpupilmm', 'measuredpupildiameter'}
        % Pupil diameter in mm over for which wavefront expansion is valid
        wvf.measpupilMM = val;
        
    case {'measuredwave','measuredwl', 'measuredwavelength'}
        % Measurement wavelength (nm)
        % There should be only one wavelength for the measurement.
        wvf.measWlNM = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'measuredopticalaxis', 'measuredopticalaxisdeg'}
        % Measurement optical axis, degrees eccentric from fovea
        wvf.measOpticalAxisDeg = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'measuredobserveraccommodation', 'measuredobserveraccommodationdiopters'}
        % Observer accommodation, in diopters relative to relaxed state of eye
        wvf.measObserverAcommodationDiopters = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'measuredobserverfocuscorrection', 'measuredobserverfocuscorrectiondiopters'}
        % Focus correction added optically for observer at measurement time (diopters)
        wvf.measObserverAcommodationDiopters = val;
        wvf.PUPILFUNCTION_STALE = true;
        
        %% Zernike coefficients and related
        %
        % These specify the measured (or assumed) wavefront aberrations in
        % terms of a Zernike polynomial expansion.  Exanding these gives us
        % the wavefront abberations in microns over the measured pupil.
        %
        % The coefficients represent measurements that were made (or
        % assumed to be made) at a particular optical axis, state of
        % accommodation of the observer, wavelength, and over a particular
        % pupil size diameter.  We specify all of this size information
        % along with the coefficients, even though we don't know quite how
        % to use all of it at present.
        %
        % Zernike coeffs 0,1,2 (piston, verticle tilt, horizontal tilt) are
        % typically 0 since they are either constant (piston) or only
        % change the point spread location, not quality, as measured in
        % wavefront aberrations. We use the "j" single-index scheme of OSA
        % standards
    case {'zcoeffs', 'zcoeff','zcoef'}
        % wvfSet(wvf,'zcoeffs',val,jIndex);
        % idx is optional, and can be a vector of j values
        % or a string array of coefficient names (see wvfOSAIndexToVectorIndex).
        % Note that j values start at 0, and that is the convention followed
        % here.
        %
        % The length of jIndex must match that of val, if it is passed. If
        % the current vector of zcoeffs is shorter than required by jIndex,
        % the vector is padded out with zeros prior to the insertion of the
        % passed coefficients.
        if (isempty(varargin))
            wvf.zcoeffs = val;
        else
            idx = wvfOSAIndexToVectorIndex(varargin{1});
            maxidx = max(idx);
            if (maxidx > length(wvf.zcoeffs))
                wvf.zcoeffs(length(wvf.zcoeffs)+1:maxidx) = 0;
            end
            wvf.zcoeffs(idx) = val;
        end
        wvf.PUPILFUNCTION_STALE = true;

        %% Spatial sampling parameters
        %
        % In the end, we calculate using discretized sampling.  Because
        % the pupil function and the psf are related by a fourier transform,
        % it is natural to use the same number of spatial samples for both
        % the pupil function and the corresponding psf.   The parameters
        % here specify the sampling.
        %
        % Note that this may be done independently of the wavefront
        % measurements, because the spatial scale of those is defined by
        % pupil size over which the Zernike coefficients define the
        % wavefront aberrations.
        %
        % There are a number of parameters that are yoked together here,
        % because the sampling intervals in the pupil and psf domains are
        % yoked, and because the overall size of the sampled quantities is
        % determined from the sampling intervals and the number of pixels.
        %
        % As a general matter, it will drive us nuts to have the number of
        % pixels varying with anything, because then we can't sum over
        % wavelength easily.  So we set the number of number of pixels and
        % size of the sampling in the pupil plane at the measurement
        % wavelength, and then compute/set everything else as needed.
        %
        % Because the sampling in the pupil and psf domains is yoked, its
        % important to choose values that do not produce discretization
        % artifacts in either domain.  We don't have an automated way to do
        % this, but the default numbers here were chosen by experience
        % (well, really by Heidi Hofer's experience) to work well.  Be
        % attentive to this aspect if you decide you want to change them by
        % very much.
        %
        % The other thing that is tricky is that the relation between the
        % sampling in the pupil and psf domains varies with wavelength. So,
        % you can't easily have the sample interval stay constant over
        % wavelength in both the pupil and psf domains.  You have to choose
        % one or the other. We will typically force equal sampling in the
        % psf domain, but we allow specification of which.
    case {'sampleintervaldomain'}
        % Determine what's held constant with calculated wavelength.
        % Choices are 'psf' and 'pupil'
        wvf.constantSampleIntervalDomain = val;
        
    case {'numberspatialsamples','spatialsamples', 'npixels', 'fieldsizepixels'}
        % Number of pixels that both pupil and psf planes are discretized
        % with.
        %
        % This is a stored value.
        wvf.nSpatialSamples = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'refpupilplanesize', 'refpupilplanesizemm', 'fieldsizemm'}
        % Total size of computed field in pupil plane.  This is for the measurement
        % wavelength.  The value can vary with wavelength, but this one
        % sets the scale for all the other wavelengths.
        %
        % This is a stored value.
        wvf.refSizeOfFieldMM = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'refpupilplanesampleinterval', 'refpupilplanesampleintervalmm', 'fieldsamplesize','fieldsamplesizemmperpixel'}
        % Pixel sampling interval of sample pupil field.  This is for the measurement
        % wavelength.  The value can vary with wavelength, but this one
        % sets the scale for all the other wavelengths.
        wvf.refSizeOfFieldMM = val*wvf.nSpatialSamples;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'refpsfsampleinterval' 'refpsfarcminpersample', 'refpsfarcminperpixel'}
        % Arc minutes per pixel of the sampled psf at the measurement
        % wavelength.
        %
        % When we convert between the pupil function and the PSF,
        % we use the fft.  Thus the size of the image in pixels
        % is the same for the sampled pupil function and the sampled
        % psf.
        %
        % The number of arc minutes per pixel in the sampled PSF is
        % related to the number of mm per pixel for hte pupil function,
        % with the relation depending on the wavelength.  The fundamental
        % formula in the pupil plane is that the pixel sampling interval
        % in cycles/radian is:
        %
        %   pupilPlaneCyclesRadianPerPix = pupilPlaneField/[lambda*npixels]
        %
        % where npixels is the number of linear pixels and lambda is the
        % wavelength. This formula may be found as Eq 10 of Ravikumar et
        % al. (2008), "Calculation of retinal image quality for
        % polychromatic light," JOSA A, 25, 2395-2407, at least if we think
        % their quantity d is the size of the pupil plane field being
        % sampled.
        %
        % If we now remember how units convert when we do the fft, we
        % obtain that the number of radians in the PSF image is the inverse
        % of the sampling interval:
        %
        %   radiansInPsfImage = [lambda*npixels]/pupilPlaneField
        %
        % which then gives us the number of radiansPerPixel in the
        % PSF image as
        %
        %   radiansPerPixel = lambda/pupilPlaneField
        %
        % The formula below implements this, with a conversion from radians
        % to minutes with factor (180*60/3.1416) and converts wavelength to
        % mm from nm with factor (.001*.001)
        %
        % DHB, 5/22/12, based on earler comments that were here.  Someone
        % else might take a look at the paper referenced above and the
        % logic of this comment and check that it all seems right.  Did I
        % think through the fft unit conversion correctly?  And, there must
        % be a more fundamental reference than the paper above, and for
        % which one wouldn't have to guess quite as much about what is
        % meant.
        radiansPerPixel = val/(180*60/3.1416);
        wvf.refSizeOfFieldMM = wvfGet(wvf,'measured wl','mm')/radiansPerPixel;
        wvf.PUPILFUNCTION_STALE = true;
        
        
    %% Calculation parameters
    % These parameters are used for the specific calculations with this,
    % interpolating the measured values that are stored above.
    case {'calcpupilsize' 'calculatedpupil','calculatedpupildiameter'}
        % Pupil diameter in mm - must be smaller than measurements
        if (val > wvf.measpupilMM)
            error('Pupil diamter used for calculation must be smaller than that used for measurements');
        end
        wvf.calcpupilMM = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'calcopticalaxis'}
        % Specify observer accommodation at calculation time
        if (val ~= wvfGet(wvf,'measuredopticalaxis'))
            error('We do not currently know how to deal with values that differ from measurement time');
        end
        wvf.calcOpticalAxisDegrees = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'calcobserveraccommodation'}
        % Specify observer accommodation at calculation time
        if (val ~= wvfGet(wvf,'measuredobserveraccommodation'))
            error('We do not currently know how to deal with values that differ from measurement time');
        end
        wvf.calcObserverAccommodationDiopters = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'calcobserverfocuscorrection', 'defocusdiopters'}
        % Specify optical correction added to observer focus at calculation time
        wvf.calcObserverFocusCorrectionDiopters = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'calcwave','calcwavelengths','wavelengths','wavelength','wls','wave'}
        % Normally just a vector of wavelengths in nm
        % but allow SToWls case for PTB users.
        %
        % wvfSet(wvfP,'wave',400:10:700)  OR
        % wvfSet(wvfP,'wave',[400 10 31])
        %
        % Note that it isn't sufficient just to call SToWls
        % (which will pass a vector of evenly spaced wls
        % through, because we might want to allow unevenly
        % spaced wls.)
        if size(val,2) == 3 && size(val,1) == 1 % SToWls case
            % Row vector with 3 entries.
            wls = SToWls(val);
            wvf.wls = MakeItWls(wls);
        else  % A column vector case
            wvf.wls = val(:);
        end
        wvf.PUPILFUNCTION_STALE = true;
        
    case {'calcconepsfinfo'}
        % Structure that has cone sensitivities and a
        % weighting function for aggregating the polychromatic
        % psf down to cone psfs.
        wvf.conePsfInfo = val;
        
    %% Stiles-Crawford Effect
    % Angular dependence of the cone absorptions are calculated by the
    % parameters in this structure.  Values from the structure are
    % retrieved and set using sceGet/Set
    case {'sceparams','stilescrawford'}
        % The structure of sce is defined in sceCreate
        wvf.sceParams = val;
        wvf.PUPILFUNCTION_STALE = true;
        
    otherwise
        error('Unknown parameter %s\n',parm);
        
end


return
