function vScriptsList = validateListAllValidationDirs
%
% This encapsulates a vull list of our validation directories, so we only
% need to update it in one place.\
% 
% Doesn't list the example scripts, and doesn't override any default prefs.
%
% ISETBIO Team (c) 2014

vScriptsList = {...
            {'validationScripts/color' } ...
            {'validationScripts/cones'} ...
            {'validationScripts/human'} ...
            {'validationScripts/optics'} ...
            {'validationScripts/radiometry', } ...    
            {'validationScripts/scene' } ...    
        };
    
end