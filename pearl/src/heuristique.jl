include("io.jl")

function heuristique(n, white, black)
    open_d = get_open_directions(n)
    unionEdge = collect(1:n^2)
    isWhite = zeros(Int64, n^2)
    loop = Set{Tuple{Int, Int}}()

    line_of_white(open_d, white)
    black_neighbors(open_d, black)
    match_open_d(open_d)

    prev_open_d = copy_open_d(open_d)

    while true
        for i in black
            black_check(i, open_d, loop)
        end

        for i in white
            white_check(i, open_d, isWhite, loop)
        end

        not_all_straight_white(open_d, isWhite, loop)

        close_edges(open_d, loop)
        
        update_unionEdge(open_d, loop, unionEdge)
        match_open_d(open_d)

        fill_edges(open_d, loop, unionEdge)
        close_edges(open_d, loop)

        update_unionEdge(open_d, loop, unionEdge)
        match_open_d(open_d)

        if open_d == prev_open_d
            break
        else
            prev_open_d = copy_open_d(open_d)
        end
      
    end
    
    return sort(collect(loop))
end




function copy_open_d(open_d)
    return [copy(x) for x in open_d]
end

function valid_edge(edge, n)
	return all(x -> x <= n^2 && x > 0, edge)
end

#Create a list of open directions for each square i
function get_open_directions(n)
    open_d = Array{Vector{Int}, 1}(undef, n^2)

    for i in 1:n^2
        directions = Int[]

        # Check left
        if i%n != 1
            push!(directions, 0)
        end

        # Check up
        if i > n
            push!(directions, 1)
        end

        # Check right
        if i%n != 0
            push!(directions, 2)
        end

        # Check down
        if i+n <= n^2
            push!(directions, 3)
        end

        open_d[i] = directions
    end

    return open_d
end

#Check if there is 3 white circles line up and force the direction
function line_of_white(open_d, white)
    n = Int(sqrt(length(open_d)))

    for i in 1:length(white) - 2
        for j in i+1:length(white) - 1
            for k in j+1:length(white)
                a, b, c = white[i], white[j], white[k]

                if (a - b == 1 && b - c == 1) || (c - b == 1 && b - a == 1)
                    del(open_d[b], 0)
                    del(open_d[b], 2)
                elseif (a - b == n && b - c == n) || (c - b == n && b - a == n)
                    del(open_d[b], 1)
                    del(open_d[b], 3)
                end
            end
        end
    end
end

#Check if there are 2 black circles that are neighbors and force the direction
function black_neighbors(open_d, black)
    n = Int(sqrt(length(open_d)))

    for i in 1:length(black) - 1
        for j in i+1:length(black)
            a, b = black[i], black[j]

            if a - b == 1
                del(open_d[a], 0)
                del(open_d[b], 2)
            elseif b - a == 1
                del(open_d[a], 2)
                del(open_d[b], 0)
            elseif a - b == n
                del(open_d[a], 1)
                del(open_d[b], 3)
            elseif b - a == n
                del(open_d[a], 3)
                del(open_d[b], 1)
            end
        end
    end
end

#Find directions in which you can't go 2 square straight and return opposite direction (used for black_check)
function find_opposite_directions(i, open_d, loop)
    opposite_directions = Int[]

    n = Int(sqrt(length(open_d)))

    # Check right (opposite of left)
    if (i % n != 0 && (!in(2, open_d[i]) || !in(2, open_d[i+1]))) || i%n == 0
    	push!(opposite_directions, 0)
    end

    # Check down (opposite of up)
    if (i + n <= n^2 && (!in(3, open_d[i]) || !in(3, open_d[i+n]))) || i+n > n^2
        push!(opposite_directions, 1)
    end

    # Check left (opposite of right)
    if (i % n != 1 && (!in(0, open_d[i]) || !in(0, open_d[i-1]))) || i%n == 1
        push!(opposite_directions, 2)
    end

    # Check up (opposite of down)
    if (i > n && (!in(1, open_d[i]) || !in(1, open_d[i-n]))) || i <= n
        push!(opposite_directions, 3)
    end

    return tuple(opposite_directions...)
end



