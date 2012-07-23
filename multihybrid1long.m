%% Fitting multiple molecules, using makeFitme
%clear classes;
%topDir = 'T:\matdl\yaron\6-22-12\scaleconst\';
topDir = 'scalehybridbajs2/';
% if (Aprocess == 1)
%    ics = [1 6];
% elseif (Aprocess == 2)
%    ics = [2 7];
% else
%    ics = [3 9];
% end

%trainC{1}  = {'h2',2:7,'envs',1:10};
%testC{1} = {'h2',2:7,'envs',20:30};
ftype = 2;
trainC{1}  = {'h2',[],'ch4',1:17,'envs',1:10};
testC{1} = {'h2',[],'ch4',1:17,'envs',20:30};
filePrefix{1} = 'ch4';

trainC{2}  = {'h2',[],'ethane',1:7,'envs',1:10};
testC{2} = {'h2',[],'ethane',1:7,'envs',15:25};
filePrefix{2} = 'c2h6';

trainC{3}  = {'h2',[],'ethylene',1:7,'envs',1:10};
testC{3} = {'h2',[],'ethylene',1:7,'envs',20:30};
filePrefix{3} = 'c2h4z2';

trainC{4}  = {'h2',[],'ch4',1:7,'ethane',1:7,'envs',1:10};
testC{4} = {'h2',[],'ch4',1:7,'ethane',1:7,'envs',15:25};
filePrefix{4} = 'ch4-c2h6';

trainC{5}  = {'h2',[],'ch4',1:7,'ethane',1:7,'ethylene',1:7,'envs',1:10};
testC{5} = {'h2',[],'ch4',1:7,'ethane',1:7,'ethylene',1:7,'envs',15:25};
filePrefix{5} = 'ch4-c2h6-c2h4';

trainC{6}  = {'h2',[],'ch4',1:19,'ethane',1:7,'envs',1:10};
testC{6} = {'h2',[],'ch4',1:19,'ethane',1:7,'envs',15:25};
filePrefix{6} = 'ch4f-c2h6';

trainC{7}  = {'h2',[],'ch4',1:19,'ethane',1:7,'ethylene',1:7,'envs',1:10};
testC{7} = {'h2',[],'ch4',1:19,'ethane',1:7,'ethylene',1:7,'envs',15:25};
filePrefix{7} = 'ch4f-c2h6-c2h4';

trainC{8}  = {'h2',[],'propane',1:7,'envs',1:10};
testC{8} = {'h2',[],'propane',1:7,'envs',15:25};
filePrefix{8} = 'c3h8';

trainC{9}  = {'h2',[],'ch4',1:19,'ethane',1:7,'propane',1:7,'envs',1:10};
testC{9} = {'h2',[],'ch4',1:19,'ethane',1:7,'propane',1:7,'envs',15:25};
filePrefix{9} = 'ch4-c2h6-c3h8';

