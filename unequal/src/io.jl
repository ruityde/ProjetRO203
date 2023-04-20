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

"""
Write a solution in an output stream

Arguments
- fout: the output stream (usually an output file)
- t: 2-dimensional array of size n*n
"""
function writeSolution(fout::IOStream, t::Matrix{Int64})
    
    println(fout, "solution = [")
    n = size(t, 1)
    
    for l in 1:n

        #print(fout, "[ ")
        
        for c in 1:n
            print(fout, string(t[l, c]) * " ")
        end 

        endLine = ""

        if l != n
            endLine *= ";"
        end

        println(fout, endLine)
    end

    println(fout, "]")
end 


"""
Save a grid in a text file
Save the coordinates of the unequalties in the text file
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


"""
Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function performanceDiagram(outputFile::String)

    resultFolder = "../res/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    folderName = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)
            
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)

    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end

    folderCount = 0
    maxSolveTime = 0

    # For each subfolder
    for file in readdir(resultFolder)
            
        path = resultFolder * file
        
        if isdir(path)

            folderCount += 1
            fileCount = 0

            # For each text file in the subfolder
            for resultFile in filter(x->occursin(".txt", x), readdir(path))

                fileCount += 1
                include(path * "/" * resultFile)

                if isOptimal
                    results[folderCount, fileCount] = solveTime

                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end
            end 
        end
    end 

    # Sort each row increasingly
    results = sort(results, dims=2)

    println("Max solve time: ", maxSolveTime)


    # For each line to plot
    for dim in 1: size(results, 1)

        x = Array{Float64, 1}()
        y = Array{Float64, 1}()

        # x coordinate of the previous inflexion point
        previousX = 0
        previousY = 0

        append!(x, previousX)
        append!(y, previousY)
            
        # Current position in the line
        currentId = 1

        # While the end of the line is not reached 
        while currentId != size(results, 2) && results[dim, currentId] != Inf

            # Number of elements which have the value previousX
            identicalValues = 1

             # While the value is the same
            while results[dim, currentId] == previousX && currentId <= size(results, 2)
                currentId += 1
                identicalValues += 1
            end

            # Add the proper points
            append!(x, previousX)
            append!(y, currentId - 1)

            if results[dim, currentId] != Inf
                append!(x, results[dim, currentId])
                append!(y, currentId - 1)
            end
            
            previousX = results[dim, currentId]
            previousY = currentId - 1
            
        end

        append!(x, maxSolveTime)
        append!(y, currentId - 1)

        # If it is the first subfolder
        if dim == 1

            # Draw a new plot
            plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)
        end 
        # Add the new curve to the created plot
        savefig(plot!(x, y, label = folderName[dim], linewidth=3), outputFile)
    end
end 


"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String)
    
    resultFolder = "../res/"
    dataFolder = "../data/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    # Open the latex output file
    fout = open(outputFile, "w")

    # Print the latex file output
    println(fout, raw"""\documentclass{article}

\usepackage[french]{babel}
\usepackage [utf8] {inputenc} % utf-8 / latin1 
\usepackage{multicol}

\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
\setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
\setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
\setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
\setlength{\voffset}{-18pt} % Bon pour DOS
\setlength{\marginparsep}{7pt} % Séparation de la marge
\setlength{\topmargin}{0pt} % Pas de marge en haut
\setlength{\headheight}{13pt} % Haut de page
\setlength{\headsep}{10pt} % Entre le haut de page et le texte
\setlength{\footskip}{27pt} % Bas de page + séparation
\setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

\begin{document}""")

    header = raw"""
\begin{center}
\renewcommand{\arraystretch}{1.4} 
 \begin{tabular}{l"""

    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Vector{String}()

    # List of all the instances solved by at least one resolution method
    solvedInstances = Vector{String}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)

            # Add its name to the folder list
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            # Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end 

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Only keep one string for each instance solved
    unique(solvedInstances)

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end

    header *= "}\n\t\\hline\n"

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end

    header *= "\\\\\\hline\n"

    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)

    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1

    # For each solved files
    for solvedInstance in solvedInstances

        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))

        # For each resolution method
        for method in folderName

            path = resultFolder * method * "/" * solvedInstance

            # If the instance has been solved by this method
            if isfile(path)

                include(path)

                println(fout, " & ", round(solveTime, digits=2), " & ")

                if isOptimal
                    println(fout, "\$\\times\$")
                end 
                
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end

        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)

    println(fout, "\\end{document}")

    close(fout)
    
end 
