oscilloscope_file_name = sprintf('./dataset/oscilloscope_%s.mat',str) ; % received signal from oscilloscope in Matlab format
load(oscilloscope_file_name); % import: symbol_rate, transmitted_symbol
time_vector = Y.';
voltage_vector = X.'; % extract voltage values
no_of_transmitted_symbol = length(transmitted_symbol);
number_of_symbol = round(symbol_rate * (max(time_vector)-min(time_vector))); % number of symbols inside received vector
sample_per_symbol = round(size(time_vector, 1) / number_of_symbol); % number of samples per symbol
eq = number_of_symbol*sample_per_symbol;
x=1:1:2500;
xq = 1:2500/eq:2500;
voltage_vector = interp1(x,voltage_vector',xq)';
transmitted_vector = kron(transmitted_symbol, ones(1, sample_per_symbol))'; % create transmitted vector with the same samples per symbol
transmitted_vector = (transmitted_vector-1)*-1;
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
extracted_received_sequence = voltage_vector(sequence_index : sequence_index + no_of_transmitted_symbol * sample_per_symbol - 1);
extracted_received_symbol = reshape(extracted_received_sequence, [sample_per_symbol , no_of_transmitted_symbol]);
file_name = sprintf('./dataset/extracted_recieved_symbol_%s',str);
save(file_name);

