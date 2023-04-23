Ce qui a été implémenté et testé

	-Résolution par Cplex fonctionne
	-displayGrid qui affiche une instance non résolue
	-readInputFile qui renvoie

		-la taille de la grille carrée
		-la liste des coordonnées des points blancs
		-la liste des coordonnées des points noirs

	-L'heuristique (dans un fichier à part pour l'instant)

Ce qui a été codé mais ne fonctionne pas encore

	- La génération d'instance

Instances de test 

	- Game Id: 6x6:bBBnWaBbWfBaBbB
		-> cplexSolve(6, [3 4 21 31 33 36], [19 24])
	- Game Id: 5x5:bWdBfWeBcB
		-> cplexSolve(5, [8 21 25], [3 15])