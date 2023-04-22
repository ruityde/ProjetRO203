using JuMP, GLPK

function place(v::Vector{Int64}, d::Int64, c::Int64)
	if d in v
		return true
	end
	if v[1] == -1
		v[1] = d
		c+=1
	else
		if v[2] == -1
			v[2] = d
			c+=1
		else
			return false
		end
	end
	return true
end



function heuristique(n::Int64, white::Vector{Int64}, black::Vector{Int64})
	
	x = [copy([-1, -1]) for i in 1:n^2]

	c_bonds = 1
	while c_bonds > 0
		c_bonds = 0

		for w in white
			#Sur les bords haut-bas
		    if w < n || w > n^2-n
		        place(x[w],0,c_bonds)
		        place(x[w],2,c_bonds)
		        place(x[w-1],2,c_bonds)
		        place(x[w+1],0,c_bonds)
		    end
		    #Sur les bords gauche-droite
		    if w%n == 1 || w%n == 0
		        place(x[w],1,c_bonds)
		        place(x[w],3,c_bonds)
		        place(x[w-n],3,c_bonds)
		        place(x[w+n],1,c_bonds)
		    end
		    #A l'intérieur
		    if w >= n && w <= n^2-n && w%n != 1 && w%n != 0
		        if x[w-n] == [0,2] || x[w-n] == [2,0] || x[w+n] == [0,2] || x[w+n] == [2,0]
		            place(x[w],0,c_bonds)
		            place(x[w],2,c_bonds)
		            place(x[w-1],2,c_bonds)
		            place(x[w+1],0,c_bonds)
		        end
		        if x[w-1] == [1,3] || x[w-1] == [3,1] || x[w+1] == [1,3] || x[w+1] == [3,1]
		            place(x[w],1,c_bonds)
		            place(x[w],3,c_bonds)
		            place(x[w-n],3,c_bonds)
		            place(x[w+n],1,c_bonds)
		        end
		    end
		    #Si un trait arrive dans la case, la direction est donnée
		    if 0 in x[w] || 2 in x[w]
		    	place(x[w],0,c_bonds)
		        place(x[w],2,c_bonds)
		        place(x[w-1],2,c_bonds)
		        place(x[w+1],0,c_bonds)
		    end
		    if 1 in x[w] || 3 in x[w]
		    	place(x[w],1,c_bonds)
		        place(x[w],3,c_bonds)
		        place(x[w-n],3,c_bonds)
		        place(x[w+n],1,c_bonds)
		    end
		end

		for b in black
			#2 premières lignes
			if floor(b/n) <= 1
				place(x[b],3,c_bonds)
				place(x[b+n],1,c_bonds)
				place(x[b+n],3,c_bonds)
				place(x[b+2*n],1,c_bonds)
			else
				if 0 in x[b-n] || 2 in x[b-n] || x[b-2*n] == [0,2] || x[b-2*n] == [2,0]
					place(x[b],3,c_bonds)
					place(x[b+n],1,c_bonds)
					place(x[b+n],3,c_bonds)
					place(x[b+2*n],1,c_bonds)
				end
			end
			#2 dernières lignes
			if floor(b/n) >= n-2
				place(x[b],1,c_bonds)
				place(x[b-n],1,c_bonds)
				place(x[b-n],3,c_bonds)
				place(x[b-2*n],3,c_bonds)
			else
				if 0 in x[b+n] || 2 in x[b+n] || x[b+2*n] == [0,2] || x[b+2*n] == [0,2]
					println(b)
					println(x[b+n])
					place(x[b],1,c_bonds)
					place(x[b-n],1,c_bonds)
					place(x[b-n],3,c_bonds)
					place(x[b-2*n],3,c_bonds)
				end
			end
			#2 premières colonnes
			if b%n == 1 || b%n == 2
				place(x[b],2,c_bonds)
				place(x[b+1],0,c_bonds)
				place(x[b+1],2,c_bonds)
				place(x[b+2],0,c_bonds)
			else
				if 1 in x[b-1] || 3 in x[b-1] || x[b-2] == [1,3] || x[b-2] == [3,1]
					place(x[b],2,c_bonds)
					place(x[b+1],0,c_bonds)
					place(x[b+1],2,c_bonds)
					place(x[b+2],0,c_bonds)
				end
			end
			#2 dernières colonnes
			if b%n == 0 || b%n == n-1
				place(x[b],0,c_bonds)
				place(x[b-1],0,c_bonds)
				place(x[b-1],2,c_bonds)
				place(x[b-2],2,c_bonds)
			else
				if 1 in x[b+1] || 3 in x[b+1] || x[b+2] == [1,3] || x[b+2] == [3,1]
					place(x[b],0,c_bonds)
					place(x[b-1],0,c_bonds)
					place(x[b-1],2,c_bonds)
					place(x[b-2],2,c_bonds)
				end
			end


		end


	end

	return x





end