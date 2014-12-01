% Method to remove the root validationData directory
function removeValidationDataDir(obj)

    if (exist(obj.validationDataDir, 'dir'))
        fprintf('\nRemoving validation data directory ''%s''.\n', obj.validationDataDir); 
        rmpath(obj.validationDataDir);
        system(sprintf('rm -r -f %s', obj.validationDataDir));
    end
end
        