function bsc_amalgamatgeROISacrossSubject_single(amalgumDir,subjectDirs,subselect,instruction,thresh)

%path to mni t1
%mniT1=niftiRead('/N/dc2/projects/lifebid/HCP/Dan/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c.nii');

mkdir(fullfile(amalgumDir,'rois'));

for isubjects =1:length(subjectDirs)
    isubjects
    %silly, but necessary for brainlife
    firstDirContents=dir(subjectDirs{isubjects});
    dirInd=find(and(contains({firstDirContents.name},'rois'),[firstDirContents.isdir]));

    
    %parse roiDirectory
    roiDirContents=dir(fullfile(subjectDirs{isubjects},firstDirContents(dirInd).name,'rois'));
    roiDirNames={roiDirContents(:).name};
    roiBool=contains(roiDirNames,'.nii.gz');
    roiInd=find(roiBool);
    
    %creates list of roi names
    preRoiNames={roiDirNames{roiInd}};
    roiNames=[];
    
    for isubSelect=1:length(subselect)
    roiIndexes=find(contains(preRoiNames,subselect{isubSelect}));
    roiNames=horzcat(roiNames,preRoiNames(roiIndexes));
    end
    
    %determines which rois have been labeled as either LPI or RAS,
    %necessary to do check for consistency
    RASorLPIbool=or(contains(roiNames,'RAS'),contains(roiNames,'LPI'));
    
   for iROIs=1:length(roiNames)
        iROIs
        currRoiFilePath=fullfile(subjectDirs{isubjects},firstDirContents(dirInd).name,'rois',roiNames{iROIs});
        amalgumRoiFilePath=fullfile(amalgumDir,'rois',roiNames{iROIs});
        amalgumRoiFilePath;
        %if the file doesn't exist (as would be the case for the first one)
        %go ahead and create the first amalgum roi
        if ~exist(amalgumRoiFilePath,'file')
            fprintf('\n copying first  nifti')
            %depending on instruction case, different things need to be
            %done
            switch instruction
                case 'sum'
                    copyfile(currRoiFilePath,amalgumRoiFilePath)
                case 'binarized'
                    currROInifti=niftiRead(currRoiFilePath);
                    if ~notDefined('thresh')
                        currROInifti.data(currROInifti.data<thresh)=0;
                    end
                    currROInifti.data=int32(~currROInifti.data==0);
                    amalgumRoiFilePath;
                    currROInifti.fname=amalgumRoiFilePath;
                    writeFileNifti(currROInifti)
                    %bsc_saveNifti(currROInifti,amalgumRoiFilePath)
            end
            
            if ~isubjects==1
                warning('\n mismatch between initial amalgum rois and current subjects rois, \n creating new roi for %s', roiNames{iROIs})
            end
        else
            %in the event that the file DOES exist, we load and do our
            %check
            fprintf('\n loading nifti')
            currROInifti=niftiRead(currRoiFilePath);
            if RASorLPIbool(iROIs)
                %first find the appropriate partner name
                pairIND=horzcat(strfind(currRoiFilePath,'RAS'),strfind(currRoiFilePath,'LPI')):horzcat(strfind(currRoiFilePath,'RAS'),strfind(currRoiFilePath,'LPI'))+2;
                curPairLabel=currRoiFilePath(pairIND);
                switch curPairLabel
                    case 'LPI'
                        roiPairPath=strrep(currRoiFilePath,curPairLabel,'RAS');
                    case 'RAS'
                        roiPairPath=strrep(currRoiFilePath,curPairLabel,'LPI');
                end
                %find ind for amalgum mask
                currAmalgumTargetNifti=niftiRead(amalgumRoiFilePath);
                almagumNiftiInd=find(currAmalgumTargetNifti.data);
                %find ind for curr roi mask
                currROInifti=niftiRead(currRoiFilePath);
                %if thresh exists, apply
                
                currROINiftiInd=find(currROInifti.data);
                %find ind for curr roi mask partner
                currROIPartnerNifti=niftiRead(roiPairPath);
                %if thresh exists, apply
                
                currROIPartnerNiftiInd=find(currROIPartnerNifti.data);
                %now find which roi overlaps more with the target
                totalCurOverlap=length(intersect(currROINiftiInd,almagumNiftiInd));
                totalParterner=length(intersect(currROIPartnerNiftiInd,almagumNiftiInd));
                %if 1, then current ROI is correct, if 2 then partner
                mostSimilarIndex=find([totalCurOverlap totalParterner]==max([totalCurOverlap totalParterner]));
                
                %do the threshold here
                if ~notDefined('thresh')
                    currROIPartnerNifti.data(currROIPartnerNifti.data<thresh)=0;
                end
                if ~notDefined('thresh')
                    currROInifti.data(currROInifti.data<thresh)=0;
                end
                
                %HUGE ASSUMPTION HERE, if both are the same, namely zero,
                %just go with the first guess
                if and(length(mostSimilarIndex)==2,[totalCurOverlap + totalParterner]==0)
                    mostSimilarIndex=1;
                elseif length(mostSimilarIndex)==1
                    %that's just fine
                elseif and(length(mostSimilarIndex)==2,~[totalCurOverlap + totalParterner]==0)
                    error('\n ambiguity as to which endpoint cloud is correct')
                end
                
                % now actually merge the appropriate two data structures
                switch mostSimilarIndex
                    case 1
                        switch instruction
                            case 'sum'
                                currAmalgumTargetNifti.data=currAmalgumTargetNifti.data+currROInifti.data;
                            case 'binarized'
                                %is this even doing anything?  Yes, it is
                                %masking.
                                currROInifti.data=int32(~currROInifti.data==0);
                                currAmalgumTargetNifti.data=currAmalgumTargetNifti.data+currROInifti.data;
                        end
                    case 2
                        switch instruction
                            case 'sum'
                                currAmalgumTargetNifti.data=currAmalgumTargetNifti.data+currROIPartnerNifti.data;
                            case 'binarized'
                                %is this even doing anything?  Yes, it is
                                %masking
                                currROIPartnerNifti.data=int32(~currROIPartnerNifti.data==0);
                                currAmalgumTargetNifti.data=currAmalgumTargetNifti.data+currROIPartnerNifti.data;
                        end
                end
            else
                % in the event that LPI and RAS convention isnt used, no
                % need to bother
                currROInifti=niftiRead(currRoiFilePath);
                %if thresh exists, apply
                if ~notDefined('thresh')
                    currROInifti.data=currROInifti.data(currROInifti.data>thresh);
                end
                currAmalgumTargetNifti=niftiRead(amalgumRoiFilePath);
                switch instruction
                    case 'sum'
                        currAmalgumTargetNifti.data=currAmalgumTargetNifti.data+currROInifti.data;
                    case 'binarized'
                        currROInifti.data=~currROInifti.data==0;
                        currAmalgumTargetNifti.data=currAmalgumTargetNifti.data+currROInifti.data;
                end
            end
            %now actually save it
            currAmalgumTargetNifti.fname=amalgumRoiFilePath;
            amalgumRoiFilePath;
            writeFileNifti(currAmalgumTargetNifti)
            max(max(max(currAmalgumTargetNifti.data)))
            
            %bsc_saveNifti(currAmalgumTargetNifti,amalgumRoiFilePath)
        end
        
    end
    
end


               
                       
                       
                
    
