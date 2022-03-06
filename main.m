clear all; close all; clc;
ports = serialportlist;
bluetooth = true;
hist_size = 100;
if bluetooth
    I = startsWith(ports, "/dev/tty.DSDTECHH");
    port = ports(I);
    device = serialport(port, 38400);
else
    I = startsWith(ports, "/dev/tty.usbmodem");
    port = ports(I);
    device = serialport(port, 9600);
end
vals_file = 'test.txt';
export_data = false;

data = readline(device);
time = [];

all_names = cell(0);
all_vals = [];

tic;
i = 0;
axeses = gobjects(0);
plots = gobjects(0);
yaxises = gobjects(0);
ytitle = gobjects(0);
colors = {'#444444', '#D95319', '#EDB120', 	'#7E2F8E', '#77AC30','#4DBEEE',...
    '#0072BD', '#D95319', '#EDB120', 	'#7E2F8E', '#77AC30','#4DBEEE'};
status = 1;
while true
    i = i + 1;
    time(i) = toc;
    if device.NumBytesAvailable > 128*4
        %disp('got behind');
        flush(device);
        readline(device);
    end
    data = readline(device);%bmaflush(device);
    data = char(data);    % convert to char array
    data = data(1:end-1); % remove newline charachter
    % Split into n by 2, name then val cell array
    try
        datas = strtrim(split(split(data,','), ':'));
        names = datas(:,1);
        vals = cellfun(@str2num, datas(:,2));
    catch
        continue;
    end
    for j = 1:length(names)
        if ~any(strcmp(all_names,names{j}))
            all_names{end+1} = names{j};
        end
        I = strcmp(all_names,names{j});
        if find(I, 1) > 7
            continue;
        end
        all_vals(i, I) = vals(I);
    end

    if i==1
        fig = figure;
        set(gcf, 'Position',  [300, 600, 800, 400]);
        %plot1 = plot(time, all_vals, 'LineWidth', 2);
        %xlabel('Time (s)');
        %ylabel('Value');
        %legend(all_names{:}, 'Location', 'best');

        for j = 1:length(all_names)
            if (contains(lower(all_names{j}), 'temp'))
                inds_bool = contains(lower(all_names), 'temp');
                inds = find(inds_bool);
                if inds(1) ~= j
                    plots(j) = line(axeses(inds(1)), time, all_vals(:,j), 'Color', colors{j}, 'LineWidth', 2);
                else
                    axeses(end+1) = axes('Color','none');
                    plots(j) = line(axeses(end), time, all_vals(:,j), 'Color', colors{j}, 'LineWidth', 2);
                end
            else
                axeses(end+1) = axes('Color','none');
                plots(j) = line(axeses(end), time, all_vals(:,j), 'Color', colors{j}, 'LineWidth', 2);
            end
            axeses(end).YAxis.Visible = false;
        end
        legend(axeses(1), plots, all_names{:}, 'Location', 'northeast');
        xlabel('Time (s)');
    end
    for j = 1:length(plots)
        plots(j).XData = time(max(length(time)-hist_size,1):end);
        plots(j).YData = all_vals(max(length(time)-hist_size,1):end,j);
    end
    for j = 1:length(axeses)
        axeses(j).XLim = [time(max(i-hist_size, 1)), time(end)+1];
    end
    if i == 1
        delete(findall(gcf,'type','annotation'));
        for j = 1:length(axeses)
            for jj = 1:length(plots)
                if plots(jj).Parent == axeses(j)
                    ind = jj;
                end
            end
            ymax = max(max(plots(ind).YData, (1.5+ind*0.5)*mean(plots(ind).YData)));
            if strcmpi(all_names{ind}, 'DHT Humidity')
                ymax=100;
            end
            if strcmpi(all_names{ind}, 'windDirection')
                ymax=360;
            end
            if strcmpi(all_names{ind}, 'Speed')
                ymax=35000;
            end
            if strcmpi(all_names{ind}, 'Current')
                ymax=500;
            end
            if strcmpi(all_names{ind}, 'DHT Temp')
                ymax=50;
            end
            if strcmpi(all_names{ind}, 'turbineSound')
                ymax=5;
            end
            if isnan(ymax)
                ymax = 0;
            end
            axeses(j).YLim = [0, ymax + 1];
            
            [yaxises(j,:)] = plotYAxis(axeses(j), j, length(axeses), fig, all_names{ind}, colors{ind});
        end
    end
    if mod(i+24, 50) == 0
        %saveas(fig, 'plot.png');
    end
    if mod(i+12, 50) == 0
       %writeNewVals(all_names, all_vals(end, :), vals_file);
    end
    drawnow;
    [pred_current, err] = predictOutputCurrent(all_vals(end,:));
    if pred_current*1.4 < all_vals(end,2)
        disp(['BREAKDOWN! pred: ' num2str(pred_current) ' true: ' num2str(all_vals(end,2))]);
        status = 0;
    else
        disp(['STATUS UP! pred: ' num2str(pred_current) ' true: ' num2str(all_vals(end,2))]);
        status = 1;
    end

    if export_data
         writeNewVals(all_names, all_vals(end, :), vals_file, pred_current, status);
         saveas(fig, 'plot.png');
    end
end

clear device;

function [objs] = plotYAxis(axis, num, max_num, f, name, color)
    objs = gobjects(0);
    ap = axis.Position;
    anotation_loc = [ap(1)*num/max_num, ap(1)*num/max_num, ap(2), ap(4)];
    objs(end+1) = annotation(f, 'line', anotation_loc(1:2), anotation_loc(3:4), 'Color',color, 'LineWidth', 2);
    if contains(lower(name), 'temp')
        name = '^{\circ}C';
    elseif strcmpi(name, 'speed')
        name = 'rpm';
    elseif strcmpi(name, 'current')
        name = 'mA';
    elseif strcmpi(name, 'DHT Humidity')
        name = '%';
    elseif strcmpi(name, 'sound')
        name = 'volts';
    elseif strcmpi(name, 'windDirection')
        name = 'degrees';
    end
    b = annotation(f, 'textarrow', anotation_loc(1:2)-0.01, [anotation_loc(4), anotation_loc(4)]-.04, 'string',name); 
    b.TextRotation = 90;
    b.Color = 'none';
    b.TextColor = 'black';
    b.HorizontalAlignment = 'left';
    b.FontSize = 11;
    objs(end+1) = b;

    num_ticks = 3;
    for i = 1:num_ticks
        per = anotation_loc(3) + ((i-1)/num_ticks)*anotation_loc(4);
        val = axis.YLim(1) + ((i-1)/num_ticks)*axis.YLim(2);
        c = annotation(f, 'textarrow', [anotation_loc(1)-0.01, anotation_loc(1)+0.01], [per,per], 'string',num2str(val,'%02.2f')); 
        c.TextRotation = 90;
        c.Color = 'none';
        c.TextColor = 'black';
        c.FontSize = 10;
        objs(end+1) = c;
    end
end

function writeNewVals(names, vals, file, pred_current, status)
    fid = fopen(file,'w');
    for i = 1:length(names)
        fprintf(fid,'%s,%05.2f\n', names{i}, vals(i));
    end
    fprintf(fid, '%s,%05.2f\n', 'PredictedPower', pred_current(1));
    fprintf(fid, '%s,%05.2f\n', 'Status', status(1));
    fclose(fid);
end