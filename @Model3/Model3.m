classdef Model3 < handle
    %{
   Interpolate between narrow and diffuse STO-3G matrix elements.
    %}
    properties
        % Input to the class
        frag;  % Fragment with regular STO-3G basis set
        fnar;  % Fragment with narrow  STO-3G basis set
        fdif;  % Fragment with diffuse STO-3G basis set
        
        % Most recent predictions of the model
        Ehf     % Hartree Fock energy
        Eorb    % (nbasis,1)      molecular orbital energies
        orb     % (nbasis,nbasis) molecular orbital coefficients
        EhfEnv   % (1,nenv)        Hartree-Fock energy in env
        EorbEnv; % (nbasis,nenv)   molecular orbital energies in env
        orbEnv;  % (nbasis,nbasis,nenv) molecular orbitals in env
        
        % Useful properties initialized in the constructor
        natom   % number of atoms in fragment
        nelec   % number of electrons in the fragment
        Z       % (1,natom) atomic numbers of the molecules
        rcart   % (3,natom) cartesian coordinates of the atoms
        nenv
        
        H2j     % {nbasis,nbasis} cell array of coulomb integrals
        H2k     % {nbasis,nbasis} cell array of exchange integrals
        
        nbasis  % number of atomic (and molecular) basis functions
        basisAtom  % (nbasis,1) atom # on which the function is centered
        basisType  % (nbasis,1) l quantum number: 0=s 1=p 2=d 3=d etc
        basisSubType % (nbasis,1) m quantum number: s=1 p=3 d=6 (cartesian)
        onAtom     % {natom,1}  list of basis functions on iatom
        valAtom    % {natom,type} list of valence basis functions of type
        %              (1-s 2-p) on iatom
        isBonded   % (natom,natom)  1 if atoms are bonded, 0 otherwise
        charges    % (natom,nenv+1)  current charges on the atoms
        bondOrders % (natom,natom,nenv+1) current bond orders
        
        mixers     % (1,n)   cell array of mixers that are currently in use
        KEmods     % {1,n}   cell array of modifications to KE operator
        ENmods   % {natom}{1,n} cell array of modifications to H1en opers
        % a modification has the following members
        %   ilist : modify ilist x jlist elements
        %   jlist :
        %   mixer  : pointer to a mix function
        
    end
    properties (Transient)
        densitySave   % cell array {1:nenv+1} of most recent density matrices
        % used to start HF iterations
    end
    methods
        function res = Model3(frag_,fnar_, fdif_)
            res.frag = frag_;
            res.fnar = fnar_;
            res.fdif = fdif_;
            res.natom = frag_.natom;
            res.nelec = frag_.nelec;
            res.Z     = frag_.Z;
            res.rcart = frag_.rcart;
            res.nenv  = frag_.nenv;
            res.nbasis = frag_.nbasis;
            res.basisAtom = frag_.basisAtom;
            res.basisType = frag_.basisType;
            res.basisSubType = frag_.basisSubType;
            for iatom = 1:res.natom
                res.onAtom{iatom,1} = find(res.basisAtom == iatom);
            end
            for iatom = 1:res.natom
                % kind of a hack. For s orbitals, we take the maximum value
                % from the list of basis functions on the atom, since this
                % will be the valence orbital (2s instead of 1s for C)
                res.valAtom{iatom,1} = find(res.basisAtom == iatom & ...
                    res.basisType == 0, 1, 'last' );
                % For p orbitals, we just take the ones that matach
                res.valAtom{iatom,2} = find(res.basisAtom == iatom & ...
                    res.basisType == 1);
            end
            res.isBonded = zeros(res.natom,res.natom);
            for iatom = 1:res.natom
                for jatom = 1:res.natom
                    res.isBonded(iatom,jatom) = res.bonded(iatom,jatom);
                end
            end
            res.KEmods = cell(0,0);
            res.ENmods = cell(1,res.natom);
            for i=1:res.natom
                res.ENmods{1,i} = cell(0,0);
            end
            res.densitySave = cell(1,res.nenv+1);
            res.mixers = cell(0,0);
            % Initialize charges and bond orders
            res.charges = zeros(res.natom,res.nenv+1);
            for ienv = 0:res.nenv
                res.charges(:,ienv+1) = res.frag.mcharge(ienv)';
            end
            % Initialize bond orders
            res.bondOrders = zeros(res.natom,res.natom,res.nenv+1);
            for ienv = 0:res.nenv
                res.bondOrders(:,:,ienv+1) = res.frag.calcBO(ienv);
            end
                     res.H2j = cell(res.nbasis,res.nbasis);
                     res.H2k = cell(res.nbasis,res.nbasis);
