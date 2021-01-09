%TEST2 Code for communicating with an instrument. 
%  
%   This is the machine generated representation of an instrument control 
%   session using a device object. The instrument control session comprises  
%   all the steps you are likely to take when communicating with your  
%   instrument. These steps are:
%       
%       1. Create a device object   
%       2. Connect to the instrument 
%       3. Configure properties 
%       4. Invoke functions 
%       5. Disconnect from the instrument 
%  
%   To run the instrument control session, type the name of the file,
%   TEST2, at the MATLAB command prompt.
% 
%   The file, TEST2.M must be on your MATLAB PATH. For additional information
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command
%   prompt.
%
%   Example:
%       TEST2;
%
%   See also ICDEVICE.
%

%   Creation time: 11-Apr-2019 11:39:48 
for i=10000:10001

% Create a VISA-USB object.
% check the USB address using VISA program: click on VISA icon -> Instrument manager
interfaceObj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB::0x0699::0x03A6::C032080::INSTR', 'Tag', '');

% interfaceObj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB::0x0699::0x0356::C020110::INSTR', 'Tag', '');


% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(interfaceObj)
%    interfaceObj = visa('TEK', 'USB::0x0699::0x0356::C020110::INSTR');

      interfaceObj = visa('TEK','USB::0x0699::0x03A6::C032080::INSTR');

else
    fclose(interfaceObj);
    interfaceObj = interfaceObj(1);
end

% Create a device object. 
deviceObj = icdevice('tektronix_tds2024.mdd', interfaceObj);

% Connect device object to hardware.
connect(deviceObj);

% Execute device object function(s).
groupObj = get(deviceObj, 'Waveform');
[X,Y,YUNIT,XUNIT] = invoke(groupObj, 'readwaveform', 'Channel1');

% Delete objects.
delete([deviceObj interfaceObj]);

%file_name = sprintf('oscilloscope_%s', datestr(now,'mm-dd-yyyy_HH-MM'));
file_name = sprintf('oscilloscope_%s', str);
save(file_name, 'X','Y','YUNIT','XUNIT');

sampling= repmat(X,1,1);
to_column= sampling(:);
filename = ['Test',num2str(i),'.csv'];
% csvwrite(filename,to_column);

end
