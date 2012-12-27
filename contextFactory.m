clear classes;
close all;
topDir = 'C:/Users/mtanha/MSQC/msqc/factoryInterp/';
maxIter = 500;

h2fits = 0;
combinations = 0;
costs = []; %[5 10 25 50]; %[0.0001 0.1];
printDetailsOnLoad = 0;
weights = [40:-4:4 3 2 1:-0.1:0];% 1:10;
for weightProp = 1
for weightFromScratch = 0:1
if (h2fits)
  dsets = cell(1,2);
  dname = cell(1,1);
  dname{1} = 'h2';
  dfile = ['datasets/h2Dat.mat'];
  ms = MSet;
  ms.addData(dfile,[1 3 5 7], 1:2:20 ,1,796);
  dsets{1,1} = ms;
  ms = MSet;
  ms.addData(dfile,[2 4 6], 2:2:20 ,1,796);
  dsets{1,2} = ms;
else
% CREATE MODEL SETS

% dataf = {'ch4rDat','ch4rDat-1c','ch4rDat-diponly','ch4rDat-linrho','ethanerDat','ethylenerDat'};
dataf = {'ch4rDat' ,'ethanerDat'};% ,'ethylenerDat'};
pnn = [791,792,793];

dsets = cell(1,2);
dname = cell(1,1);
for idata = 1:length(dataf)
   dname{idata} = dataf{idata};
   dfile = ['datasets/',dataf{idata},'.mat'];
   % train data
   ms = MSet;
   ms.addData(dfile, 1:10, 1:2:20 ,1,pnn(idata));
   dsets{idata,1} = ms;
   % test data
   ms = MSet;
   ms.addData(dfile, 11:20, 2:2:20 ,1,pnn(idata));
   dsets{idata,2} = ms;
end

if (combinations)
   combs = {[1 2]};%, [2 3], [1 2 3]};
   dtemp = dsets;
   ntemp = dname;
   dsets = cell(0,0);
   dname = cell(0,0);
   for ic = 1:length(combs)
      name = '';
      for iset = combs{ic}
         if (isempty(name))
            name = ntemp{iset};
         else
            name = [name,'_',ntemp{iset}];
         end
      end
      dname{ic,1} = name;
      comb = combs{ic};
      for j = 1:2
         ms = MSet;
         for iset = combs{ic}
            ms.addSet(dtemp{iset,j}.deepCopy);
         end
         dsets{ic,j} = ms;
      end
   end
end
end

%% CREATE POLICIES
policies = cell(0,0);
pname = cell(0,0);

if (h2fits)
pname{1} = 'h2';
m1 = MFactory;
m1.addPolicy('o','*', 'i',1, 'f','interp',  'sp','separate', 'c','r q bo');
m1.addPolicy('o','*', 'i',1, 'j',1, 'f','interp',  'sp','hybrid', 'c','r bo q');
policies{end+1} = m1.policy;
m1 = [];
else

% pname{1} = 'hybridsp';
% m1 = MFactory;
% m1.addPolicy('o','KE', 'f','scale', 'sp','sonly', 'i',1, 'c','q r bo');
% m1.addPolicy('o','EN', 'f','scale', 'sp','sonly', 'i',1, 'c','q r bo');
% m1.addPolicy('o','E2', 'f','scale', 'sp','sonly', 'i',1, 'c','q r bo');
% 
% m1.addPolicy('o','KE', 'f','scale', 'sp','hybrid', 'i',6, 'j',1, ...
%    'c','r bo q');
% m1.addPolicy('o','EN', 'f','scale', 'sp','hybrid', 'i',6, 'j',1, ...
%    'c','r bo q');
% m1.addPolicy('o','E2', 'f','scale', 'sp','hybrid', 'i',6, 'j',1, ...
%    'c','r bo q');
% 
% m1.addPolicy('o','KE', 'f','scale', 'sp','separate', 'i',6, 'c','q r bo');
% %m1.addPolicy('o','KE', 'f','const', 'i',6, 'sp','combine');
% m1.addPolicy('o','EN', 'f','scale', 'sp','separate', 'i',6, 'c','q r bo');
% %m1.addPolicy('o','EN', 'f','const', 'i',6, 'sp','combine');
% m1.addPolicy('o','E2', 'f','scale', 'sp','combine', 'i',6, 'c','q r bo');
% 
% m1.addPolicy('o','E2', 'f','scale', 'sp','sonly', 'i',1, 'j',1, ...
%    'c','r','nb',1);


% pname{end+1} = 'const';
% m1 = MFactory;
% m1.addPolicy('o','*', 'f','const', 'i','*', 'sp','combine','c','r q bo');
% policies{end+1} = m1.policy;
% m1 = [];

