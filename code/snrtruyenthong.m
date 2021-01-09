recieved_file_name = sprintf('./dataset/extracted_recieved_symbol_40000_500_1.mat');
load(recieved_file_name,'extracted_received_symbol');
x1=extracted_received_symbol;
transmitted_file_name = sprintf('./dataset/Transmitted_PAM_data_40000_500_1.mat');
load(transmitted_file_name,'transmitted_symbol');
a1=transmitted_symbol;
low = x1(:, a1 == 1);
high = x1(:, a1 == 0 );
[row,~] = size(low);
nlow = reshape(low,[1 row*length(low)]);
nhigh = reshape(high,[1 row*length(high)]);
ber=1/2*erfc(sqrt(SNR/2))
x=mean(extracted_received_symbol);
a=(x-min(x))/(max(x)-min(x));
plot(a,'LineWidth',2,...
'MarkerSize',10,...
'MarkerEdgeColor','b')
hold on
%plot((transmitted_symbol-1)*-1)


