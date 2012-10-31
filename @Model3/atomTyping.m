function  atomTyping(obj)
for iatom = 1:obj.natom
    if (obj.aType(iatom) == 6)
        bondedAtoms = find(obj.isBonded(iatom,1:obj.natom));
        bAtom = obj.aType(bondedAtoms);
        if isempty(find(bAtom == 6))
            obj.aType(iatom) = 6;
        elseif length(find(bAtom == 6)) == 1
            obj.aType(iatom) = 601;
        elseif length(find(bAtom == 6)) == 2
            obj.aType(iatom) = 602;
        elseif length(find(bAtom == 6)) == 3
            obj.aType(iatom) = 603;
        else
            obj.aType = 604;
        end
    end
end
for iatom = 1:obj.natom
    if (obj.aType(iatom) == 1)
        bondedAtoms = find(obj.isBonded(iatom,1:obj.natom));
        bAtom = obj.aType(bondedAtoms);
        if (find(bAtom == 601))
            obj.aType(iatom) = 101;
        elseif (find(bAtom == 602))
            obj.aType(iatom) = 102;
        elseif (find(bAtom == 603))
            obj.aType(iatom) = 103;
        else
            obj.aType(iatom) = 1;
        end
    end
end
end
