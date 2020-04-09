% 'Track and Label Bounding Box(Cuboid) Automatically Based on predefined Bounding Box
% 
% [Japanese]
% トラッキングアルゴリズムを利用することで、点群データ向けラベリング(Cuboid)を半自動化します。
% 使い方は以下の通りです。
% 
% Step 1 : Labeler上でROIラベルを定義します。ラベルタイプは"Cuboid"を選択します。
%
% Step 2 : 点群データをクラスタリングします。Labeler本体の機能としてクラスタリング機能が
% 提供されていますので、そちらを利用します。LabelerのツールストリップからLidarタブを選択、
% "Snap to Cluster" ボタンを押します。
%
% Step 3 : 地表面の除去を行います。多くのケースでデータには地表面を表す点群が含まれており、
% 対象オブジェクトを分離するにあたり問題となります。Labeler本体の機能として地表面を
% 除去する機能が提供されていますので、そちらを利用します。LabelerのツールストリップからLidarタブを選択、
% "Hide Ground"を推します。
%
% Step 4 : 最初のフレームに対してラベリングを行います。ラベリング対象となるオブジェクトに対して
% ラベルを付与してください。Step1で定義済のラベルを選択し、対象オブジェクトの上にカーソルを
% 移動させます。移動したカーソルにあわせて灰色のCuboidがクラスタを囲みますので、所望のクラスタが
% 選択されている状態で左クリックします。
%
% Step 5 : (任意) 半自動化アルゴリズムに関連するパラメータを設定します。
% クラスタ作成のROIやオブジェクトのサイズ等が調整可能です。Lebelerのツールストリップから
% Automateタブを選択、"Settings"を押します。ダイアログボックスが起動しますので、
% 調整したいパラメータの値を変更します。
%
% Step 6 : 半自動化アルゴリズムを実行します。Labelerのツールストリップから
% Automateタブを選択、"Run"を押します。
%
% Step 7 : 半自動化による結果のレビュー&修正を行います。playbackのボタンを押すと
% 前のフレームの結果を確認できます。自動付与されたCuboidの結果が望ましくない場合、
% Cuboidのサイズの修正、削除もしくは追加が可能です。結果に問題がなければ
% Acceptを押します。
%
% Step 8 : (任意) パラメータ類の調整と再実行を行います。半自動化による結果が
% 思わしくなかった場合、半自動化関連のパラメータを再調整して再度実行できます。
% その場合、"Undo Run"ボタンを押して半自動化による結果を全て削除し、"Settings"ボタンで
% パラメータを調整、その後に再度"Run"を押します。
%
% Step 9 : 結果をAcceptもしくはCancelします。期待したような結果が得られた場合、
% Acceptを推して半自動化によるラベルを確定させます。また、望ましい結果が
% 得られなかった場合、Cancelを推して全ての結果を破棄します。
%
% [English]
% Please see UserDirections cell array shown in line 70 to line 105.
%
% Copyright 2020 The MathWorks, Inc.
% Ver1.0 : 2020/04/8
% Keitaro Otsuka

