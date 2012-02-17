%%
clear classes;
load('temp.mat');
m = Model3(frag,fnar,fdif);
m.addKEmodDiag(6,[1,2]);
m.addKEmodDiag(1,1);
m.addKEmodBonded(1,6,[1 2],[1 2]);
m.addKEmodBonded(6,6,[1 2],[1 2]);
mods = m.KEmods;
for i=1:size(mods,2)
   disp(['KE ',num2str(i),' ilist [',num2str(mods{i}.ilist), ...
      '] jlist [',num2str(mods{i}.jlist),'] ',mods{i}.mixer.desc]);
end
m.addENmodDiag(6,[1,2]);
m.addENmodDiag(1,1);
m.addENmodBonded(6,1,[1 2],[1 2]);
m.addENmodBonded(6,6,[1 2],[1 2]);
for iatom = 1:m.natom
   disp(['H1 EN for atom ',num2str(iatom)]);
   mods = m.ENmods{1,iatom};
   for i=1:size(mods,2)
      disp(['EN ',num2str(i),' ilist [',num2str(mods{i}.ilist), ...
         '] jlist [',num2str(mods{i}.jlist),'] ',mods{i}.mixer.desc]);
   end
end
disp(['npar = ',num2str(m.npar)])

m2 = Model2(frag,fnar,fdif);
pars = zeros(1,m2.npar);
m2.setPar(pars);
m2.sepKE = 1;
m2.sepSP = 0;
m2.rhodep = 0;

%%
clear classes;
load('temp.mat');
% KE diagonal    1: H  2: Cs  3: Cp
% Hen diagonal   4: H  5: Cs  6: Cp
% KE bonding     7: H-Cs  8: H-Cp  9: Cs-Cs 10: Cs-Cp 11: Cp-Cp  
% Hen bonding   12: H-Cs 13: H-Cp 14: Cs-Cs 15: Cs-Cp 16: Cp-Cp
m = Model3(frag,fnar,fdif);
m.addKEmodDiag(1,1);
m.addKEmodDiag(6,1);
m.addKEmodDiag(6,2);
m.addENmodDiag(1,1);
m.addENmodDiag(6,1);
m.addENmodDiag(6,2);

% m.addKEmodBonded(1,6,1,[1 2]);
% m.addKEmodBonded(6,6,[1 2],[1 2]);

 m.addKEmodBonded(1,6,1,1);
 m.addKEmodBonded(1,6,1,2);
 m.addKEmodBonded(6,6,1,1);
 m.addKEmodBonded(6,6,1,2);
 m.addKEmodBonded(6,6,2,2);

m.addENmodBonded(1,6,1,1);
m.addENmodBonded(1,6,1,2);
m.addENmodBonded(6,6,1,1);
m.addENmodBonded(6,6,1,2);
m.addENmodBonded(6,6,2,2);

% mods = m.ENmods;
% for i=1:size(mods,2)
%    disp(['KE ',num2str(i),' ilist [',num2str(mods{i}.ilist), ...
%       '] jlist [',num2str(mods{i}.jlist),'] ',mods{i}.mixer.desc]);
% end
for iatom = 1:m.natom
   disp(['H1 EN for atom ',num2str(iatom)]);
   mods = m.ENmods{1,iatom};
   for i=1:size(mods,2)
      disp(['EN ',num2str(i),' ilist [',num2str(mods{i}.ilist), ...
         '] jlist [',num2str(mods{i}.jlist),'] ',mods{i}.mixer.desc]);
   end
end

m2 = Model2(frag,fnar,fdif);
m2.sepKE = 1;
m2.sepSP = 1;
m2.rhodep = 0;

pars = rand(1,m2.npar+1);
m.setPar(pars);
m2.setPar(pars);
disp(['KE diff ',num2str( max(max(abs(m2.KE(1)-m.KE(1)))))]);

for iatom = 1:m.natom
   disp(['EN diff ',num2str(iatom),' ',num2str( max(max(abs(m2.H1en(iatom)-m.H1en(iatom)))))]);
end



