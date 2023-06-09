# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX, JuMP

include("generation.jl")
include("heuristique.jl")
include("tools.jl")

TOL = 0.00001

function ToBigTerrain(n, N, i)
    return (div(i-1,n)+1)*N + (i-1)%n + 2
end

function ToSmallTerrain(n,N,I)
    return (div(I-1,N)-1)*n + (I-1)%N
end

"""
Solve an instance with CPLEX
"""
function cplexSolve(n::Int, cycleLen::Int, noirs::Array{Int}, blancs::Array{Int})

    # Taille du terrain avec les variables de bord
    N = n+2
    # Indices des cases noires dans le terrain avec les bords supplémentaires
    newNoirs = [ToBigTerrain(n, N, i) for i in noirs]
    # Indices des cases blanches dans le terrain avec les bords supplémentaires
    newBlancs = [ToBigTerrain(n,N,i) for i in blancs]

    # Create the model
    m = Model(CPLEX.Optimizer)

    # Permet d'afficher le nom des contraintes problématique pour debug
    set_optimizer_attribute(m, CPLEX.PassNames(), true)

    @objective(m, Max, 0)

    # Création des variables du problème
    @variable(m, x[1:N^2, 0:3, 0:3], Bin)
    @variable(m, u[1:n^2], Int)

    # Aucun chemin ne passe sur les bords du terrain
    # Haut du terrain
    @constraint(m, Bords_Terrain_Haut[i in 1:N], sum([x[i,j,k] for j in 0:3, k in 0:3]) == 0)
    # Bas du terrain
    @constraint(m, Bords_Terrain_Bas[i in (N^2-N+1):N^2], sum([x[i,j,k] for j in 0:3, k in 0:3]) == 0)
    # Bords du terrain
    @constraint(m, Bords_Terrain_Cotes[i in 1:N^2; i%N <= 1], sum([x[i,j,k] for j in 0:3, k in 0:3]) == 0)

    # Aucun chemin ne mène ou ne sort d'un bord du terrain
    # Haut du terrain
    @constraint(m, Bords_Terrain_Acces_Haut[i in (N+2):(2N-1)], sum([x[i,1,k] + x[i,k,1] for k in 0:3]) == 0)
    # Bas du terrain
    @constraint(m, Bords_Terrain_Acces_Bas[i in (N^2-2*N+2):(N^2-N-1)], sum([x[i,3,k] + x[i,k,3] for k in 0:3]) == 0)
    # Bords du terrain
    @constraint(m, Bords_Terrain_Acces_Droite[i in (N+2):(N^2-N-1); i%N == N-1], sum([x[i,2,k] + x[i,k,2] for k in 0:3]) == 0)
    @constraint(m, Bords_Terrain_Acces_Gauche[i in (N+2):(N^2-N-1); i%N == 2], sum([x[i,0,k] + x[i,k,0] for k in 0:3]) == 0)

    # Empêche de passer 2 fois par la même case
    @constraint(m, Non_croisement[i in (N+2):(N^2-N-1); i%N > 1], sum([x[i,j,k] for j in 0:3, k in 0:3]) <= 1)

    #Continuité des chemins
    @constraint(m, Continuité_Gauche[i in (N+2):(N^2-N-1); i%N > 1], sum([x[i,k,0] - x[i-1,2,k] for k in 0:3]) == 0)
    @constraint(m, Continuité_Haut[i in (N+2):(N^2-N-1); i%N > 1], sum([x[i,k,1] - x[i-N,3,k] for k in 0:3]) == 0)
    @constraint(m, Continuité_Droite[i in (N+2):(N^2-N-1); i%N > 1], sum([x[i,k,2] - x[i+1,0,k] for k in 0:3]) == 0)
    @constraint(m, Continuité_Bas[i in (N+2):(N^2-N-1); i%N > 1], sum([x[i,k,3] - x[i+N,1,k] for k in 0:3]) == 0)
    
    # Au plus 2 chemins entrants/sortants
    @constraint(m, No_Croisement[i in (N+2):(N^2-N-1); i%N > 1], sum([x[i+1,0,k] + x[i-1,2,k] + x[i-N,3,k] + x[i+N,1,k] + x[i+1,k,0] + x[i-1,k,2] + x[i-N,k,3] + x[i+N,k,1] for k in 0:3]) <= 2)

    # Angle droit sur les noirs
    @constraint(m, Noirs_Angle_Droit[i in newNoirs], sum([x[i,j,k]*(abs(j-k)%2) for j in 0:3, k in 0:3]) == 1)

    # Noirs connectés qu'à des lignes droites
    @constraint(m, Noirs_Connect_Droite[i in newNoirs], x[i+1,0,2] + x[i-1,2,0] + x[i-N,3,1] + x[i+N,1,3] + x[i+1,2,0] + x[i-1,0,2] + x[i-N,1,3] + x[i+N,3,1] == 2)

    # Ligne droite sur les blancs
    @constraint(m, Blancs_Ligne_Droite[i in newBlancs], sum([x[i,j,k]*abs(j-k) for j in 0:3, k in 0:3]) == 2)

    # Blancs connectés à au moins un angle droit
    @constraint(m, Blancs_Connect_Angle[i in newBlancs], x[i+1,0,2] + x[i-1,2,0] + x[i-N,3,1] + x[i+N,1,3] + x[i+1,2,0] + x[i-1,0,2] + x[i-N,1,3] + x[i+N,3,1] <= 1)


    #Pour éviter les sous-cycles (MTZ)
    # On cherche un point initial devant apartenir au cycle (ie l'indice de u1 dans MTZ)
    uInit_Id = -1
    if size(blancs,1) != 0
        uInit_Id = blancs[1]
    elseif size(noirs,1) != 0
        uInit_Id = noirs[1]
    end
    
    # S'il existe un tel u1, on ajoute les contraintes MTZ
    if  uInit_Id != -1
        @constraint(m, MTZ_Init, u[uInit_Id] == 1)
        @constraint(m, MTZ_Ineg[i in 1:n^2; i != uInit_Id], 2 <= u[i] <= cycleLen)

        #Contrainte MTZ sur les éléments voisins de i
        @constraint(m, MTZ_Condition_Sides[i in 1:n^2, j in (-n,-1,1,n); i != uInit_Id && i+j != uInit_Id && IsNeighbor(n,i,j)], u[i] - u[i+j] + 1 <= (1 - sum([x[ToBigTerrain(n,N,i),k,ChangeDirType(n,j)] for k in 0:3]))*cycleLen)
    end

    # Pour debug les contraintes
    #println(m[:Non_croisement][40])

    # Empêche d'afficher les détails de la résolution
    set_silent(m)

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    stop = time()

    solutionFound = primal_status(m) == MOI.FEASIBLE_POINT

    # On récupère la solution et la converti pour la repasser en indice dans le terrain d'origine
    if solutionFound
        solution = [(ToSmallTerrain(n,N,I), j, k) for I in 1:N^2, k in 0:3, j in 0:3 if value(x[I,j,k]) == 1]
    else
        solution = []
    end

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    # 3 - the found solution
    return solutionFound, stop - start, solution
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve(n::Int64, white::Vector{Int64}, black::Vector{Int64}, cycleLen::Int64)

    start = time()

    solvedCycle = heuristique(n,white,black)

    stop = time()

    println(solvedCycle)

    solvedCycleFormat = ToSolutionFormat(n,solvedCycle)

    return size(solvedCycle,1) == cycleLen - 1, stop - start, solvedCycleFormat
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    #resolutionMethod = ["cplex"]
    resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        terrainSize, cycleLength, white, black = readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"

                    # Solve it and get the results
                    isOptimal, resolutionTime, solvedCycle = cplexSolve(terrainSize, cycleLength, black, white)

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Solve it and get the results
                    isSolved, resolutionTime, solvedCycle = heuristicSolve(terrainSize, white, black, cycleLength)

                    # Est-ce que la solution est optimale
                    isOptimal = isSolved

                    # Si la solution n'est pas optimale
                    if !isOptimal
                        println("Solution found by the heuristic is not optimal")
                        println(solvedCycle)
                        displayGrid(terrainSize, white, black, solvedCycle)
                    end
                end

                if isOptimal
                    displayGrid(terrainSize, white, black, solvedCycle)
                end

                fout = open(outputFile, "w")  

                # Si une erreur apparait, on ferme le fichier avant de quitter
                try
                    println(fout, "n = ", terrainSize)

                    # Write the solution found (if any)
                    if isOptimal
                        println(fout, "solution = ", solvedCycle)
                    end

                    println(fout, "solveTime = ", resolutionTime) 
                    println(fout, "isOptimal = ", isOptimal)

                catch e
                    showerror(stdout, e)
                finally
                    close(fout)
                end
            else
                println("Already solved in " * outputFile)
            end

            # Display the results obtained with the method on the current instance
            include(outputFile)
"""
            if occursin("instance_t10_d0.6_mp15", outputFile)
                displayGrid(terrainSize, white, black, solution)
            end
"""
            #println(resolutionMethod[methodId], " optimal: ", isOptimal)
            #println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
