function pushToGitHub(obj)

    % For this to work, we must clone a second version of ISETBIO
    % and check-out the gh-pages branch. 
    % Directory for ISETBIO - gh-pages branch 
    ISETBIO_gh_pages_CloneDir = '/Users/Shared/Matlab/Toolboxes/ISETBIO_GhPages/isetbio';
    
    % Directory where all validation HTML docs will be moved to
    validationDocsDir  = sprintf('%s/validationdocs', ISETBIO_gh_pages_CloneDir);
    
    % URL where validation docs will live
    validationDocsURL = 'http://isetbio.github.io/isetbio/validationdocs';
    
    % Local dir where the ISTEBIO wiki is cloned to. This is where we store the ValidationResults.md file
    % with contains a the catalog of the validation runs and pointers to
    % the html files containing the code and results
    % wikiCloneDir = '/Users/Shared/GitWebSites/ISETBIO/ISETBIO_ValidationDocs.wiki';
    wikiCloneDir = '/Users/Shared/Matlab/Toolboxes/ISETBIO_Wiki/isetbio.wiki';
    
    % Name of the markup file containing the catalog of validation runs and
    % pointers to the corresponding html files.
    validationResultsCatalogFile = 'ValidationResults.md';
    
    % URL on remote where the validationResultsCatalogFile lives
    % validationResultsCatalogFileURL = 'https://github.com/npcottaris/ISETBIO_ValidationDocs/wiki/ValidationResults';
    validationResultsCatalogFileURL = 'https://github.com/isetbio/isetbio/wiki/ValidationResults';
    
    % First do a git pull (so we can push later with no conflicts)
    cd(validationDocsDir);
    system('git pull');
    
    cd(wikiCloneDir);
    system('git pull');
    
    % Now we can modify things
    % Remove previous validationResultsCatalogFile
    system(['rm -rf ' fullfile(wikiCloneDir, validationResultsCatalogFile)]);
    
    % Open new validationResultsCatalogFile
    validationResultsCatalogFID = fopen(fullfile(wikiCloneDir, validationResultsCatalogFile),'w');
    fprintf(validationResultsCatalogFID,'***\n_This file is autogenerated by the pushToGit.m ISETBIO script. Do not edit manually, as all changes will be overwritten during the next validation run._\n***');
    
    
    % Determine name of validation root directory from the location of this script 
    validationRootDirectory = obj.validationRootDirectory;

    sectionNames = keys(obj.sectionData);
    for sectionIndex = 1:numel(sectionNames)
        
        % write sectionName
        sectionName = sectionNames{sectionIndex};
        fprintf(validationResultsCatalogFID,'\n####  %s \n', sectionName);
        
        % Write section info text
        functionNames = obj.sectionData(sectionName);
        if (isempty(functionNames))
            fprintf(validationResultsCatalogFID,'_This section contains no scripts with successful validation outcomes._ \n');
            continue;
        end
        
        [validationScriptDirectory, ~, ~] = fileparts(which(sprintf('%s.m', char(functionNames{1}))));
        cd(validationScriptDirectory);
        fprintf(validationResultsCatalogFID,'_%s_ \n', sprintf('%s', fileread('info.txt')));
        
        for functionIndex = 1:numel(functionNames)
            validationScriptName = sprintf('%s', char(functionNames{functionIndex}));
            [validationScriptDirectory, ~, ~] = fileparts(which(validationScriptName));
            seps = strfind(validationScriptDirectory, '/');
            validationScriptSubDir = validationScriptDirectory(seps(end)+1:end);
            
            % make subdir in local validationDocsDir 
            sectionWebDir = fullfile(validationDocsDir , validationScriptSubDir,'');
            if (~exist(sectionWebDir,'dir'))
                mkdir(sectionWebDir);
            end
        
            % cd to validationRootDirectory/sectionSubDir
            cd(sprintf('%s', validationScriptDirectory));
        
            % synthesize the source HTML directory name
            sourceHTMLdir = sprintf('%s_HTML', validationScriptName);
        
            % synthesize the target HTML directory name
            targetHTMLdir = fullfile(validationDocsDir , validationScriptSubDir, sourceHTMLdir, '');
        
            % remove any existing target HTML directory
            system(sprintf('rm -rf %s', targetHTMLdir));
        
            if (exist(sourceHTMLdir, 'dir') == 0)
                fullPathSourceHTMLdir = sprintf('%s/validationScripts/%s/%s', validationRootDirectory, validationScriptSubDir,sourceHTMLdir);
                fprintf(2,'\n>>>> Directory %s not found.\n>>>> Rerun validateAll(), or make sure there is no typo.\n', fullPathSourceHTMLdir);
                return;
            end
        
            % mv source to target directory
            system(sprintf('mv %s %s',  sourceHTMLdir, targetHTMLdir));
        
            % get summary text from validation script.
            summaryText = getSummaryText(validationScriptName);
        
             % Add entry to validationResultsCatalogFile
            fprintf(validationResultsCatalogFID, '* [ %s ]( %s/%s/%s/%s.html) - %s \n',  validationScriptName, validationDocsURL, validationScriptSubDir, sourceHTMLdir, validationScriptName, summaryText);  
        
        end
       
        fprintf('\n');
    end % sectionIndex
    
    
    % Now add some summary about the state of all the probes
    fprintf(validationResultsCatalogFID,'\n***\n#  Validation run summary \n');
    fprintf(validationResultsCatalogFID,'Performed by **%s** from **%s** on **%s**\n', obj.systemData.userName, obj.systemData.computerAddress, obj.systemData.datePerformed);
    
    for probeIndex = 1:numel(obj.validationSummary)
        fprintf(validationResultsCatalogFID, '* %s', char(obj.validationSummary{probeIndex}));
    end
     
    % Close the validationResultsCatalogFile
    fclose(validationResultsCatalogFID);
        
   
        % Now push stuff to git
    % ----------------- IMPORTANT NOTE REGARDING PUSHING TO GIT  FROM MATLAB -----------------
    % Note: to make push work from withing MATLAB, I had to change the
    % libcurl library found in /Applications/MATLAB_R2014a.app/bin/maci64
    % This is because MATLAB's libcurl does not have support for https
    % as evidenced by system('curl -V') which gives:
    % curl 7.30.0 (x86_64-apple-darwin13.0) libcurl/7.21.6
    % Protocols: dict file ftp gopher http imap pop3 smtp telnet tftp 
    % Features: IPv6 Largefile 
    %
    % In contrast curl -V in a terminal window gives:
    % curl 7.30.0 (x86_64-apple-darwin13.0) libcurl/7.30.0 SecureTransport zlib/1.2.5
    % Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtsp smtp smtps telnet tftp 
    % Features: AsynchDNS GSS-Negotiate IPv6 Largefile NTLM NTLM_WB SSL libz 
    %
    % To fix this, open a terminal and go to the following directory:
    %   cd /Applications/MATLAB_R2014a.app/bin/maci64
    %   ls -al libcur*
    % This gives me:
    %   libcurl.4.dylib
    %   libcurl.dylib -> libcurl.4.dylib
    % Remove the pointer to the existing library:
    %   rm libcurl.dylib
    % Also backup the existing library in case something goes wrong.
    %   mv libcurl.4.dylib existing_libcurl.4.dylib
    % Then make soft links to the system's libcurl as follows:
    %   ln -s /usr/lib/libcurl.4.dylib libcurl.4.dylib
    %   ln -s /usr/lib/libcurl.4.dylib libcurl.dylib
    % After this, system('curl -V') shows support for https and 
    % system('git push') works fine (at least on Mavericks 10.9.4).
    % ----------------- IMPORTANT NOTE REGARDING PUSHING TO GIT  FROM MATLAB -----------------
    
    % First push the HTML validation datafiles
    fprintf('\n\n1. Pushing validation reports (HTML) to github ...\n');
    cd(validationDocsDir);
    
    system('git config --global push.default matching');
    %system('git config --global push.default simple');
    
    % Stage everything
    system('git add -A');
    
    % Commit everything
    system('git commit -a -m "Validation results docs update";');
    
    % Push to remote
    system('git push origin gh-pages');
    
    
    
    % Next update the wiki catalog of validation runs
    fprintf('\n\n2. Pushing catalog of validation reports to github ...\n');
    cd(wikiCloneDir);
    
    system('git config --global push.default matching');
    %system('git config --global push.default simple');
    
    % Pull first in case there are changes
    system('git pull');
    
    % Stage everything
    system('git add -A');
    
    % Commit everything
    system('git commit -a -m "Validation results catalog update";');
    
    % Push to remote
    system('git push');
    
    % Open git web page with validation results for visualization. 
    % This may take a while to update.
    fprintf('\n\nValidation results pushed to: %s\n\n', validationResultsCatalogFileURL);
    
    % All done. Return to root directory
    cd(validationRootDirectory);
end


function summaryText = getSummaryText(validationScriptName)

    % Open file
    fid = fopen(which(sprintf('%s.m',validationScriptName)),'r');

    % Throw away first two lines
    lineString = fgetl(fid);
    lineString = fgetl(fid);

    % Get line with function description (3rd lone)
    lineString = fgetl(fid);
    % Remove any comment characters (%)
    summaryText  = regexprep(lineString ,'[%]','');
    
end
