function [really_all_data, histogram_bins, wavelength_with_errors] = TDCtimestampAnalysis(locationFormatString, wavelengths, varargin)
%TDCTIMESTAMPANALYSIS Summary of this function goes here
%   Detailed explanation goes here

% Required parameters
% @locationFormatString path/to/files/basename_%i_.txt with %i an
% @wavelengths value.
% @wavelengths array of wavelength values associated to analysis files.

p = inputParser;
addOptional(p, 'NumberOfHistogramBins', 100, @(x) x > 9)
addOptional(p, 'CounterOverflowTime', 2^24 /350e6, @(x) x > 0)
addOptional(p, 'TruncateSignificantOutliers', true, @(x) islogical(x) )
addOptional(p, 'ShowVisualIntermediateOutput', true, @(x) islogical(x));
addOptional(p, 'FigureNumberForOutput', 1, @(x) x>0);
addOptional(p, 'TruncateDetectorIntegrationErrors', true, @(x) islogical(x))
addOptional(p, 'ToleranceForDetectorIntegrationErrors', 0.1, @(x) x >= 0 && x <= 1)
parse(p, varargin{:});

baseFilename = locationFormatString;
nbins = p.Results.NumberOfHistogramBins;
overflow_time = p.Results.CounterOverflowTime;
truncate_significant_outlier_spcm_counts = p.Results.TruncateSignificantOutliers;
visual_summary_of_analysis = p.Results.ShowVisualIntermediateOutput;
skip_detector_integration_time_error_events = p.Results.TruncateDetectorIntegrationErrors;
variation_tolerance = p.Results.ToleranceForDetectorIntegrationErrors;

line_time_from_data = 0;
really_all_data = [];
wavelength_with_errors = [];

for wavelength = wavelengths
    filename = [baseFilename num2str(wavelength) '.txt'];
    % Step 0.
    % Read START/STOP times.
    [edge_times, spcm_times] = get_raw_edge_and_spcm_times(filename);

    % Step 1. Determine the source for the line time estimate
    if(line_time_from_data == 0)
        % More than one memory set may be available. Average across each.
        for index_ = 1:size(edge_times, 1)
            % Only include the non-zero entries for this row.
            source_for_estimate = edge_times(index_, (edge_times(index_,:) > 0));
            % Estimate of the line time, based on raw counts.
            estimated_line_time(index_) = mean( abs(mod(diff(source_for_estimate), overflow_time)) ); %#ok<SAGROW>, [s]
        end
        estimated_line_time = mean(estimated_line_time);
        % Update the loop with the consistent estimate for line time.
        line_time_from_data = estimated_line_time;
    else
        % Some varargin meta data. This is useful when requiring the same
        % bin size over a series of wavelengths for example. Or, assigned
        % during the first iteration of the bulk series data.
        estimated_line_time = line_time_from_data;
    end

    if(estimated_line_time > overflow_time/2)
        warning('Probably aliasing for too large line scan time.')
    end

    % Prepare a histogram on a fixed bin size.
    histogram_bin_edges = (0:(nbins))/(nbins) * estimated_line_time;


    % Step 2. Make the data monotonically incremental.

    % Make monotonic increase in edge times.
    [mono_edge_times, ~] = make_timestamps_monotonic(edge_times, overflow_time);
    mono_spcm_times = make_timestamps_monotonic(spcm_times, overflow_time);

    % This will contain all valid data for all memory buffers associated to
    % this wave length TDC time stamp data.
    index_data = get_spcm_before_next_edge_times(mono_edge_times,mono_spcm_times, overflow_time, variation_tolerance, truncate_significant_outlier_spcm_counts, estimated_line_time, visual_summary_of_analysis, wavelength);



    % Perform a histogram on this data set, normalize as simple probability.
    if(numel(index_data) > 0)
        [hcounts, ~] = histcounts(index_data, histogram_bin_edges, 'Normalization', 'probability');
    else
        hcounts = zeros([nbins 1]);
    end

    % This is the normalized probability of creating a photon at a given
    % time bin interval before the next edge event.
    really_all_data(end+1, :) = hcounts;

    %     % Show what the resulting data set looks like?
    %     if(visual_summary_of_analysis)
    %         % This plots the stitched data set (lower row in figure).
    %         subplot(2, size(mono_edge_times_full, 1), useIndex+(1:useIndex));
    %         plot(1e3* index_data,  '.')
    %         title('All sets merged (new approach)');
    %         drawnow;
    %     end


end

histogram_bins = cumsum(diff(histogram_bin_edges));

end

