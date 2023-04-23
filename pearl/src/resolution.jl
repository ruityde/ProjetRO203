# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX, JuMP

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(n::Int, noirs::Array{Int}, blancs::Array{Int})

    # Taille du terrain avec les variables de bord
    N = n+2
    # Indices des cases noires dans le terrain avec les bords supplémentaires
    newNoirs = [(div(i-1,n)+1)*N + (i-1)%n + 2 for i in noirs]
    # Indices des cases blanches dans le terrain avec les bords supplémentaires
    newBlancs = [(div(i-1,n)+1)*N + (i-1)%n + 2 for i in blancs]

    # Create the model
    m = Model(CPLEX.Optimizer)

    # Permet d'afficher le nom des contraintes problématique pour debug
    set_optimizer_attribute(m, CPLEX.PassNames(), true)

    @objective(m, Max, 0)

    # Création des variables du problème
    @variable(m, x[1:N^2, 0:3, 0:3], Bin)

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

    if solutionFound
        solution = [((div(I-1,N)-1)*n + (I-1)%N, j, k) for I in 1:N^2, k in 0:3, j in 0:3 if value(x[I,j,k]) == 1]
    else
        solution = []
    end

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return solutionFound, stop - start, solution
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
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
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

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
        terrainSize, cycleLength, noirs, blancs = readInputFile(dataFolder * file)

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
                    isOptimal, resolutionTime, solvedCycle = cplexSolve(terrainSize, noirs, blancs)

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime, solvedCycle = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                fout = open(outputFile, "w")  
                try
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
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
