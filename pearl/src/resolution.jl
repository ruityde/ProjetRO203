# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX, JuMP

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(n::Int, Noirs::Array{Int}, Blancs::Array{Int})

    # Taille du terrain avec les variables de bord
    N = n+2

    # Indices des cases noires dans le terrain avec les bords supplémentaires
    newNoirs = [(div(i-1,n)+1)*N + (i-1)%n + 2 for i in Noirs]

    # Indices des cases blanches dans le terrain avec les bords supplémentaires
    newBlancs = [(div(i-1,n)+1)*N + (i-1)%n + 2 for i in Blancs]

    # Create the model
    m = Model(CPLEX.Optimizer)

    @objective(m, Max, 0)

    # Création des variables du problème
    @variable(m, x[1:N^2, 0:3, 0:3], Bin)

    # Contraintes des bords du terrain
    # Haut du terrain
    @constraint(m, Bords_Terrain_Haut[i in 1:N], sum([x[i,j,k] for j in 0:3, k in 0:3]) == 0)
    # Bas du terrain
    @constraint(m, Bords_Terrain_Bas[i in (N^2-N+1):N^2], sum([x[i,j,k] for j in 0:3, k in 0:3]) == 0)
    # Gauche du terrain
    @constraint(m, Bords_Terrain_Gauche[i in 1:N^2; i%(n+2) == 1], sum([x[i,j,k] for j in 0:3, k in 0:3]) == 0)
    # Droite du terrain
    @constraint(m, Bords_Terrain_Droite[i in 1:N^2; i%(n+2) == 0], sum([x[i,j,k] for j in 0:3, k in 0:3]) == 0)

    # Empêche de passer 2 fois par la même contraintes
    @constraint(m, Non_croisement[i in 1:N^2], sum([x[i,j,k] for j in 0:3, k in 0:3]) <= 1)

    # Autant de chemins entrants que sortants
    @constraint(m, Cycle_Continuite[i in (n+4):(N^2-N); i%N > 1], sum([x[i+1,0,k] + x[i-1,2,k] + x[i-n,3,k] + x[i+n,1,k] - x[i+1,k,0] - x[i-1,k,2] - x[i-n,k,3] - x[i+n,k,1] for k in 0:3]) == 0)
    
    """
    # Le centre du terrain, hors bords
    @constraint(m, Cycle_Continuite_Centre[i in (n+1):(n^2-n); i%n > 1], sum([x[i+1,0,k] + x[i-1,2,k] + x[i-n,3,k] + x[i+n,1,k] - x[i+1,k,0] - x[i-1,k,2] - x[i-n,k,3] - x[i+n,k,1] for k in 0:3]) == 0)
    # Le haut du terrain
    @constraint(m, Cycle_Continuite_Haut[i in 1:n; i%n > 1], sum([x[i+1,0,k] + x[i-1,2,k] + x[i+n,1,k] - x[i+1,k,0] - x[i-1,k,2] - x[i+n,k,1] for k in 0:3]) == 0)
    # Le bas du terrain
    @constraint(m, Cycle_Continuite_Bas[i in (n^2-n+1):n^2; i%n > 1], sum([x[i+1,0,k] + x[i-1,2,k] + x[i-n,3,k] - x[i+1,k,0] - x[i-1,k,2] - x[i-n,k,3] for k in 0:3]) == 0)
    # La gauche du terrain
    @constraint(m, Cycle_Continuite_Gauche[i in n+1:(n^2-n); i%n == 1], sum([x[i+1,0,k] + x[i-n,3,k] + x[i+n,1,k] - x[i+1,k,0] - x[i-n,k,3] - x[i+n,k,1] for k in 0:3]) == 0)
    # La droite du terrain
    @constraint(m, Cycle_Continuite_Droite[i in (n+1):(n^2-n); i%n == 0], sum([x[i-1,2,k] + x[i-n,3,k] + x[i+n,1,k] - x[i-1,k,2] - x[i-n,k,3] - x[i+n,k,1] for k in 0:3]) == 0)
    # Coins
    @constraint(m, Cycle_Continuite_HautGauche, sum([x[2,0,k] + x[1+n,1,k] - x[2,k,0] - x[1+n,k,1] for k in 0:3]) == 0)
    """

    # Au plus 2 chemins entrants/sortants
    @constraint(m, No_Croisement[i in (n+4):(N^2-N); i%n > 1], sum([x[i+1,0,k] + x[i-1,2,k] + x[i-n,3,k] + x[i+n,1,k] + x[i+1,k,0] + x[i-1,k,2] + x[i-n,k,3] + x[i+n,k,1] for k in 0:3]) <= 2)
    
    """
    # Le centre du terrain, hors bords
    @constraint(m, No_Croisement_Centre[i in (n+1):(n^2-n); i%n > 1], sum([x[i+1,0,k] + x[i-1,2,k] + x[i-n,3,k] + x[i+n,1,k] + x[i+1,k,0] + x[i-1,k,2] + x[i-n,k,3] + x[i+n,k,1] for k in 0:3]) <= 2)
    # Le haut du terrain
    @constraint(m, No_Croisement_Haut[i in 1:n], sum([x[i+1,0,k] + x[i-1,2,k] + x[i+n,1,k] + x[i+1,k,0] + x[i-1,k,2] + x[i+n,k,1] for k in 0:3]) <= 2)
    # Le bas du terrain
    @constraint(m, No_Croisement_Centre[i in (n^2-n+1):n^2], sum([x[i+1,0,k] + x[i-1,2,k] + x[i-n,3,k] + x[i+n,1,k] + x[i+1,k,0] + x[i-1,k,2] + x[i-n,k,3] + x[i+n,k,1] for k in 0:3]) <= 2)
    # La gauche du terrain
    @constraint(m, Cycle_Continuite[i in 1:n^2; i%n == 1], sum([x[i+1,0,k] + x[i-n,3,k] + x[i+n,1,k] - x[i+1,k,0] - x[i-n,k,3] - x[i+n,k,1] for k in 0:3]) == 0)
    # La droite du terrain
    @constraint(m, Cycle_Continuite[i in 1:n^2; i%n == 0], sum([x[i-1,2,k] + x[i-n,3,k] + x[i+n,1,k] - x[i-1,k,2] - x[i-n,k,3] - x[i+n,k,1] for k in 0:3]) == 0)
    """

    # Angle droit sur les noirs
    @constraint(m, Noirs_Angle_Droit[i in newNoirs], sum([x[i,j,k]*(abs(j-k)%2) for j in 0:3, k in 0:3]) == 1)

    # Noirs connectés qu'à des lignes droites
    @constraint(m, Noirs_Connect_Droite[i in newNoirs], x[i+1,0,2] + x[i-1,2,0] + x[i-n,3,1] + x[i+n,1,3] + x[i+1,2,0] + x[i-1,0,2] + x[i-n,1,3] + x[i+n,3,1] == 2)

    # Ligne droite sur les blancs
    @constraint(m, Blancs_Ligne_Droite[i in newBlancs], sum([x[i,j,k]*abs(j-k) for j in 0:3, k in 0:3]) == 2)

    # Blancs connectés à au moins un angle droit
    @constraint(m, Blancs_Connect_Angle[i in newBlancs], x[i+1,0,2] + x[i-1,2,0] + x[i-n,3,1] + x[i+n,1,3] + x[i+1,2,0] + x[i-1,0,2] + x[i-n,1,3] + x[i+n,3,1] <= 1)

    # Start a chronometer
    start = time()

    # Solve the model
    set_silent(m)
    optimize!(m)

    stop = time()

    solutionFound = primal_status(m) == MOI.FEASIBLE_POINT

    if solutionFound
        solution = [((div(I-1,N)-1)*n + (I-1)%N, j, k) for I in 1:N^2, k in 0:3, j in 0:3 if value(x[i,j,k]) == 1]
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
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
                    end

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
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
