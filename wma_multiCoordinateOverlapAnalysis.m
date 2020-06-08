function wma_multiCoordinateOverlapAnalysis(csvDir,ROIDir,saveDir,thresh)
% wma_multiCoordinateOverlapAnalysis(csvDir,ROIDir,saveDir)
%
%  Purpose:  This function iterates across input CSV files with sets of
%  coordiantes, and for each CSV in the csvDir and each nifti in the ROIDir
%  directory computes the proportion of the coordinates that fall within
%  the above-threshold voxels of the ROI.
%
%  Inputs
%
%  csvDir:  A directory containing potentially multiple csv files.  Each
%  file should be N by 3, where N is the number of coordinates.
%
%  ROIDir:  A directory containing multiple rois (.nii.gz files, nifti
%  format).  It is presumed that all are in the appropriate reference space
%  in order to be relevant to the input coordinates.  Moreover, this
%  implies that all of the input nifti files are aligned to one another.
%
%  saveDir:  The directory in which to save the output figure and table.
%
%  thresh:  the minimum value in the input ROIs considered for overlap.
%  Entries below this value are treated as 0.  Defaults to 0
%
%  Outputs
%
%  None, saves down the output
%% Begin code

%set the thresh to 0 if nothing is intered
if isempty(thresh)
    thresh=0;
end

%set the savedir to working dir if nothing is passed.
if isempty(saveDir)
    saveDir=pwd;
end

%find the contents of the directories
csvDirContents=dir(csvDir);
roiDirContents=dir(ROIDir);

%select the relevant files
csvBool=contains({csvDirContents.name},'.csv');
niftiBool=contains({roiDirContents.name},'.nii.gz');

%create lists of the relevant files
niftiNamesVec={roiDirContents(niftiBool).name};
csvNamesVec={csvDirContents(csvBool).name};

%create 
dataMatrix=[];
niftiIndexes=find(niftiBool);
csvIndexes=find(csvBool);

%go ahead and get the first roi to serve as a template for the roi creation
templateNifti=niftiRead(niftiNamesVec{1});

%iterate over the csv files
for iCSVs=1:length(csvIndexes)
    %create path to current csv
    csvPath=fullfile(csvDir,csvDirContents(csvIndexes(iCSVs)).name);
    %load it
    currCSV=csvread(csvPath);
    %convert the coordinates to a .mat roi from vistasoft
    currCordCloud = dtiNewRoi([], [], currCSV);
    %convert the .mat format roi to a .nifti style roi
    [coordRoi, ~] = dtiRoiNiftiFromMat(currCordCloud,templateNifti,[],false);
   
    %find the total number of nonzero coordinates in the coordinate roi
    %nifti.  Should be the same number as the input coord file
    totalCoords=sum(sum(sum(coordRoi.data)));
   
    %iterate across the rois
    for iROIS=1:length(niftiIndexes)
        
        %set up path to current Nifti
        curROI=fullfile(ROIDir,roiDirContents(niftiIndexes(iROIS)).name);
        %Read in the file
        curNifti=niftiRead(curROI);
        %apply the threshold
        curNifti.data(curNifti.data<thresh)=0;
        %find the number of entries where the source nifit overlaps with
        %the coordinates
        bothData=curCSVnifti.data&curNifti.data;
        %put this data in the appropriate rown and column of the output
        %matirx
        dataMatrix(csvIndexes(iCSVs),iROIS)= sum(sum(sum(bothData)))/totalCoords;
    end
end

%find the size of the data matrix
dataSize=size(dataMatrix);
%set a vector
validBool=[];
%iterate across the rois (not the coordinates) to find those rois which
%have ANY overlap with a coordinate.  We'll be dropping the rois that don't
%have any overlap from the output
for iData=1:dataSize(2)
    %place a true value where any overlap is found
    validBool(iData)=sum(dataMatrix(:,iData))>0;
end

%conert it to a logical.  May be necessary to set type like this
validBool=logical(validBool);

%index out the valid names so that we can use them in the matrix and
%visualization
validNiftiNames=niftiNamesVec(validBool);
%directly port over the csv names
validCSVNames=csvNamesVec;

%resample the data so that only the rois (columns) with data are present
resizeData=dataMatrix(csvBool,validBool);
%get the size of this new output
resizeSize=size(resizeData);

%plot the output
imagesc(resizeData)
h = colorbar; set(get(h,'label'),'string','Proportion of ECoG sites in termination area')
%set up image
xticks(1:resizeSize(2))
xticklabels(validNiftiNames)
xtickangle(30)
yticks(1:resizeSize(1))
yticklabels(validCSVNames)

%crete the save paths
figSavePath=fullfile(saveDir,'matrixPlot.epsc');
tableSavePath=fullfile(saveDir,'matrixPlot.epsc');

%set the table up
outTable = table(resizeData,...
    'VariableNames',validNiftiNames,...
    'RowNames',validCSVNames);

%write the files down
writetable(outTable,tableSavePath)
saveas(gcf,figSavePath,'epsc')
end   