#Find the orientation of white : horizontal or vertical (used in white_check)
function find_orthogonal_direction(i, open_d)
    n = Int(sqrt(length(open_d)))

    # Check if up (1) or down (3) directions are not allowed
    if !in(1, open_d[i]) || !in(3, open_d[i]) && in(0, open_d[i])
        # Orthogonal direction is left (0)
        return (0, i-1, i+1)
    end

    # Check if left (0) or right (2) directions are not allowed
    if !in(0, open_d[i]) || !in(2, open_d[i]) && in(1, open_d[i])
        # Orthogonal direction is up (1)
        return (1, i - n, i + n)
    end

    return (-1,-1,-1)
end


"""
#Find the possible edges according to the open directions
function find_possible_edges(i, open_d)
    n = Int(sqrt(length(open_d)))
    edges = Set{Tuple{Int, Int}}()

    # Check left neighbor
    if in(0, open_d[i])
        push!(edges, (i - 1, i))
    end

    # Check right neighbor
    if in(2, open_d[i])
        push!(edges, (i, i + 1))
    end

    # Check up neighbor
    if in(1, open_d[i])
        push!(edges, (i - n, i))
    end

    # Check down neighbor
    if in(3, open_d[i])
        push!(edges, (i, i + n))
    end

    return collect(edges)
end
"""

#Add edges if there is a direction that you are sure you can go
function black_check(i, open_d, loop)
    n = Int(sqrt(length(open_d)))
    opposite_dirs = find_opposite_directions(i, open_d, loop)
    for dir in opposite_dirs
        edge1, edge2 = (0, 0), (0, 0)
        if dir == 0  # Left
            edge1, edge2 = (i - 1, i), (i - 2, i - 1)
            del(open_d[i], 2)
            if i % n ≠ 0
                del(open_d[i + 1], 0)
            end
        elseif dir == 1  # Up
            edge1, edge2 = (i - n, i), (i - 2* n, i - n)
            del(open_d[i], 3)
            if i + n ≤ n^2
                del(open_d[i + n], 1)
            end
        elseif dir == 2  # Right
            edge1, edge2 = (i, i + 1), (i + 1, i + 2)
            del(open_d[i], 0)
            if i % n ≠ 1
                del(open_d[i - 1], 2)
            end
        elseif dir == 3  # Down
            edge1, edge2 = (i, i + n), (i + n, i + 2 * n)
            del(open_d[i], 1)
            if i - n ≥ 1
                del(open_d[i - n], 3)
            end
        end
        if edge1 ∉ loop && valid_edge(edge1,n)
            push!(loop, edge1)
        end
        if edge2 ∉ loop && valid_edge(edge2,n)
            push!(loop, edge2)
        end
    end
end


#Add edges if you are sure of the right direction (hor or ver)
function white_check(i, open_d, isWhite, loop)
    n = Int(sqrt(length(open_d)))
    edges = []
    (orthogonal_dir, neighboor1, neighboor2) = find_orthogonal_direction(i, open_d)
    
    straight_neighbor = find_other_elem(loop, i)

    if straight_neighbor != -1
    	if straight_neighbor == i-1 || straight_neighbor == i+1
    		del(open_d[i], 1)
        	del(open_d[i], 3)
        end
        if straight_neighbor == i-n || straight_neighbor == i+n
        	del(open_d[i], 0)
        	del(open_d[i], 2)
        end
    end

    if orthogonal_dir == -1
    	return nothing
    end

    if orthogonal_dir == 0  # Horizontal
        edges = [(i - 1, i), (i, i + 1)]
        del(open_d[i], 1)
        del(open_d[i], 3)
    elseif orthogonal_dir == 1  # Vertical
        edges = [(i - n, i), (i, i + n)]
        del(open_d[i], 0)
        del(open_d[i], 2)
    end

    for edge in edges
        if edge ∉ loop && valid_edge(edge,n)
            push!(loop, edge)
        end
    end

    isWhite[neighboor1] = neighboor2
    isWhite[neighboor2] = neighboor1
end

#Removes the item from the array
function del(arr, item)
    filter!(x -> x != item, arr)
end

#Find if there is an edge with the element a and return the other element of the edge
function find_other_elem(tuples, a)
    for tuple in tuples
        if a in tuple
            return a == tuple[1] ? tuple[2] : tuple[1]
        end
    end
    return -1
end


