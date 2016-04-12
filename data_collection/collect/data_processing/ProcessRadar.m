%% Initailize Parameters
clear;
addpath('../data');

% File parameters 
rp_file = 'radar_param';
scan_file = 'multi_row_test';


% TODO 
% need additional file printed at start of scan for radar paramenters 
% (struct) rp = read_parameter_file(rp_file);
% scanStartPs = rp.scanStartPs;
% maxDistance_m = rp.maxDistance_m;
% pulseIntegrationIndex = rp.pii;
% transmitGain = rp.transmitGain;
% scanIntervalTime_ms = rp.scanIntervalTime_ms;
% scanStepBins = rp.scanStepBins;
% antennaMode = rp.antennaMode;

% User selectable   
scanStartPs = 17400;            % Adjust this to match antenna delay
maxDistance_m = 20;             % P410 will quantize to closest value above this number
pulseIntegrationIndex = 12;     % The number of pulses per scan point (2^n)
transmitGain = 63;              % Tx power (0 for FCC legal)
scanIntervalTime_ms = 0;        % Time between start of each scan in millisecs
ovsFac = 4;                     % Oversampling factor applied when interpolating
rangeScaleFac = 3/2;            % Normalize by r^rangeScaleFac
ampFilter = 1.5e+7;             % Amplitude to filter below

% Derived parameters
C_mps = 299792458;
scanStopPs = scanStartPs + (2*maxDistance_m/C_mps)*1e12; % 1e12 ps in one sec
codeChannel = 0;            % PN code
antennaMode = 3;            % Tx: B, Rx: A
scanStepBins = 32;          
scanResPs = scanStepBins*1.907;          % 61 ps sampling resolution
scanCount = 1;              % number of scans per spatial location (2^16-1 for continuous)    

%% Read Radar Data From File
[raw_scan, gps_data] = read_multiscan_file(scan_file);
scan_dim = size(raw_scan);               % [num_scans bins_per_scan]

%% Plot Raw Radar Data 
plotRawScan(raw_scan, scan_dim, scanResPs, C_mps);

%% Format Raw Radar Data
rawCollect = formatData(raw_scan, gps_data, scan_dim, ...
                        C_mps, scanResPs,scanIntervalTime_ms);

%% Process Raw Radar Data
display_image = true;                   % display image during processing?

% GPS data often sucks. If the test went horrible, set this variable to 
% override the GPS data.
GPS_override = true;
scan_incriment = 0;
if GPS_override
    aperture_length = 3.3;             % (m) aperture length
    scan_incriment = aperture_length / scan_dim(1);
end 

% create a 3D or 2D image depending on the size of the data set
if numel(scan_dim) == 3
    image_set = SAR_3D(rawCollect);
else 
    % define scene size
    height = 0.3810;                            % aperture height
    sceneSizeX = 10;
    sceneSizeY = maxDistance_m;
    sceneSize = [sceneSizeX sceneSizeY height]; % [X Y Z]
    
    % create 1D backprojection image of radar scene
    processScan(rawCollect, ovsFac, C_mps, rangeScaleFac);
    
    % create 2D backprojection image of radar scene
    image_set = SAR_2D(rawCollect, sceneSize, display_image,...
                        GPS_override, scan_incriment);
end 












