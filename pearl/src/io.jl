# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)

    size_w = findnext(x -> x == "", data, 4) - 4
    white_list = zeros(Int64, size_w)
    size_b = length(data) - size_w - 4
    black_list = zeros(Int64, size_b)

    size_grid = parse(Int64, data[1])
    cycle_len = parse(Int64, data[2])

    for i in 1:size_w
        #w = parse.(Int64, split(data[i+3], ","))
        #white_list[i] = size_grid*(w[1]-1) + w[2]
        white_list[i] = parse.(Int64, data[i+3])
    end

    for j in 1:size_b
        #b = parse.(Int64, split(data[j+4+size_w], ","))
        #black_list[j] = size_grid*(b[1]-1) + b[2]
        black_list[j] = parse.(Int64, data[j+4+size_w])
    end

    return size_grid, cycle_len, white_list, black_list

end

function displayGrid(size_grid::Int64, w::Vector{Int64}, b::Vector{Int64}, x::Vector{Tuple{Int64,Int64,Int64}})
    
    grid = zeros(Int64, size_grid, size_grid)

    white_list = zeros(Int64, length(w), 2)
    black_list = zeros(Int64, length(b), 2)

    for i in 1:length(w)
        white_list[i,1] = floor((w[i]-1)/size_grid) + 1
        white_list[i,2] = (w[i]-1)%size_grid + 1
    end

    for j in 1: length(b)
        black_list[j,1] = floor((b[j]-1)/size_grid) + 1
        black_list[j,2] = (b[j]-1)%size_grid + 1
    end


    for i in 1:size(white_list,1)
        grid[white_list[i,1], white_list[i,2]] = 1
    end

    for j in 1:size(black_list, 1)
        grid[black_list[j,1], black_list[j,2]] = 2
    end

    println(" ", "-"^(size_grid*2-1))

    x_ids = [-1 for i in 1:size_grid^2]
    for i in 1:size(x,1)
        x_ids[x[i][1]] = i
    end

    for i in 1:size_grid
        print("|")
        for j in 1:size_grid
            if grid[i,j] == 0
                print("+")
            else
                if grid[i,j] == 1
                    print("o")
                else
                    print("x")
                end
            end
            x_numb = size_grid*(i-1) +j
            x_id = x_ids[x_numb]
            if j < size_grid
                if x_id != -1 && (x[x_id][2] == 2 || x[x_id][3] == 2)
                    print("-")
                else
                    print(" ")
                end
            end
        end

        println("|")

        if i<size_grid
            print("|")

            for k in 1:size_grid
                x_numb = size_grid*(i-1) + k
                x_id = x_ids[x_numb]
                if i < size_grid
                    if x_id != -1 && (x[x_id][2] == 3 || x[x_id][3] == 3)
                        print("|")
                    else
                        print(" ")
                    end
                    if k < size_grid
                        print(" ")
                    end
                end
            end
            println("|")
        end
    end
    println(" ", "-"^(size_grid*2-1))
end


"""
Save the size of a grid and the length of the cycle
Save the coordinates of the black and white points in the text file
"""
function saveInstance(terrainSize::Int64, cycleLen::Int64, white::Vector{Int64}, black::Vector{Int64}, outputFile::String)

    sizeWhite = size(white,1)
    sizeBlack = size(black,1)

    # Open the output file
    writer = open(outputFile, "w")

    # Si une erreur apparait, on ferme le fichier avant de quitter
    try
        println(writer, terrainSize)
        println(writer, cycleLen)

        print(writer, "\n")

        # For each white position
        for i in 1:sizeWhite
            println(writer, white[i])
        end

        print(writer, "\n")

        # For each white position
        for i in 1:sizeBlack
            println(writer, black[i])
        end

    catch e
        showerror(stdout, e)
    finally
        close(writer)
    end
    
end 