#Make sure that the line going through a white dot is not straight on both sides
function not_all_straight_white(open_d, isWhite, loop)
    n = Int(sqrt(length(open_d)))

    for i in 1:length(isWhite)
        if isWhite[i] != 0
            neighbor1 = i
            neighbor2 = isWhite[i]

            left_edge = (neighbor1 - 1, neighbor1)
            right_edge = (neighbor1, neighbor1 + 1)
            up_edge = (neighbor1 - n, neighbor1)
            down_edge = (neighbor1, neighbor1 + n)

            if (left_edge in loop) && (right_edge in loop)
                if neighbor1 < neighbor2
                    del(open_d[neighbor2], 2)  # Remove right direction
                else
                    del(open_d[neighbor2], 0)  # Remove left direction
                end
            elseif (up_edge in loop) && (down_edge in loop)
                if neighbor1 < neighbor2
                    del(open_d[neighbor2], 3)  # Remove down direction
                else
                    del(open_d[neighbor2], 1)  # Remove up direction
                end
            end
        end
    end
end


#Make sure that if you can't go in a direction from a square, you also can't enter in this square from the neighbor
function match_open_d(open_d)
    n = Int(sqrt(length(open_d)))
    for i in 1:length(open_d)
        if 2 ∉ open_d[i] && i%n != 0
            del(open_d[i + 1], 0)
        end
        if 1 ∉ open_d[i] && i-n > 0
            del(open_d[i - n], 3)
        end
        if 0 ∉ open_d[i] && i%n != 1
            del(open_d[i - 1], 2)
        end
        if 3 ∉ open_d[i] && i+n <= n^2
            del(open_d[i + n], 1)
        end
    end
end


#If there are 2 edges in one square, remove the other open directions
function close_edges(open_d, loop)
    n = Int(sqrt(length(open_d)))
    
    for i in 1:length(open_d)
        left_edge = (i - 1, i)
        right_edge = (i, i + 1)
        up_edge = (i - n, i)
        down_edge = (i, i + n)
        
        if left_edge in loop && right_edge in loop
            del(open_d[i], 1)
            del(open_d[i], 3)
        end
        
        if up_edge in loop && down_edge in loop
            del(open_d[i], 0)
            del(open_d[i], 2)
        end
        
        if left_edge in loop && down_edge in loop
            del(open_d[i], 0)
            del(open_d[i], 1)
        end
        
        if up_edge in loop && right_edge in loop
            del(open_d[i], 1)
            del(open_d[i], 2)
        end
    end
end

#Make sure that if there is an edge between 2 squares, both squares have the same unionEdge value.
function update_unionEdge(open_d, loop, unionEdge)
    for edge in loop
        i, j = edge
        unionEdge[j] = unionEdge[i]
    end
    return unionEdge
end


#If there is an edge going into a square, check if there is only one output possible. If so, add it to the loop.
function fill_edges(open_d, loop, unionEdge)
    n = Int(sqrt(length(open_d)))
    new_edges = Set()

    function find_possible_edges(i, open_d, unionEdge)
        possible_edges = []
        if 0 ∈ open_d[i] && i - 1 ≥ 1 && unionEdge[i] ≠ unionEdge[i - 1]
            push!(possible_edges, (i - 1, i))
        end
        if 1 ∈ open_d[i] && i - n ≥ 1 && unionEdge[i] ≠ unionEdge[i - n]
            push!(possible_edges, (i - n, i))
        end
        if 2 ∈ open_d[i] && i + 1 ≤ n^2 && unionEdge[i] ≠ unionEdge[i + 1]
            push!(possible_edges, (i, i + 1))
        end
        if 3 ∈ open_d[i] && i + n ≤ n^2 && unionEdge[i] ≠ unionEdge[i + n]
            push!(possible_edges, (i, i + n))
        end
        return possible_edges
    end

    for edge in loop
        i, j = edge
        i_possible_edges = find_possible_edges(i, open_d, unionEdge)
        j_possible_edges = find_possible_edges(j, open_d, unionEdge)

        if length(i_possible_edges) == 1
            for e in i_possible_edges
                if e ∉ loop && e ∉ new_edges && valid_edge(e,n)
                    push!(new_edges, e)
                end
            end
        end

        if length(j_possible_edges) == 1
            for e in j_possible_edges
                if e ∉ loop && e ∉ new_edges && valid_edge(e,n)
                    push!(new_edges, e)
                end
            end
        end
    end

    return union(loop, new_edges)
end














