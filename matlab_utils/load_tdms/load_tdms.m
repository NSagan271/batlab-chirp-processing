function [chan_volt] = load_tdms (filename, chan_num)



tdms_data = TDMS_getStruct(filename);

if chan_num == 1
    chan_volt = tdms_data.Untitled.Voltage_0.data;
elseif chan_num == 2
    chan_volt = tdms_data.Untitled.Voltage_1.data;
elseif chan_num == 3
    chan_volt = tdms_data.Untitled.Voltage_2.data;
elseif chan_num == 4
    chan_volt = tdms_data.Untitled.Voltage_3.data;
elseif chan_num == 5
    chan_volt = tdms_data.Untitled.Voltage_4.data;
elseif chan_num == 6
    chan_volt = tdms_data.Untitled.Voltage_5.data;
elseif chan_num == 7
    chan_volt = tdms_data.Untitled.Voltage_6.data;
elseif chan_num == 8
    chan_volt = tdms_data.Untitled.Voltage_7.data;
end    
