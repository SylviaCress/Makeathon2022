function [currents,error] = predictOutputCurrent(all_vals)
    data = all_vals;
    % swap speed and current
    data(:,1) = all_vals(:,2);
    data(:,2) = all_vals(:,1);

    data = data(:, 2:end);
    % training normalization values:
    n = [39200000       29890       23600       54000      360000        2580] ./ 1000;
    %normalizing data
    data = data ./ n;

    data(:,5) = []; %delete wind data
    % if sensor isnt working
    if any(isnan(data(:,3:4)))
        data(:,2) = 0.9869;
        data(:,3) = 0.9649;
        data(:,4) = 0.9837;
        data(:,5) = 0.9675;
    end
    % prepare input var
    X = [ones(size(data,1), 1) data];

    B =[ 12.7438
    1.1483
    0.9887
    2.0725
  -17.7516
    2.3316];
    
    Y = X * B;

    % traning normalization for current
    ny = 348860/1000;
    error = mean((all_vals(:,2)/ny - Y).^2);
    currents = Y * ny;
end