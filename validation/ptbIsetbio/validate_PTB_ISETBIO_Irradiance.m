function validate_PTB_ISETBIO_Irradiance()

    % Initialize a @UnitTest object to handle the results
    unitTestOBJ = UnitTest(mfilename('fullpath'));

    unitTestOBJ.addProbe(...
        'name',           'PTB vs. ISETBIO irradiance compute', ...  % probe name
        'onErrorReactBy', 'CatchingExcemption', ...         % how to react on errors in the validation script. Options are 'CatchingExcemption' or 'RethrowingExcemption'
        'functionHandle',  @PTB_ISETBIO_Irradiance, ...     % name of the validation script
        'functionParams',  struct(...                       % struct with input arguments expected by the validation script
                            'fov',            20, ...   % Big field required
                            'roiSize',         5, ...
                            'generatePlots',   false...
                            ) ...
    );
                     
end


function validationData = PTB_ISETBIO_Irradiance(params)

    % Unload params struct with PTB_ISETBIO_Irradiance - specific params
    fov             = params.fov;
    roiSize         = params.roiSize;
    generatePlots   = params.generatePlots;
    
    % Initiate validationData struct. 
    % We must have at least a 'report' field.
    validationData = struct('report', 'none');
    
    % Initialize ISETBIO
    s_initISET

    % Create a radiance image in ISETBIO
    scene = sceneCreate('uniform ee');    % Equal energy
    scene = sceneSet(scene,'name','Equal energy uniform field');
    scene = sceneSet(scene,'fov', fov);

    % Compute the irradiance in ISETBIO
    %
    % To make comparison to PTB work, we turn off
    % off axis correction as well as optical blurring
    % in the optics.
    oi     = oiCreate('human');
    optics = oiGet(oi,'optics');
    optics = opticsSet(optics,'off axis method','skip');
    optics = opticsSet(optics,'otf method','skip otf');
    oi     = oiSet(oi,'optics',optics);
    oi     = oiCompute(oi,scene);

    % Define a region of interest starting at the scene's center with size
    % roiSize x roiSize
    sz = sceneGet(scene,'size');
    rect = [sz(2)/2,sz(1)/2,roiSize,roiSize];
    sceneRoiLocs = ieRoi2Locs(rect);
    
    % Get wavelength and spectral radiance spd data (averaged within the scene ROI) 
    wave  = sceneGet(scene,'wave');
    radiancePhotons = sceneGet(scene,'roi mean photons', sceneRoiLocs);
    radianceEnergy  = sceneGet(scene,'roi mean energy',  sceneRoiLocs); 
    
    % Need to recenter roi because the optical image is
    % padded to deal with optical blurring at its edge.
    sz         = oiGet(oi,'size');
    rect       = [sz(2)/2,sz(1)/2,roiSize,roiSize];
    oiRoiLocs  = ieRoi2Locs(rect);

    % Get wavelength and spectral irradiance spd data (averaged within the scene ROI)
    wave             = oiGet(scene,'wave');
    irradianceEnergy = oiGet(oi, 'roi mean energy', oiRoiLocs);

    % Compute the irradiance in PTB
    %
    % Get the underlying parameters that are needed from the ISETBIO structures.
    optics = oiGet(oi,'optics');
    pupilDiameterMm  = opticsGet(optics,'pupil diameter','mm');
    focalLengthMm    = opticsGet(optics,'focal length','mm');

    % The PTB calculation is encapsulated in ptb.ConeIsomerizationsFromRadiance.
    % This routine also returns cone isomerizations, which we are not validating here.
    %
    % The macular pigment and integration time parameters affect the isomerizations,
    % but don't affect the irradiance returned by the PTB routine.
    % The integration time doesn't affect the irradiance, but we
    % need to pass it 
    macularPigmentOffset = 0;
    integrationTimeSec   = 0.05;
    [isoPerCone, ~, ptbPhotoreceptors, ptbIrradiance] = ...
        ptb.ConeIsomerizationsFromRadiance(radianceEnergy(:), wave(:),...
        pupilDiameterMm, focalLengthMm, integrationTimeSec,macularPigmentOffset);
    

    % Compare irradiances computed by ISETBIO vs. PTB
    % accounting for the magnification difference.
    % The magnification difference results from how Peter Catrysse implemented the radiance to irradiance
    % calculation in isetbio versus the simple trig formula used in PTB. Correcting for this reduces the difference
    % to about 1%.
    m = opticsGet(optics,'magnification',sceneGet(scene,'distance'));
    ptbMagCorrectIrradiance = ptbIrradiance(:)/(1+abs(m))^2;
    
    % Numerical check to decide whether we passed.
    tolerance = 0.01;
    
    ptbMagCorrectIrradiance = ptbMagCorrectIrradiance(:);
    irradianceEnergy = irradianceEnergy(:);
    difference = ptbMagCorrectIrradiance-irradianceEnergy;
    
    % Generate report
    if (max(abs(difference./irradianceEnergy)) > tolerance)
        error('Difference between PTB and isetbio irradiance exceeds tolerance');
    else
        validationData.report = sprintf('Validation PASSED. PTB and isetbio agree about irradiance to %0.0f%%',round(100*tolerance));
    end

    % Add fields to validationData if we wish to save some other
    % computations
    validationData.roiSize = roiSize;
    validationData.scene   = scene;
    validationData.oi      = oi;
     
    if (generatePlots)
        figure(500);
        subplot(1,2,1);
        plot(wave, ptbIrradiance, 'ro', wave, irradianceEnergy, 'ko');
        set(gca,'ylim',[0 1.2*max([max(ptbIrradiance(:)) max(irradianceEnergy(:))])]);
        legend('PTB','ISETBIO')
        xlabel('Wave (nm)'); ylabel('Irradiance (q/s/nm/m^2)')
        title('Without magnification correction');
    
        subplot(1,2,2);
        plot(wave,ptbMagCorrectIrradiance,'ro',wave,irradianceEnergy,'ko');
        set(gca,'ylim',[0 1.2*max([max(ptbIrradiance(:)) max(irradianceEnergy(:))])]);
        xlabel('Wave (nm)'); ylabel('Irradiance (q/s/nm/m^2)')
        legend('PTB','ISETBIO')
        title('Magnification corrected comparison');
    end
    
    
end