% pname{end+1} = 'hybrid3';
% m1 = MFactory;
% % diagonal terms same for all operators and atom types
% m1.addPolicy('o','*', 'f','scale', 'sp','combine', 'i','*', 'c','r q bo');
% % put diagonal constants on all operators
% m1.addPolicy('o','*', 'f','const', 'i',6, 'sp','combine');
% % bonding terms
% m1.addPolicy('o','*', 'f','scale', 'sp','hybrid', 'i','*', 'j','*', ...
%    'c','r bo q');
% % non-bond interactions between hydrogens
% m1.addPolicy('o','E2', 'f','scale', 'sp','sonly', 'i',1, 'j',1, ...
%    'c','bo','nb',1);
% policies{end+1} = m1.policy;
% m1 = [];
% 
% pname{end+1} = 'hybrid2sp';
% m1 = MFactory;
% % diagonal terms same for all operators and atom types
% m1.addPolicy('o','*', 'f','scale', 'sp','separate', 'i','*', 'c','r q bo');
% % no constants since s and p are separate
% % bonding terms
% m1.addPolicy('o','*', 'f','scale', 'sp','hybrid', 'i','*', 'j','*', ...
%    'c','r bo q');
% % non-bond interactions between hydrogens
% m1.addPolicy('o','E2', 'f','scale', 'sp','sonly', 'i',1, 'j',1, ...
%    'c','bo','nb',1);
% policies{end+1} = m1.policy;
% m1 = [];
% 

% pname{end+1} = 'hybridspc';
% m1 = MFactory;
% % Diag core on C only
% m1.addPolicy('o','*', 'i',6, 'f','scale',  'sp','core');
% m1.addPolicy('o','*', 'i','*', 'f','scale',  'sp','separate', 'c','r q bo');
% 
% % Bonding
% m1.addPolicy('o','*', 'i','*', 'j','*', 'f','scale',  'sp','hybrid', 'c','r bo q');
% % nonbond between hydrogen
% m1.addPolicy('o','E2', 'i',1,   'j',1,  'f','scale',  'sp','sonly',  ...
%     'c','bo','nb',1);
% policies{end+1} = m1.policy;
% m1 = [];

pname{end+1} = 'hybridslater';
m1 = MFactory;
% Diag core on C only
m1.addPolicy('o','*', 'i',6, 'f','interp',  'sp','core');
m1.addPolicy('o','KE', 'i','*', 'f','interp',  'sp','separate', 'c','r q bo');
m1.addPolicy('o','EN', 'i','*', 'f','interp',  'sp','separate', 'c','r q bo');
m1.addPolicy('o','E2', 'i','*', 'f','interp',  'sp','slater', 'c','r q bo');

% Bonding
m1.addPolicy('o','*', 'i','*', 'j','*', 'f','interp',  'sp','hybrid', 'c','r bo q');
% nonbond between hydrogen
m1.addPolicy('o','E2', 'i',1,   'j',1,  'f','interp',  'sp','sonly',  ...
   'c','bo','nb',1);
policies{end+1} = m1.policy;
m1 = [];

% pname{end+1} = 'shift';
% m1 = MFactory;
% m1.addPolicy('o','KE', 'i',6, 'f','const',  'sp','shift');
% m1.addPolicy('o','EN', 'i',1, 'f','const',  'sp','shift');
% m1.addPolicy('o','EN', 'i',6, 'f','const',  'sp','shift');
% m1.addPolicy('o','E2', 'i',6, 'f','scale',  'sp','shift');
% 
% policies{end+1} = m1.policy;
% m1 = [];

end
%%
for ipol = 1:length(policies)
   for idata = 1:size(dsets,1)
      filePre=[pname{ipol},'/',dname{idata}];
      dataDir = [topDir,filePre];
      if (exist(dataDir,'dir') ~= 7)
         status = mkdir(dataDir);
      end
      summaryName = [topDir,filePre,'/summary.txt'];
      % if (exist(summaryName,'file'))
      %    delete(summaryName);
      % end
      summaryFile = fopen(summaryName,'a');
      diaryName = [topDir,filePre,'/cfit.diary'];
      % if (exist(diaryName,'file'))
      %    delete(diaryName);
      % end
      diary(diaryName);
      diary on;
      
      % Create fitme object
      fact  = MFactory;
      fact.policy = policies{ipol};
      fact.makeMixInfo(dsets{idata,1}.atomTypes);
      f1    = fact.makeFitme(dsets{idata,1});
      ftest = fact.makeFitme(dsets{idata,2});
      
      fprintf(summaryFile,'train and test starting error \n');
      f1.printEDetails(summaryFile);
      ftest.printEDetails(summaryFile);
      
      %
      startName = [topDir,filePre,'/start.mat'];
      toSave = {'fact','f1','ftest','currentTrainErr', ...
         'currentPar','currentErr'};
      if (exist(startName,'file'))
         fprintf(1,'LOADING START \n');
         fprintf(summaryFile,'LOADING START \n');
         load(startName,toSave{:});
         loaded = 1;
      else
         [currentTrainErr,currentPar,currentErr] = ...
            contextFit3(f1,ftest,maxIter);
         save(startName,toSave{:});
         loaded = 0;
      end
      
      str1 = 'initial error %12.5f test %12.5f \n';
      fprintf(1,str1,currentTrainErr,currentErr);
      fprintf(summaryFile,str1,currentTrainErr,currentErr);
      if (~loaded || printDetailsOnLoad)
         f1.printEDetails(summaryFile);
         ftest.printEDetails(summaryFile);
      end
      ticID = tic;
      for iter = 1:3
         allName = [topDir,filePre,'/all-',num2str(iter),'.mat'];
         if (exist(allName,'file'))
            fprintf(1,'LOADING ITERATION %i \n',iter);
            fprintf(summaryFile,'LOADING ITERATION %i \n',iter);
            load(allName,toSave{:});
            loaded = 1;
         else
            loaded = 0;
            fprintf(1,'STARTING ITERATION %i \n',iter);
            fprintf(summaryFile,'STARTING ITERATION %i \n',iter);
            % unfix 1 level of context
            for imix = 1:length(f1.mixers)
               mix = f1.mixers{imix};
               for ipar = 1:length(mix.fixed)
                  if (mix.fixed(ipar) == 1)
                     mix.fixed(ipar) = 0;
                     break;
                  end
               end
            end
            [currentTrainErr,currentPar,currentErr] = ...
               contextFit3(f1,ftest,maxIter);
            save(allName,toSave{:});
         end
         str2 = 'context error %12.5f test %12.5f \n';
         fprintf(1,str2,currentTrainErr,currentErr);
         fprintf(summaryFile,str2,currentTrainErr,currentErr);
         if (~loaded || printDetailsOnLoad)
            f1.printEDetails(summaryFile);
            ftest.printEDetails(summaryFile);
         end
         
      end
      if (~isempty(costs))
         for cost = costs
