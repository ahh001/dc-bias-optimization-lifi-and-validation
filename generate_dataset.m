% This script generates the dataset used for training the ML models
% in the proposed DCO-OFDM Li-Fi system.
clc
clear all;
%close all;
format short;

% Definition of parameters.
M = input('Enter the value of M ');                      % Size of signal constellation

k = log2(M);                                             % Number of bits per symbol
N =1024; %input('Enter the number of subcarriers ');           % Number of bits to process
% N =256;

cp_percent = 0;                                         % Length of Cyclic Prefix in percentage
Nbits = 200000; % input('Enter the number of bits to process ');
bias = 0.7; %input('Enter bias level ');
PL =0; % input('Enter 1 for pathloss ');

dimming = 1; % input('The value of dimming within 1  ');
ppl = 0; %input('Enter 1 if it is a peak power limited channel, else Enter 0 ');

Sum_Equalizer = 0;
No_Equalizer = 0; %input('Enter 0 for no equalizers, type 1 for equalizers '); % With or without equalizers
N_Loop = 10 ;


d = 3;          % 0.3 Meter
f = 400*1e12;         % 1 Tera Hz
pathloss_dB = 20*log10(d) + 20*log10(f) - 147.55;

if PL==1
att = power(10, 0.1*pathloss_dB);
else
att = 1;
end




% Expression of SNR in terms of Eb/No, k and oversampling rate
%EbNo = 30;
EbNo = [0:5:50];            % The range of Eb/No in dB
EbNoLinear = power(10, 0.1*EbNo);
SNR = EbNo + 10*log10(k);   % For complex input signals such as M-QAM this equation is valid
snrLen = length(SNR);       % No of snr or EbNo points considered for the BER vs EbNo  graph plot

%% Creation of Modulator and Demodulator
hMod = modem.qammod(M);         % Create a M-QAM modulator
hMod.InputType = 'Bit';         % Accept bits as inputs
hMod.SymbolOrder = 'Gray';      % Accept Gray coded inputs
hDemod = modem.qamdemod(hMod);  % Create a M-QAM demodulator


for j=1:snrLen

  Equalizer = 0;
  Sum_Equalizer =0;
  Avg_Equalizer =0;


  TotalError = 0;
  Totalbits =0;
  err = 0;
  x = 0;

  while (Totalbits < Nbits)

x = x+1;


N11 = N/2;

% data = randi([0 1], k, N11); % Random binary data of siz (N*k) by N
data = randi([0 1], N11, k);

%% Modulation using M-QAM.
Mod_data = modulate(hMod, data);

[ col_mod] = length(Mod_data);


%%%%%%%%%%%%% Hermitian Computation%%%%%%%%%%%%%%

Mod_data(:,1)=0;              % Forcing the first column to be zero

for kcol=2:N11

        Hermi_part(1,kcol)=Mod_data(1,N11-kcol+2);
end

Hermi_part(:,1) = Mod_data(:,1);             % Forcing the first column to be zero
Hermitian_data=[Mod_data conj(Hermi_part)];  % Formation of the Hermitian Matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ifft_data=ifft(Hermitian_data) ;   % Computing 2D IFFT


ofdm = ifft_data;                    % Denoting the resultant signal as the OFDM signal to be transmitted
[ c_ofdm]=length(ofdm);               % Findinig the rows and columns of the OFDM signal


%%%%%%%%%%%%%%%%%%%%%%%%% DC-biasing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dc_level = bias*std(ofdm);
dc_component = ones(1, c_ofdm) * dc_level; % Generation of a DC voltage of amplitude equal to "dc_level"
dc_biased_ofdm = ofdm + dc_component;           % Addition of the DC level to the OFDM component

%%%%%%%%%%%%%%%%%%%%%%%%% End of DC-biasing %%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%% Clipping at zero %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for    jBias = 1: c_ofdm

    if dc_biased_ofdm( jBias ) >0
        dc_clip_ofdm( jBias) = dc_biased_ofdm( jBias);
    else
        dc_clip_ofdm( jBias) = 0;
    end

end


  norm_factor = 1;
  
  ofdm_norm = dc_clip_ofdm*norm_factor;


%%%%%%%%%%%%% End of clipping at zero %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of Transmission  Side %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






%%%%%%%%%%%%%%%%%%%%%% Start of Receiving Section %%%%%%%%%%%%%%%%%%%%%%%%
    for Iter = 1:N_Loop
