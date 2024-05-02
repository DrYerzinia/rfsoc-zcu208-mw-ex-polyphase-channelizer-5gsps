%--------------------------------------------------------------------------
% Software Interface Script
% 
% Generated with MATLAB 9.10 (R2021a) and modified for the channelizer
% demonstration

%% Create fpga object
p = xilinxsoc('10.118.183.151', 'root', 'root');
hFPGA = fpga(p)

%% Parameters
fftSize = 512;
% NCO parameters
rfsocChannelizerInit

%% Setup fpga object
% This function configures the "fpga" object with the same interfaces as the generated IP core
hostIO_rfsocChannelizer_setup(hFPGA,fftSize);


%% Collect data and plot
scopeSpectrum = dsp.SpectrumAnalyzer;
scopeSpectrum.InputDomain = 'Frequency';
scopeSpectrum.SampleRate = 5e9;
scopeSpectrum.PlotAsTwoSidedSpectrum = false;
scopeSpectrum.PeakFinder.Enable = true;
scopeSpectrum.ViewType = "Spectrum";


scopeSpectrogram = dsp.SpectrumAnalyzer;
scopeSpectrogram.InputDomain = 'Frequency';
scopeSpectrogram.SampleRate = 5e9;
scopeSpectrogram.PlotAsTwoSidedSpectrum = false;
scopeSpectrogram.PeakFinder.Enable = true;
scopeSpectrogram.ViewType = "Spectrogram";
scopeSpectrogram.AxesScaling = 'Manual';
scopeSpectrogram.ColorLimits = [-95 20];


FrequencyArr = [1:100 99:-1:1]*20; %list of frequencies to jump to with the NCO

%% Data capture loop
for ii=1:150
    writePort(hFPGA, "TriggerCapture", false);
    writePort(hFPGA, "TriggerCapture", true);
    writePort(hFPGA, "TriggerCapture", false);
    
    rd_data = readPort(hFPGA, "S2MM_Data");
    
    idx = mod(ii,length(FrequencyArr))+1;
    nco_tone = FrequencyArr(idx);
    fprintf('Changing NCO Tx tone to %d MHz \n',nco_tone);
    writePort(hFPGA, "AXI4_NCO_incr", uint16(incrScale*nco_tone*1e6) );

    fft_frame = reinterp_stream_data(rd_data);
    spectrum = 20*log10(abs(fft_frame(1:256)));
    
    scopeSpectrum(spectrum);
    scopeSpectrogram(spectrum);  
end

disp('Done frequency sweep');


%% Release hardware resources
release(hFPGA);

%% Helper functions

function fft_frame = reinterp_stream_data(rd_data)
    T = numerictype(1,25,22);    
    re = bitsliceget(rd_data,25,1);
    im = bitsliceget(rd_data,50,26);    
    re = reinterpretcast(re,T);
    im = reinterpretcast(im,T);
    fft_frame = double(complex(re,im));    
end

