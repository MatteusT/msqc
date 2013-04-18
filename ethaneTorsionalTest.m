clear classes
close all

dataf = {'ethanetor-orig'};
dsets = cell(1,1);
fitme = cell(1,2);

    dfile = ['datasets/',dataf{1},'.mat'];
    % test data
    mf = MFactory;
    ms = MSet;
    ms.addData(dfile, 1:18, 0:12,1,791);
    dsets = ms;
fct = cell(0,0);
load(['C:\Users\mtanha\MSQC\data\ethanerDat\all-3.mat'],'fact');
for i= 1:length(fact.mixer)
    fact.mixer{i}.bonded = 1;
end
fact.mixer{end}.bonded= 0;
fct{1} = fact;
%%
color={'co','b-','r-','g-','k-','m-','y-','b-','r-','g-','k-','m-','y-'};
etot1= [];
etot2= [];
f1 = [];

    etotEnv = [];
    f1 = fct{1}.makeFitme(dsets);
    [err pnum etype] = f1.err(f1.getPars);
    nmb =[];
           range= 1:234;
        ngeom = 18;
          etot1 = err(etype == 3);

    step2 = 0;
    estep = 12;
    
    for in = 1:ngeom
        step1 = step2+1;
        step2 = step1 + estep;
        nmb = [nmb; range(step1:step2)];
    end

    ext = 0.85:0.03:1.42;
    for i = 1:13
        ic = 0;
        for i2 = 1:ngeom
            ic = ic+1;
           etotEnv(ic) =etot1(nmb(i2,i));
        end
        figure(100)
        plot(ext(1:ngeom),etotEnv,color{i});
        hold on
        xlabel(']');
        ylabel('Total Error [kcal/mol]')
    end  
 
%%
for ienv = 3:12;
    for idata = 1%:length(dataf)
        EHL = [];
        ELL = [];
        for i2 =1:ngeom
            EHL(i2) = f1.HLKE{i2}(ienv)+sum(f1.HLEN{i2}(:,ienv))...
                +f1.HLE2{i2}(ienv)+f1.models{i2}.Hnuc(0);
            ELL(i2) =  f1.LLKE{i2}(ienv)+sum(f1.LLEN{i2}(:,ienv))...
                +f1.LLE2{i2}(ienv)+f1.models{i2}.Hnuc(0);
        end
        EHL = EHL - ((min(EHL)+ max(EHL))/2);
        ELL = ELL - ((min(ELL)+ max(ELL))/2);
        figure((idata+5)*100+ienv)
        hold on
        plot(ext(1:ngeom),EHL,'r-');
        plot(ext(1:ngeom),ELL,'k-');
        xlabel('Angle');
        ylabel('Total Energy [kcal/mol]')
    end
end

