classdef Fitme < handle
   properties
      models  % {1,nmodels}  cell array of models
      HLs     % {1,nmodels}  cell array to fit to
      HLKE    % {1,nmodels}(1,nenv) KE energy
      HLEN    % {1,nmodels}(natom,nenv) electron-nuclear interaction
      HLE2    % {1,nmodels}(1,nenv) two-elec enerty
      mixers  % {1,nmixer}   cell
      
      envs      % {1,nmodels} list of environments to include in fit
      includeKE % include kinetic energy in fit
      includeEN % {1,Z} include elec-nuc operators for element Z
      includeE2 % include two-elec energy in fit
      
      parHF   % Last parameters for which HF was solved
      epsDensity % re-evaluate density matrix if par change > eps
      
      plot       % Plot results on every call to err()
      LLKE       % {1,nmodels}(1,nenv) used only for plots
      LLEN       % {1,nmodels}(natom,nenv) used only for plots
      LLE2       % {1,nmodels}(1,nenv) used for plots
      plotNumber % (1,nmodels): number for plot of this model
      plotNumErr % plot number for the error plots (default = 799)
      errCalls   % number of calls to the err function
      testFitme  % fitme object that has the test data
      
      itcount    % counter for the err arrays
      errTrain   % error in train as a function of iteration
      errTest    % error in test set
      
      arms       % (npar,narms): for bandit algorithm
      parallel   % true to run updateDensity in parallel
      restartFile % place to save intermediate results
   end
   methods
      function res = Fitme
         res.models = cell(0,0);
         res.HLs    = cell(0,0);
         res.HLKE   = cell(0,0);
         res.HLEN   = cell(0,0);
         res.epsDensity = 0.0;
         res.includeKE = 1;
         res.includeEN = zeros(1,6);
         res.includeE2 = 0;
         res.parHF = [];
         res.plot = 1;
         res.plotNumber = [];
         res.plotNumErr = 799;
         res.LLKE = cell(0,0);
         res.LLEN = cell(0,0);
         res.errCalls = 0;
         res.itcount = 0;
         res.parallel = 0;
      end
      function addMixer(obj, mix)
         add = 1;
         for i=1:size(obj.mixers,2)
            if (mix == obj.mixers{1,i})
               add = 0;
               break;
            end
            end
            if (add == 1)
                obj.mixers{1,end+1} = mix;
            end
        end
        function addMixers(obj,mixersIn)
            % mixes is a cell array (1,:) of mixers
            for i=1:size(mixersIn,2)
                obj.addMixer(mixersIn{i});
            end
        end
        function addFrag(obj,model,HL,plotnumber)
            if (nargin < 4)
                plotnumber = 800;
            end
            obj.models{1,end+1} = model;
            obj.addMixers(model.mixers);
            obj.HLs{1,end+1} = HL;
            obj.plotNumber(1,end+1) = plotnumber;
        end
        function setEnvs(obj,envsIn)
            % currently assumes same environments for every frag/model
            obj.envs = cell(1,obj.nmodels);
            for i=1:obj.nmodels
                obj.envs{1,i} = envsIn;
            end
            obj.HLKE = cell(0,0);
            obj.HLEN = cell(0,0);
            obj.HLE2 = cell(0,0);
            obj.LLKE = cell(0,0);
            obj.LLEN = cell(0,0);
            obj.LLE2 = cell(0,0);
            for imod = 1:obj.nmodels
                envs1 = obj.envs{1,i};
                HL = obj.HLs{imod};
                % will plot against the STO-3G result
                LL = obj.models{imod}.frag;
                obj.HLKE{1,end+1} = HL.EKE(envs1);
                obj.LLKE{1,end+1} = LL.EKE(envs1);
                nenv = size(envs1,2);
                en = zeros(HL.natom, nenv);
                enl = zeros(LL.natom, nenv);
                for iatom = 1:HL.natom
                    en(iatom,:) = HL.Een(iatom,envs1);
                    enl(iatom,:) = LL.Een(iatom,envs1);
                end
                obj.HLEN{1,end+1} = en;
                obj.LLEN{1,end+1} = enl;
                obj.HLE2{1,end+1} = HL.E2(envs1);
                obj.LLE2{1,end+1} = LL.E2(envs1);
            end
            obj.parHF = [];
        end
        function res = nmodels(obj)
            res = size(obj.models,2);
        end
        function res = npar(obj)
            res = 0;
            for i=1:size(obj.mixers,2)
                res = res + obj.mixers{i}.npar;
            end  
        end
        function res = getPars(obj)
            res = zeros(1,obj.npar);
            ic = 1;
            for i = 1:size(obj.mixers,2)
                mtemp = obj.mixers{1,i};
                np = mtemp.npar;
                if (np > 0)
                    res(ic:(ic+np-1)) = mtemp.getPars;
                end
                ic = ic + np;
            end
        end
        function initializeChBO(obj)
            for i=1:obj.nmodels
                obj.models{i}.updateChBO;
            end
        end
        function setPars(obj,par)
            % sets parameters, and updates densities
            if (size(par,2) ~= obj.npar)
                error(['Fitme.SetPars called with ',num2str(size(par,2)), ...
                    ' parameters when ',num2str(obj.npar),' are needed ']);
            end
            ic = 1;
            for i = 1:size(obj.mixers,2)
                mtemp = obj.mixers{1,i};
                np = mtemp.npar;
                if (np > 0)
                    mtemp.setPars( par(ic:(ic+np-1)));
                end
                ic = ic + np; 
            end
        end
        function dpar = updateDensity(obj)
            par = obj.getPars;
            if ((size(obj.parHF,1) == 0) || ...
                    (length(obj.parHF) ~= length(par) ) )
                dpar = 1e10;
            else
                dpar = max(abs(obj.parHF-par));
            end
            if (dpar > obj.epsDensity)
                if (~obj.parallel)
                    disp(['solving for density matrices']);
                    for imod = 1:obj.nmodels
                        obj.models{imod}.solveHF(obj.envs{1,imod});
                    end
                else
                    disp(['parallel solving for density matrices']);
                    for imod = 1:obj.nmodels
                        modFile1 = obj.models{imod};
                        envsFile1 = obj.envs{1,imod};
                        save(['scratch/todo',num2str(imod),'.mat'], ...
                            'modFile1','envsFile1');
                    end
                    runModelsParallel('scratch/',obj.nmodels);
                    for imod = 1:obj.nmodels
                        modd = obj.models{imod};
                        filename = ['scratch/done',num2str(imod),'.mat'];
                        load(filename); % contains outFile
                        if (sum(obj.envs{1,imod}==0))
                            modd.orb = modFile2.orb;
                            modd.Eorb = modFile2.Eorb;
                            modd.Ehf = modFile2.Ehf;
                        end
                        modd.orbEnv      = modFile2.orbEnv;
                        modd.EorbEnv     = modFile2.EorbEnv;
                        modd.EhfEnv      = modFile2.EhfEnv;
                        modd.densitySave = modFile2.densitySave;
                        delete(filename);
                    end
                end
                obj.parHF = par;
            end
        end
        function res = ndata(obj)
            ic = 0;
            for imod = 1:obj.nmodels
                if (obj.includeKE == 1)
                    ic = ic + size(obj.HLKE{1,imod},2);
                end
                for iatom = 1:obj.models{imod}.natom
                    if (obj.includeEN( obj.models{imod}.Z(iatom) ))
                        ic = ic + size(obj.HLEN{imod}(iatom,:),2);
                    end
                end
                if (obj.includeE2 == 1)
                    ic = ic + size(obj.HLE2{1,imod},2);
                end
            end
            res = ic;
        end
        function [res plotnum etype] = err(obj,par,reslimit)
            if (nargin<3)
                reslimit = 1000;
            end
            flip = 0; % to handle fit routines that pass row or column
            if (size(par,1)>size(par,2))
                par = par';
                flip = 1;
            end
            disp(['Fitme.err called with par = ',num2str(par)]);
            obj.setPars(par);
            dpar = obj.updateDensity();
            
            doPlots = obj.plot; %&& (dpar > 1.0e-4);
            
            if (doPlots)
                for i=unique([obj.plotNumber])
                    figure(i);
                    clf;
                end
            end
            
            ic = 1;
            ndat = obj.ndata;
            res = zeros(1,ndat);
            plotnum = zeros(1,ndat);
            etype = zeros(1,ndat);
            for imod = 1:obj.nmodels
                if (obj.includeKE == 1)
                    hlevel = obj.HLKE{1,imod};
                    modpred = obj.models{imod}.EKE(obj.envs{1,imod});
                    t1 = hlevel - modpred;
                    n = size(t1,2);
                    res(1,ic:(ic+n-1))= t1;
                    if mean(t1) > reslimit
                        error('Parameters are so bad that you can not solve the problem');
                    end
                    plotnum(1,ic:(ic+n-1))= obj.plotNumber(imod);
                    etype(1,ic:(ic+n-1))= 1;
                    ic = ic + n;
                    if (doPlots)
                        figure(obj.plotNumber(imod));
                        subplot(5,2,1);
                        hold on;
                        llevel = obj.LLKE{1,imod};
                        plot(llevel,llevel,'k.');
                        plot(llevel,hlevel,'r.');
                        plot(llevel,modpred,'b.');
                        %title('Kinetic E: LL(black) HL(red) model(blue)');
                        %xlabel('LL')
                        subplot(5,2,2);
                        hold on;
                        x1 = min(hlevel);
                        x2 = max(hlevel);
                        plot(hlevel,modpred,'g.');
                        plot([x1 x2],[x1 x2],'k-');
                        %title('Kinetic E: HL(black) model(red)');
                        %xlabel('HL')
                    end
                end
                for iatom = 1:obj.models{imod}.natom
                    if (obj.includeEN( obj.models{imod}.Z(iatom) ))
                        hlevel = obj.HLEN{imod}(iatom,:);
                        modpred = obj.models{imod}.Een(iatom,obj.envs{1,imod});
                        t1 = hlevel - modpred;
                        n = size(t1,2);
                        res(1,ic:(ic+n-1)) = t1;
                        if mean(t1) > reslimit
                            error('Parameters are so bad that you can not solve the problem');
                        end
                        plotnum(1,ic:(ic+n-1))= obj.plotNumber(imod);
                        etype(1,ic:(ic+n-1))= 10 + obj.models{imod}.Z(iatom);
                        ic = ic + n;
                        if (doPlots)
                            if (obj.models{imod}.Z(iatom) == 1)
                                frame1 = 3;
                                frame2 = 4;
                                element = 'H';
                            elseif (obj.models{imod}.Z(iatom) == 6)
                                frame1 = 5;
                                frame2 = 6;
                                element = 'C';
                            else
                                frame1 = 7;
                                frame2 = 8;
                                element = 'F';
                            end
                            subplot(5,2,frame1);
                            hold on;
                            llevel = obj.LLEN{1,imod}(iatom,:);
                            plot(llevel,llevel,'k.');
                            plot(llevel,hlevel,'r.');
                            plot(llevel,modpred,'b.');
                            %title(['EN for ',element]);
                            %xlabel('LL');
                            subplot(5,2,frame2);
                            hold on;
                            x1 = min(hlevel);
                            x2 = max(hlevel);
                            plot(hlevel,modpred,'g.');
                            plot([x1 x2],[x1 x2],'k-');
                            %title(['EN for ',element]);
                            %xlabel('HL');
                        end
                    end
                end
                if (obj.includeE2)
                    hlevel = obj.HLE2{1,imod};
                    modpred = obj.models{imod}.E2(obj.envs{1,imod});
                    t1 = hlevel - modpred;
                    n = size(t1,2);
                    res(1,ic:(ic+n-1))= t1;
                    if mean(t1) > reslimit
                        error('Parameters are so bad that you can not solve the problem');
                    end
                    plotnum(1,ic:(ic+n-1))= obj.plotNumber(imod);
                    etype(1,ic:(ic+n-1))= 2;
                    ic = ic + n;
                    if (doPlots)
                        figure(obj.plotNumber(imod));
                        subplot(5,2,9);
                        hold on;
                        llevel = obj.LLE2{1,imod};
                        plot(llevel,llevel,'k.');
                        plot(llevel,hlevel,'r.');
                        plot(llevel,modpred,'b.');
                        %title('E2: LL(black) HL(red) model(blue)');
                        %xlabel('LL')
                        subplot(5,2,10);
                        hold on;
                        x1 = min(hlevel);
                        x2 = max(hlevel);
                        plot(hlevel,modpred,'g.');
                        plot([x1 x2],[x1 x2],'k-');
                        %title('E2: HL(black) model(red)');
                        %xlabel('HL')
                    end
                end
            end
       

         disp(['RMS err/ndata = ',num2str(sqrt(res*res')/ndat), ...
            ' kcal/mol err = ',num2str(sqrt(res*res'/ndat)*627.509)]);
         obj.itcount = obj.itcount + 1;
         obj.errTrain(obj.itcount) = norm(res);
         if (size(obj.testFitme,1) > 0)
            err1 = obj.testFitme.err(par);
            obj.errTest(obj.itcount) = norm(err1);
         end

         if (doPlots)
            figure(obj.plotNumErr);
            if (obj.errCalls == 0)
               hold off;
               title('log10(error) for test (red+) and train (blue o)');
            else
                hold on
            end
        plot(obj.errCalls+1, log10(norm(res)/length(res)),'bo');
            if (size(obj.testFitme,1) > 0)
               hold on;
               plot(obj.errCalls+1, log10(norm(err1)/length(err1)),'r+');
            end
         end
         if (flip == 1)
            res = res';
         end
         obj.errCalls = obj.errCalls + 1;
         
         if (dpar > 1.0e-4)
            if (~isempty(obj.restartFile))
               disp('saving restart file');
               ptSave = par;
               itSave = obj.itcount;
               errTrainSave = obj.errTrain;
               errTestSave = obj.errTest;
               save(obj.restartFile,'ptSave','itSave', ...
                  'errTrainSave','errTestSave');
            end
         end
         
      end
      function generateArms(obj,narms,plow,phigh)
         rr = rand(obj.npar,narms);
         obj.arms = plow + (phigh-plow).*rr;
      end
      function res = pullArm(obj,iarm)
         imod = randi(obj.nmodels);
         ienv = randi(length(obj.envs{1,imod}));
         obj.models{1,imod}.setPars( obj.arms(:,iarm) );
         obj.models{1,imod}.solveHF(ienv);
         res = (obj.models{1,imod}.EKE(ienv) - obj.HLKE{1,imod}(ienv)).^2;
         for iatom = 1:obj.models{imod}.natom
            res = res + ...
               (obj.HLEN{imod}(iatom,ienv) - ...
               obj.models{imod}.Een(iatom,ienv)).^2;
         end
         res = sqrt(res);
      end
      function res = randMolError(obj,par)
         % selects a random molecule and environment
         % calculates the error for the parameters in par
         % returns a vector of errors to be minimized
         imod = randi(obj.nmodels);
         ienv = randi(length(obj.envs{1,imod}));
         obj.models{1,imod}.setPars( par );
         obj.models{1,imod}.solveHF(ienv);
         res = obj.models{1,imod}.EKE(ienv) - obj.HLKE{1,imod}(ienv);
         for iatom = 1:obj.models{imod}.natom
            temp =  ...
               obj.HLEN{imod}(iatom,ienv) - ...
               obj.models{imod}.Een(iatom,ienv);
            res = [res , temp];
         end
         res = -1.0 * norm(res);
      end
      function res = armError(obj,iarm)
         res = 0;
         for imod = 1:obj.nmodels
            obj.models{1,imod}.setPars( obj.arms(:,iarm) );
            obj.models{1,imod}.solveHF(ienv);
            res = (obj.models{1,imod}.EKE(ienv) - obj.HLKE{1,imod}(ienv)).^2;
            for iatom = 1:obj.models{imod}.natom
                res = res + ...
                    (obj.HLEN{imod}(iatom,ienv) - ...
                    obj.models{imod}.Een(iatom,ienv)).^2;
            end
            res = sqrt(res);
         end
      end
        
        function res = normErr(obj,par)
            err = obj.err(par);
            res = norm(err);
        end
    end
end
