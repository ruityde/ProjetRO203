# Unequal

## Commandes

1) Se placer dans le dossier ProjetRO203/unequal/src
2) Lancer julia

3) Générer un dataset: 

	- include("generation.jl)
	- generateDataSet()

3) Résoudre le dataset:

	- include("resolution.jl")
	- solveDataSet()

4) Mise en forme des résultats:

	- include("io.jl")
	- performanceDiagram("../res/ResultatDiagramme.pdf")
	- resultsArray("../res/ResultsArray.tex")
