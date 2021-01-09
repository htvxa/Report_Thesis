%% example: creating m-PAM symbol for arbitrary singal generator
str = input('Mau tao vao = ','s')
number_of_PAM_level = 2; % 2: NRZ;  4, 8, 16, ... m: m-PAM
bit_rate = 10000; % bit per second, use to calculate the frequency of the arbitrary singal generator, change if needed
number_of_transmitted_symbol = 400;
 % number of transmitted m-PAMsymbols and pilot symbols, change if needed

symbol_rate = bit_rate / log2(number_of_PAM_level); % symbol per second, replated to number of bits per symbol
sample_rate = 1 * symbol_rate; % sample per symbol, does not implemented in this code

pilot_symbol = [1 0 1 0 0 0 1 0 1]; % pilot sequence to find the received symbols on the oscilloscope, change if needed 

[transmitted_symbol, transmitted_bit] = PAM_symbol_creation(number_of_PAM_level, number_of_transmitted_symbol, pilot_symbol);

generator_period = length(transmitted_symbol) * 1/ sample_rate; % signal generator period in second
generator_frequency = 1 / generator_period; % Adjust the signal generator frequency to this number

visaAddress = 'USB::0x0699::0x0356::C020110::INSTR'; % Use VISA 'Instrument Manager - Properties' to find the USB port address

generator_import(transmitted_symbol, visaAddress, sample_rate, generator_period); % import the transmitted symbol to the signal generator
 
file_name = sprintf('Transmitted_PAM_data_%s', str);
save(file_name); % save all variables for demodulation process

% file_name = sprintf('Transmitted_PAM_symbol_%s.csv', datestr(now,'mm-dd-yyyy_HH-MM'));
% writematrix(transmitted_symbol, file_name); % save transmitted symbols in .csv file to import to ArbExpress program

%% other functions

function [transmitted_symbol, transmitted_bit] = PAM_symbol_creation(number_of_PAM_level, number_of_transmitted_symbol, pilot_symbol)
% This function create a sequence consists of pilot symbols and random PAM
% symbols.
% Input: 
%  number_of_PAM_level: number of m-PAM levels, bit_per_PAM_symbol = log2(PAM_level)
%  number_of_transmitted_symbol: total number of transmitted symbols, including pilot symbols and data symbols
%  pilot_symbol: pilot symbols, select by the user
% Output:
%  transmitted_symbol: transmitted m-PAM symbols, normalized from 0 to 1.
%  transmitted_bit: matrix of trasmitted bits for BER calculation, size = [number of transmitted symbol, bit per symbol]

    number_of_data_symbol = number_of_transmitted_symbol - size(pilot_symbol,2);
    
    random_PAM_symbol = randi(number_of_PAM_level,[1, number_of_data_symbol])-1;
    
    transmitted_bit = de2bi(random_PAM_symbol);
    
    % ramdom m-PAM symbols, with magnitude scaled to 0-1 
    random_PAM_symbol_normalized = random_PAM_symbol / (number_of_PAM_level-1);
    
    pos = strfind(random_PAM_symbol_normalized, pilot_symbol);
    
    % replace data similar to pilot to avoid synchromization error
    pilot_replace = 1 - pilot_symbol;
    if isempty(pos) == 0
        for index_pilot = 1:length(pos)
            tem_pos = pos(index_pilot);
            random_PAM_symbol_normalized(tem_pos:tem_pos+length(pilot)-1) = pilot_replace;
        end
    end

    transmitted_symbol = [pilot_symbol random_PAM_symbol_normalized];
    
end

%%
function generator_import(transmitted_symbol, visaAddress, sample_rate, generator_period)
% This function import a waveform into the signal generator 
% Input: 
%  transmitted_symbol: sample of waveform to be imported
%  visaAddress: TekVISA address of the signal generator,
%  sample_rate: number of sample per second
%  generator_period: length in second of the whole waveform
% Output:

%     visaAddress = 'USB::0x0699::0x0356::C020110::INSTR'; % Use VISA 'Instrument Manager - Properties' to find the USB port address

    timeVec = 0:1/sample_rate:generator_period;
    timeVec = timeVec(1:end-1);
    
    tem_1 = min(transmitted_symbol);
    tem_2 = max(transmitted_symbol);
    tem_4 = transmitted_symbol - (tem_2 - tem_1)/2;
    normalize_transmitted_symbol = tem_4./max(tem_4);
    
    waveform = normalize_transmitted_symbol; % transmitted_symbol is a vector (1, samples of symbol sequence)
    waveform =  round((waveform + 1.0)*8191); % Convert the double values integer values between 0 and 16382 (14 bit vertical resolution)
    waveformLength = length(waveform); % Encode variable 'waveform' into binary waveform data for AFG.

    binblock = zeros(2 * waveformLength, 1);
    binblock(2:2:end) = bitand(waveform, 255);
    binblock(1:2:end) = bitshift(waveform, -8);
    binblock = binblock';

    bytes = num2str(length(binblock)); % Build binary block header
    header = ['#' num2str(length(bytes)) bytes];

    instrreset; % Clear MATLAB workspace of any previous instrument connections

    myFgen = visa('TEK', visaAddress); % Create a VISA object

    myFgen.OutputBufferSize = length(binblock) * 8; % OutputBufferSize = number of data points * datatype size in bytes

    myFgen.ByteOrder = 'littleEndian'; % Set ByteOrder to match the requirement of the instrument

    fopen(myFgen); % Open the connection to the function generator

    % fprintf: write text format data, fwrite: write binary format data
    fprintf(myFgen, '*RST'); % Reset the function generator to a know state
    fprintf(myFgen, '*CLS;'); 
    
    fprintf(myFgen, ['DATA:DEF EMEM, ' num2str(length(timeVec)) ';']); % Resets the contents of edit memory and define the length of signal 1001 
    fwrite(myFgen, [':TRACE EMEM, ' header binblock ';'], 'uint8'); % Transfer the custom waveform from MATLAB to edit memory of instrument
    fprintf(myFgen, 'SOUR1:FUNC EMEM'); % Associate the waveform in edit memory to channel 1
    fprintf(myFgen, 'SOUR2:FUNC EMEM');

    fprintf(myFgen, 'SOUR1:FREQ:FIXed 25Hz'); % Set the output frequency to 1 Hz to avoid further upconverted by AFG
fprintf(myFgen, 'SOUR2:FREQ:FIXed 25Hz');
    fprintf(myFgen,'source1:voltage:level:immediate:low 0V');        %Set channel 2 low level at 0V
    fprintf(myFgen,'source1:voltage:level:immediate:high 3V'); %Set channel 2 high level at 3V
fprintf(myFgen,'source2:voltage:level:immediate:low 0V');
fprintf(myFgen,'source2:voltage:level:immediate:high 3V');
%     fprintf(myFgen, ':OUTP1 ON'); % Turn on Channel 1 output

    fclose(myFgen); % Clean up - close the connection and clear the object
    clear myFgen;

end