%             startName = [topDir,filePre,'/all-',num2str(3),'.mat'];
%             fprintf(1,'LOADING %s for cost %10.5f \n',allName,cost);
%             fprintf(summaryFile,'LOADING %s for cost %10.5f \n',allName,cost);
%             load(allName,toSave{:});
            costDir = [topDir,filePre,'/all-',num2str(3),'-cost'];
            if (exist(costDir,'dir') ~= 7)
               status = mkdir(costDir);
            end
            f1.cost = cost;
            allName = [costDir,'/all-',num2str(cost),'.mat'];
            if (exist(allName,'file'))
               fprintf(1,'LOADING COST %10.5f \n',cost);
               fprintf(summaryFile,'LOADING COST %10.5f \n',cost);
               load(allName,toSave{:});
            else
               fprintf(1,'STARTING COST %10.5f \n',cost);
               fprintf(summaryFile,'STARTING COST %10.5f \n',cost);
               f1.cost = cost;
               [currentTrainErr,currentPar,currentErr] = ...
                  contextFit3(f1,ftest,maxIter);
               save(allName,toSave{:});
            end
            str2 = 'context error %12.5f test %12.5f \n';
            fprintf(1,str2,currentTrainErr,currentErr);
            fprintf(summaryFile,str2,currentTrainErr,currentErr);
            f1.printEDetails(summaryFile);
            ftest.printEDetails(summaryFile);
         end
      end
      if (~isempty(weights))
         for weight = weights
%             startName = [topDir,filePre,'/all-',num2str(3),'.mat'];
%             fprintf(1,'LOADING %s for cost %10.5f \n',allName,cost);
%             fprintf(summaryFile,'LOADING %s for cost %10.5f \n',allName,cost);
%             load(allName,toSave{:});
            weightDir = [topDir,filePre,'/all-',num2str(3),'-weight'];
            if (weightProp)
               weightDir = [weightDir,'p'];
            end
            if (weightFromScratch)
               weightDir = [weightDir,'-scratch'];
            end
            if (exist(weightDir,'dir') ~= 7)
               status = mkdir(weightDir);
            end
            allName = [weightDir,'/all-',num2str(weight),'.mat'];
            if (exist(allName,'file'))
               fprintf(1,'LOADING WEIGHT %10.5f \n',weight);
               fprintf(summaryFile,'LOADING WEIGHT %10.5f \n',weight);
               load(allName,toSave{:});
            else
               fprintf(1,'STARTING WEIGHT %10.5f \n',weight);
               fprintf(summaryFile,'STARTING WEIGHT %10.5f \n',weight);
               f1.setWeights(weight,weightProp);
               [currentTrainErr,currentPar,currentErr] = ...
                  contextFit3(f1,ftest,maxIter);
               save(allName,toSave{:});
            end
            if (weightFromScratch)
               f1.setPars(zeros(size(f1.getPars)));
            end
            str2 = 'context error %12.5f test %12.5f \n';
            fprintf(1,str2,currentTrainErr,currentErr);
            fprintf(summaryFile,str2,currentTrainErr,currentErr);
            f1.printEDetails(summaryFile);
            ftest.printEDetails(summaryFile);
         end

      end

      runTime = toc(ticID)
      diary off;
      fclose(summaryFile);
      %    %%
      %    for i=1:length(errors)
      %       mix = f1.mixers{mixes{i}.imix};
      %       ipar = mixes{i}.ipar;
      %       etemp = errors(i);
      %       disp([mix.desc,' context ',num2str(ipar),' err ', ...
      %          num2str(etemp)]);
      %       disp(['pars ',num2str(pars{i})]);
      %    end
   end
end


end
end
