# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

using Random


"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
- numb_unequal: number in [|0, 2n(n-1)|] of unequalities in the grid
"""
function generateInstance(n::Int64, density::Float64, numb_unequal::Int64)

    table = zeros(Int64, n, n)
    table_unequal = zeros(Int64, n, n, n, n)

    # Creating a valid n*n grid

    table[1, :] = shuffle(Vector(1:n))
    newLine = zeros(Int64,n)
    for line in 2:n
        isValid = false
        while !isValid
            isValid = true
            newLine = shuffle(Vector(1:n))
            for col in 1:n
                for prec in 1:(line-1)
                    if table[prec,col] == newLine[col]
                        isValid = false

                    end
                end
            end
        end
        table[line, :] = newLine
    end


    # Creating the unequalities

    # TODO


    # Deleting values to have the needed density

    mat = rand(n,n)
    while count(mat .< density) != round(Int, n * n * density)
        mat = rand(n,n)
    end
    table[mat .> density] .= 0

    return table

    
end 




"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # For each grid size considered
    for size in [4, 8, 10, 20]

        # For each grid density considered
        for density in [0.1, 0.2, 0.3]

            # For each number of unequalities
            for numb_uneq in 3:3:(size*2)

                # Generate 5 instances
                for instance in 1:3

                    fileName = "./data/instance_t" * string(size) * "_d" * string(density) * "_nu" * string(numb_uneq) * "_" * string(instance) * ".txt"

                    if !isfile(fileName)
                        println("-- Generating file " * fileName)
                        saveInstance(generateInstance(size, density, numb_uneq), fileName)
                    end 
                end
            end
        end
    end
    
end



