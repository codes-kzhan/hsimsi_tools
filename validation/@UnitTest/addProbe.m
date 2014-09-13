function addProbe(obj, varargin)
    % validate input params
    p = inputParser;
    p.addParamValue('name', @ischar);
    p.addParamValue('functionHandle', []);
    p.addParamValue('functionParams', @isstruct);
    p.addParamValue('generatePlots',  @islogical);
    p.parse(varargin{:});
    
    % get input params
    newProbe.name = p.Results.name;
    newProbe.functionHandle = p.Results.functionHandle;
    newProbe.functionParams = p.Results.functionParams;
    
    if (isa(newProbe.functionHandle, 'function_handle') == false)
       error('The value of key:''functionHandle'' is not a valid function handle');
    end
    
    % attempt to run the probe
    probeCommandString = sprintf('validationData = newProbe.functionHandle(newProbe.functionParams);');
    command = sprintf('try \n\t%s \n\t newProbe.result.validationData = validationData; newProbe.result.status = ''OK''; \ncatch err \n\t newProbe.result.status = ''failed''; newProbe.result.message = err.message; \nend', probeCommandString);
    eval(command);
    
    % add the probe result
    pIndex = numel(obj.probesPerformed) + 1;
    obj.probesPerformed{pIndex} = newProbe;
    
    if strcmp(obj.probesPerformed{pIndex}.result.status, 'failed')
        fprintf(2,'\n%2d. \t Name\t\t\t: ''%s'' \n', pIndex, obj.probesPerformed{pIndex}.name);
        fprintf(2,'\t ValidationScript\t:  %s.m\n', func2str(newProbe.functionHandle));
        fprintf(2,'\t Status\t\t\t:  Error. Code raised an excemption which we caught. \n');
        fprintf(2,'\t Excemption message\t:  %s\n', obj.probesPerformed{pIndex}.result.message);
    else
        fprintf('\n%2d. \t Name\t\t\t: ''%s'' \n', pIndex, obj.probesPerformed{pIndex}.name);
        fprintf('\t ValidationScript\t:  %s.m\n', func2str(newProbe.functionHandle));
        fprintf('\t Status\t\t\t:  Success. No excemption was raised during execution.\n');
    end
    
end

