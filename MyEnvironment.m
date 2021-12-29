%% environment for the case with proposed strategy

classdef MyEnvironment < rl.env.MATLABEnvironment
    %MYENVIRONMENT: Template for defining custom environment in MATLAB.    
    
    %% Properties (set properties' attributes accordingly)
    properties
        % Specify and initialize environment's necessary properties    
        
        % RSRP at which to end the episode
        RSRPThreshold = 0.95

        %load threshold table
        threshold = table2array(readtable('Threshold.xlsx'));
        
        %load p file; one tx
        p=jason2p('test.json');
               
        % Reward scale at each time step 
        bonus = 1
        
        % Penalty when hit the boundary
        Penalty = -0.5
    end
    
    properties
        % Initialize system state [cellAngles,cellDowntilt,patterns]'
        State = zeros(3,1)
    end
    
    properties(Access = protected)
        % Initialize internal flag to indicate episode termination
        IsDone = false        
    end

    %% Necessary Methods
    methods              
        % Contructor method creates an instance of the environment
        % Change class name and constructor name accordingly
        function this = MyEnvironment
            % Initialize Observation settings
            ObservationInfo = rlNumericSpec([3 1]);
            ObservationInfo.Name = 'Txs States';
            ObservationInfo.Description = 'cellAngles, cellDowntilt, patterns';
   
            
            % Initialize Action settings   
            % full space
%             ActionInfo = rlFiniteSetSpec({[-1 -1 -1], [-1 -1 0], [-1 -1 1],[-1 0 -1], [-1 0 0], [-1 0 1],[-1 1 -1],[-1 1 0],[-1 1 1],[0 -1 -1], [0 -1 0], [0 -1 1],[0 0 -1], [0 0 0], [0 0 1],[0 1 -1],[0 1 0],[0 1 1],[1 -1 -1], [1 -1 0], [1 -1 1],[1 0 -1], [1 0 0], [1 0 1],[1 1 -1],[1 1 0],[1 1 1]});
            %smaller action space
            ActionInfo = rlFiniteSetSpec({[1 0 0], [0 1 0],[0 0 1]});
            ActionInfo.Name = 'Tx Action';
            
            % The following line implements built-in functions of RL env
            this = this@rl.env.MATLABEnvironment(ObservationInfo,ActionInfo);
            [this.p.cellAntenna,this.p.cellFrequencies] = huaweiBeams(this.p.patterns,this.p.tx_rows,this.p.tx_cols);
            % Initialize property values and pre-compute necessary values
            updateActionInfo(this);
        end
        
        % Apply system dynamics and simulates the environment with the 
        % given action for one step.
        function [Observation,Reward,IsDone,LoggedSignals] = step(this,Action)
            LoggedSignals = [];
            
            % Unpack state vector
            Observation = this.State+Action';
            Observation(3)=mod(Observation(3),17); %pattern 0-16
                 % cellAngles ~ uniform this.p.bore + this.threshold(pattern0+1,2)~this.threshold(pattern0+1,3)
           Observation(1)=this.p.bore+this.threshold(Observation(3)+1,2)+mod(Observation(1)-this.p.bore-this.threshold(Observation(3)+1,2),this.threshold(Observation(3)+1,3)-this.threshold(Observation(3)+1,2)+1);
                  % cellDowntilt ~ uniform this.p.tilt + this.threshold(pattern0+1,4)~ this.threshold(pattern0+1,5)
           Observation(2)=this.p.tilt +this.threshold(Observation(3)+1,4)+mod(Observation(2)-this.p.tilt - this.threshold(Observation(3)+1,4),this.threshold(Observation(3)+1,5)-this.threshold(Observation(3)+1,4)+1);        
           flag=false;%flag=true if current state is out of boundary
            if Observation(1)<this.p.bore+this.threshold(Observation(3)+1,2)||Observation(1)>this.p.bore+this.threshold(Observation(3)+1,3)||Observation(2)<this.p.tilt+this.threshold(Observation(3)+1,4)||Observation(2)>this.p.tilt+this.threshold(Observation(3)+1,5)
%             Observation=this.State;
            flag=true;
            end
            
           
        %modify json parameter 
        this.p.cellAngles = Observation(1);
        this.p.cellDowntilt = Observation(2);
        this.p.patterns = Observation(3);
            
        % Open the siteviewer with terrain and building files
        persistent VIEWER PRE_OSM PRE_DT1 rsrp_history
        if ~strcmp(PRE_OSM,this.p.osmFile) % if osm File is different
            if ~isempty(VIEWER); close(VIEWER); end % Close the previous siteviewer
            if ~strcmp(PRE_DT1,this.p.dt1File) % if dt1 File is different
                try
                    addCustomTerrain(this.p.terrain,this.p.dt1File);
                    catch
                    removeCustomTerrain(this.p.terrain);
                    addCustomTerrain(this.p.terrain,this.p.dt1File);
                end
            end
       VIEWER = siteviewer("Terrain",this.p.terrain,'Position',[1 1 0.5 0.5],"Buildings",this.p.osmFile,'Basemap','darkwater'); 
       PRE_OSM = this.p.osmFile; PRE_DT1 = this.p.dt1File;
       end
        % Channel model selection
        pm = propagationModel(this.p.channelModel);
        
        [~, ext] = fileparts(this.p.dt1File);
        %read rsrp history at the beginning
        if this.p.cn==1
            try
                %history file name
                name=[this.p.outputPath,append(this.p.terrain,['_',ext,'_rsrpprop_history_',num2str(length(this.p.ueLats)),'_',num2str(this.p.cellNames),'.mat'])];
                rsrp_history = load(name).rsrp_history;
            catch
                rsrp_history=[];
            end
        end
        
        %calculate P(RSRP>-110)
        if isempty(rsrp_history)
            r1 = RSRPandSINR(this.p,pm,VIEWER,[]);
            rsrp_prop = round(sum(r1.RSRP>-110)/length(r1.RSRP),4);
            rsrp_history=[rsrp_history;[rsrp_prop,this.p.cellAngles,this.p.cellDowntilt,this.p.patterns]];
        else
            [testcondition,location] = ismember([this.p.cellAngles,this.p.cellDowntilt,this.p.patterns],rsrp_history(:,2:end),'rows');
            if testcondition %condition=1 if rsrp calculated historically
            rsrp_prop = rsrp_history(location,1);
            else
            r1 = RSRPandSINR(this.p,pm,VIEWER,[]);
            rsrp_prop = round(sum(r1.RSRP>-110)/length(r1.RSRP),4);
            rsrp_history=[rsrp_history;[rsrp_prop,this.p.cellAngles,this.p.cellDowntilt,this.p.patterns]];
            end
        end


  
        %%%%%%%%%% write table every n steps
        if mod(this.p.cn,this.p.n)==0
        save([this.p.outputPath,append(this.p.terrain,['_',ext,'_rsrpprop_history_',num2str(length(this.p.ueLats)),'_',num2str(this.p.cellNames),'.mat'])], 'rsrp_history');
        end
        
        % Update system states
        this.State = Observation;
        this.p.cn=this.p.cn+1;
            
        % Check terminal condition 
%         if Observation(3) < this.threshold(1,1)||Observation(3) > this.threshold(end,1)
%         IsDone=true;
%         else
        IsDone = rsrp_prop > this.RSRPThreshold && ~flag;% || Observation(1) < this.p.bore+this.threshold(Observation(3)+1,2) || Observation(1) > this.p.bore+this.threshold(Observation(3)+1,3) || Observation(2) < this.p.tilt+this.threshold(Observation(3)+1,4) || Observation(2) > this.p.tilt+this.threshold(Observation(3)+1,5);
%         end
        this.IsDone = IsDone;
     
            
        % Get reward
        Reward = getReward(this,rsrp_prop,flag);

        % (optional) use notifyEnvUpdated to signal that the 
        % environment has been updated (e.g. to update visualization)
        notifyEnvUpdated(this);
        end
        
        % Reset environment to initial state and output initial observation
        function InitialObservation = reset(this)
            % patterns ~ uniform(0,16)
            pattern0 = randi(17) -1;
            % cellAngles ~ uniform this.p.bore + this.threshold(pattern0+1,2)~this.threshold(pattern0+1,3)
            cellAngles0 = this.p.bore + randi(this.threshold(pattern0+1,3)-this.threshold(pattern0+1,2)+1) + this.threshold(pattern0+1,2)-1 ;  
            % cellDowntilt ~ uniform this.p.tilt + this.threshold(pattern0+1,4)~ this.threshold(pattern0+1,5)
            cellDowntilt0 = this.p.tilt + randi(this.threshold(pattern0+1,5)-this.threshold(pattern0+1,4)+1) + this.threshold(pattern0+1,4)-1 ;
          
            
            InitialObservation = [cellAngles0;cellDowntilt0;pattern0];
            this.State = InitialObservation;
            
            % (optional) use notifyEnvUpdated to signal that the 
            % environment has been updated (e.g. to update visualization)
            notifyEnvUpdated(this);
        end
    end
    %% Optional Methods (set methods' attributes accordingly)
    methods               
        % Helper methods to create the environment
        % update the action info based on max force
        function updateActionInfo(this)
%             this.ActionInfo.Elements = [-1 0 1];
        end
        
        % Reward function
        function Reward = getReward(this,rsrp_prop,flag)
          
                if ~this.IsDone      
                            if flag
                               %current state is out of boundary
                               Reward=this.Penalty;
                            else  
                               Reward = this.bonus*(rsrp_prop-1);
                            end
%                        end
                else
                    %reach the required rsrp proportion inside the area
                    Reward = this.bonus*(rsrp_prop-1)+50*this.bonus*abs(this.Penalty);     
                end
        
        end
        
        
        % (optional) Properties validation through set methods
        function set.State(this,state)
            validateattributes(state,{'numeric'},{'finite','real','vector','numel',3},'','State');
            this.State = double(state(:));
            notifyEnvUpdated(this);
        end
        function set.bonus(this,val)
            validateattributes(val,{'numeric'},{'real','finite','scalar'},'','bonus');
            this.RewardForNotFalling = val;
        end
        function set.Penalty(this,val)
            validateattributes(val,{'numeric'},{'real','finite','scalar'},'','Penalty');
            this.Penalty = val;
        end
    end
    
    methods (Access = protected)
        % (optional) update visualization everytime the environment is updated 
        % (notifyEnvUpdated is called)
        function envUpdatedCallback(this)
        end
    end
end
