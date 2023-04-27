# Useful functions for handling terrains in linear coordinates

# Returns true if i is a coordinate inside the terrain
function ValidCoord(n, i)
    return i >= 1 && i <= n^2
end

# Returns true if i+dir is next to i in the terrain, false otherwise
function IsNeighbor(n,i,dir)
    if !ValidCoord(n,i)
        return false
    end

    if dir in (1,-1)
        return ValidCoord(n,i+dir) && div(i+dir-1,n) == div(i-1,n)
    else
        return ValidCoord(n, i+dir)
    end
end

# Change une direction du type -1,-n,1,n en une direction du type 0,1,2,3 
# (correspondant respectivement à gauche, haut, droite, bas)
function ChangeDirType(n,dir)
    if abs(dir) == 1
        return dir+1
    else
        return div(dir,n) + 2
    end
end


# Retourne la direction (0,1,2,3) de i à j, -1 s'il y a une erreur
function GetDir(n,i,j)
    if !ValidCoord(n,i) || !ValidCoord(n,j)
        return -1
    end

    dir = j - i
    if !IsNeighbor(n,i,dir)
        return -1
    end
    
    return ChangeDirType(n,dir)
end

function ToSolutionFormat(n, cycle)
    out = Vector{Tuple{Int64, Int64, Int64}}()
    for i in 1:n^2
        dirDepart = -1
        dirArrive = -1
        iInCycle = false
        for j in (i+1):n^2
            if (i,j) in cycle || (j,i) in cycle
                iInCycle = true

                if dirDepart == -1
                    dirDepart = GetDir(n,i,j)
                elseif dirArrive == -1
                    dirArrive = GetDir(n,i,j)
                end
            end
        end

        if iInCycle
            out = vcat(out, (i, dirArrive, dirDepart))
        end
    end

    return out
end