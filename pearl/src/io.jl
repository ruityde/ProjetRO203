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
    white_list = zeros(Int64, size_w)
    size_b = length(data) - size_w - 3
    black_list = zeros(Int64, size_b)

    size_grid = parse(Int64, data[1])

    for i in 1:size_w
        w = parse.(Int64, split(data[i+2], ","))
        white_list[i] = size_grid*(w[1]-1) + w[2]
    end

    for j in 1:size_b
        b = parse.(Int64, split(data[j+3+size_w], ","))
        black_list[j] = size_grid*(b[1]-1) + b[2]
    end

    return size_grid, white_list, black_list

end

function displayGrid(size_grid::Int64, w::Vector{Int64}, b::Vector{Int64}, x::Vector{Tuple{Int64,Int64,Int64}})
    
    grid = zeros(Int64, size_grid, size_grid)

    #for l in 1:size_grid^2
        #x[l] = (l,2,3)
        #x[l] = (l,0,0)
    #end

    white_list = zeros(Int64, length(w), 2)
    black_list = zeros(Int64, length(b), 2)

    for i in 1:length(w)
        white_list[i,1] = floor(w[i]/size_grid)+1
        white_list[i,2] = w[i]%size_grid
    end

    for j in 1: length(b)
        black_list[j,1] = floor(b[j]/size_grid) +1
        black_list[j,2] = b[j]%size_grid
    end


    for i in 1:size(white_list,1)
        grid[white_list[i,1], white_list[i,2]] = 1
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
            x_numb = size_grid*(i-1) +j
            if j < size_grid
                if x[x_numb][2] == 2 || x[x_numb][3] == 2
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
                if i < n
                    if x[x_numb][2] == 3 || x[x_numb][3] == 3
                        print("|")
                    else
                        print(" ")
                    end
                    if k < n
                        print(" ")
                    end
                end
            end
            println("|")
        end
    end
    println(" ", "-"^(size_grid*2-1))
end
