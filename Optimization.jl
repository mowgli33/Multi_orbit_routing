#On cherche à optimiser le problème créé précédemment dans Toymodel


#On charge les données csv

using CSV
using DataFrames


# nodes = CSV.read("./data/nodes.csv", DataFrame)
# arcs = CSV.read("./data/arcs.csv", DataFrame)
# tasks = CSV.read("./data/tasks.csv", DataFrame)
# subtasks = CSV.read("./data/subtasks.csv", DataFrame)
# servicers = CSV.read("./data/servicers.csv", DataFrame)
# times = CSV.read("./data/times.csv", DataFrame)

files = readdir("./data")
df = Dict()
for val in files
    df[val[1:end-4]] = CSV.read("./data/$val",DataFrame)
end

subtasks = df["subtasks"]
println(first(subtasks,5))


#Création du modèle

using JuMP
using GLPK


# Création du modèle
model = Model(GLPK.Optimizer)

# Extraction des indices (tâche, sous-tâche) valides
ind_subtasks = [(j, i) for j in 1:size(subtasks, 2), i in 1:size(subtasks, 1) if !ismissing(subtasks[i, j])]

# Définition des variables binaires pour chaque sous-tâche
@variable(model, beta[ind_subtasks], Bin)

# Définition des variables de fuel capacity
@variable(model, f[1:size(df["servicers"],1),1:size(df["times"],1)]>=0)

# Extraction des indices
D = df["servicers"].id
A = collect(zip(df["arcs"].start_node, df["arcs"].end_node)) # Paires (i, j) des arcs
T = df["times"].id

@variable(model, y[d in D, (i, j) in A, t in T], Bin)

# Affichage des indices et des variables
model





