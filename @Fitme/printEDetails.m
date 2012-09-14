function res = printEDetails(obj, ofile)
if (nargin < 2)
    ofile = 1;
end

molName = {'CH4' 'C2H6' 'C2H4' 'C3H8' 'C4H6'};

[err pnum etype modn envn] = obj.err(obj.getPars);

err =err*627.509;
eke = err(etype==1);
eH  = err(etype==11);
eC  = err(etype==16);
e2  = err(etype==2);
sumerr = [];
for imod = unique(modn)
    for ienv = unique(envn(modn==imod))
        emke = err(modn==imod & envn==ienv & etype==1);
        emH = sum(err(modn==imod & envn==ienv & etype==11));
        emC = sum(err(modn==imod & envn==ienv & etype==16));
        em2 = err(modn==imod & envn==ienv & etype==2);
        sumerr = [sumerr, emke+emH+emC+em2];
    end
end
tot = norm(err)/sqrt(length(err));
ke = norm(eke)/sqrt(length(eke));
H = norm(eH)/sqrt(length(eH));
C = norm(eC)/sqrt(length(eC));
r2 = norm(e2)/sqrt(length(e2));
sumerr = norm(sumerr)/sqrt(length(sumerr));
fprintf(ofile,'tot %5.3f ke %5.3f H %5.3f C %5.3f E2 %5.3f sumerr %5.3f \n',...
    tot, ke, H, C, r2, sumerr);
if (length(unique(pnum)) > 1)
    for ip = unique(pnum)
        etot = err(pnum==ip);
        eke = err(etype==1 & pnum==ip);
        eH  = err(etype==11 & pnum==ip);
        eC  = err(etype==16 & pnum==ip);
        e2  = err(etype==2 & pnum==ip);
        sumerr = [];
        for imod = unique(modn(pnum==ip))
            for ienv = unique(envn(modn==imod))
                emke = err(modn==imod & envn==ienv & etype==1);
                emH = sum(err(modn==imod & envn==ienv & etype==11));
                emC = sum(err(modn==imod & envn==ienv & etype==16));
                em2 = err(modn==imod & envn==ienv & etype==2);
                sumerr = [sumerr, emke+emH+emC+em2];
            end
        end
        tot = norm(etot)/sqrt(length(etot));
        ke = norm(eke)/sqrt(length(eke));
        H = norm(eH)/sqrt(length(eH));
        C = norm(eC)/sqrt(length(eC));
        r2 = norm(e2)/sqrt(length(e2));
        sumerr = norm(sumerr)/sqrt(length(sumerr));
        
        fprintf(ofile,'>> %s ',molName{ip-790});
        fprintf(ofile,'tot %5.3f ke %5.3f H %5.3f C %5.3f E2 %5.3f sumerr %5.3f \n',...
            tot, ke, H, C, r2, sumerr);
    end
end

fprintf(ofile,'\n');
end


