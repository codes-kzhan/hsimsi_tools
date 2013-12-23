function img = sensorData2Image(sensor,dataType,gam,scaleMax)
% Produce the image data displayed in the sensor window.
%
%   img = sensorData2Image(sensor,[dataType = 'volts'],[gam=1],[scaleMax=0 (false)])
%
% This function renders an image of the CFA.  It creates the color at each
% pixel resemble the transmissivity of the color filter at that pixel. The
% intensity measures the size of the data.  The dataType is normally volts.
%
% Normally, the function takes in one CFA planes. It can also handle the
% case of multiple exposure durations.
%
% While it is usally used for volts, the routine converts the image from
% the 'dv' fields or even 'electrons' (I think). 
%
% The returned images can be written out as a tiff file by sensorSaveImage.
%
% Examples:
%  sensor = vcGetObject('sensor');
%  oi     = vcGetObject('oi');
%  sensor = sensorCompute(sensor,oi);
%  img    = sensorData2Image(sensor,'volts',0.6);
%  figure; imagesc(img)
%
%  sensor = sensorSet(sensor,'expTime',[.01 .3 ; 0.3 0.01]);
%  sensor = sensorCompute(sensor,oi);
%  img    = sensorData2Image(sensor,'volts',0.6);
%  figure; imagesc(img)
%
%  sensor = sensorSet(sensor,'expTime',[0.05 .1 .2 0.4]);
%  sensor = sensorCompute(sensor,oi);
%  img    = sensorData2Image(sensor,'volts',0.6);
%  figure; imagesc(img)
%
%  vcReplaceAndSelectObject(sensor); sensorImageWindow();
%
% Copyright ImagEval Consultants, LLC, 2003.

if ieNotDefined('sensor'),     sensor = vcGetObject('sensor'); end
if ieNotDefined('dataType'),   dataType = 'volts'; end
if ieNotDefined('gam') ,       gam = 1; end
if ieNotDefined('scaleMax'),   scaleMax = 0; end

img = sensorGet(sensor,dataType);
if isempty(img), return; end

% Determine the scale factor for the maximum of the display
if scaleMax,     mxImage = max(img(:));
else             mxImage = sensorGet(sensor,'max output');
end

% Call the an imaging routine; the choice depends on the sensor data type.
% Because of noise, it is possible that the img data will be < 0.
%
% Applying img.^ gam makes the data out of range.  So we need to trap this
% condition.
%
% A mosaicked color image.  This is the main routine to convert
% the planar image to an RGB image.  The conversion depends on the
% nature of the color filters in the cfa.
nSensors   = sensorGet(sensor,'nFilters');
expTimes   = sensorGet(sensor,'expTimes');
nExposures = sensorGet(sensor,'nExposures');

if nExposures > 1

    pSize = size(sensorGet(sensor,'pattern'));
    if isequal(pSize,size(expTimes))
        % Each plane goes into a different pixel in the constructed CFA.
        % If the pattern size is (r,c) the first r planes fill the first
        % row in the CFA pattern
        %
        %   ( 1 3 5
        %     2 4 6)
        nRows = sensorGet(sensor,'rows');
        nCols = sensorGet(sensor,'cols');
        cfa   = zeros(nRows,nCols);
        
        whichExposure = 1;
        for cc = 1:pSize(2)
            colSamps = cc:pSize(2):nCols;
            for rr=1:pSize(1)
                rowSamps = rr:pSize(1):nRows;
                cfa(rowSamps,colSamps) = img(rowSamps,colSamps,whichExposure);
                whichExposure = whichExposure + 1;
            end
        end
        img = cfa;
    else
        % In bracketing case we can select which exposure to render
        expPlane = sensorGet(sensor,'exposurePlane');
        img = sensorGet(sensor,dataType);
        img = img(:,:,expPlane);
    end
end

if nSensors > 1    % A color CFA

    img = plane2rgb(img,sensor,0);

    % We should find a transformation, T, that maps the existing
    % sensors into RGB colors.  Then we apply that T to the image data.
    % This algorithm should work for any choice of color filter
    % spectra.  Perhaps the scaling (above) should be done below?  Or
    % at least T should be scaled.
    %
    % Notice that we sort the strings so that rgb and bgr and so forth are
    % all treated the same.  They are both treated as RGB. Also rgbw and
    % wrgb are treated the same.  They are both treated as WRGB.
    % Some thoughts: 
    %   We can  adjust T to get nice saturated colors.
    % One thought is to find the max value in each row and set that
    % to 1 and set the others to 0. That would handle a lot of
    % cases.
    % This trick forces a saturated color on every line ...
    %             mx = max(T,[],2);
    %             mx = diag( 1 ./ mx);
    %             T  = mx*T; T(T(:)<1) = 0;
    %
    % Another thought:
    %    T = colorTransformMatrix('cmy2rgb');
    %    This is a good grbc case.
    %    T = [1 0 0 ; 0 1 0 ; 0 0 1 ; 0 1 1];
    %
    % We could insert other switches.  For example, we could trap cmy and
    % cym cases here. 

    switch sensorGet(sensor,'filterColorLetters')
        case 'rgb'
            % We just leave rgb data alone.
            % T = eye(3,3);  RGB case
            % We could always just run the case below, though.  It
            % seems to work OK.
            %                 T = sensorDisplayTransform(sensor);
            %                 img = imageLinearTransform(img,T);
        case 'wrgb'
            T = [1 1 1; 1 0 0; 0 1 0; 0 0 1];  
            img = imageLinearTransform(img,T);
        case 'rgbw'
            T = [1 0 0; 0 1 0; 0 0 1; 1 1 1];  
            img = imageLinearTransform(img,T);       
        otherwise
            % I think this covers 3 and four color cases.  I am not
            % sure the other cases (above) should be handled
            % separately.  
            T = sensorDisplayTransform(sensor);
            img = imageLinearTransform(img,T);
    end

    % Scale the displayed image intensity to the range between 0 and
    % the voltage swing.  RGB images are supposed to run from 0,1
    img = img/mxImage;
    img = ieClip(img,0,1).^gam;

elseif nSensors == 1
    % Gray scale images run from 0 to 255 for display

    img = (img/mxImage).^gam;
    img = ieClip(img,0,[])*255;
    % img = ieClip(img,0,[]);
end


return;


%-----------------------------------------------------
function T = sensorDisplayTransform(sensor)
%
%  T = sensorDisplayTransform(sensor)
%
%   Find a transform that maps the sensor filter spectra into a an
%   approximation of their (R,G,B) appearance. This transform is used for
%   displaying the sensor data.
%   To see estimate the RGB appearance of the filterSpectra, we create
%   block matrix functions and multiply the filterspectra
%
%      filterRGB = bMatrix'*filterSpectra
%
%   The first column of filterRGB tells us the RGB value to use to display
%   the first filter, and so forth.  So, if the sensor data are in the
%   columns of a matrix, we want the display image to be
%
%                   sensorData*filterRGB'
%
%   Also, we want to scale T reasonably.  For now, we have [1,1,1]*T set to
%   a max value of 1.  But these images look a little dim to me.
%

% We set the extrapVal to 0.2 because we may have infrared data
bMatrix = colorBlockMatrix(sensorGet(sensor,'wave'),0.2);
filterSpectra = sensorGet(sensor,'filterspectra');

filterRGB = bMatrix'*filterSpectra;
T = filterRGB';
% o = ones(1,size(T,1));
s = max(T(:));
% s = max((o*T)');
T = T/s;

return;

