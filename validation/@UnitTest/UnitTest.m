classdef UnitTest < handle
    % Class to handle ISETBIO unit tests
    
    % Public properties
    properties
        
    end
    
    properties (SetAccess = private) 
        % a collection of various system information
        systemData = struct();

        % validation root directory: same as dir of the executive script
        validationRootDirectory;
        
        % cell array with data for all examined probes
        allProbeData;
    end
    
    properties (Access = private)  
         % validation results for current probe
        validationFailedFlag = true;
        validationData       = struct();
        validationReport     = 'None';
        
        % map describing section organization
        sectionData;
    end
    
    % Public methods
    methods
        % Constructor
        function obj = UnitTest(validationScriptFileName)
            [obj.validationRootDirectory, ~, ~] = fileparts(which(validationScriptFileName));
            obj.systemData.vScriptFileName      = sprintf('%s',validationScriptFileName);
            obj.systemData.vScriptListing       = fileread([validationScriptFileName '.m']);
            obj.systemData.datePerformed        = datestr(now);
            obj.systemData.matlabVersion        = version;
            obj.systemData.computer             = computer;
            obj.systemData.gitRepoBranch        = obj.retrieveGitBranch();
            obj.sectionData                     = containers.Map();
            obj.allProbeData                    = {};
        end
        
        % Method to add and execute a new probe
        addProbe(obj, varargin);
         
        % Method to print the validation report
        printReport(obj);
    
        % Method to store the validatation results
        %storeValidationResults(obj, varargin); ...
   
        % Method that pushes results to github
        pushToGitHub(obj);
    end
    
    methods (Access = private)    
        % Method to retrieve the git branch string
        gitBranchString = retrieveGitBranch(obj);
    end
    
    methods (Static)
        validationResults = updateParentUnitTestObject(validationReport, validationFailedFlag, validationDataToSave, runParams);
    end
    
end
