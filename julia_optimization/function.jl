function import_data(import_directory::String)
    # Lire les fichiers CSV
    nodes_df = CSV.read(joinpath(input_directory, "nodes.csv"), DataFrame)
    tasks_df = CSV.read(joinpath(input_directory, "tasks.csv"), DataFrame)
    subtasks_df = CSV.read(joinpath(input_directory, "subtasks.csv"), DataFrame)
    arcs_df = CSV.read(joinpath(input_directory, "arcs.csv"), DataFrame)
    robots_df = CSV.read(joinpath(input_directory, "robots.csv"), DataFrame)
    # refueling_arc_df = CSV.read(joinpath(input_directory, "refueling_arcs.csv"), DataFrame)
    # f_dij_df = CSV.read(joinpath(input_directory, "f_dij.csv"), DataFrame)


    # Convertir les DataFrames en dictionnaires
    N = Dict(row["Node"] => row["ID"] for row in eachrow(nodes_df))
    B = Dict(row["Task"] => row["Weight"] for row in eachrow(tasks_df))
    B_v = Dict()
    A_Rt = Dict()
    f_dij = Dict()
    
    for row in eachrow(subtasks_df)
        task = row["Task"]
        if !haskey(B_v, task)
            B_v[task] = Dict()
        end
        B_v[task][row["SubTask"]] = (row["Node"], row["Time"])
    end
    
    A = Dict()
    for row in eachrow(arcs_df)
        from_to = "$(row["FromNode"]) => $(row["ToNode"])"
        A[from_to] = (row["Tau"], row["Phi"],row["Psi"])
    end
    
    D = Dict(row["RobotID"] => Dict("s_d" => row["StartingNode"], "F_d" => row["MaxFuel"]) for row in eachrow(robots_df))
    
    T = unique(subtasks_df[:, "Time"])
    
    T_dict = Dict("t$(i-1)" => t for (i, t) in enumerate(T))

    # for row in eachrow(refueling_arc_df)
    #     t = row.Time
    #     arcs = split(row.Arcs, ", ")
    #     A_Rt[t] = Tuple(arcs)
    # end

    # for row in eachrow(f_dij_df)
    #     robot = row.Robot
    #     arc = row.Arc
    #     value = row.Value
    
    #     # Si le robot n'existe pas encore dans F_dij, on l'ajoute
    #     if !haskey(f_dij, robot)
    #         f_dij[robot] = Dict()
    #     end
    
    #     # Ajouter l'arc et la valeur au sous-dictionnaire du robot
    #     f_dij[robot][arc] = value
    # end
    
    return N, B, B_v, A, D, T, T_dict, A_Rt, f_dij
end


function print_all_manoeuvres(y_dijt_values, f_dt_values, beta_vk_values, A, T, D)
    # Parcourir tous les temps disponibles dans T
    for time in T
        println("À t = $time :")
        
        
        # Imprimer les manœuvres
        println("  Manœuvres :")
        for ij in keys(A)
            from_node, to_node = split(ij, " => ")
            if y_dijt_values[ij, time] == 1.0
                println("    Manœuvre: $(from_node) => $(to_node)")
            end
        end
        
        # Imprimer les valeurs de f_dt
        println("  Valeurs de f_dt :")
        for d in keys(D)
            println("    Robot $(d) : $(f_dt_values[d, time])")
        end
        
        # Imprimer les valeurs de beta_vk où beta_vk = 1
        println("  Valeurs de beta_vk :")
        for v in keys(B_v)
            for k in keys(B_v[v])
                if beta_vk_values[v, k] == 1
                    println("    Task $(v), Subtask $(k) : $(beta_vk_values[v, k])")
                end
            end
        end
        
        println("\n")  # Ligne vide pour séparation entre les temps
    end
end
