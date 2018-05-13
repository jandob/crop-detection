close all; clear all
rng(42)
%% configuration
basepathImages = '../results/';
basepathData = '../data/';

% set to false to quickly run the evaluation without recalculating landmarks (only does error calculation, plots etc.) 
global recalculateApproach recalculateMeanshift
recalculateApproach = true;
recalculateMeanshift = true;

% set to true to be able to edit manual landmarks
updateLandmarksManual = false;

% plot figure titles; set this to false to get the figures for publication
plotFigureTitles = false;

%% datasets with parameter definitions
days = [...
    struct('args', {{... % datasets from day 1
                'searchRadius', 0.05, 'alpha', 0.02, 't', 10, 'sfeSearchRadius', ...
                0.1, 'distanceMetric', 'correlation', 'minTFDist', 0.1, 'nSample', 8000 ...
           }}, 'datasets', [ ...
                "bonirob_2016-05-23-10-37-10_0.bag_offset-120.mat", ...
                "bonirob_2016-05-23-10-37-10_0.bag_offset-140.mat", ...
                "bonirob_2016-05-23-10-37-10_0.bag_offset-160.mat", ...
                "bonirob_2016-05-23-10-37-10_0.bag_offset-180.mat" ...
           ]...
    )...
    struct('args', {{... % datasets from day 2
                'searchRadius', 0.05, 'alpha', 0.02, 't', 10, 'sfeSearchRadius', ...
                0.1, 'distanceMetric', 'correlation', 'minTFDist', 0.1,'nSample', 8000
           }}, 'datasets', [ ...
                "bonirob_2016-05-31-15-10-46_6.bag_offset-20.mat", ...
                "bonirob_2016-05-31-15-10-46_6.bag_offset-40.mat", ...
                "bonirob_2016-05-31-15-10-46_6.bag_offset-60.mat", ...
                "bonirob_2016-05-31-15-10-46_6.bag_offset-100.mat" ...
           ]...
    )...
    struct('args', {{... % datasets from day 3
                'searchRadius', 0.05, 'alpha', 0.02, 't', 10, 'sfeSearchRadius', ...
                0.1, 'distanceMetric', 'correlation', 'minTFDist', 0.1,'nSample', 8000
           }}, 'datasets', [ ...
                "bonirob_2016-06-09-12-05-11_7.bag_offset-0.mat", ...
                "bonirob_2016-06-09-12-05-11_7.bag_offset-20.mat", ...
                "bonirob_2016-06-09-12-05-11_7.bag_offset-100.mat", ...
                "bonirob_2016-06-09-12-05-11_7.bag_offset-140.mat", ...
           ]...
    )
];
nDays = length(days); 

%% plot examples from all days
for day = 1:nDays
    h = figure(day+798);
    datasets = days(day).datasets;
    data = load(strcat(basepathData, datasets{2}));
    pNorm = geometry.normalizePointCloud(data.mapFull);
    plot.pc(pNorm(:,1:2), data.mapColorFull, 'markersize', 20);
    ax = gca;
    ax.FontSize = 5;
    ax.XLim = [-3 3];
    ax.YLim = [-0.3 0.3];
    set(gcf, 'Position', [200.6040  713.8713  691.0099  120.7129])
    print(h, '-dpng', [basepathImages 'example_day' num2str(day) '.png'], '-r300')
end

