% speed
%current
% thermresistor temp
% dht temp
% dht humidity
% wind direction
% turbine sound



clc
clear
dataRegress = importdata('tubineData.csv')
temp = dataRegress(:,1);
% current, speed, thermresistor temp, dht temp, dht humidity, wind direction, turbine sound

dataRegress(:,1) = dataRegress(:,2);
dataRegress(:,2) = temp;
dataRegress;

%normalizing data
dataRegress(:,1)=dataRegress(:,1)./max(dataRegress(:,1));
dataRegress(:,2)=dataRegress(:,2)./max(dataRegress(:,2));
dataRegress(:,3)=dataRegress(:,3)./max(dataRegress(:,3));
dataRegress(:,4)=dataRegress(:,4)./max(dataRegress(:,4));
dataRegress(:,5)=dataRegress(:,5)./max(dataRegress(:,5));
dataRegress(:,6)=dataRegress(:,6)./max(dataRegress(:,6));
dataRegress(:,7)=dataRegress(:,7)./max(dataRegress(:,7));


turbineInputs = dataRegress(:,2:7); %input columns
turbineInputs(:,5) = []; %delete wind data
outputPower = dataRegress(:,1);

X = turbineInputs;
Y = outputPower;
X = [ones(size(X(:,1))) X]; %add a column of ones
B = regress(Y, X);

b0 = B(1)
b1 = B(2)
b2 = B(3)
b3 = B(4)
b4 = B(5)
b5 = B(6)


currentOut_predict = b0+b1*turbineInputs(:,1)+b2*turbineInputs(:,2)+b3*turbineInputs(:,3)+b4*turbineInputs(:,4)+b5*turbineInputs(:,5); %not using wind

differentPoints = (abs(currentOut_predict-Y) >= .2); %setting thresh hold

error = Y-X*B;

MSE = mean(error.^2);

figure(1)
hold on
scatter(Y, currentOut_predict)
%scatter(X(:,2), Y)
scatter(Y(differentPoints), currentOut_predict(differentPoints), '+') %plotting points that are different
xlabel('true current')
ylabel('current output prediction')
hold off