commonIn = {};
%
for iC = 1
    trainIn = trainC{iC};
    testIn = testC{iC};
    filePre = filePrefix{iC};
    for iPar = 1
        if (iPar == 1)
            if (ftype == 2)
                iP = 1;
            else
                iP = 0;
            end
            ke.H = Mixer(iP,1,'ke.H',ftype);
            ke.Cs = Mixer(iP,1,'ke.Cs',ftype);
            ke.Cp = Mixer(iP,1,'ke.Cp',ftype);
            ke.HH = Mixer(iP,1,'ke.HH',ftype);
            ke.CsH = Mixer(iP,1,'ke.CsH',ftype);
            ke.CpH = Mixer(iP,1,'ke.CpH',ftype);
            ke.CsH.hybrid = 1;
            ke.CpH.hybrid = 1;

            
            en.H = Mixer(iP,1,'en.H',ftype);
            en.Cs = Mixer(iP,1,'en.Cs',ftype);
            en.Cp = Mixer(iP,1,'en.Cp',ftype);
            en.HH = Mixer(iP,1,'en.HH',ftype);
            en.CsH = Mixer(iP,1,'en.CsH',ftype);
            en.CpH = Mixer(iP,1,'en.CpH',ftype);
            en.CsH.hybrid = 1;
            en.CpH.hybrid = 1;
            ke.CsCs = Mixer(iP,1,'ke.CsCs',ftype);
            ke.CsCp = Mixer(iP,1,'ke.CsCp',ftype);
            ke.CpCs = Mixer(iP,1,'ke.CpCs',ftype);
            ke.CpCs.hybrid = 2;
            ke.CpCp = Mixer(iP,1,'ke.CpCp',ftype);
            ke.CpCp.hybrid = 2;
            en.CsCs = Mixer(iP,1,'en.CsCs',ftype);
            en.CsCp = Mixer(iP,1,'en.CsCp',ftype);
            en.CpCs = Mixer(iP,1,'en.CpCs',ftype);
            en.CpCs.hybrid = 2;
            en.CpCp = Mixer(iP,1,'en.CpCp',ftype);
            en.CpCp.hybrid = 2;
            e2.CC = Mixer(iP,1,'e2.CC',ftype);
            e2.H = Mixer(iP,1,'e2.H',ftype);
            e2.C = Mixer(iP,1,'e2.C',ftype);
            e2.HH = Mixer(iP,1,'e2.HH',ftype);
            e2.CH = Mixer(iP,1,'e2.CH',ftype);
            %           ftest = makeFitme(testIn{:},commonIn{:},'enstruct1',en, ...
            %              'kestruct',ke,'e2struct',e2,'plot',2);
            %           ftest.parallel = 0;
            %           ftest.plot = 0;
            f1 = makeFitme(trainIn{:},commonIn{:},'enstruct',en,'kestruct',ke, ...
                'e2struct',e2);%,'testFitme',ftest);
            f1.plot = 0;
            f1.parallel = 0;
            %pst = [ -1.2840    1.4139   -0.9773   -0.1648    2.9684   -1.7791    5.7310   -9.6449    8.0355  12.5867   -0.1876   -0.1118    2.0048   -0.3105];
            %f1.setPars(pst);
            %          f1.parHF = zeros(size(f1.getPars));
            %          etest1 = f1.err(f1.getPars);
            %          f1.parHF = zeros(size(f1.getPars));
            %          f1.parallel = 1;
            %          etest2 = f1.err(f1.getPars);
            %          input('hi');
        elseif (iPar == 2) % add constants
            % freeze all parameters at values from previous fit
            if iC==1
            for m1 = [ke.H ke.Cs ke.Cp en.H en.Cs en.Cp ke.HH ke.CsH ...
                    ke.CpH en.HH en.CsH en.CpH en.HCs en.HCp e2.HH e2.CH ]
                m1.fixed = ones(size(m1.fixed));
            end
            else
                for m1 = [ke.H ke.Cs ke.Cp en.H en.Cs en.Cp ke.HH ke.CsH ...
                        ke.CpH en.HH en.CsH en.CpH en.HCs en.HCp e2.HH...
                        e2.CH en.CCs en.CCp ke.CCs ke.CCp e2.CC]
                    m1.fixed = ones(size(m1.fixed));
                end
            end
            % loop through some turning on context sensitive
            for m1 = [ke.H ke.Cs ke.Cp en.H en.Cs en.Cp]
                m1.funcType = 3;
                m1.par(2) = 0;
                m1.fixed(1) = 0;
                m1.fixed(2) = 0; % needed because fixed array must expand
                % do a fit here
                m1.fixed = ones(size(m1.fixed)); % freeze them again
            end
        elseif (iPar == 3)
            % then let it try fitting all at once
            % loop through some turning on context sensitive
            for m1 = [ke.H ke.Cs ke.Cp en.H en.Cs en.Cp]
                m1.funcType = 3;
                m1.fixed = ones(size(m1.fixed));
            end
            % do a fit here
            % Now freeze off these and try doing the next set
        elseif (iPar == 4) % add context sensitiv
            if iC ==1
                for m1 = [ke.HH ke.CsH ke.CpH en.HH en.CsH en.CpH ...
                        en.HCs en.HCp]
                    m1.funcType = 3;
                    m1.par(2) = 0;
                    m1.fixed(1) = 0;
                    m1.fixed(2) = 0; % needed because fixed array must expand
                end
            else
                for m1 = [ke.HH ke.CsH ke.CpH en.HH en.CsH en.CpH...
                        en.HCs en.HCp en.CCs ke.CCs ke.CCp en.CCp]
                    m1.funcType = 3;
                    m1.par(2) = 0;
                    m1.fixed(1) = 0;
                    m1.fixed(2) = 0; % needed because fixed array must expand
                end
            end
        elseif (iPar == 5)
            if iC == 1
                for m1 = [ke.HH ke.CsH ke.CpH en.HH en.CsH en.CpH ...
                        en.HCs en.HCp]
                    m1.funcType = 3;
                    m1.fixed = ones(size(m1.fixed));
                end
            else
                for m1 = [ke.HH ke.CsH ke.CpH ke.CCs ke.CCp en.HH ...
                        en.CsH en.CpH en.HCs en.HCp en.CCs en.CCp]
                    m1.funcType = 3;
                    m1.fixed = ones(size(m1.fixed));
                end
            end
        elseif (iPar == 6) 
            if iC == 1
                for m1 = [ e2.HH e2.CH]
                    m1.funcType = 3;
                    m1.par(2) = 0;
                    m1.fixed(1) = 0;
                    m1.fixed(2) = 0;
                end
            else
                for m1 = [ e2.HH e2.CH e2.CC]
                    m1.funcType = 3;
                    m1.par(2) = 0;
                    m1.fixed(1) = 0;
                    m1.fixed(2) = 0;
                end
            end
        end
        
        
        dataDir = [topDir,filePre,'/fit-',num2str(iPar),'/'];
        allFile = [dataDir,'all.mat'];
        if (exist(allFile,'file'))
            load(allFile,'pt');
            f1.setPars(pt);
            disp([filePre,' iC ',num2str(iC),'fit# ',num2str(iPar),...
                'loaded from file']);
        else
            options = optimset('DiffMinChange',1.0e-5,'TolFun',1.0e-3, ...
                'TolX',3.0e-3,'MaxFunEvals',500);
            if (exist(dataDir,'dir') ~= 7)
                status = mkdir(dataDir);
            end
            diary([dataDir,'out.diary']);
            diary on;
            tic
            lowLimits = zeros(f1.npar,1);
            highLimits = lowLimits;
            i1 = 1;
            for imix = 1:length(f1.mixers)
                mix = f1.mixers{imix};
                if ((mix.funcType == 2)||(mix.funcType == 3))
                    lowLimits(i1) = 0.0;
                    highLimits(i1) = 10.0;
                    i1 = i1+1;
                    for i2 = 2:mix.npar
                        lowLimits(i1) = -inf;
                        highLimits(i1) = inf;
                        i1 = i1+1;
                    end
                else
                    for i2 = 1:mix.npar
                        lowLimits(i1) = -inf;
                        highLimits(i1) = inf;
                        i1 = i1+1;
                    end
                end
            end
            restartFile = [dataDir,'restart.mat'];
            f1.restartFile = restartFile;
            if (exist(restartFile,'file'))
                disp('loading restart file');
                load(restartFile);
                start = ptSave;
                f1.itcount = itSave;
                f1.errTrain = errTrainSave;
                f1.errTest = errTestSave;
            else
                start = f1.getPars;
            end
            %f1.parallel = 0;
            %etest3 = f1.err(start);
            %f1.parallel = 1;
            [pt,resnorm,residual,exitflag,output,lambda,jacobian] = ...
                lsqnonlin(@f1.err, start,lowLimits,highLimits,options);
            %       options = LMFnlsq;
            %      options.Display =1;
            %    options.FunTol = 1.0e-6;
            %    options.XTol = 1.0e-5;
            %    [pt,resnorm, CNT, Res, XY] = LMFnlsq(@f1.err,start',options);
            clockTime = toc
            pt
            resnorm
            f1.printMixers;
            save([dataDir,'all.mat']);
            diary off;
            if (f1.plot)
                figure(799); saveas(gcf,[dataDir,'error.fig']);
                if (~isempty(find(cellfun(@(x)isequal(lower(x),'ch4'),trainIn)) ))
                    figure(801); saveas(gcf,[dataDir,'ch4-train.fig']);
                    figure(811); saveas(gcf,[dataDir,'ch4-test.fig']);
                end
                if (~isempty(find(cellfun(@(x)isequal(lower(x),'ethane'),trainIn)) ))
                    figure(802); saveas(gcf,[dataDir,'c2h6-train.fig']);
                    figure(812); saveas(gcf,[dataDir,'c2h6-test.fig']);
                end
                if (~isempty(find(cellfun(@(x)isequal(lower(x),'ethylene'),trainIn)) ))
                    figure(803); saveas(gcf,[dataDir,'c2h4-train.fig']);
                    figure(813); saveas(gcf,[dataDir,'c2h4-test.fig']);
                end
            end
        end
    end
end


