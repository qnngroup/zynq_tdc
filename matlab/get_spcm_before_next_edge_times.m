function [index_data, wavelength_with_errors] = get_spcm_before_next_edge_times(mono_edge_times_full,mono_spcm_times_full, overflow_time, variation_tolerance, truncate_significant_outlier_spcm_counts, estimated_line_time, visual_summary_of_analysis, wavelength)
%GET_SPCM_BEFORE_NEXT_EDGE_TIMES Summary of this function goes here
%   Detailed explanation goes here
% Analyse each memory array of the TDC data.

index_data = [];
wavelength_with_errors = [];

if(visual_summary_of_analysis)
    figure(1); clf; hold on;
end

for useIndex = 1:size(mono_edge_times_full, 1)
    % Estimate the data integration time for this memory array, for
    % START and STOP events seperately. The total integration time
    % should be close to one another, or else some jitter or
    % acquisition error may have occured during collection.
    edge_total_time = cumsum(mod(diff(mono_edge_times_full(useIndex,:)), overflow_time));
    edge_total_time = edge_total_time(end);
    spcm_total_time = cumsum(mod(diff(mono_spcm_times_full(useIndex,:)), overflow_time));
    spcm_total_time = spcm_total_time(end);

    % Integrated time difference divided by the average integrated
    % time.
    variation = 2 * abs(edge_total_time-spcm_total_time) / abs(edge_total_time+spcm_total_time);
    if(variation > variation_tolerance)
        % One detector ran way longer than the other...
        warning(sprintf('Detector discrepancy for total integration time, var %0.3f, wavelength %i nm, index %i', variation, wavelength, useIndex))
        wavelength_with_errors(end+1) = wavelength;
        %             really_all_data(end+1, :) = nan([nbins 1]);
        % Skip the remainder for analysis of this memory vector.
        % However, there might be relevant data in one of the other (if
        % applicable) useIndex buffers.

    else

        % Work on parsing only the time stamps in this memory index.
        mono_edge_times = mono_edge_times_full(useIndex, :);
        mono_spcm_times = mono_spcm_times_full(useIndex, :);


        % Remember how the dark count rate of the SPCM ensures that you
        % always capture at least one event per overflow_time. Let's use
        % that to our advantage.

        % 1. First, throw out any SPCM event prior to the first EDGE event.
        % Why removing this line helps!?
        mono_spcm_times(mono_spcm_times < mono_edge_times(1)) = [];

        % 2. Next, throw out the first edge event (since there won't be any
        % event data prior to it anyhow.
        % More strictly, delete any mono_edges before the first SPCM.
        mono_edge_times(mono_edge_times < mono_spcm_times(1)) = [];

        % 3. Then, align timestamps. Obtain the SPCM time relative before the next
        % edge time.

        spcm_copy = mono_spcm_times;
        times_before_edge = [];


        for edge_index = 1:numel(mono_edge_times)
            % Find all SPCM before this edge.
            my_spcm_times = spcm_copy( spcm_copy < mono_edge_times(edge_index));
            if(numel(my_spcm_times) > 0)
                % Add the times to the data buffer.
                times_before_edge = [times_before_edge ...
                    mono_edge_times(edge_index)-my_spcm_times];
                % Remove used indices from copy.
                spcm_copy(1:numel(my_spcm_times)) = [];
            end
        end

        % Some SPCM counts may result from a missed edge, meaning they are
        % far outside of the expected time difference range. You may safely
        % disregard such counts.
        if(truncate_significant_outlier_spcm_counts)
            times_before_edge(times_before_edge > 1.2*estimated_line_time) = [];
        end

        % Visual summary of the remaining data for convenience.
        if(visual_summary_of_analysis)
            subplot(2, size(mono_edge_times_full, 1), useIndex);
            plot(1e3*times_before_edge, '.')
            title(['Set ' num2str(useIndex)]);
            drawnow;
        end

        % This variable must have some name, ...
        % It contains all valid relative SPCM counts with respect to the
        % next EDGE event time. Append it to the existing slurry of data.
        index_data = [index_data times_before_edge];

    end
end
% Show what the resulting data set looks like?
if(visual_summary_of_analysis)
    % This plots the stitched data set (lower row in figure).
    subplot(2, size(mono_edge_times_full, 1), useIndex+(1:useIndex));
    plot(1e3* index_data, '.')
    title('All sets merged (new approach)');
    drawnow;
end
end