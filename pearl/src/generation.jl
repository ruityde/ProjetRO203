# This file contains methods to generate a data set of instances (i.e., sudoku grids)

using Random:shuffle

include("io.jl")
include("tools.jl")

"""
Generate an n*n grid with a given density
Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid

Horizontal
-o-

Vertical
|
o
|


1   |   |   2
    |   |
  --o   o--
  --o   o--
    |   |   
3   |   |   4


"""

function generateInstance(n::Int64, density::Float64, max_points::Int64) 
    cycleLen, cycle = GenerateCycle(n, density)

    blancs = Vector{Int64}()
    noirs = Vector{Int64}()

    #Détection des blancs

    for arete in cycle
        isWhite = false
        i,j = arete[1],arete[2]

        #Horizontal
        if i%n != 1
            if j == i+1
                if (i-1,i) in cycle
                    if i-n >0
                        if (i-n-1,i-1) in cycle || (i-n+1,i+1) in cycle
                            isWhite = true
                        end
                    end
                    if i+n <= n^2
                        if (i-1, i+n-1) in cycle || (i+1,i+n+1) in cycle
                            isWhite = true
                        end
                    end
                end
            end
        end

        #Vertical
        if i>n
            if j == i+n
                if (i-n,i) in cycle
                    if i%n != 1
                        if (i-n-1,i-n) in cycle || (i+n-1,i+n) in cycle
                            isWhite = true
                        end
                    end
                    if i%n < n
                        if (i-n,i-n+1) in cycle || (i+n,i+n+1) in cycle
                            isWhite = true
                        end
                    end
                end
            end
        end

        if isWhite
            push!(blancs,i)
        end
    end

    #Détection des noirs

    for arete in cycle
        isBlack = false
        i,j = arete[1], arete[2]

        #Détection 2 et 4
        if i%n < n-1
            if j == i+1

                #Détection 4
                if i + 2*n <= n^2
                    if (i,i+n) in cycle
                        if (i+1, i+2) in cycle && (i+n, i+2*n) in cycle
                            isBlack = true
                        end
                    end
                end

                #Détection 2
                if i - 2*n > 0
                    if (i-n,i) in cycle
                        if (i+1,i+2) in cycle && (i-2*n, i-n) in cycle
                            isBlack = true
                        end
                    end
                end
            end
        end

        #Détection 1 et 3
        if i%n > 2 || i%n == 0
            if j == i+n

                #Détection 3
                if i+2*n <= n^2
                    if (i-1,i) in cycle
                        if (i-2,i-1) in cycle && (i+n,i+2*n) in cycle
                            isBlack = true
                        end
                    end
                end

                #Détection 1
                if i-n > 0
                    if (i+n-1,i+n) in cycle
                        if (i+n-2,i+n-1) in cycle && (i-n,i) in cycle
                            isBlack = true
                            i = j
                        end
                    end
                end
            end
        end

        if isBlack
            push!(noirs, i)
        end
    end

    # On s'assure que chaque point n'apparait qu'une seule fois
    # (évite des redondances et des problèmes avec Cplex lors de la déclaration des contraintes)
    blancs = unique(blancs)
    noirs = unique(noirs)

    # On retourne au plus max_points de chaque couleur, de manière aléatoire et triés par ordre d'indice croissant
    blancs = sort(shuffle(blancs)[1:min(max_points,length(blancs))])
    noirs = sort(shuffle(noirs)[1:min(max_points,length(noirs))])

    #DisplayTerrainWithCycle(cycle, n, blancs, noirs)

    return cycleLen, blancs, noirs
end 


