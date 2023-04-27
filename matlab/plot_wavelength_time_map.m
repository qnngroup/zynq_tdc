function [figHandle] = plot_wavelength_time_map(spectral_map, wavelengths, sweep_axis, varargin)
%PLOT_SPECTRUM Summary of this function goes here
%   Detailed explanation goes here

% Some formatting.
set(groot,'defaulttextinterpreter','latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

% Custom figure number.
if(nargin == 3)
    figNumber = 1;
else
    figNumber = varargin{1};
end

figHandle = figure(figNumber);
clf; hold on;

% Visual output of all data.


imagesc(1e3*sweep_axis([1 end]) ,wavelengths([1 end]), spectral_map);
xlabel('Time before next edge (ms)');
ylabel('Wavelength (nm)');
title('Memory-based post-processing');
colormap bone;
colorbar;
axis tight; box on;
set(gca, 'Layer', 'top');
set(gca, 'YDir', 'reverse');



end