%                      H2ij = zeros(res.nbasis,res.nbasis);
%                      H2kl = zeros(res.nbasis,res.nbasis);
%             for i=1:res.nbasis
%                 for j=1:res.nbasis
%                     for k = 1:res.nbasis
%                         for l = 1:res.nbasis
%                             res.H2ij(k,l) =(frag_.H2(sym_hash(sym_hash(i,j),sym_hash(k,l))));
%                             res.H2kl(k,l) =(frag_.H2(sym_hash(sym_hash(i,k),sym_hash(l,j))));           
%                         end    
%                     end
%                     res.H2j{i,j} = squeeze(H2ij);
%                     res.H2k{i,j} = squeeze(H2kl);
%                 end
%             end
%         for i=1:res.nbasis
%             for j=1:res.nbasis
% 
%                res.H2j{i,j} = squeeze(frag_.H2(i,j,:,:));
%                res.H2k{i,j} = squeeze(frag_.H2(i,:,:,j));
%             end
%         end
         res.EhfEnv  = zeros(1,res.nenv);
         res.EorbEnv = zeros(res.nbasis,res.nenv);
         res.orbEnv  = zeros(res.nbasis,res.nbasis,res.nenv);
      end
      function res = npar(obj)
         res = 0;
         for i=1:size(obj.mixers,2)
            res = res + obj.mixers{1,i}.npar;
         end
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
       function setPars(obj, pars)
          ic = 1;
          for i = 1:size(obj.mixers,2)
             mtemp = obj.mixers{1,i};
             n = mtemp.npar;
             if (n > 0)
                mtemp.setPars( pars(ic:(ic+n-1)));
             end
             ic = ic + n;
          end
       end
      function res = H1(obj, ienv)
         if (nargin < 2)
            ienv = 0;
         end
         res = obj.KE(ienv);
         for iatom = 1:obj.natom
            res = res + obj.H1en(iatom,ienv);
         end
         if (ienv > 0)
            res = res + obj.frag.H1Env(:,:,ienv);
         end
      end
      function res = KE(obj,ienv)
         % start with H1 matrix of unmodified STO-3G
         res   = obj.frag.KE;
         
         for imod = 1:size(obj.KEmods,2)
            mod = obj.KEmods{1,imod};
            ii = mod.ilist;
            jj = mod.jlist;
            res(ii,jj) = res(ii,jj) - obj.frag.KE(ii,jj) ...
               + mod.mixer.mix(obj.fnar.KE(ii,jj), obj.fdif.KE(ii,jj), ...
               obj,ii,jj,ienv);
         end
      end
      function mixUsed = addKEmodDiag(obj,Zs,types,mix)
         if (nargin < 3)
            types = [1 2];
         end
         if (nargin < 4)
            mix = Mixer;
            % create a mix object for these blocks
            mix.desc = ['KE Diag Zs [',num2str(Zs),'] types [', ...
               num2str(types),']'];
         end
         mixerAdded = 0;
         for iZ = Zs % loop over all desired elements
            for iatom = find(obj.Z == iZ) % loop over atoms of this element
               ilist = []; % orbitals of "types" on this atom
               for itype = types
                  ilist = [ilist obj.valAtom{iatom,itype}'];
               end
               % Create a modifier for this block of the matrix
               mod.ilist = ilist;
               mod.jlist = ilist;
               mod.mixer = mix;
               obj.KEmods{1,end+1} = mod;
               mixerAdded = 1;
            end
         end
         if (mixerAdded)
            obj.addMixer(mix);
            mixUsed = mix;
         else
            mixUsed = [];
         end
      end
      function mixUsed = addKEmodBonded(obj,Z1,Z2,types1,types2, mix)
         if (nargin < 4)
            types1 = [1 2];
         end
         if (nargin < 5)
            types2 = [1 2];
         end
         if (nargin < 6)
            mix = Mixer();
            mix.desc = ['KE bonded Z [',num2str(Z1),'] types [', ...
               num2str(types1),'] with Z [',num2str(Z2),'] types [', ...
               num2str(types2),']'];
         end
         mixerAdded = 0;
         for iatom = 1:obj.natom
            for jatom = 1:obj.natom
               if (obj.isBonded(iatom,jatom))
                  for itype = 1:2
                     for jtype = 1:2
                        addmods = 0;
                        if ((obj.Z(iatom) == Z1) && (obj.Z(jatom) == Z2))
                           if (any(ismember(itype,types1)) && ...
                                 any(ismember(jtype,types2)) )
                              addmods = 1;
                           end
                        end
                        if ((obj.Z(iatom) == Z2) && (obj.Z(jatom) == Z1))
                            if (any(ismember(itype,types2)) && ...
                                 any(ismember(jtype,types1)) )
                              addmods = 1;
                            end
                        end
                        if (addmods)
                           mixerAdded = 1;
                           mod.ilist = obj.valAtom{iatom,itype}';
                           mod.jlist = obj.valAtom{jatom,jtype}';
                           mod.mixer = mix;
                           obj.KEmods{1,end+1} = mod;
                        end
                     end
                  end
               end
            end
         end
         if (mixerAdded)
            obj.addMixer(mix);
            mixUsed = mix;
         else
            mixUsed = [];
         end
      end
      function res = H1en(obj, iatom, ienv)
         % start with H1 matrix of unmodified STO-3G
         res   = obj.frag.H1en(:,:,iatom);
         
         mods = obj.ENmods{1,iatom};
         for imod = 1:size(mods,2)
            mod = mods{1,imod};
            ii = mod.ilist;
            jj = mod.jlist;
            res(ii,jj) = res(ii,jj) - obj.frag.H1en(ii,jj,iatom) ...
               + mod.mixer.mix(obj.fnar.H1en(ii,jj,iatom), ...
               obj.fdif.H1en(ii,jj,iatom), obj, ii, jj, ienv );
         end
      end
      function mixUsed = addENmodDiag(obj,Zs,types,mix)
         if (nargin < 3)
            types = [1 2];
         end
         if (nargin < 4)
            mix = Mixer;
            mix.desc = ['EN Diag Zs [',num2str(Zs),'] types [', ...
               num2str(types),']'];
         end
         mixerAdded = 0;
         % create a mix object that will be the same for all these blocks
         for iZ = Zs % loop over all desired elements
            for iatom = find(obj.Z == iZ) % loop over atoms of this element
               ilist = []; % orbitals of "types" on this atom
               for itype = types
                  ilist = [ilist obj.valAtom{iatom,itype}'];
               end
               % Create a modifier for this block of the matrix
               mod.ilist = ilist;
               mod.jlist = ilist;
               mod.mixer = mix;
               obj.ENmods{iatom}{1,end+1} = mod;
               mixerAdded = 1;
            end
         end
         if (mixerAdded)
            obj.addMixer(mix);
            mixUsed = mix;
         else
            mixUsed = [];
         end
      end
      function mixUsed = addENmodBonded(obj,Z1,Z2,types1,types2, mix)
         if (nargin < 4)
            types1 = [1 2];
         end
         if (nargin < 5)
            types2 = [1 2];
         end
         if (nargin < 6)
            mix = Mixer();
            mix.desc = ['EN bonded Z ',num2str(Z1),' types [', ...
               num2str(types1),'] with Z ',num2str(Z2),' types [', ...
               num2str(types2),']'];
         end
         mixerAdded = 0;
         for operAtom = 1:obj.natom
            for iatom = 1:obj.natom
               for jatom = 1:obj.natom
                  if (obj.isBonded(iatom,jatom) && ...
                        ((iatom==operAtom) || (jatom==operAtom)) )
                     for itype = 1:2
                        for jtype = 1:2
                           addmods = 0;
                           if ((obj.Z(iatom) == Z1) && (obj.Z(jatom) == Z2))
                              if (any(ismember(itype,types1)) && ...
                                    any(ismember(jtype,types2)) )
                                 addmods = 1;
                              end
                           end
                           if ((obj.Z(iatom) == Z2) && (obj.Z(jatom) == Z1))
                              if (any(ismember(itype,types2)) && ...
                                    any(ismember(jtype,types1)) )
                                 addmods = 1;
                              end
                           end
                           if (addmods)
                              mod.ilist = obj.valAtom{iatom,itype}';
                              mod.jlist = obj.valAtom{jatom,jtype}';
                              mod.mixer = mix;
                              obj.ENmods{1,operAtom}{1,end+1} = mod;
                              mixerAdded = 1;
                           end
                        end
                     end
                  end
               end
            end
         end
         if (mixerAdded)
            obj.addMixer(mix);
            mixUsed = mix;
         else
            mixUsed = [];
         end
      end
      function mixUsed = addENmodBonded1(obj,Z1,Z2,types1,types2, mix)
         % Modifies only the EN operator for atoms that match Z1
         if (nargin < 4)
            types1 = [1 2];
         end
         if (nargin < 5)
            types2 = [1 2];
         end
         if (nargin < 6)
            mix = Mixer();
            mix.desc = ['EN bonded(1 only) Z ',num2str(Z1),' types [', ...
               num2str(types1),'] with Z ',num2str(Z2),' types [', ...
               num2str(types2),']'];
         end
         mixerAdded = 0;
         for iatom = find(obj.Z == Z1)
            for jatom = find(obj.Z == Z2)
               if (obj.isBonded(iatom,jatom))
                  for itype = 1:2
                     for jtype = 1:2
                        if (any(ismember(itype,types1)) && ...
                              any(ismember(jtype,types2)) )
                           mod.ilist = obj.valAtom{iatom,itype}';
                           mod.jlist = obj.valAtom{jatom,jtype}';
                           mod.mixer = mix;
                           obj.ENmods{1,iatom}{1,end+1} = mod;
                           mod.jlist = obj.valAtom{iatom,itype}';
                           mod.ilist = obj.valAtom{jatom,jtype}';
                           obj.ENmods{1,iatom}{1,end+1} = mod;
                           mod.mixer = mix;
                           mixerAdded = 1;
                        end
                     end
                  end
               end
            end
         end
         if (mixerAdded)
            obj.addMixer(mix);
            mixUsed = mix;
         else
            mixUsed = [];
         end
      end
      function res = Hnuc(obj,ienv)
         if (ienv == 0)
            res = obj.frag.Hnuc;
         else
            res = obj.frag.HnucEnv(ienv);
         end
      end
      function mixUsed = addH2modDiag(obj,Zs,mix)
         if (nargin < 3)
            mix = Mixer;
            % create a mix object for these blocks
            mix.desc = ['H2 Diag Zs [',num2str(Zs),']'];
         end
         mixerAdded = 0;
         for iZ = Zs % loop over all desired elements
            for iatom = find(obj.Z == iZ) % loop over atoms of this element
               ilist = obj.onAtom{iatom}'; % orbitals on this atom
               % Create a modifier for this block of the matrix
               mod.ilist = ilist;
               mod.jlist = ilist;
               mod.klist = ilist;
               mod.llist = ilist;
               mod.mixer = mix;
               obj.H2mods{1,end+1} = mod;
               mixerAdded = 1;
            end
         end
         if (mixerAdded)
            obj.addMixer(mix);
            mixUsed = mix;
         else
            mixUsed = [];
         end
      end
      function mixUsed = addH2modOffDiag(obj,Z1,Z2, mix)
         if (nargin < 4)
            mix = Mixer();
            mix.desc = ['KE bonded Z ',num2str(Z1),' with Z ', ...
               num2str(Z2)];
         end
         mixerAdded = 0;
         for iatom = 1:obj.natom
            for jatom = 1:obj.natom
               if ( ((obj.Z(iatom) == Z1) && (obj.Z(jatom) == Z2)) || ...
                     ((obj.Z(iatom) == Z2) && (obj.Z(jatom) == Z1)) )
                  mixerAdded = 1;
                  mod.ilist = obj.onAtom{iatom}';
                  mod.jlist = obj.onAtom{iatom}';
                  mod.klist = obj.onAtom{jatom}';
                  mod.llist = obj.onAtom{jatom}';
                  mod.mixer = mix;
                  obj.H2mods{1,end+1} = mod;
               end
            end
         end
         if (mixerAdded)
            obj.addMixer(mix);
            mixUsed = mix;
         else
            mixUsed = [];
         end
      end
      function res = H2(obj,ienv)
         if (nargin < 2)
            ienv = 0;
         end
         res = obj.frag.H2;
         for imod = 1:length(obj.H2mods)
            mod = obj.H2mods{imod};
            i = mod.ilist;
            j = mod.jlist;
            k = mod.klist;
            l = mod.llist;
            res(i,j,k,l) = res(i,j,k,l) - obj.frag.H2(i,j,k,l) ...
               + mod.mixer.mix(obj.fnar.H2(i,j,k,l), ...
               obj.fdif.H2(i,j,k,l), obj, i, j, ienv);
         end
      end
      function res = S(obj)
         res = obj.frag.S;
      end
      function updateChBO(obj)
            % Updates charges and bond orders
            obj.solveHF;
            for ienv = 0:obj.nenv
                obj.charges(:,ienv+1) = obj.mcharge(ienv)';
                obj.bondOrders(:,:,ienv+1) = obj.calcBO(ienv);
            end
      end
   end % methods
end %