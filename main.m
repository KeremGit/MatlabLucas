fileConfig =  config();

% Access the individual paths:
basePath = fileConfig.basePath;
capPath = fileConfig.capPath;
savePath = fileConfig.savePath;

inputFile = fullfile(basePath, 'v3p.mat');  % Change to the actual dataset name

preprocess_single_dataset(inputFile)