%%%%%%%%%%%%% Addition of AWGN noise  %%%%%%%%%%%%%%%%%%%%%%%%%

     Noiseg=  randn(1, c_ofdm );

     signal_voltage = abs(ofdm_norm/att) ;                   % Finding the signal voltage in the constellation
 %    signal_voltage = abs(dc_clip_ofdm/att) ;                   % Finding the signal voltage in the constellation
     signal_power = power(signal_voltage,2);        % Finding the signal power in the constellation

     if ppl == 1
     avg_power =  max(signal_power);          % Finding the peak signal power in the constellation
     else
     avg_power =  mean(signal_power) ;        % Finding the average signal power in the constellation
     end

     signal_dB = 10* log10(avg_power);              % Finding the signal power in dB
     nVar_dB(j) = signal_dB - SNR(j);               % Finding the noise power/variance in dB

     nVar(j) = power(10, 0.1*nVar_dB(j) );          % noise variance/power in linear scale
     nSD(j) =  sqrt(nVar(j) );                       % noise voltage in linear scale

     noisy_signal_norm = (dimming*ofdm_norm)/att + Noiseg.*nSD(j);        % received signal in terms of ofdm signal and noise
     noisy_signal = noisy_signal_norm/norm_factor;

     %%%%%%%%%%%%%%%% End of Noise Addition %%%%%%%%%%%%%%%%%%


     %%%%%%%%%%%%% Start of optical Power %%%%%%%%%%%%%%%%%%%%%%

   avg_opt_power = mean(mean(signal_voltage));
   normalizationfactor = 1/avg_opt_power;

   normalizedopticalpower = mean(signal_voltage*normalizationfactor);
   opt_signal_dB = 10*log10(normalizedopticalpower);
   EbNo_opt = opt_signal_dB - 10*log10(k) - nVar_dB(j); %%%%% Optical EbNo %%%%%

   normalizedelectpower = mean((signal_voltage*normalizationfactor).^2  );
   elct_signal_dB = 10*log10(normalizedelectpower);
   EbNo_elect = elct_signal_dB- 10*log10(k) - nVar_dB(j); %%%%% Electrical EbNo %%%%%

   %% The difference between opt and elect EbNo for the signal received %%%%% %%%
   Conversion(j) = EbNo_elect - EbNo_opt;  %%% Difference between Opt and Elect EbNo %%%%
                          %%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%% End of optical power %%%%%%%%%%%%%%%




  received_data=fft2(noisy_signal);    % Comuting the FFT2


  %%%%%%%%%%%%%%%%%%%%%%%%%%% start of spatial frequency domain equalization %%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%% For Equalization %%%%%%%%%%%%%%%%%%%
%
   Equalizer = Hermitian_data./received_data; %%%%%%% For equalization (each sp. frequency element) %%%%%%%
   Sum_Equalizer = Sum_Equalizer + Equalizer;
%
   end %End of iteration loop for equalization%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   %%%%%%% For equalization (Averaging over multiple iterations) %%%%%%%

 if  No_Equalizer == 1
   Avg_Equalizer = Sum_Equalizer./(N_Loop );

   received_data2 = received_data.*Avg_Equalizer;
 end
%
  %%%%%% end of
  %%%%%% equalization%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    if  No_Equalizer == 0
     received_data_all = received_data/norm_factor;  %%%%%%%%%%%%%% For the case of No Equalization %%%%%%%%%%%%%%%%%%%%%%%%
    elseif No_Equalizer == 1
        received_data_all = received_data2; %%%%%%%%%%%%%% For the case of Equalization %%%%%%%%%%%%%%%%%%%%%%%%
    end


     % Initialization for the next loop %%%%%

     Equalizer = 0;
     Sum_Equalizer = 0;
     Avg_Equalizer = 0;

     %%%% End of initialization for the next loop %%%%




   demod_data_double = demodulate(hDemod,received_data_all);   % Computing the  QAM demodulation
   demod_data_single = demod_data_double(:, (1:N11) );    %%%% Removing the Hermitian Part %%%%%%%%%


  data1=data( :,(2:N11) ) ;                   % Considering the data without the first column
  demod_data1 = demod_data_single( :, (2:N11) ); % Considering the detected data without the first column


 %% Computing BER
 [err ber] = biterr(data1, demod_data1); % Finding the bit error "err" and bit error rate "ber"

  TotalError = TotalError + err;

Totalbits = Totalbits + N11* k;  % Summation of bits


end % End of while loop

mean_ofdm = mean(ofdm)
minimum = min(ofdm)
maximum = max(ofdm)
std_value = std(ofdm)
ber1(j) = TotalError/Totalbits
end % End of snr loop


zdBs = [6:0.05:20];
N_zdBs = length(zdBs);
ll = N_zdBs;

for xi = 1:ll

       CCDF_simulated1(xi) = sum(papr1>zdBs(xi))/ll;
end


 %%%%%% Calculation of optical SNR %%%%%%%%%%%%%%%
 EbNoOpt = EbNo - Conversion; %% Opt EbNo is eqaul to the elect EbNo minus the conversion factor %%%%
 %%%%%% End of optical SNR %%%%%%%%



%
% %%%%%This figure will show the "BER vs EbNo"  curve for M-QAM
figure(1)
%semilogy(EbNo, ber1,'*r');
semilogy(EbNoOpt, ber1,'r');
set(gca,'Fontname','Times New Roman');
set(gca,'FontSize',24);
%xlabel('\itE_b_(_e_l_e_c_)/N_o \rmin dB');
xlabel('\itE_b_(_o_p_t_)/N_o \rmin dB');
ylabel('BER');
axis([ 0 50, 10e-4 1 ]);
set(gca,'FontSize',18);

figure(2);
semilogy(zdBs(1:50:end),CCDF_simulated1(1:50:end),'-rs','MarkerEdgeColor','r','MarkerSize',12);
grid on;

axis([zdBs([1 end]) 1e-4 100]);  title('CCDF plot of 16 QAM  DCO-OFDM vs. 16 QAM Flip-OFDM');
xlabel('PAPR_0 (dB)'); ylabel('CCDF = Probability ( PAPR > PAPR_0 )');

hold on;
