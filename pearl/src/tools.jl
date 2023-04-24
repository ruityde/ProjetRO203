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