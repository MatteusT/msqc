clear classes
close all

dataf = {'ch4ext-orig','ch4asym-orig'};
dsets = cell(1,1);
fitme = cell(1,2);
for idata = 1:length(dataf);
    dfile = ['datasets/',dataf{idata},'.mat'];
    % test data
    mf = MFactory;
    ms = MSet;
    if idata == 1
        ms.addData(dfile, 1:15, 1:12,1,791);
    elseif idata == 2
        ms.addData(dfile, 6:15, 1:12,1,791);
    end
    dsets{idata} = ms;
end
fct = cell(0,0);
load(['C:\Users\Matteus\Research\msqc\dec12a\hybridslater\ch4rDat\all-3.mat'],'fact');
for i= 1:length(fact.mixer)
    fact.mixer{i}.bonded = 1;
end
fact.mixer{end}.bonded= 0;
fct{1} = fact;
%%
color={'b-','r-','g-','k-','m-','y-','bx','rx','gx','kx','mx','yx'};
etot1= [];
etot2= [];
f1 = [];
for idata = 1:length(dataf);
    etotEnv = [];
    f1{idata} = fct{1}.makeFitme(dsets{idata});
    [err pnum etype] = f1{idata}.err(f1{idata}.getPars);
    nmb =[];
    if idata == 1
        range= 1:180;
        ngeom = 15;
          etot1 = err(etype == 3);
    elseif idata == 2
        range= 1:120;
        ngeom = 10;
        etot2 = err(etype == 3);
    end
    
    step2 = 0;
    estep = 11;
    
    for in = 1:ngeom
        step1 = step2+1;
        step2 = step1 + estep;
        nmb = [nmb; range(step1:step2)];
    end

    ext = 0.85:0.03:1.42;
    for i = 1:12
        ic = 0;
        for i2 = 1:ngeom
            ic = ic+1;
            if idata == 1
            etotEnv(ic) =etot1(nmb(i2,i));
            extmax = 15;
            elseif idata == 2
            etotEnv(ic) =etot2(nmb(i2,i));
            extmax = 10;
            end
        end
        figure(idata*100)
        plot(ext(1:extmax),etotEnv,color{i});
        hold on
        xlabel('r [Å]');
        ylabel('Total Error [kcal/mol]')
    end  
end

%%
for ienv = 1%:12;
    for idata = 1%:length(dataf)
        EHL = [];
        ELL = [];
        for i2 =1:ngeom
            EHL(i2) = f1{idata}.HLKE{i2}(ienv)+sum(f1{idata}.HLEN{i2}(:,ienv))...
                +f1{idata}.HLE2{i2}(ienv)+f1{idata}.models{i2}.Hnuc(0);
            ELL(i2) =  f1{idata}.LLKE{i2}(ienv)+sum(f1{idata}.LLEN{i2}(:,ienv))...
                +f1{idata}.LLE2{i2}(ienv)+f1{idata}.models{i2}.Hnuc(0);
        end
        figure((idata+5)*100+ienv)
        hold on
        plot(ext(1:extmax),EHL,'r-');
        plot(ext(1:extmax),ELL,'k-');
        xlabel('r [Å]');
        ylabel('Total Energy [kcal/mol]')
    end
end

