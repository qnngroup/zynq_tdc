function [all_monotonic_timestamps, avg_line_scan_time] = make_timestamps_monotonic(time_stamps, overflow_time, varargin)
%MAKE_TIMESTAMPS_MONOTONIC Convert raw TDC timestamps that are limited by
%the binary counter overflow value (typically 47 ms) into a monotonically
%increasing time array.
%   Convert raw TDC timestamps that are limited by the binary counter
%   overflow value (typically 47 ms) into a monotonically increasing time
%   array.
%   This takes an array or matrix of time stamps that is typically prepared
%   by calling @get_raw_edge_and_spcm_times. When the time difference
%   between two consecutive elements is negative, the @overflow_time value
%   is added to the latter element. A @cleanup_factor may optionally be
%   applied that truncates any element that has a time difference in ecxess
%   of @cleanup_factor times the average line scan time. Set to zero to
%   discard.

% Notice: if a memory overflow took place, it is identified by more than
% one row in the provided data set. Repeat the following for each row.

numRows = size(time_stamps, 1);

all_monotonic_timestamps = [];

if(nargin == 2)
    cleanup_factor = 0;
else
    cleanup_factor = varargin{1};
end

for row = 1:numRows

    % Make monotonic increase in edge times.
    time_differences = abs(mod(diff(time_stamps(row, :)), overflow_time));
    % Remove any trailing zeros.
    time_differences(time_differences == 0) = [];

    % Determine the average line scan time.
    avg_line_scan_time = mean((time_differences));
    % Remove 'double' triggers, only for edge events.
    if(cleanup_factor > 0)
        time_differences(time_differences < cleanup_factor * avg_line_scan_time) = [];
    end

    % Now, build the cumulative time stamp array, and offset it by
    % time_stamps(1) for absolute reference to the other channels.
    monotonic_timestamps = [time_stamps(row, 1)  time_stamps(row, 1)+cumsum(time_differences)];
    all_monotonic_timestamps(row, 1:numel(monotonic_timestamps)) = monotonic_timestamps;
end

end

