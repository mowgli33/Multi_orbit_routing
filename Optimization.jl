#On cherche à optimiser le problème créé précédemment dans Toymodel


#On charge les données csv

using CSV
using DataFrames
using JSON3


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
ind_subtasks = [(k, v) for k in 1:size(subtasks, 2), v in 1:size(subtasks, 1) if !ismissing(subtasks[v, k])]    #On prend en compte que certaines valeurs du dataframe sont des NaN

# Définition des variables binaires pour chaque sous-tâche
@variable(
    model, 
    beta[ind_subtasks], 
    Bin)

# Définition des variables de fuel capacity
@variable(
    model, 
    f[1:size(df["servicers"],1),1:size(df["times"],1)]>=0)

# Extraction des indices servicer, arc, time
D = df["servicers"].id
A = collect(zip(df["arcs"].start_node, df["arcs"].end_node)) # Paires (i, j) des arcs
T = df["times"].t

@variable(
    model, 
    y[d in D, (i, j) in A, t in T], 
    Bin)


# Définition des contraintes

@constraint(
    model,
    [v in df["tasks"].id],
    sum(beta[(v, k)] for (v2, k) in ind_subtasks if v2 == v) <= 1
)



# @constraint(
#     model,
#     [(v,k) in ind_subtasks],
#     sum(
#         sum(
#             y[d,(i,n),t-tho] for (i,n,tho) in zip(df["arcs"].start_node,df["arcs"].end_node,df["arcs"].tho) if n == JSON3.read(String(df["subtasks"][k,v]))[1] && 900 - tho >=0
#             ) for d in df["servicers"].id
#     ) >= beta[(v,k)]
# )

@constraint(
    model,
    [(v,k) in ind_subtasks],
    sum(
        y[1,(i,n),JSON3.read(String(df["subtasks"][k,v]))[2]-tho] for (i,n,tho,type) in zip(df["arcs"].start_node[1:3],df["arcs"].end_node[1:3],df["arcs"].tho[1:3],df["arcs".type[1:3]]) if n == JSON3.read(String(df["subtasks"][k,v]))[1] && JSON3.read(String(df["subtasks"][k,v]))[2] - tho >=0
        ) >= beta[(v,k)]
)

###On remplace pour l'instant subtasks.duration par le pas de temps de notre simulation 900