%% do the evaluation for each error_threshold
for threshold_error = [0.01 0.02 0.04]

    %%
    for day = 1:nDays 
        %% evaluate each day individually
        datasets = days(day).datasets;
        
        % combine individual datasets for each day
        dayCombined.landmarksMeanshift = [];
        dayCombined.landmarksMeanshiftScores = [];
        dayCombined.landmarksApproach = [];
        dayCombined.landmarkScores = [];
        dayCombined.landmarksManual = [];
        dayCombined.map = [];
        dayCombined.mapColor = [];

        for j = 1:numel(datasets)
            datasetPath = [basepathData datasets{j}];
            data = load(datasetPath);
            %% plant soil segmentation 
            if ~isfield(data, 'map')
                [segmentation, extractorPolygon1, extractorPolygon2] = tools.greenextract(data.mapFull, data.mapColorFull);
                data.map = data.mapFull(segmentation,:);
                data.mapColor = data.mapColorFull(segmentation,:);
                save(datasetPath, '-struct', 'data', 'map', 'mapColor','-append')
            end
            %% manual landmarks
            if ~isfield(data, 'landmarksManual')
                h = figure(733);
                plot.pc(data.map, data.mapColor, 'markerSize', 20)
                datacursormode on
                dcm_obj = datacursormode(gcf);
                waitfor(msgbox('Click ok when finished labeling plants!'));
                cursor_info = getCursorInfo(dcm_obj);
                data.landmarksManual = vertcat(cursor_info.Position);
                if size(data.landmarksManual,2) == 3 
                    data.landmarksManual = data.landmarksManual(:,1:2);
                end
                save(datasetPath, '-struct', 'data', 'landmarksManual','-append')
            end
            if updateLandmarksManual
                figure(733);
                h = plot.pc(data.map(:,1:2), data.mapColor, 'markerSize', 20);
                datacursormode on
                dcm_obj = datacursormode(gcf);
                hTarget = handle(h);
                xdata = get(hTarget,'XData');
                ydata = get(hTarget,'YData');
                idx = knnsearch([xdata' ydata'], data.landmarksManual);

                for tipIdx = 1:size(data.landmarksManual, 1)
                    hDatatip = dcm_obj.createDatatip(hTarget);
                    propPointDataCursor = get(hDatatip,'Cursor'); 
                    % Move the datatip 
                    propPointDataCursor.DataIndex = idx(tipIdx); 
                    pos = [xdata(idx(tipIdx)) ydata(idx(tipIdx))];
                    propPointDataCursor.Position = pos;
                    set(hDatatip,'Position',pos)
                end
                waitfor(msgbox('Click ok when finished labeling plants!'));
                cursor_info = getCursorInfo(dcm_obj);
                data.landmarksManual = vertcat(cursor_info.Position);
                if size(data.landmarksManual,2) == 3 
                    data.landmarksManual = data.landmarksManual(:,1:2);
                end
                save(datasetPath, '-struct', 'data', 'landmarksManual','-append')
            end
            %% tf density approach on whole map
            if recalculateApproach && isfield(data, 'landmarksApproach')
                data = rmfield(data, 'landmarksApproach');
            end
            if ~isfield(data, 'landmarksApproach')
                [data.landmarksApproach, data.landmarkScores] = optimization.detectPlants(data.map, days(day).args{:});
                save(datasetPath, '-struct', 'data', 'landmarksApproach', 'landmarkScores', '-append')
            end
            %% mean shift baseline
            if recalculateMeanshift && isfield(data, 'landmarksMeanshift')
                data = rmfield(data, 'landmarksMeanshift');
            end
            if ~isfield(data, 'landmarksMeanshift')
                [data.landmarksMeanshift,~,clusterSizes] = clustering.meanshift(data.map', days(day).args{12});
                data.landmarksMeanshiftScores = vector.normalize(cellfun('length',clusterSizes));
                save(datasetPath, '-struct', 'data', 'landmarksMeanshift', 'landmarksMeanshiftScores', '-append')
            end

            %% combine 
            dayCombined.landmarksMeanshift = [dayCombined.landmarksMeanshift; data.landmarksMeanshift];
            dayCombined.landmarksMeanshiftScores = [dayCombined.landmarksMeanshiftScores; data.landmarksMeanshiftScores];
            dayCombined.landmarksApproach = [dayCombined.landmarksApproach; data.landmarksApproach];
            dayCombined.landmarkScores = [dayCombined.landmarkScores; data.landmarkScores]; 
            dayCombined.landmarksManual = [dayCombined.landmarksManual; data.landmarksManual]; 
            dayCombined.map = [dayCombined.map; data.map];
            dayCombined.mapColor = [dayCombined.mapColor; data.mapColor];
        end
        landmarksMeanshift = dayCombined.landmarksMeanshift;
        landmarksMeanshiftScores = dayCombined.landmarksMeanshiftScores;
        landmarksApproach = dayCombined.landmarksApproach;
        landmarkScores = dayCombined.landmarkScores;
        landmarksManual = dayCombined.landmarksManual;
        fprintf('day %d: %d labels\n', day,size(landmarksManual,1))

        %% calculate errors
        [errorMeanshiftVecidx, errorMeanshift] = knnsearch(landmarksManual, landmarksMeanshift(:,1:2));
        [errorApproachVecidx, errorApproach] = knnsearch(landmarksManual, landmarksApproach(:,1:2));
        errorMeanshiftVec = landmarksManual(errorMeanshiftVecidx,:) - landmarksMeanshift(:,1:2);
        errorApproachVec = landmarksManual(errorApproachVecidx,:) - landmarksApproach(:,1:2);

        %% eval approach
        figure(day); view(2)
        thresholds = [];
        rms = [];
        sizes =  [];
        for step = 1:100
            landmarksApproachSel = landmarksApproach(landmarkScores > ((step-1)/100),:);
            [errorApproachVecidx, errorApproach] = knnsearch(landmarksManual, landmarksApproachSel(:,1:2));
            sizes(step) = size(landmarksApproachSel,1);
            thresholds(step) =  step/100;
            rms(step) = sqrt(mean(errorApproach.^2));
            if thresholds(step) == 0.9
               fprintf('day %d, score threshold 0.9, rms %f, detection ratio %f\n', day, rms(step), sizes(step)/size(landmarksManual,1))
            end
        end
        yyaxis left
        plot(thresholds,1000*rms, '--b')
        xlabel('score threshold')
        ylabel('RMS error [mm] (dashed line)')
        hold on
        yyaxis right
        plot(thresholds,sizes,'r')
        hline = refline([0 size(landmarksManual,1)]);
        hline.LineStyle= '-.';
        hline.Color = 'r';
        ylabel('Nr. of detected landmarks')
        legend(hline, 'Nr. of landmarks (ground truth)')
        hold off
        ax_msc = gca;
        ax_msc.FontSize = 16;

        %% approach precision recall
        precision = [];
        recall = [];
        for threshold_score = 0:0.01:1
            %% For each SEP find nearest estimate (with score > threshold)
            tpFpIdx = landmarkScores > threshold_score; 
            tpFpPos = landmarksApproach(tpFpIdx,1:2);
            nextSEP = rangesearch(landmarksManual, tpFpPos, threshold_error);
            tpIdx = cellfun('length',nextSEP) >= 1;
            tp = sum(tpIdx);
            tpfp = sum(tpFpIdx);
            tpfn = length(landmarksManual);
            precision = [precision; tp/(tpfp)];
            recall = [recall; tp/(tpfn)];
        end
        figure(21388+threshold_error*1000)
        xlabel("Recall")
        ylabel("Precision")
        if day > 1
            hold on
            plot(recall, precision)
            hold off
        else
            plot(recall, precision)
        end

       %% eval meanshift
       landmarkScores = landmarksMeanshiftScores;
       landmarksApproach = landmarksMeanshift;
        figure(day+20); view(2)
        thresholds = [];
        rms = [];
        sizes =  [];
        for step = 1:100
            landmarksApproachSel = landmarksApproach(landmarkScores > ((step-1)/100),:);
            [errorApproachVecidx, errorApproach] = knnsearch(landmarksManual, landmarksApproachSel(:,1:2));
            sizes(step) = size(landmarksApproachSel,1);
            thresholds(step) =  step/100;
            rms(step) = sqrt(mean(errorApproach.^2));
        end
        yyaxis left
        plot(thresholds,1000*rms, '--b')
        xlabel('score threshold')
        ylabel('RMS error [mm] (dashed line)')
        hold on
        yyaxis right
        plot(thresholds,sizes,'r')
        hline = refline([0 size(landmarksManual,1)]);
        hline.LineStyle= '-.';
        hline.Color = 'r';
        ylabel('Nr. of detected landmarks')
        legend(hline, 'Nr. of landmarks (ground truth)')
        hold off
        ax_approach = gca;
        ax_approach.FontSize = 16;
        
        %% synchronize rms error plot axes
        lim = [ax_msc.YAxis(1).Limits; ax_approach.YAxis(1).Limits];
        ax_msc.YAxis(1).Limits = [0 max(lim(:,2))];
        ax_approach.YAxis(1).Limits = [0 max(lim(:,2))];
        
        lim = [ax_msc.YAxis(2).Limits; ax_approach.YAxis(2).Limits];
        ax_msc.YAxis(2).Limits = [0 max(lim(:,2))];
        ax_approach.YAxis(2).Limits = [0 max(lim(:,2))];
        
        figure(day)
        if plotFigureTitles, title(['Day ' num2str(day) ' Approach']), end
        saveas(figure(day),[basepathImages 'evaluation_day_' num2str(day) '.png'])
        figure(day+20)
        if plotFigureTitles, title(['Day ' num2str(day) ' MSC']), end
        saveas(figure(day+20),[basepathImages 'evaluation_msc_day_' num2str(day) '.png'])
   
        %% meanshift precision recall
        precision = [];
        recall = [];
        for threshold_score = 0:0.01:1
            %% For each SEP find nearest estimate (with score > threshold)
            tpFpIdx = landmarkScores > threshold_score; 
            tpFpPos = landmarksApproach(tpFpIdx,1:2);
            nextSEP = rangesearch(landmarksManual, tpFpPos, threshold_error);
            tpIdx = cellfun('length',nextSEP) >= 1;
            tp = sum(tpIdx);
            tpfp = sum(tpFpIdx);
            tpfn = length(landmarksManual);
            precision = [precision; tp/(tpfp)];
            recall = [recall; tp/(tpfn)];
        end
        figure(21389+threshold_error*1000)
        xlabel("Recall")
        ylabel("Precision")
        if day > 1
            hold on
            plot(recall, precision)
            hold off
        else
            plot(recall, precision)
        end        
    end
    %% precision recall for current day
    % approach
    figure(21388+threshold_error*1000)
    if plotFigureTitles, title(['Precision-Recall approach ' num2str(threshold_error*1000) 'mm']), end
    set(gca,'FontSize',16)
    set(gca,'XLim', [0 1])
    set(gca,'YLim', [0 1])
    legend('Dataset S', 'Dataset M', 'Dataset L', 'Location', 'southeast');
    saveas(figure(21388+threshold_error*1000),[basepathImages 'prec_recal_threshold_' num2str(threshold_error*1000) 'mm.png'])
    % msc
    figure(21389+threshold_error*1000)
    if plotFigureTitles, title(['Precision-Recall MSC ' num2str(threshold_error*1000) 'mm']), end
    set(gca,'FontSize',16)
    set(gca,'XLim', [0 1])
    set(gca,'YLim', [0 1])
    legend('Dataset S', 'Dataset M', 'Dataset L', 'Location', 'southeast');
    saveas(figure(21389+threshold_error*1000),[basepathImages 'prec_recal_threshold_msc_' num2str(threshold_error*1000) 'mm.png'])
    
    % recalculation needs to be done only once; ugly i now :)
    recalculateApproach = false;
    recalculateMeanshift = false;
end


