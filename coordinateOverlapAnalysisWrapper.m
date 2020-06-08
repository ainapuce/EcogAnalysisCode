%this is the directory that contains the CSVs which have the coordinates
%stored within them
csvDir='/N/dc2/projects/lifebid/HCP/Dan/EcogProject/Coords/AllCoords';

%this is the project directory after downloading from brainlife
projectDir='/N/dc2/projects/lifebid/HCP/Dan/EcogRecheck/proj-5d89354698422078697ec179';

%get the paths to the roi directories in this project
[dataDirPaths]=bsc_getBrainlifeDataDirPaths(projectDir,{'rois'});

%because of the structure of the rois datatype, we have to add an roi
%directory to the path
for iDataDirpaths=1:length(dataDirPaths)
    dataDirPaths{iDataDirpaths}=fullfile(dataDirPaths{iDataDirpaths},'rois');
end

%this is the directory in which you'd like save your output
outDir='/N/dc2/projects/lifebid/HCP/Dan/EcogProject/';

%This is the threshold applied to endpoint maps prior to amalgamation.
%voxel values below this number will be set to zero prior to amalgamation.
preAmalgumThresh=.01;

bsc_amalgamateROISacrossDirectories(dataDirPaths,[],outDir,'binarized',.01)

%This is the minimum number of subjects exhibiting (binarized) endpoint
%density from the previous amalgamation step needed in order to be
%considered as a valid voxel for overlap analysis.  Voxel values in amalgum
%niftis below this value are set to zero prior to overlap analysis.
overlapSubjectNumThresh=100;

wma_multiCoordinateOverlapAnalysis(csvDir,outDir,outDir,overlapSubjectNumThresh)