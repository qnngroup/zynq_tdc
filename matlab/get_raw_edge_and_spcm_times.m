function [edge_times, spcm_times] = get_raw_edge_and_spcm_times(filename)
%GET_EDGE_AND_SPCM_TIMES Read a TDC two-channel data file, that contains
%START and STOP events.
%   Read a TDC two-channel data file, that contains START and STOP events.
%   This return unprocessed timestamps that are in the range between 0 ps
%   and 24-bit limited acquisition of the TDC (around 47 ms). This function
%   also checks for memory index reset that may have occured when the TDC
%   was reset during acquisition. 
%   This function returns a 1-dimensional array when no memory reset is
%   detected, or a 2-dimensional matrix when multiple memory blocks are
%   obtained from the raw data file. This discrimination is based on the
%   hexadecimal encoding of the raw TDC binary output value.

% Place holders for return data time stamps.
edge_times = [];
spcm_times = [];

fid = fopen(filename, 'r');

% Track memory reset events.
edge_memory_index = 0;
spcm_memory_index = 0;

egde_el_index = 0;
spcm_el_index = 0;

% Read the first line to learn about the number of START (edge) events.
lineNr = 0;
while ~feof(fid)
    lineNr = lineNr + 1;
    line = fgets(fid);
    if(lineNr == 1)
        cells = textscan(line, 'START %d');
        edge_events = cells{1};
        % Nothing more to do here.
        continue
    end

    if(lineNr < (edge_events+2) )
        % Collect all edge timings.
        cells = textscan(line, '%f|0x%s');
        this_timestamp = cells{1};
        this_memorystamp = cells{2}{1};

        % Check if this is the start of a new memory block.
        if( strcmp(this_memorystamp( (end-3): end), '0000') )
            edge_memory_index = edge_memory_index + 1;
            egde_el_index = 0;
        end
        egde_el_index = egde_el_index + 1;
        edge_times(edge_memory_index, egde_el_index) = this_timestamp; %#ok<AGROW>
        continue;
    end

    if(lineNr == (edge_events+2))
        % This is the STOP (spcm) events header line
        %cells = textscan(line, 'STOP %d');
        %spcm_events = cells{1};

        continue
    end

    % Will only reach here after the STOP header line.
    cells = textscan(line, '%f|0x%s');
    this_timestamp = cells{1};
    this_memorystamp = cells{2}{1};

    % Check if this is the start of a new memory block.
    if( strcmp(this_memorystamp( (end-3): end), '0000') )
        spcm_memory_index = spcm_memory_index + 1;
        spcm_el_index = 0;
    end
    spcm_el_index = spcm_el_index + 1;
    spcm_times(spcm_memory_index, spcm_el_index) = this_timestamp; %#ok<AGROW>
end
end

