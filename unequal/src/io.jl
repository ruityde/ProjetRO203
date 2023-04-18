# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
# import GR

"""
Read an instance from an input file

2, , , 
 , , , 
 , , , 
 , , , 
 
 1,1,1,2
 2,3,3,3
 3,4,2,4
 4,1,4,2
 4,4,4,3

 The grid is a square with values separated by commas.
 Values can be integers or white spaces.
 Then after a blank line, there is lines of 4 coordinates (i,j,k,l) separated by commas
    representing the fact that table(i,j) > table(k,l).

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)

    t_size = length(split(data[1], ","))
    table = zeros(Int64, t_size, t_size)

    nb_unequal = length(data) - t_size - 1
    table_unequal = zeros(Int64, nb_unequal, 4)

    i = 1
    # For each line of the input file
    for line in data

        # First lines go into table
        if i < t_size + 1
            lineSplit = split(line, ",")

            for colNb in 1:t_size

                if lineSplit[colNb] != " "
                    table[i, colNb] = parse(Int64, lineSplit[colNb])

                else
                    table[i, colNb] = 0
                end
            end
        end
        
        # Unequalities coordinates
        if i > t_size + 1
            line = replace(line, "," => " ")
            #coord = parse.(Int64, split(line, " "))
            table_unequal[i-t_size-1, :] = parse.(Int64, split(line, " "))
            #table_unequal[coord[1], coord[2], coord[3], coord[4]] = 1
        end

        i += 1
    end
    return table, table_unequal
end

"""
Representation of the grid

 -----------
|2 >.. .. ..|
|           |
|.. .. .. ..|
|      v  ^ |
|.. .. .. ..|
|           |
|..>.. ..<..|
 -----------

"""
function displayGrid(table::Matrix{Int64}, table_unequal::Matrix{Int64})

    t_size = size(table,1)

    grid_unequal = zeros(Int64, t_size*2-1, t_size)

    for i in 1:size(table_unequal, 1)
        if table_unequal[i,1] == table_unequal[i,3]
            if table_unequal[i,2] < table_unequal[i,4]
                grid_unequal[2*table_unequal[i,1]-1, table_unequal[i,2]] = 1
            else
                grid_unequal[2*table_unequal[i,1]-1, table_unequal[i,4]] = -1
            end
        else
            if table_unequal[i,1] < table_unequal[i,3]
                grid_unequal[2*table_unequal[i,1], table_unequal[i,2]] = 1
            else
                grid_unequal[2*table_unequal[i,3], table_unequal[i,2]] = -1
            end
        end
    end

    println(" ", "-"^(t_size*3-1))


    for line in 1:(t_size)
        # Print a line of numbers + line unequalities
        print("|")

        for col in 1:t_size
            if table[line,col] == 0
                print("..")
            else
                if table[line,col] < 10
                    print(table[line,col], " ")
                else
                    print(table[line,col])
                end
            end

            if col < t_size
                if grid_unequal[2*line-1,col] == 1
                    print(">")
                else
                    if grid_unequal[2*line-1, col] == -1
                        print("<")
                    else
                        print(" ")
                    end
                end
            end
        end
        println("|")

        # Print a line of column unequalities
       
        if line < t_size
            print("|")
            for col in 1:t_size
                if grid_unequal[2*line, col] == 1
                    print("v ")
                else
                    if grid_unequal[2*line, col] == -1
                        print("^ ")
                    else
                        print("  ")
                    end
                end
                if col < t_size
                    print(" ")
                end
            end
            println("|")
        end
    end
    println(" ", "-"^(t_size*3-1))

end

function writeGrid(fout::IOStream, table::Matrix{Int64}, table_unequal::Matrix{Int64})

    t_size = size(table,1)

    grid_unequal = zeros(Int64, t_size*2-1, t_size)

    for i in 1:size(table_unequal, 1)
        if table_unequal[i,1] == table_unequal[i,3]
            if table_unequal[i,2] < table_unequal[i,4]
                grid_unequal[2*table_unequal[i,1]-1, table_unequal[i,2]] = 1
            else
                grid_unequal[2*table_unequal[i,1]-1, table_unequal[i,4]] = -1
            end
        else
            if table_unequal[i,1] < table_unequal[i,3]
                grid_unequal[2*table_unequal[i,1], table_unequal[i,2]] = 1
            else
                grid_unequal[2*table_unequal[i,3], table_unequal[i,2]] = -1
            end
        end
    end

    println(fout, " ", "-"^(t_size*3-1))


    for line in 1:(t_size)
        # Print a line of numbers + line unequalities
        print(fout, "|")

        for col in 1:t_size
            if table[line,col] == 0
                print(fout, "..")
            else
                if table[line,col] < 10
                    print(fout, table[line,col], " ")
                else
                    print(fout, table[line,col])
                end
            end

            if col < t_size
                if grid_unequal[2*line-1,col] == 1
                    print(fout, ">")
                else
                    if grid_unequal[2*line-1, col] == -1
                        print(fout, "<")
                    else
                        print(fout, " ")
                    end
                end
            end
        end
        println(fout, "|")

        # Print a line of column unequalities
       
        if line < t_size
            print(fout, "|")
            for col in 1:t_size
                if grid_unequal[2*line, col] == 1
                    print(fout, "v ")
                else
                    if grid_unequal[2*line, col] == -1
                        print(fout, "^ ")
                    else
                        print(fout, "  ")
                    end
                end
                if col < t_size
                    print(fout, " ")
                end
            end
            println(fout, "|")
        end
    end
    println(fout, " ", "-"^(t_size*3-1))

end


"""

