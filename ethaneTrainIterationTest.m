clear classes
% close all
Iter = 1;
ngeom = 20;
nenv = 10;
dataf = {'ethanerDat'};
dsets = cell(1,1);
fitme = cell(1,2);
for idata = 1:length(dataf);
    dfile = ['datasets/',dataf{idata},'.mat'];
    % test data
    mf = MFactory;
    ms = MSet;
    ms.addData(dfile, 1:ngeom, 1:nenv,1,791);
    dsets{idata} = ms;
end
fct = cell(0,0);
load(['C:\Users\mtanha\MSQC\data\ethanerDat\all-',num2str(Iter),'.mat'],'fact');
for i= 1:length(fact.mixer)
    fact.mixer{i}.bonded = 1;
end
fact.mixer{end}.bonded= 0;
fct{1} = fact;
%%
color={'co','b-','r-','g-','k-','m-','y-','bx','rx','gx','kx','mx','yx'};
etot= [];
f1 = [];
for idata = 1:length(dataf);
    etotEnv = [];
    f1{idata} = fct{1}.makeFitme(dsets{idata});
    [err pnum etype] = f1{idata}.err(f1{idata}.getPars);
    nmb =[];
    etot = err(etype == 3);
    ic = 1;
    for inmb = 1:nenv
        icn = ic:ic+ngeom-1;
        ic = icn(end)+1;
    nmb = [nmb;icn];
    end
   geom = 1:ngeom;
    for i = 1:nenv
        ic = 0;
        for i2 = 1:ngeom
            ic = ic+1;       
            etotEnv(ic) =etot(nmb(i,i2));
        end
        figure(idata*100)
        plot(1:ngeom,etotEnv,color{i});
        hold on
        xlabel('r [Å]');
        ylabel('Total Error [kcal/mol]')
    end  
end

%%
for ienv = 9%:12;
    for idata = 1%:length(dataf)
        EHL = [];
        ELL = [];
        for i2 =1:ngeom
            EHL(i2) = f1{idata}.HLKE{i2}(ienv)+sum(f1{idata}.HLEN{i2}(:,ienv))...
                +f1{idata}.HLE2{i2}(ienv)+f1{idata}.models{i2}.Hnuc(0);
            ELL(i2) =  f1{idata}.LLKE{i2}(ienv)+sum(f1{idata}.LLEN{i2}(:,ienv))...
                +f1{idata}.LLE2{i2}(ienv)+f1{idata}.models{i2}.Hnuc(0);
              RLL(i2) = f1{idata}.models{i2}.frag.EhfEnv(ienv);
        end
        RLL = RLL-min(RLL);
        EHL = EHL-min(EHL);
        ELL = ELL-min(ELL);
        figure((Iter+2)*100+ienv)
        hold on
        plot(1:ngeom,EHL,'r-');
        plot(1:ngeom,ELL,'k-');
        plot(1:ngeom,RLL,'g-');
        xlabel('r [Å]');
        ylabel('Total Energy [kcal/mol]')
    end
end