function GenerateCycle(n, density)
    wantedLen = round(density*n^2)

    x = hcat([[0 for i in 1:n^2] for j in 1:n^2]...)
    hasBeenInCycle = hcat([0 for i in 1:n^2]...)

    # Choix d'un point de départ du cycle
    i = rand(1:n^2)

    # On génère le premier carré
    # Choix d'une direction aléatoire valide
    valid = false
    dirJ = 0
    j = i
    while !valid
        dirJ =  rand((-n, -1, 1, n))
        j = i + dirJ
        if ValidCoord(n, j) && IsNeighbor(n, i, dirJ)
            valid = true
        end
    end

    # Choix d'une direction aléatoire valide et orthogonale à la direction précédente
    dirK = 0
    k = i
    if abs(dirJ) == n
        dirK = 1
    else
        dirK = n
    end
    dirK *= rand((1, -1))
    k = i + dirK
    if !ValidCoord(n, k) || !IsNeighbor(n, i, dirK)
        dirK *= -1
        k = i + dirK
        if !ValidCoord(n, k) || !IsNeighbor(n, i, dirK)
            throw(DomainError((n,i,k,j), "Couldn't make a square in the terrain"))
        end
    end

    # On ajoute le carré i,j,j+dirK,k
    AddLine(x,hasBeenInCycle,i,j)
    AddLine(x,hasBeenInCycle,j,j+dirK)
    AddLine(x,hasBeenInCycle,j+dirK,k)
    AddLine(x,hasBeenInCycle,k,i)
    cycleLen = 4

    # Nombre maximum d'itération
    maxIterations = 2*(n^2)
    iterations = 0
    while iterations < maxIterations && cycleLen < wantedLen
        # Choix d'un point aléatoire sur le cycle ayant une direction en dehors du cycle
        exist = false
        i = 0
        dirK = 0
        while !exist
            i = RandomInCycle(x, n)
            exist, dirK = RandomDirOutCycle(hasBeenInCycle,n,i)
        end

        # Choix d'une direction aléatoire dirL orthogonale à dirK tq i+dirL soit dans le cycle
        dirL = 0
        if abs(dirK) == n
            dirL = 1
        else
            dirL = n
        end
        dirL *= rand((1, -1))
        l = i + dirL
        if !ValidCoord(n,l) || !IsInCycle(x,n,l) || x[i,l] != 1 || !IsNeighbor(n, i, dirL)
            dirL *= -1
            l = i + dirL
            if !ValidCoord(n, l) || !IsInCycle(x,n,l) || x[i,l] != 1 || !IsNeighbor(n, i, dirL)
                throw(DomainError((l,i,dirK, IsInCycle(x,n,l), IsInCycle(x,n,i+dirK), IsInCycle(x,n,i)), "Error: maybe k is not out of the cycle, or i is not in the cycle"))
            end
        end

        # On essaie d'ajouter le point
        # Si ca échoue, on est dans la situation de **** explicitée dans le rapport
        # On effectue alors une rotation du problème
        trials = 0
        pointsAdded = TryAddPoint(x,n,hasBeenInCycle,i,dirK,dirL)
        while pointsAdded == -1 && trials < 4
            i = k + dirL
            tempDirK = -dirL
            dirL = dirK
            dirK = tempDirK

            trials += 1
            if ValidCoord(n, i) && ValidCoord(n, i+dirK) && ValidCoord(n, i+dirL)
                pointsAdded = TryAddPoint(x,n,hasBeenInCycle,i,dirK,dirL)
            end
        end

        cycleLen += pointsAdded

        #println("\nIteration ", iterations, ": Points in the cycle ", cycleLen, " / ", wantedLen)
        #PrintTerrain(x,n)
        iterations += 1
    end

    #PrintTerrain(x,n)

    return cycleLen, [(i, j) for i in 1:n^2, j in 1:n^2 if i < j && x[i,j]==1]
end

# Fonction ajoutant le point i+dirK au cycle via le carré passant par i,i+dirK,i+dirK+dirL,i+dirL
# Retourne le nombre d'éléments ajoutés au cycle
function TryAddPoint(x,n,hasBeenInCycle,i, dirK, dirL)
    k = i + dirK
    l = i + dirL
    pointsAdded = 0
    if !IsInCycle(x,n,l+dirK)
        # Ajout et suppression des arrêtes au cycle
        AddLine(x,hasBeenInCycle, i, k)
        AddLine(x,hasBeenInCycle, k, l+dirK)
        AddLine(x,hasBeenInCycle, l+dirK, l)

        RemoveLine(x, i, l)

        pointsAdded = 2
    elseif x[l+dirK, l] == 1
        # Ajout et suppression des arrêtes au cycle
        AddLine(x,hasBeenInCycle, i, k)
        AddLine(x,hasBeenInCycle, k, k+dirL)

        RemoveLine(x, l+dirK, l)
        RemoveLine(x, i, l)

        pointsAdded = 1
    end

    return pointsAdded
