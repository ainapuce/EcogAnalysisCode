function csvAnalysis()


csvDir='/N/dc2/projects/lifebid/HCP/Dan/EcogProject/Coords/AllCoords';
ROIDir='/N/dc2/projects/lifebid/HCP/Dan/EcogProject/proj-5c33a141836af601cc85858d/amalgums/';
fsDir='/N/dc2/projects/lifebid/HCP/Dan/ICBM2009c_asym_nlin';
csvDirContents=dir(csvDir)
roiDirContents=dir(ROIDir)

csvBool=contains({csvDirContents.name},'.csv')
niftiBool=contains({roiDirContents.name},'.nii.gz')

thresh=100;

niftiNamesVec={roiDirContents(niftiBool).name}
csvNamesVec={csvDirContents(csvBool).name}

dataMatrix=[];
 niftiIndexes=find(niftiBool);
 csvIndexes=find(csvBool);
 
for iCSVs=1:length(csvIndexes)
    csvPath=fullfile(csvDir,csvDirContents(csvIndexes(iCSVs)).name);
    currCSV=csvread(csvPath);
    [curCSVnifti] = wma_coordCloud2ROI(currCSV,fsDir);
    totalCoords=sum(sum(sum(curCSVnifti.data)));
   
    for iROIS=1:length(niftiIndexes)
        curROI=fullfile(ROIDir,roiDirContents(niftiIndexes(iROIS)).name);
        curNifti=niftiRead(curROI);
        curNifti.data(curNifti.data<thresh)=0;
        
        bothData=curCSVnifti.data&curNifti.data;
        
        dataMatrix(csvIndexes(iCSVs),iROIS)= sum(sum(sum(bothData)))/totalCoords;
        
       
        
        
        
       

    end
end

dataSize=size(dataMatrix);
validBool=[];
for iData=1:dataSize(2)
    validBool(iData)=sum(dataMatrix(:,iData))>0;
end

validBool=logical(validBool);

validNiftiNames=niftiNamesVec(validBool);
validCSVNames=csvNamesVec;

resizeData=dataMatrix(csvBool,validBool)

resizeSize=size(resizeData)

imagesc(resizeData)
h = colorbar; set(get(h,'label'),'string','Proportion of ECoG sites in termination area')

xticks(1:resizeSize(2))
xticklabels(validNiftiNames)
xtickangle(30)
yticks(1:resizeSize(1))
yticklabels(validCSVNames)

saveas(gcf,'/N/dc2/projects/lifebid/HCP/Dan/EcogProject/matrixPlot','epsc')
    