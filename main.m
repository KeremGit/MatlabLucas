fileConfig =  config();

% Access the individual paths:
basePathADHD = fileConfig.basePathADHD;
capPath = fileConfig.capPath;
savePath = fileConfig.savePath;

inputFile = fullfile(basePathADHD, 'v3p.mat');  % Change to the actual dataset name

preprocess_single_dataset(inputFile, savePath)