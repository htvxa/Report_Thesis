%% example: extracting m-PAM symbol from oscilloscope .csv file

% import transmitted and received data
transmitted_file_name = '.\Transmitted_PAM_data_25.mat'; % transmitted data for generator
load(transmitted_file_name); % import: symbol_rate, transmitted_symbol

received_file_name = '.\oscilloscope_25.mat'; % received signal from oscilloscope in Matlab format
load(received_file_name); % import: symbol_rate, transmitted_symbol
time_vector = Y.'; % extract time values
voltage_vector = X.'; % extract voltage values

% received_file_name2 = '.\F0001CH1.CSV'; % received signal from oscilloscope in csv format
% data_table = readtable(received_file_name2); % import: entire table in received file
% received_data = data_table{:,[4 5]}; % convert table format to matrix format
% time_vector = received_data(:,1); % extract time values
% voltage_vector = received_data(:,2); % extract voltage values

number_of_symbol = symbol_rate * (max(time_vector)-min(time_vector)); % number of symbols inside received vector
sample_per_symbol = round(size(time_vector, 1) / number_of_symbol); % number of samples per symbol

transmitted_vector = kron(transmitted_symbol, ones(1, sample_per_symbol))'; % create transmitted vector with the same samples per symbol

% find colleration between transmitted and received vectors to find the location of received symbols
transmitted_vector_length = size(transmitted_vector,1);
received_vector_length = size(voltage_vector,1);
length_diff = received_vector_length - transmitted_vector_length; % received vector is at least equal to transmitted vector

correlation_value = zeros(length_diff+1,1);
for index_shifting = 1 : length_diff+1
    shifted_received_vector = voltage_vector(index_shifting : index_shifting + transmitted_vector_length -1);
    tem_1 = corrcoef(transmitted_vector, shifted_received_vector);
    correlation_value(index_shifting, 1) = tem_1(1,2);
end

[~, sequence_index] = max(correlation_value); % index of the first symbol in the transmitted sequence inside the recieved vector

% extracting received symbol, save as a maxtrix extracted_received_symbol, where each column is a symbol
no_of_transmitted_symbol = length(transmitted_symbol);
extracted_received_sequence = voltage_vector(sequence_index : sequence_index + no_of_transmitted_symbol * sample_per_symbol - 1);
extracted_received_symbol = reshape(extracted_received_sequence, [sample_per_symbol , no_of_transmitted_symbol]);

file_name = sprintf('extracted_recieved_symbol_%s', str);
save(file_name);
