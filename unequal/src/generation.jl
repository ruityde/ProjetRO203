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

    table_uneq = zeros(Int64,numb_unequal,4)

    for uneq in 1:numb_unequal
        coord = rand(1:n,2)
        coord_neig = copy(coord)
        valid = false
        while !valid
            valid = true
            xory = rand(1:2)
            coord_neig[xory] = coord[xory] + rand((1,-1))
            # Si les coordonnées sont invalides
            if (count(coord_neig .> n) + count(coord_neig .< 1)) > 0
                coord_neig[xory] = coord[xory]
                valid = false
            # Sinon si les coordonnées sont valides mais que la valeur en coord est <= à celle en coord_neig, on les inverse
            elseif table[coord[1], coord[2]] <= table[coord_neig[1], coord_neig[2]]
                temp = coord
                coord = coord_neig
                coord_neig = temp
            end
        end

        table_uneq[uneq,:] = vcat(coord, coord_neig)

    end

    displayGrid(table, table_uneq);

    # Deleting values to have the needed density

    mat = rand(n,n)
    while count(mat .< density) != round(Int, n * n * density)
        mat = rand(n,n)
    end
    table[mat .> density] .= 0

    return table, table_uneq

    
end 




"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # For each grid size considered
    for size in [4, 8, 10]

        # For each grid density considered
        for density in [0.1, 0.2, 0.3]

            # For each number of unequalities
            for numb_uneq in 3:3:(size*2)

                # Generate 3 instances
                for instance in 1:3

                    fileName = "../data/instance_t" * string(size) * "_d" * string(density) * "_nu" * string(numb_uneq) * "_" * string(instance) * ".txt"

                    if !isfile(fileName)
                        println("-- Generating file " * fileName)
                        (t, t_u) = generateInstance(size, density, numb_uneq)
                        saveInstance(t, t_u, fileName)
                    else
                        println("File already created " * fileName)
                    end 
                end
            end
        end
    end
    
end



