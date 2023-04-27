%% analysis_routine.m
%
%  Author:  M. A. R. Krielaart
%  Date:    4/27/2023
%  Description: This script demonstrates how TDC START and STOP events can
%  be analysed and used to form a probability map for temporally and
%  spectrally resolved single photon counts.
%
%  Data in the ./example_data folder is obtained as part of an experimental
%  run on 3/31/2023, and further available and described in the related
%  Google Drive QNN project folder for heralded source (see logbook data
%  Maurice).
clearvars; clc;

%% Pointing to raw data files and series definition.
% Provide a base path to the raw data files. The following file format is
% assumed: path/to/files/<filename>_<wavelength>.txt.
basePath = 'example_data/oversample-64_';

% List of <wavelength> values in the filenames.
wavelengths = 400:5:710;

%% Raw data file loading and analysis
% Perform analysis of all raw data files. The following optional parameters
% are available, with the following defaults:
% + 'NumberOfHistogramBins' The number of bins that the line scan time must
% be divided into. Default: 100.
% + 'CounterOverflowTime' The absolute TDC time when the count buffer
% overflows. Defaults to 2^24 /350e6 (about 47.9 ms).
% + 'TruncateSignificantOutliers' Delete any SPCM counts that are well
% beyond what could be associated to the next EDGE count. Default TRUE.
% + 'ShowVisualIntermediateOutput' Show the obtained memory bands based on
% what the time between TDC SPCM and EDGE events are based. Default TRUE.
% + 'FigureNumberForOutput' The figure number to use when requiring visual
% output. Defaults to 1.
% + 'TruncateDetectorIntegrationErrors' Skip any TDC SPCM and EDGE data
% series within a memory range when the accumulated time of the SPCM and
% EDGE series are not within a provided tolerance range. This may happen
% when for some reason one of the TDC channels stalls during acquisition.
% Default value TRUE.
% + 'ToleranceForDetectorIntegrationErrors' The tolerance level for
% deviation between the accumulated SPCM and EDGE time, ranging from 0
% (strict tolerance) to 1 (no tolerance verification). Default 0.1.
[spectral_time_map, histogram_bin_centers] = ...
    TDCtimestampAnalysis(basePath, wavelengths, ...
    'NumberOfHistogramBins', 100, ...
    'ToleranceForDetectorIntegrationErrors', 0.2 ...
    );

%% Simple image map of the probability counts for each wavelength, divided
% across the provided number of histogram bins.
plot_wavelength_time_map(...
    spectral_time_map, ...      The data set after post-processing.
    wavelengths, ...            The wavelength series of acquisition.
    histogram_bin_centers ...   The histogram bin centers.
    );
