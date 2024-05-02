%% Initialize parameters
%
% % For DAC NCO definition

% NCO parameters
Fo = 200.7e6;  % tone freq
% Ts = 1e-3; % sample time
Ts = 1/5e9; % ADC running at 62.5
N = 14;    % accum WL

Fs = 1/Ts;      
incrScale = (2^N)/Fs;
incr = round(Fo*incrScale/4); % phase increment