function displayGrid(table::Matrix{Int64}, table_unequal::Matrix{Int64})

    t_size = size(table,1)

    for i in 1:table_unequal


    println(" ", "-"^(t_size*3-1))


    for line in 1:(t_size)
        # Print a line of numbers + line unequalities
        print("|")

        for col in 1:t_size
            if table[line,col] == 0
                print("..")
            else
                if table[line,col] < 10
                    print(table[line,col], " ")
                else
                    print(table[line,col])
                end
            end

            if col < t_size
                if table_unequal[line,col,line,col+1] == 1
                    print(">")
                else
                    if table_unequal[line,col+1,line,col] == 1
                        print("<")
                    else
                        print(" ")
                    end
                end
            end
        end
        println("|")

        # Print a line of column unequalities
        
        if line < t_size
            print("|")
            for col in 1:t_size
                if table_unequal[line,col,line+1,col] == 1
                    print("v ")
                else
                    if table_unequal[line+1,col,line,col] == 1
                        print("^ ")
                    else
                        print("  ")
                    end
                end
                if col < t_size
                    print(" ")
                end
            end
            println("|")
        end
    end
    print(" ", "-"^(t_size*3-1))

end

"""


"""
Save a grid in a text file
Save the coordinates of the unequalties in the text file (TODO)
"""

function saveInstance(t::Matrix{Int64}, table_uneq::Matrix{Int64}, outputFile::String)

    n = size(t, 1)

    # Open the output file
    writer = open(outputFile, "w")

    # For each cell (l, c) of the grid
    for l in 1:n
        for c in 1:n

            # Write its value
            if t[l, c] == 0
                print(writer, " ")
            else
                print(writer, t[l, c])
            end

            if c != n
                print(writer, ",")
            else
                println(writer, "")
            end
        end
    end

    println(writer, "")

    for line in 1:size(table_uneq,1)
        print(writer, table_uneq[line,1])
        print(writer, ",")
        print(writer, table_uneq[line,2])
        print(writer, " ")
        print(writer, table_uneq[line,3])
        print(writer, ",")
        println(writer, table_uneq[line,4])
    end

    close(writer)
    
end 