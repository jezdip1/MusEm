config_io_32
pp_adress = hex2dec('C010'); % COM1:'03F8' LTP1:'C010' LTP3:'0378' 49168
range = 0:255;
input = nan(size(range));

for ii = range+1
outp_32(pp_adress,dec2bin(0))
pause(0.05)
outp_32(pp_adress,dec2bin(ii-1))
input(ii) = inp_32(pp_adress);
end

dec2bin(49)


