% This is to read the FPGA python implementation data files.
% Format:
% START <numberOfStartEvents> STOP <numberOfStopEvents>
% event1AbsoluteStartTime(s)|event1StartByteEncoding
% event2AbsoluteStartTime(s)|event2StartByteEncoding
% ...
% event1AbsoluteStopTime(s)|event1StopByteEncoding
% event1AbsoluteStopTime(s)|event1StopByteEncoding
% ...
% event2AbsoluteStopTime(s)|event2StopByteEncoding

clc; clearvars;

filename = 'tdc_2022-9-6.txt';
fID = fopen(filename, 'r');
line = 0;
events = [];

while(~feof(fID))
    linecontents = fgetl(fID);
    if(line == 0)
        % Get the START info.
        
        % parse string for <numberOfStartEvents>
        numberOfStartEvents = textscan(linecontents, 'START %d');
        numberOfStartEvents = numberOfStartEvents{1};
        startEventTimes = zeros(numberOfStartEvents, 1);
    elseif(line <= numberOfStartEvents)
        % This line contains a startEvent timestamp.
        linecontents = textscan(linecontents, '%.12f|0x%s');
        absoluteTime = linecontents{1};
        absoluteByte = linecontents{2};
        % Store in <events> placeholder.
        startEventTimes(line) = absoluteTime;
    elseif(line == (numberOfStartEvents+1))
        % Obtain the stop counts.
        numberOfStopEvents = textscan(linecontents, 'STOP %d');
        numberOfStopEvents = numberOfStopEvents{1};
        stopEventTimes = zeros(numberOfStopEvents, 1);
    else
        % This line contains a stopEvent timestamp.
        linecontents = textscan(linecontents, '%.12f|0x%s');
        absoluteTime = linecontents{1};
        absoluteByte = linecontents{2};
        % Store the Stop events in an array.
        stopEventTimes(line-1-numberOfStartEvents, 1) = absoluteTime;
    end
    line = line + 1;
end
fclose(fID);

% Now for the associating of the proper START and STOP events, the
% following assumption is made: associate any STOP event between two START
% times to the earlier of the two START events. However, if an overflow
% occurs in between the two START events (i.e., event 2 occurs earlier than
% event 1) take this into account as well.

% Store the associated START/STOP indices in a format 
% [lastStopForStartEvent1; lastStopForStartEvent2; ...]

lastStopForEvent = zeros(numberOfStartEvents, 1);

% Loop over all START events
lastStopIndex = 0;
eventDuration = 100e-6; %10e-6; % [s], maximum expected time seperation.
channelDelay  =  50e-9; % [s], tolerance between start and nearby stop events, bidrectional.

% Check if any consecutive start events overlap within the estimated
% <eventDuration>.
overlappingEvents = find(abs(diff(startEventTimes)) < eventDuration)
if(~isempty(overlappingEvents))
    fprintf('Overlapping events found. Will merge these now.')
    overlappingEvents
    % In the case of overlapping events, it becomes somewhat harder to tell
    % what STOP event belongs to what START event. In that case, assume
    % that the later START event sets the upper time value for the former
    % START event.
end


for startIndex = 1:numel(startEventTimes)
    startIndex
    % For startEventTimes(startIndex), find all stopEventTimes until
    % exceeding the value for startEventTimes(startIndex+1), or until
    % finding the last startIndex.
    if(startIndex == numberOfStartEvents)
        % This is the last index.
        lastStopForEvent(startIndex) = numel(stopEventTimes);
    else
        % This is not the last index. Instead, find indices up to the next
        % start event, taking into account possible jitter and the maximum
        % duration expected for this event series.
        if(any(overlappingEvents == startIndex))
            fprintf('This one overlaps with the next one.')
            subIndices = find( (stopEventTimes((lastStopIndex+1):end)) < (startEventTimes(startIndex+1)-channelDelay) );
        else
            % Non-overlapping behavior.
            subIndices = find( (stopEventTimes((lastStopIndex+1):end) - eventDuration) < (startEventTimes(startIndex)-channelDelay) );
        end
        
        
        % Check that the numbers are monotonically increasing.
        subMonoIncrease = find(diff(stopEventTimes(subIndices+lastStopIndex)) > 0);
        % Find the first occurance that skips a beat.
        subSkipIndices = find(diff(subMonoIncrease) > 1, 1);
        if(~isempty(subSkipIndices))
            % This marks the intersect for event tying.
            lastStopIndex = lastStopIndex + 1 + subSkipIndices;
        else
            % There was no skipping.
            lastStopIndex = lastStopIndex + 1 + subMonoIncrease(end);
        end
        % Store the obtained result.
        lastStopForEvent(startIndex) = lastStopIndex;
    end
    if(startIndex == 3)
%         stop
    end
end

% Remove offset timing for each series.
offsetStopEventTimes  = zeros(size(stopEventTimes));

for index = 1:numel(lastStopForEvent)
    offsetStartTime = startEventTimes(index);
    if(index == 1)
        offsetStopEventTimes( 1: lastStopForEvent(index)) = stopEventTimes( 1 : lastStopForEvent(index) ) - startEventTimes(index);
    else
        offsetStopEventTimes( (lastStopForEvent(index-1)+1) : lastStopForEvent(index) ) = stopEventTimes( (lastStopForEvent(index-1)+1) : lastStopForEvent(index) ) - startEventTimes(index);
    end
    
end

figure(1); clf; hold on;
histogram(offsetStopEventTimes, 1000)

% Print the sequences obtained.
for index = 1:numel(lastStopForEvent)
    fprintf('Start: %.12f.\n', startEventTimes(index))
    if(index == 1)
        stopEventTimes(1:lastStopForEvent(1));
    else
        stopEventTimes( (lastStopForEvent((index-1))+1) : lastStopForEvent(index) );
    end
end

