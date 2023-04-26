# Pearl

## Commandes

1) Se placer dans le dossier ProjetRO203/pearl/src
2) Lancer julia

3) Générer un dataset: 

	- include("generation.jl)
	- generateDataSet()

3) Résoudre le dataset:

	- include("resolution.jl")
	- solveDataSet()

4) Mise en forme des résultats:

	- include("io.jl")
	- resultsArray("../res/ResultsArray.tex")
	- performanceDiagram("../res/ResultatDiagramme.png")
	- timeVsSizeDiagram("../res/TimeVSize.png")

Instances de test 

	- Game Id: 6x6:bBBnWaBbWfBaBbB
		-> cplexSolve(6, [3 4 21 31 33 36], [19 24])
	- Game Id: 5x5:bWdBfWeBcB
		-> cplexSolve(5, [8 21 25], [3 15])