classdef BoundingBoxTracker < vision.labeler.AutomationAlgorithm & vision.labeler.mixin.Temporal
    
    %----------------------------------------------------------------------
    % Step 1: Define required properties describing the algorithm. This
    %         includes Name, Description and UserDirections.
    properties(Constant)
        
        % Name: Give a name for your algorithm.
        Name = 'Bounding Box(Cuboid) Tracker';
        
        % Description: Provide a one-line description for your algorithm.
        Description = 'Track and Label Bounding Box(Cuboid) Automatically Based on predefined Bounding Box.';
        
        % UserDirections: Provide a set of directions that are displayed
        %                 when this algorithm is invoked. The directions
        %                 are to be provided as a cell array of character
        %                 vectors, with each element of the cell array
        %                 representing a step in the list of directions.
        UserDirections = {...
            ['Automation algorithms are a way to automate manual labeling ' ...
            'tasks. This AutomationAlgorithm helps you to label cuboid automatically '...
            'using tracking algorithm. Below are steps' ...
            'involved in running this automation algorithm.'], ...
            ['#1 : Create an ROI label for objects you want to label. In this case, ' ...
            'Label Type shold be "Cuboid".'], ...
            ['#2 : Snap to Clusters. This labeler provides an option to snap clasters '...
            'from point cloud by using some segmentation algorithms such as pcdist. ' ...
            'On the app toolstrip, on the Lidar tab, click "Snap tp Cluster".'], ...
            ['#3 : Hide Ground. The point cloud data includes points from the ground, '...
            'which can make it more difficult to isolate the object you want to label. ' ...
            'On the app toolstrip, on the Lidar tab, click "Hide Ground". '], ...
            ['#4 : Label Cuboid for first frame. In the ROI Labels pane on the left, '...
            'click the label you want to automate, and move the pointer over the object you want to label '...
            'until the gray preview cuboid encloses the object points. '...
            'And then click the signal frame to draw thecuboid.'] ...
            ['#5 : (Optional) Tune parameters for automation algorithm. On the app toolstrip, '...
            'on the Automate tab, click "Settings". In the dialog box that opens, '...
            'modify parameters if needed.'] ...
            ['#6 : Run automation algorithm. On the app toolstrip, '...
            'on the Automate tab, click "Run".']...
            ['#7 : Review and Modify. Review automated labels over the interval ', ...
            'using playback controls. Modify/delete/add Cuboids that were not ' ...
            'satisfactorily automated at this stage. If the results are ' ...
            'satisfactory, click Accept to accept the automated labels.'], ...
            ['#8 : (Optional) Change Settings and Rerun. If automated results are not ' ...
            'satisfactory, you can try to re-run the algorithm with ' ...
            'different settings. In order to do so, click Undo Run to undo ' ...
            'current automation run, click Settings and make changes to ' ...
            'Settings, and press Run again.'], ...
            ['#9 : Accept/Cancel. If results of automation are satisfactory, ' ...
            'click Accept to accept all automated labels and return to ' ...
            'manual labeling. If results of automation are not ' ...
            'satisfactory, click Cancel to return to manual labeling ' ...
            'without saving automated labels.']};
    end
    
    %---------------------------------------------------------------------
    % Step 2: Define properties to be used during the algorithm. These are
    % user-defined properties that can be defined to manage algorithm
    % execution.
    properties
        LabelName;                                                 % Label Name (現在選択されているラベル名)
        detectorModel;                                           % Bounding Box(Cuboid) Detector (点群データに対する処理アルゴリズム-クラスタ生成)
        numObj;                                                      % Number of cuboids (トラック対象となるオブジェクトの数)
        initSize;                                                        % Size of predifined cuboids (事前定義されたCuboidのサイズ)
        tracker;                                                         % Multi-object tracker (トラッキングアルゴリズム)
        time;                                                            % Start time (トラッキング開始時間)
        dT;                                                               % Time step
        % Tunable Parameters
        XLimits = [-50 75];                                       % X axes min-max (クラスタ生成対象となるROI - X軸)
        YLimits = [-5 5];                                           % Y axes min-max (クラスタ生成対象となるROI - Y軸)
        ZLimits = [-2 5];                                           % Z axes min-max (クラスタ生成対象となるROI - Z軸)
        SegmentationMinDistance = 1.6;                 % minimum Euclidian distance (点間の最小ユークリッド距離)
        MinDetectionsPerCluster = 1;                      % minimum points per cluster (クラスタあたりの点数)
        GroundMaxDistance = 0.3;                          % maximum distance of ground points from ground plane (地平面からの最大距離)
        ObjectLength = [2 5];                                  % Range of Cluster Length(min-max) (クラスタの長さ)
        ObjectWidth = [1 3];                                    % Range of Cluster Width(min-max) (クラスタの幅)
        ObjectHeight = [0.5 20];                              % Range of Cluster Height(min-max) (クラスタの高さ)
    end
    
    %----------------------------------------------------------------------
    % Step 3: Define methods used for setting up the algorithm.
    methods (Static)
        
        % a) Use the checkSignalType method to specify whether a signal
        %    type is valid for the algorithm. This method is invoked for
        %    the selected signal to determine whether it
        %    is valid for the specified algorithm. Additionally, this
        %    method is used to cross check that the label definitions
        %    correspond to the correct signal type.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.checkSignalType
        %
        function isValid = checkSignalType(signalType)
            
            disp('Executing checkSignalType')
                        
            % Sample code for PointCloud signal type:
            isValid = (signalType == vision.labeler.loading.SignalType.PointCloud);
            
        end
        
    end
    
    methods
        
        % b) Use the checkLabelDefinition method to specify whether a label
        %    definition is valid for the algorithm. This method is invoked
        %    on each ROI and Scene label definition to determine whether it
        %    is valid for the specified algorithm.
        %
        %    Valid label definitions for Image SignalType include
        %    Rectangle, Line, and PixelLabel. Valid label definitions for
        %    PointCloud SignalType are limited only to Cuboid label
        %    definitions.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.checkLabelDefinition
        %
        function isValid = checkLabelDefinition(algObj, labelDef)
            
            disp(['Executing checkLabelDefinition on label definition "' labelDef.Name '"'])
            
            % Allow any labels that are of type 'Cuboid'
            isValid = false;
            
            if (labelDef.Type == labelType.Cuboid)
                isValid = true;
                algObj.LabelName = labelDef.Name;
            end                      
            
            
        end
        
        % c) Use the checkSetup method to specify whether the algorithm is
        %    ready and all required set up is complete. For example, use
        %    this method to check if the user has drawn an initial ROI
        %    label for tracking algorithms. If your algorithm requires no
        %    setup from the user, remove this method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.checkSetup
        %
        function isReady = checkSetup(algObj, labelsToAutomate)
            
            disp('Executing checkSetup')
            %--------------------------------------------------------------
            % Place your code here
            %--------------------------------------------------------------
            % Check-1: There must be at least two drawn ROIs
            numROIs = height(labelsToAutomate);
            assert(numROIs >= 1, ...
                'You must create at least one cuboid ROI.');
            isReady = true;
            
        end
        
        % d) Optionally, specify what settings the algorithm requires by
        %    implementing the settingsDialog method. This method is invoked
        %    when the user clicks the Settings button. If your algorithm
        %    requires no settings, remove this method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.settingsDialog
        %
        function settingsDialog(algObj)
            
            disp('Executing settingsDialog')

            % Input descriptions
            prompt={...
                'XLimits (min-max)',...
                'YLimits (min-max)',...
                'ZLimits (min-max)',...
                'Minimum Euclidian Distance',...
                'Minimum Points per Cluster',...
                'Maximum Distance of Ground Points from Ground Plane',...
                'Object Length (min-max)',...
                'Object Width (min-max)',...
                'Object Height (min-max)',...
                };
            defaultAnswer={...
                num2str(algObj.XLimits),...
                num2str(algObj.YLimits),...
                num2str(algObj.ZLimits),...
                num2str(algObj.SegmentationMinDistance),...
                num2str(algObj.MinDetectionsPerCluster),...
                num2str(algObj.GroundMaxDistance),...
                num2str(algObj.ObjectLength),...
                num2str(algObj.ObjectWidth),...
                num2str(algObj.ObjectHeight),...
                };
            
            name='Settings for bounding box detection';
            numLines=1;
            
            allValid = false;
            while(~allValid)  % Repeat till all inputs pass validation
                
                % Create the settings dialog
                options.Resize='on';
                options.WindowStyle='normal';
                options.Interpreter='none';
                answer = inputdlg(prompt,name,numLines,defaultAnswer,options);
                
                if isempty(answer)
                    % Cancel
                    break;
                end
                
                try
                    % Parse and validate inputs
                    algObj.XLimits = eval(['[,' answer{1}, ']']);
                    validateattributes(algObj.XLimits,...
                        {'double'},{'numel',2});
                    
                    algObj.YLimits = eval(['[,' answer{2}, ']']);
                    validateattributes(algObj.YLimits,...
                        {'double'},{'numel',2});
                    
                    algObj.ZLimits = eval(['[,' answer{3}, ']']);
                    validateattributes(algObj.ZLimits,...
                        {'double'},{'numel',2});
                    
                    algObj.SegmentationMinDistance  = str2double(answer{4});
                    algObj.MinDetectionsPerCluster    = str2double(answer{5});
                    algObj.GroundMaxDistance           = str2double(answer{6});

                    algObj.ObjectLength = eval(['[,' answer{7}, ']']);
                    validateattributes(algObj.ObjectLength,...
                        {'double'},{'numel',2});
                    
                    algObj.ObjectWidth = eval(['[,' answer{8}, ']']);
                    validateattributes(algObj.ObjectWidth,...
                        {'double'},{'numel',2});
                    
                    algObj.ObjectHeight = eval(['[,' answer{9}, ']']);
                    validateattributes(algObj.ObjectHeight,...
                        {'double'},{'numel',2});                    
                    
                    allValid = true;
                catch ALL
                    waitfor(errordlg(ALL.message,'Invalid settings'));
                end
            end            
        end
    end
    
    %----------------------------------------------------------------------
    % Step 4: Specify algorithm execution. This controls what happens when
    %         the user presses RUN. Algorithm execution proceeds by first
    %         executing initialize on the first frame, followed by run on
    %         every frame, and terminate on the last frame.
    methods
        % a) Specify the initialize method to initialize the state of your
        %    algorithm. If your algorithm requires no initialization,
        %    remove this method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.initialize
        %
        function initialize(algObj, I, labelsToAutomate)
            
            disp(['Executing initialize on the first frame at ' char(seconds(algObj.CurrentTime))])
            
            % A bounding box detector model.
            algObj.detectorModel = BoundingBoxDetector(...
                'XLimits',algObj.XLimits,...               % min-max
                'YLimits',algObj.YLimits,...                % min-max
                'ZLimits',algObj.ZLimits,...                % min-max
                'SegmentationMinDistance',algObj.SegmentationMinDistance,...   % minimum Euclidian distance
                'MinDetectionsPerCluster',algObj.MinDetectionsPerCluster,...        % minimum points per cluster
                'GroundMaxDistance',algObj.GroundMaxDistance,...                      % maximum distance of ground points from ground plane
                'RangeOfClusterLength', algObj.ObjectLength,...   % Range of Cluster Length(min-max)
                'RangeOfClusterWidth', algObj.ObjectWidth,...       % Range of Cluster Width(min-max)
                'RangeOfClusterHeight', algObj.ObjectHeight);      % Range of Cluster Height(min-max)
            
            % Tracker
            algObj.tracker = trackerGNN('FilterInitializationFcn', @initcvkf, ...
                'AssignmentThreshold', 30, ...
                'ConfirmationThreshold', [1 1], ...
                'DeletionThreshold', [7 10]);
            
            algObj.time = 0;       % Start time
            algObj.dT = 0.1;       % Time step
            
            measurementNoise = eye(2); 
            for i = 1:height(labelsToAutomate)
                pos = labelsToAutomate(i, 3);
                pos = pos.Position;
                detections{i} = objectDetection(algObj.time, [pos(1), pos(2)], ...
                    'MeasurementNoise', measurementNoise);
                algObj.initSize(i, :) = pos(3:6);
            end
            
            % Extract the number of objects that need to be tracked (トラック対象となるオブジェクトの数)
            algObj.numObj = height(labelsToAutomate);
            % Update tracker (トラック更新)
            [confirmedTracks, tentativeTracks, allTracks, analysysInfo] = algObj.tracker(detections, algObj.time);
        end
        
        % b) Specify the run method to process an image frame and execute
        %    the algorithm. Algorithm execution begins at the first image
        %    frame in the interval and is sequentially invoked till the
        %    last image frame in the interval. Algorithm execution can
        %    produce a set of labels which are to be returned in
        %    autoLabels.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.run
        %
        function autoLabels = run(algObj, I)
            
            disp(['Executing run on frame at ' char(seconds(algObj.CurrentTime))])
            
            % Update time (時間更新)
            algObj.time = algObj.time + algObj.dT;
            
            % Generator detections from point cloud (点群からクラスタの作成)
            [pcObstacles, labels, validLabels, detections] = algObj.detectorModel(I, algObj.CurrentTime);
               
            % Construct objectDetection object (objectDetectionオブジェクトの作成)
            numDetections = size(detections, 2);
            detObj = cell(numDetections, 1);
            measurementNoise = eye(2); 
            for i = 1:numDetections
                pos = detections(:, i);
                detObj{i} = objectDetection(algObj.time, double([pos(1), pos(2)]), ...
                    'MeasurementNoise', measurementNoise);      
            end
            
            % Pass detections to track. (トラック更新)
            [confirmedTracks, tentativeTracks, allTracks, analysisInfo] = algObj.tracker(detObj, algObj.time);
            assignments = analysisInfo.Assignments;
            exTracks = assignments(:, 1);
            
            autoLabels = [];
            % 最初のフレームはユーザー定義のCuboidがあるので自動付与しない
            if ~(algObj.dT == algObj.time)
                for i = 1:algObj.numObj
                    for ii = 1:size(confirmedTracks, 1)
                        tracks = confirmedTracks(ii);
                        if i == tracks.TrackID
                            % Extract position of object(x, y) (x, y方向の位置情報は既存Trackから)
                            x = tracks.State(1); y = tracks.State(3);
                            % Check if detections are assigned to existing tracks (detectionが割り当てられたかどうか確認)
                            idx = find(exTracks == i);
                            if ~isempty(idx)
                                detIdx = assignments(idx, 2);
                                detection = detections(:, detIdx);
                                % Update object size (initSize更新)
                                algObj.initSize(i, :) = detection(3:6)';
                            end
                            z = algObj.initSize(i, 1);
                            l = algObj.initSize(i, 2); w = algObj.initSize(i, 3); h = algObj.initSize(i, 4);
                            autoLabels(i).Name = algObj.LabelName;
                            autoLabels(i).Type = labelType.Cuboid;
                            autoLabels(i).Position = [x, y, z, l, w, h, 0, 0, 0];                        
                        end
                    end
                end
            end
        end
        
        % c) Specify the terminate method to clean up state of the executed
        %    algorithm. If your method requires no clean up, remove this
        %    method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.terminate
        %
        function terminate(algObj)
            
            disp('Executing terminate')
            
            %--------------------------------------------------------------
            % Place your code here
            %--------------------------------------------------------------
            
        end
    end
end