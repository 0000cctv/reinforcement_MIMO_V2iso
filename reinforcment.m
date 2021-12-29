%% reinforcement learning for the proposed strategy

clear% close all force;

Ts = 1;
Tf = 200;
maxsteps = Tf/Ts;
addpath(pwd,'local_Functions'); 
env = MyEnvironment;
actionInfo = getActionInfo(env);
observationInfo = getObservationInfo(env);
numObs = observationInfo.Dimension(1);
numAct = numel(actionInfo.Elements);
rng(0)

criticLayerSizes = [4 4];
actorLayerSizes = [4 4];
    % Create actor deep neural network.
  actorNetwork = [featureInputLayer(numObs,'Normalization','none','Name','observation')
        fullyConnectedLayer(actorLayerSizes(1),'Name','ActorFC1', ...
            'Weights',sqrt(2/numObs)*(rand(actorLayerSizes(1),numObs)-0.5), ...
            'Bias',1e-3*ones(actorLayerSizes(1),1))
        reluLayer('Name','ActorRelu1')
        fullyConnectedLayer(actorLayerSizes(2),'Name','ActorFC2', ...
            'Weights',sqrt(2/actorLayerSizes(1))*(rand(actorLayerSizes(2),actorLayerSizes(1))-0.5), ...
            'Bias',1e-3*ones(actorLayerSizes(2),1))
        reluLayer('Name', 'ActorRelu2')
        fullyConnectedLayer(numAct,'Name','Action', ...
            'Weights',sqrt(2/actorLayerSizes(2))*(rand(numAct,actorLayerSizes(2))-0.5), ...
            'Bias',1e-3*ones(numAct,1))
        softmaxLayer('Name','actionProb')];
    
    % Create critic deep neural network.
criticNetwork = [
        featureInputLayer(numObs,'Normalization','none','Name','observation')
        fullyConnectedLayer(criticLayerSizes(1),'Name','CriticFC1', ...
            'Weights',sqrt(2/numObs)*(rand(criticLayerSizes(1),numObs)-0.5), ...
            'Bias',1e-3*ones(criticLayerSizes(1),1))
        reluLayer('Name','CriticRelu1')
        fullyConnectedLayer(criticLayerSizes(2),'Name','CriticFC2', ...
            'Weights',sqrt(2/criticLayerSizes(1))*(rand(criticLayerSizes(2),criticLayerSizes(1))-0.5), ...
            'Bias',1e-3*ones(criticLayerSizes(2),1))
        reluLayer('Name','CriticRelu2')
        fullyConnectedLayer(1,'Name','CriticOutput', ...
            'Weights',sqrt(2/criticLayerSizes(2))*(rand(1,criticLayerSizes(2))-0.5), ...
            'Bias',1e-3)];
        criticOpts = rlRepresentationOptions('LearnRate',1e-4);
critic = rlValueRepresentation(criticNetwork,observationInfo,'Observation',{'observation'},criticOpts);
    
    % Specify representation options for the actor and critic.
actorOpts = rlRepresentationOptions('LearnRate',1e-4);
actor = rlStochasticActorRepresentation(actorNetwork,observationInfo,actionInfo,...
    'Observation',{'observation'},actorOpts);
    agentOpts = rlPPOAgentOptions(...
                'ExperienceHorizon',600,...% Number of steps the agent interacts with the environment before learning from its experience
                'ClipFactor',0.2,... % limiting the change in each policy update step
                'EntropyLossWeight',0.02,... %A higher loss weight value promotes agent exploration
                'MiniBatchSize',128,...
                'NumEpoch',3,...
                'AdvantageEstimateMethod','gae',...
                'GAEFactor',0.95,...
                'SampleTime',Ts,...
                'DiscountFactor',0.0001);%0.8


agent = rlPPOAgent(actor,critic,agentOpts);


trainOpts = rlTrainingOptions(...
    'MaxEpisodes',20000,...
    'MaxStepsPerEpisode',maxsteps,...
    'Plots','training-progress',...
    'ScoreAveragingWindowLength',100,...
    'StopTrainingCriteria','AverageReward');%,...
%     'StopTrainingValue',800); 

stats = train(agent,env,trainOpts);
save("trained_agent0")

%%%% reproduce episode manager
inspectTrainingResult(stats)

rng(0) % reset the random seed
simOpts = rlSimulationOptions('MaxSteps',Tf,'NumSimulations',100);
experience = sim(env,agent,simOpts);
Result=[];
for i=1:size(experience,1)
    Result=[Result,1+experience(i).Reward.Data(end)-25];
end
% percentage of successful simulated results
sum(Result>0)/length(Result)
% 
% 
% steps to success at each run
runs=[];
for i=1:size(experience,1)
    runs=[runs,length(experience(i).Reward.Data)];
end