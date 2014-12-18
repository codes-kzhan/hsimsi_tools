function varargout = v_stockman2xyz(varargin)
%
% Test that colorTransformMatrix does the right thing for
% Stockman-Sharpe to XYZ and back.
%

    %% Initialization
    % Initialize validation run
    runTimeParams = UnitTest.initializeValidationRun(varargin{:});
    % Initialize return params
    if (nargout > 0) varargout = {'', false, []}; end
    
    %% Call the validation function
    ValidationFunction(runTimeParams);
    
    %% Reporting and return params
    if (nargout > 0)
        [validationReport, validationFailedFlag, validationFundametalFailureFlag] = ...
                          UnitTest.validationRecord('command', 'return');
        validationData  = UnitTest.validationData('command', 'return');
        extraData       = UnitTest.extraData('command', 'return');
        varargout       = {validationReport, validationFailedFlag, validationFundametalFailureFlag, validationData, extraData};
    else
        if (runTimeParams.printValidationReport)
            [validationReport, ~] = UnitTest.validationRecord('command', 'return');
            UnitTest.printValidationReport(validationReport);
        end 
    end
end

%% Actual validation code
function ValidationFunction(runTimeParams)

%% Ihitialize
s_initISET;

%% Get Stockman-Sharpe and XYZ functions
wave = (400:5:700)';
xyz = ieReadSpectra('XYZ',wave);
stock = ieReadSpectra('stockman',wave);
if (runTimeParams.generatePlots)
    vcNewGraphWin
    plot(wave, stock)
    plot(wave,xyz)
end
UnitTest.validationData('wave', wave);
UnitTest.validationData('xyz', xyz);
UnitTest.validationData('stockman', stock);

%% Make matrix that transforms XYZ to Stockman-Sharpe
% Isetbio keeps sensitivities in columns and matrices
% are applied to the right to transform.
%
% Note (sigh) that PTB keeps sensitivities in rows and
% that matrices are appplied from the left, so if you
% are going to use PTB routines you need to think about
% this.
T_xyz2ss = xyz \ stock;
pred = xyz*T_xyz2ss;
if (runTimeParams.generatePlots)
    plot(pred(:),stock(:), '.'); grid on; axis equal
    xlim([-1 2]); ylim([-1 2]);
    xlabel('Predicted Stockman-Sharpe Sensitivities');
    ylabel('Actual Stockman-Sharpe Sensitivities');
end

%% Make the one that goes the other way.
T_ss2xyz = stock \ xyz;
pred = stock*T_ss2xyz;
if (runTimeParams.generatePlots)
    plot(pred(:),xyz(:),'.'); grid on; axis equal
    xlim([-1 2]); ylim([-1 2]);
    xlabel('Predicted XYZ Sensitivities');
    ylabel('Actual XYZ Sensitivities');
end

%% Get the same things out of colorTransformMatrix
T1 = colorTransformMatrix('stockman 2 xyz');
T2 = colorTransformMatrix('xyz 2 stockman');
tolerance = 1e-3;
if (max(abs(T1-T_ss2xyz) > tolerance))
    message = sprintf('Matrix T_ss2xyz returned by colorTransformMatrix does not agree with first principles calculation (%0.1g). !!!', tolerance);
    UnitTest.validationRecord('FAILED', message);
else
    message = sprintf('Matrix T_ss2xyz returned by colorTransformMatrix agrees with first principles calculation (%0.1g). !!!', tolerance);
    UnitTest.validationRecord('PASSED', message);
end
if (max(abs(T2-T_xyz2ss) > tolerance))
    message = sprintf('Matrix T_xyz2ss returned by colorTransformMatrix does not agree with first principles calculation (%0.1g). !!!', tolerance);
    UnitTest.validationRecord('FAILED', message);
else
    message = sprintf('Matrix T_xyz2ss returned by colorTransformMatrix agrees with first principles calculation (%0.1g). !!!', tolerance);
    UnitTest.validationRecord('PASSED', message);
end
UnitTest.validationData('T1', T1);
UnitTest.validationData('T2', T2);

%% Check for self inversion
% This matrix should be close to but not exactly the identity matrix.  The
% differnce comes in because Stockman-Sharpe and XYZ are not exact linear
% transformatinos of each other.
tolerance = 0.02;
identityCheck = T1*T2;
if (max(abs(identityCheck-eye(3))) > tolerance)
    message = sprintf('Conversions do not self invert to (%0.1g). !!!', tolerance);
    UnitTest.validationRecord('FAILED', message);
else
    message = sprintf('Conversions self invert to (%0.1g). !!!', tolerance);
    UnitTest.validationRecord('PASSED', message);
end


%% End
end
