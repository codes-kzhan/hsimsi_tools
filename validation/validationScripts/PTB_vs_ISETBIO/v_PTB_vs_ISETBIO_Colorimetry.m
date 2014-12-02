function varargout = v_PTB_vs_ISETBIO_Colorimetry(varargin)
%
%  Validate ISETBIO-based colorimetric computations by comparing to PTB-based colorimetric computations.
%

    %% Initialization
    % Initialize validation run
    runTimeParams = UnitTest.initializeValidationRun(varargin{:});
    % Initialize return params
    if (nargout > 0) varargout = {'', false, []}; end
    
    %% Validation - Call validation script
    ValidationScript(runTimeParams);
    
    %% Reporting and return params
    if (nargout > 0)
        [validationReport, validationFailedFlag] = UnitTest.validationRecord('command', 'return');
        validationData = UnitTest.validationData('command', 'return');
        varargout = {validationReport, validationFailedFlag, validationData};
    else
        if (runTimeParams.printValidationReport)
            [validationReport, ~] = UnitTest.validationRecord('command', 'return');
            UnitTest.printValidationReport(validationReport);
        end 
    end
end


function ValidationScript(runTimeParams)
    
    %% Path stuff
    % Use ISETBIO's version of lab2xyz, otherwise the new
    % Matlab function of the same name clobbers this and we
    % get screwy answers.
    %
    % Probably in the longer run should just use Matlab's version if it gives
    % the same answers.
    lab2xyz = overrideBuiltInFunction('lab2xyz', 'isetbio');
    
    %% SETUP
    isetbioPath = fileparts(which('colorTransformMatrix'));
    curDir = pwd; 
    tolerance = 1e-12;
    
    %% XYZ-related colorimetry
    UnitTest.validationRecord('message', '***** Basic XYZ *****');
    
    testXYZs = [[1 2 1]' [2 1 0.5]' [1 1 1]' [0.6 2.3 4]'];
    ptbxyYs = XYZToxyY(testXYZs);
    ptbxys  = ptbxyYs(1:2,:);
    isetxys = chromaticity(testXYZs')';
    
    if (any(abs(ptbxys-isetxys) > tolerance))
        message = sprintf('PTB-ISET DIFFERENCE for XYZ to xy (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for XYZ to xy (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    
    % append to validationData 
    UnitTest.validationData('testXYZs', testXYZs);
    UnitTest.validationData('ptbxys', ptbxys);
    UnitTest.validationData('isetxys',isetxys);
    
    %% xyY
    ptbXYZs = xyYToXYZ(ptbxyYs);
    if (any(abs(testXYZs-ptbXYZs) > tolerance))
        message = sprintf('PTB FAILS XYZ to xyY to XYZ (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB PASSES XYZ to xyY to XYZ (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData 
    UnitTest.validationData('ptbXYZs', ptbXYZs);
    
    
    isetXYZs = xyy2xyz(ptbxyYs')';
    if (any(abs(testXYZs-isetXYZs) > tolerance))
        message = sprintf('PTB-ISET DIFFERENCE for xyY to XYZ (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for xyY to XYZ (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end 
    % append to validationData 
    UnitTest.validationData('isetXYZs', isetXYZs);

    
    %% CIE uv chromaticity
    ptbuvYs = XYZTouvY(testXYZs);
    ptbuvs = ptbuvYs(1:2,:);
    [isetus,isetvs] = xyz2uv(testXYZs');
    isetuvs = [isetus' ; isetvs'];
    if (any(abs(ptbuvs-isetuvs) > tolerance))
        message = sprintf('PTB-ISET DIFFERENCE for XYZ to uv (tolerance: %g)', tolerance);
        message = sprintf('%s\n\tI think this is because ISET implements an obsolete version of the standard', message);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for XYZ to uv (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
     % append to validationData 
    UnitTest.validationData('ptbuvs', ptbuvs);
    UnitTest.validationData('isetuvs', isetuvs);
    
    %% CIELUV
    whiteXYZ = [3,4,3]';
    ptbLuvs = XYZToLuv(testXYZs,whiteXYZ);
    isetLuvs = xyz2luv(testXYZs',whiteXYZ')';
    if (any(abs(ptbLuvs-isetLuvs) > tolerance))
        message = sprintf('PTB-ISET DIFFERENCE for XYZ to Luv (tolerance: %g)', tolerance);
        message = sprintf('%s\n\tPresumably because the uv transformation differs.', message);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for XYZ to Luv (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    
    % update tovalidationData
    UnitTest.validationData('whiteXYZ', whiteXYZ);
    UnitTest.validationData('ptbLuvs',  ptbLuvs);
    UnitTest.validationData('isetLuvs', isetLuvs);
    
    %% CIELAB
    whiteXYZ = [3,4,3]';
    ptbLabs = XYZToLab(testXYZs,whiteXYZ);
    cd(isetbioPath);
    isetLabs = xyz2lab(testXYZs',whiteXYZ')';
    cd(curDir);
    if (any(abs(ptbLabs-isetLabs) > tolerance))
        message = sprintf('PTB-ISET DIFFERENCE for XYZ to Lab (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('ptbLabs',  ptbLabs);
    UnitTest.validationData('isetLabs', isetLabs);
    
    ptbXYZCheck = LabToXYZ(ptbLabs,whiteXYZ);
    isetXYZCheck = lab2xyz(isetLabs',whiteXYZ')';
    if (any(abs(testXYZs-ptbXYZCheck) > tolerance ))
        message = sprintf('PTB FAILS XYZ to Lab to XYZ (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB PASSES XYZ to Lab to XYZ (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % update to validationData
    UnitTest.validationData('ptbXYZCheck', ptbXYZCheck);
    
    if (any(abs(testXYZs-isetXYZCheck) > tolerance))
        message = sprintf('ISET FAILS XYZ to Lab to XYZ (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('ISET PASSES XYZ to Lab to XYZ (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('isetXYZCheck', isetXYZCheck);

    
    %% sRGB
    %
    % The iset routines seem to use a matrix that is 1/100 of the standard
    % definition.  Or, at least, 1/100 of what the PTB routines use.  To
    % account for this, I multiply XYZ values by 100 before passing them
    % to the iset routines.
    %
    % The iset routines take an exponent argument for the sRGB gamma transform.
    % At http://www.w3.org/Graphics/Color/sRGB this is specified as 2.4.  The
    % iset routine xyz2srgb uses 2.2, with a comment that an update at
    % www.srgb.com changed this from 2.4 to 2.2.  I think this is wrong,
    % though.  The text I can find on the web says that the 2.4 exponent, plus
    % the linear initial region, is designed to approximate a gamma of 2.2.
    % That is, you want 2.4 in the formulae to approximate the 2.2 industry
    % standard gamma.  Site www.srgb.com now appears gone, by the way, but all
    % the other sites I find seem to be the same in this regard.
    % 
    % Also note that if you change the exponent in the iset sRGB formulae, you
    % also should probably change the cutoff used at the low-end, where the
    % sRGB standard special cases the functional form of the gamma curve.  Here
    % the test is set for 2.4.
    %
    % Finally,the default gamma used by iset lrgb2srgb and by xzy2srgb
    % currently differ, so you really want to be careful using these.  The
    % inverse routine srgb2lrgb doesn't allow passing of the exponent, and it
    % is hard coded as 2.4.  This causes a failure of the iset sRGB gamma
    % routines to self-invert for gamma other than 2.4, and with their
    % defaults.
    %
    % One other convention difference is that the PTB routine rounds to
    % integers for the settings, while the iset routine leaves the rounding up
    % to the caller.
    UnitTest.validationRecord('message', '***** sRGB *****');

    % Create some test sRGB values and convert them in the PTB framework
    ptbSRGBs = [[188 188 188]' [124 218 89]' [255 149 203]' [255 3 203]'];
    ptbSRGBPrimary = SRGBGammaUncorrect(ptbSRGBs);
    ptbXYZs = SRGBPrimaryToXYZ(ptbSRGBPrimary);

    % The ISET form takes the frame buffer values in the [0,1] regime
    isetSRGBs = ptbSRGBs/255;
    isetSRGBs = XW2RGBFormat(isetSRGBs',4,1);
    isetXYZ   = srgb2xyz(isetSRGBs);
    isetXYZs  = RGB2XWFormat(isetXYZ)';

    if (any(abs(isetXYZs-ptbXYZs) > tolerance))
        d = isetXYZs - ptbXYZs;
        message = sprintf('PTB-ISET DIFFERENCE for XYZ to sRGB: %f (tolerance: %g)',max(abs(d(:))), tolerance);
        d = d ./ptbXYZs;
        message = sprintf('%s\nPTB-ISET Percent XYZ DIFFERENCE: %f\n', message, max(abs(d(:))));
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for XYZ to sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('isetXYZs_2', isetXYZs);
    UnitTest.validationData('ptbXYZs_2', ptbXYZs);
    
    % PTB testing of inversion
    if (any(abs(XYZToSRGBPrimary(ptbXYZs)-ptbSRGBPrimary) > tolerance))
        message = sprintf('PTB FAILS linear sRGB to XYZ to linear sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB PASSES linear sRGB to XYZ to linear sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('ptbSRGBPrimary', ptbSRGBPrimary);
    
    
    if (any(abs(SRGBGammaCorrect(ptbSRGBPrimary)-ptbSRGBs) > tolerance))
        message = sprintf('PTB FAILS sRGB to linear sRGB to sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB PASSES sRGB to linear sRGB to sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('ptbSRGBs', ptbSRGBs);
    
    
    % Compare sRGB matrices
    [nil,ptbSRGBMatrix] = XYZToSRGBPrimary([]);
    isetSRGBMatrix = colorTransformMatrix('xyz2srgb')';

    if (any(abs(ptbSRGBMatrix-isetSRGBMatrix) > tolerance))
        message = sprintf('PTB-ISET DIFFERENCE for sRGB transform matrix (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for sRGB transform matrix (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('ptbSRGBMatrix', ptbSRGBMatrix);
    UnitTest.validationData('isetSRGBMatrix', isetSRGBMatrix);
    
    % XYZ -> lRGB 
    % Reformat shape
    ptbXYZsImage = CalFormatToImage(ptbXYZs,1,size(ptbXYZs,2));

    % ISET convert 
    [isetSRGBImage,isetSRGBPrimaryImage] = xyz2srgb(ptbXYZsImage);

    % Reformat shape
    isetSRGBs = ImageToCalFormat(isetSRGBImage); 
    isetSRGBPrimary = ImageToCalFormat(isetSRGBPrimaryImage);

    if (any(abs(ptbSRGBPrimary-isetSRGBPrimary) > tolerance))
        d = ptbSRGBPrimary - isetSRGBPrimary;
        message = sprintf('PTB-ISET DIFFERENCE for XYZ to sRGB: %f (tolerance: %g)',max(abs(d(:))), tolerance);
        d = d ./isetSRGBPrimary;
        message = sprintf('%s\n\t\tPTB-ISET Percent RGB DIFFERENCE: %f', message, max(abs(d(:))));
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for XYZ to linear sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('ptbSRGBPrimary_2', ptbSRGBPrimary);
    UnitTest.validationData('isetSRGBPrimary_2', isetSRGBPrimary);
    
    
    % ISET/PTB sRGB comparison in integer gamma corrected space
    if (any(abs(round(isetSRGBs*255)-ptbSRGBs) > tolerance))
        message = sprintf('PTB-ISET DIFFERENCE for XYZ to sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for XYZ to sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('isetSRGBs', isetSRGBs*255);
    UnitTest.validationData('ptbSRGBs_2', ptbSRGBs);
    
    
    % lrgb -> srgb -> lrgb in ISET
    isetSRGBPrimaryCheckImage = srgb2lrgb(isetSRGBImage);
    isetSRGBPrimaryCheck = ImageToCalFormat(isetSRGBPrimaryCheckImage);
    if (any(abs(isetSRGBPrimaryCheck-isetSRGBPrimary) >  tolerance))
        message = sprintf('ISET FAILS linear sRGB to sRGB to linear sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('ISET PASSES linear sRGB to sRGB to linear sRGB (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('isetSRGBPrimaryCheck', isetSRGBPrimaryCheck);
    UnitTest.validationData('isetSRGBPrimary', isetSRGBPrimary);
    

    %% Quanta/Energy
    %
    % The ISET routines define c and h to more places than the PTB, so the
    % agreement is only good to about 5 significant places.  Seems OK to me.
    UnitTest.validationRecord('message', '***** Energy/Quanta *****');
    
    load spd_D65
    spdEnergyTest = spd_D65;
    wlsTest = SToWls(S_D65);
    testPlaces = 5;
    ptbQuanta = EnergyToQuanta(wlsTest,spdEnergyTest);
    isetQuanta = Energy2Quanta(wlsTest,spdEnergyTest);
    toleranceQuanta = (10^-testPlaces)*min(ptbQuanta);
    if (any(abs(ptbQuanta-isetQuanta) > toleranceQuanta))
        message = sprintf('PTB-ISET DO NOT AGREE for energy to quanta conversion at %d significant places (tolerance: %0.1g quanta)',testPlaces, toleranceQuanta);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for energy to quanta conversion to %d significant places (tolerance: %0.1g quanta)',testPlaces,  toleranceQuanta);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('ptbQuanta', ptbQuanta);
    UnitTest.validationData('isetQuanta', isetQuanta);
    
    if (any(abs(QuantaToEnergy(wlsTest,ptbQuanta)-spdEnergyTest) > tolerance))
        message = sprintf('PTB FAILS energy to quanta to energy (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB PASSES energy to quanta to energy (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('ptbEnergyFromQuanta', QuantaToEnergy(wlsTest,ptbQuanta));
    UnitTest.validationData('spdEnergyTest', spdEnergyTest);
    
    if (any(abs(Quanta2Energy(wlsTest,isetQuanta')'- spdEnergyTest) > tolerance))
        message = sprintf('ISET FAILS energy to quanta to energy (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('ISET PASSES energy to quanta to energy (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('isetEnergyFromQuanta', Quanta2Energy(wlsTest,isetQuanta')');
    
    %% CIE daylights
    % 
    % These routines are now running in ISET and everything agrees.
    UnitTest.validationRecord('message', '***** CIE Daylights *****');
    
    load B_cieday
    testWls = SToWls(S_cieday);
    testTemp = 4987;
    ptbDaySpd = GenerateCIEDay(testTemp,B_cieday);
    ptbDaySpd = ptbDaySpd/max(ptbDaySpd(:));

    % Iset version of normalized daylight
    isetDaySpd = daylight(testWls,testTemp);
    isetDaySpd = isetDaySpd/max(isetDaySpd(:));
    if (any(abs(isetDaySpd-ptbDaySpd) > tolerance))
        message = sprintf('PTB-ISET DIFFERENCE for daylight (tolerance: %g)', tolerance);
        UnitTest.validationRecord('FAILED', message);
    else
        message = sprintf('PTB-ISET AGREE for for daylight (tolerance: %g)', tolerance);
        UnitTest.validationRecord('PASSED', message);
    end
    % append to validationData
    UnitTest.validationData('isetDaySpd', isetDaySpd);
    UnitTest.validationData('ptbDaySpd',  ptbDaySpd);
    
    %% Plotting
    if (runTimeParams.generatePlots)

    end
end