end

# Returns true if a direction around i pointing outside of the cycle exists, false otehrwise
# Returns a random direction among the ones pointing outsideof the cycle
function RandomDirOutCycle(hasBeenInCycle,n,i)
    exists = false
    dirOut = []
    for dir in (-n, -1, 1, n)
        if ValidCoord(n,i+dir) && hasBeenInCycle[i+dir] != 1 && IsNeighbor(n,i,dir)
            dirOut = vcat(dirOut, dir)
            exists = true
        end
    end

    if (exists)
        dir = rand(dirOut)
    else
        dir = 0
    end

    return exists, dir
end

# Adds a line between i and j in x
function AddLine(x, hasBeenInCycle, i, j)
    x[i, j] = 1
    x[j, i] = 1

    hasBeenInCycle[i] = 1
    hasBeenInCycle[j] = 1
end

# Remove the line between i and j in x
function RemoveLine(x, i, j)
    x[i, j] = 0
    x[j, i] = 0
end

# Returns a random point in the cycle in x
function RandomInCycle(x,n)
    cycleLen = sum(x)/2
    if cycleLen == 0
        throw(DomainError(cycleLen, "The terrain has no cycle"))
    end
    num = rand(1:cycleLen)
    found = 0
    id = 1
    while found < num && ValidCoord(n,id)
        if IsInCycle(x, n, id)
            found+=1
        end
        id += 1
    end
    
    return id-1
end

# Returns true if i is in the cycle defined in x
function IsInCycle(x, n, i)
    if !ValidCoord(n,i)
        return false
    end

    isInCycle = false
    for dir in (-1, -n, 1, n)
        if ValidCoord(n, i+dir) && IsNeighbor(n, i, dir)
            isInCycle = isInCycle || x[i, i+dir] == 1
        end
    end
    return isInCycle
end

# Retourne au plus 2 directions dans lesquelle la case i est liée à une autre case du cycle
function GetDirsAround(x,n,i)
    dirA = -1
    dirD = -1
    for dir in (-n, -1, 1, n)
        if ValidCoord(n,i+dir) && x[i,i+dir]==1
            if dirA == -1
                dirA = ChangeDirType(n,dir)
            else
                dirD = ChangeDirType(n,dir)
            end
        end
    end

    return dirA, dirD
end

# Affiche le terrain à partir de l'ensemble x des arrètes du cycle
function PrintTerrain(x,n)
    out = Vector{Tuple{Int64, Int64, Int64}}()
    for i in 1:n^2
        if IsInCycle(x,n,i)
            dirArrive, dirDepart = GetDirsAround(x,n,i)
            if dirArrive == -1 || dirDepart == -1
                println("Error: la case ", i, " n'est liées qu'à une seule case")
            end
            out = vcat(out, (i, dirArrive, dirDepart))
        end
    end
    
    displayGrid(n, Vector{Int64}(), Vector{Int64}(), out)
end

# Affiche le terrain à partir de l'ensemble x des arrètes du cycle
function DisplayTerrainWithCycle(cycle,n,blancs,noirs)
    cycleFormat = ToSolutionFormat(n,cycle)
    
    displayGrid(n, blancs, noirs, cycleFormat)
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()
    # For each grid size considered
    for size in [4, 5, 6, 7, 8, 9, 10]

        # For each grid density considered
        for density in [0.6, 0.7, 0.8]

            # For each number of points
            for max_points in [round(Int64, density*size^2/i) for i in 2:5]
                
                # Generate 3 instances
                for instance in 1:3

                    fileName = "../data/instance_t" * string(size) * "_d" * string(density) * "_mp" * string(max_points) * "_" * string(instance) * ".txt"

                    if !isfile(fileName)
                        println("-- Generating file " * fileName)
                        cycleLen, blancs, noirs = generateInstance(size, density, max_points)
                        saveInstance(size, cycleLen, blancs, noirs, fileName)
                    else
                        println("File already created " * fileName)
                    end 
                end
            end
        end
    end
end
