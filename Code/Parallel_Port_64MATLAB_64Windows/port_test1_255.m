% addpath('A:\matlab_toolboxes\Parallel_Port\Parallel_Port_64MATLAB_64Windows')
config_io_64
pp_adress = hex2dec('C050'); % Gschasi: COM1:'03F8' LTP1:'C010' LTP2:'C050' LTP3:'0378' 49168
                             % Stimulation PC: LTP3: 'E880'
while 1
for ii = 1:255
    outp_64(pp_adress,ii)
    pause(10*10^-6)% Pause 10µs, else software might miss trigger
    outp_64(pp_adress,0)
    disp(num2str(ii))
    pause(0.1)
end
end