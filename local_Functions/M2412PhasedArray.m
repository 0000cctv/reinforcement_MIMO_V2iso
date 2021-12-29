function varargout = M2412PhasedArray(fq,Am,tilt,az3dB,el3dB,varargin)
%M2412PhasedArray   Create Phased Array antenna corresponding to Report ITU-R M.2412

%   Copyright 2020 Asiainfo Co., Ltd.

% Pattern Parameters Example
% Am = 30; % Maximum attenuation (dB)
% tilt = 0; % Tilt angle
% az3dB = 65; % 3 dB bandwidth in azimuth
% el3dB = 65; % 3 dB bandwidth in elevation

% Define antenna pattern
azvec = -180:180;
elvec = -90:90;
[az,el] = meshgrid(azvec,elvec);
azMagPattern = -12*(az/az3dB).^2;
elMagPattern = -12*((el-tilt)/el3dB).^2;
combinedMagPattern = azMagPattern + elMagPattern;
combinedMagPattern(combinedMagPattern<-Am) = -Am; % Saturate at max attenuation
phasepattern = zeros(size(combinedMagPattern));

% Create antenna element
antennaElement = phased.CustomAntennaElement(...
    'AzimuthAngles',azvec, ...
    'ElevationAngles',elvec, ...
    'MagnitudePattern',combinedMagPattern, ...
    'PhasePattern',phasepattern);


switch length(varargin)
    
    case 0
        antennaArray = antennaElement;
    case 4
        % Define array size
        nrow = varargin{1};
        ncol = varargin{2};
        
        % Define Sidelobe Attenuation
        sidelobeAttenuation_z = varargin{3};
        sidelobeAttenuation_y = varargin{4};
        
        % Define element spacing
        lambda = physconst('lightspeed')/fq;
        drow = lambda/2;
        dcol = lambda/2;
        
        % Create 8-by-8 antenna array
        taper_z = chebwin(nrow,sidelobeAttenuation_z);
        taper_y = chebwin(ncol,sidelobeAttenuation_y);
        tapers = taper_z*taper_y.';
        antennaArray = phased.URA('Size',[nrow ncol], ...
            'Element',antennaElement, ...
            'ElementSpacing',[drow dcol],...
            'Taper',tapers, ...
            'ArrayNormal','x');
    otherwise
        error('The number of beam parameters should be 0 or 2.')
        
end

if nargout == 1
    varargout{1} = antennaArray;
elseif nargout == 0
    pattern(antennaArray,fq);
else
    error('The number of output parameters should be 0 or 1.')
end

end