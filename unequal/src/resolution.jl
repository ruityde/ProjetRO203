# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX, JuMP

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(table::Array{Int}, table_unequal::Array{Int})

    # Create the model
    m = JuMP.Model(CPLEX.Optimizer)

    n = size(table,1)

    @objective(m, Max, 0)

    # Création des variables du problème
    @variable(m, x[1:n, 1:n, 1:n], Bin)

    # Ajout des contraintes de valeur du terrain
    for i in 1:n, j in 1:n
        k = table[i,j]
        if k > TOL
            @constraint(m, x[i,j,k] == 1)
        end
    end

    # Ajout des contraintes d'inégalités
    @constraint(m, Inegalites[cId in 1:size(table_unequal, 1), l in 1:n], x[table_unequal[cId,3],table_unequal[cId,4], l] <= sum(x[table_unequal[cId,1], table_unequal[cId,2], k] for k in (l+1):n))

    # Ajout des contraintes d'unicité de la valeur pour chaque ligne
    @constraint(m, Unicité_ligne[i in 1:n, k in 1:n], sum(x[i,j,k] for j in 1:n) == 1)

    # Ajout des contraintes d'unicité de la valeur pour chaque colonne
    @constraint(m, Unicité_colonne[j in 1:n, k in 1:n], sum(x[i,j,k] for i in 1:n) == 1)

    # Ajout des contraintes d'unicité de chaque valeur
    @constraint(m, Unicité_valeur[i in 1:n, j in 1:n], sum(x[i,j,k] for k in 1:n) == 1)

    # Start a chronometer
    start = time()

    # Solve the model
    set_silent(m)
    optimize!(m)

    stop = time()

    solutionFound = primal_status(m) == MOI.FEASIBLE_POINT
    
    if solutionFound
        # Mise en forme de la solution
        solutionMatrix = hcat([[k for k in 1:n, i in 1:n if value(x[i,j,k]) == 1] for j in 1:n]...)
    else
        solutionMatrix = table
    end

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return solutionFound, stop - start, solutionMatrix
    
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
        table, table_unequal = readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)

            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"

                    # Solve it and get the results
                    isOptimal, resolutionTime, solvedTable = cplexSolve(table, table_unequal)

                end

                fout = open(outputFile, "w")
                try
                    # Write the solution found (if any)
                    if isOptimal
                        writeSolution(fout, solvedTable)
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
