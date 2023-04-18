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

    size_w = findnext(x -> x == "", data, 3) - 3
    white_list = zeros(Int64, size_w, 2)
    size_b = length(data) - size_w - 3
    black_list = zeros(Int64, size_b, 2)

    size_grid = parse(Int64, data[1])

    for i in 1:size_w
        white_list[i, :] = parse.(Int64, split(data[i+2], ","))
    end

    for j in 1:size_b
        black_list[j, :] = parse.(Int64, split(data[j+3+size_w], ","))
    end

    return size_grid, white_list, black_list

end

function displayGrid(size_grid::Int64, white_list::Matrix{Int64}, black_list::Matrix{Int64})
    
    grid = zeros(Int64, size_grid, size_grid)

    for i in 1:size(white_list,1)
        grid[white_list[i,1], white_list[i,2]] = 1
        println("x")
    end

    for j in 1:size(black_list, 1)
        grid[black_list[j,1], black_list[j,2]] = 2
    end

    println(" ", "-"^(size_grid*2-1))

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
            if j != size_grid
                print(" ")
            end
        end
        println("|")
    end

    println(" ", "-"^(size_grid*2-1))

end