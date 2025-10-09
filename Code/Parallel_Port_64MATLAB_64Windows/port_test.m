config_io_64
pp_adress = hex2dec('C010'); % COM1:'03F8' LTP1:'C010' LTP3:'0378' 49168
range = 0:255;
input = nan(size(range));

for ii = range+1
outp_64(pp_adress,0)
pause(0.1)
outp_64(pp_adress,ii-1)
input(ii) = inp_64(pp_adress);
end



