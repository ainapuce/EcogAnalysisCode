function  [blankNifti] = wma_coordCloud2ROI(coords,fsDir)
% function  wma_endpointMapsDecay(fg, fsDir, thresholdinmm, decayFunc)
%
% OVERVIEW: generate .nifti files for (both) of the coordinate cloud that
% was input
%
% INPUTS:
% -coords: 3xN matrix of the coords that the user would like to turn into
%          an roi
% -fsDir: path to THIS SUBJECT'S freesurfer directory
%

%
% OUTPUTS:
% -blankNifti: Endpoint density file for two distinct endpoint clouds of the tract.
% In this file, we simply sum the values across streamline endpoints. LPI =
% left posterior inferior endpoint group, RAS = Right anterior superior
% endpoint group
%
% (C) Daniel Bullock and Hiromasa Takemura, 2016, CiNet HHS
%  Overhaul by DNB 9/2019
%
%  Dependancies:  Vistasoft

%% Parameter settings & preliminaries
%generate the gm mask if it doesn't exist



%Note, this hardpath should be set to wherever you have this atlas stored (mni_icbm152_t1_tal_nlin_asym_09c.nii)
%atlas obtained from https://figshare.com/articles/FreeSurfer_reconstruction_of_the_MNI152_ICBM2009c_asymmetrical_non-linear_atlas/4223811
graynii = niftiRead('/N/dc2/projects/lifebid/HCP/Dan/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c.nii');
% 

blankNifti=graynii;
blankNifti.scl_slope=0;
blankNifti.scl_inter=0;
blankNifti.data(:,:,:)=false;

ROINiiData=blankNifti.data;

%why is it sto_ijk
imgCoords  = floor(mrAnatXformCoords(blankNifti.sto_ijk, coords'));

ROIindex=round(imgCoords)+1;


for iCoords=1:length(coords)
    ROINiiData(ROIindex(iCoords,1),ROIindex(iCoords,2),ROIindex(iCoords,3))=ROINiiData(ROIindex(iCoords,1),ROIindex(iCoords,2),ROIindex(iCoords,3))+1;
end

blankNifti.data=ROINiiData;

end

