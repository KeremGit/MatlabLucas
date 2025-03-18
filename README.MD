# EEG Preprocessing Pipeline

## Overview
This document outlines the key steps in the EEG preprocessing pipeline used for processing multiple datasets, including ADHD and Control groups. The preprocessing is conducted using EEGLAB in MATLAB and involves importing data, cleaning, re-referencing, filtering, and performing Independent Component Analysis (ICA).

## Steps

### 1. **Define File Paths**
- Define base paths for ADHD and Control datasets.
- Set up directories for saving processed datasets.
- Ensure directories exist before proceeding.

### 2. **Initialize EEGLAB**
- Load EEGLAB environment to handle EEG data processing.

### 3. **Process Datasets in Multiple Folders**
For each dataset:
1. **Load EEG Data**
   - Import EEG `.mat` files as EEGLAB datasets.
   - Assign dataset names, sampling rate, and subject metadata.
   - Save the raw EEG dataset.

2. **Clean EEG Data**
   - Remove bad channels and artifacts using EEGLAB's `pop_clean_rawdata` function.
   - Save the cleaned EEG dataset.

3. **Re-referencing**
   - Apply common average reference.
   - Save the re-referenced dataset.

4. **High-pass Filtering**
   - Apply a 1 Hz high-pass filter to remove low-frequency noise.
   - Save the filtered dataset.

5. **Independent Component Analysis (ICA)**
   - Run ICA to identify and remove artifacts (e.g., eye blinks, muscle activity).
   - Save the ICA dataset.
   - Apply ICA weights and save the updated dataset.

6. **Classify and Save Final Dataset**
   - Categorize datasets into "Control" or "Experimental" based on folder name.
   - Save the final processed dataset in the appropriate directory.

### 4. **Finalizing the Process**
- Redraw EEGLAB interface to visualize processed datasets.
- Print a message indicating successful processing of each dataset.

## Output Files
Each dataset undergoes multiple stages of processing, resulting in the following files:
- `*.set` (Raw EEG dataset)
- `*_CRD.set` (Cleaned dataset)
- `*_CRD_REREF.set` (Re-referenced dataset)
- `*_CRD_REREF_HPASS.set` (High-pass filtered dataset)
- `*_CRD_REREF_HPASS_WICA.set` (ICA dataset)
- `*_CRD_REREF_WICA.set` (ICA-applied dataset)
- `*_Final.set` (Final categorized dataset)

## Notes
- Ensure that `capFile` contains correct channel locations for accurate preprocessing.
- ICA requires an appropriate number of channels; ensure proper configuration.
- Processed datasets are saved separately for Control and Experimental groups.

## Dependencies
- MATLAB
- EEGLAB Toolbox
- EEG datasets in `.mat` format

This pipeline ensures a standardized preprocessing workflow for multiple EEG datasets, facilitating further analysis.

