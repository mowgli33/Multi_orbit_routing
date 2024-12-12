using JuMP, CPLEX, CSV, DataFrames
include("function.jl")

# CSV repertory to import the data from the python code 
name_of_case_study = "Toymodel"

input_directory = "output"  # * name_of_case_study
output_directory = "./results/" * name_of_case_study

N, B, B_v, A, D, T, T_dict, A_Rt, f_dij = import_data(input_directory)
# Check if the data is good
println("N: ", N)
println("B: ", B)
println("B_v: ", B_v)
for print in keys(A)
    println(print," : ", A[print])
end
println("D: ", D)
println("T: ", T)
println("T_dict: ", T_dict)

function create_and_solve_model(B, B_v, D, A, N, T, T_dict, A_Rt, f_dij)

    # --- Model --- #
    model = Model(CPLEX.Optimizer)

    # --- Decision variable --- #
    @variable(model, beta_vk[keys(B), keys(B_v["v1"])], Bin)
    @variable(model, 0 <= f_dt[keys(D), T] <= D["d1"]["F_d"])
    @variable(model, y_dijt[keys(A), T], Bin)
    
    # @variable(model, x_PM[keys(B), T], Bin)
    # @variable(model, x_CM[keys(B), T], Bin)
    # @variable(model, f[keys(B), T], Bin)

    #---------------- Constraints ----------------#
    
    #----- c1 -----#
    @constraint(model, c1[v in keys(B)], 
        sum(beta_vk[v, :]) 
        <= 
        1
    )

    #----- c2 -----#
    @constraint(model, c2[v in keys(B), k in keys(B_v[v])], 
        sum(y_dijt[ij, B_v[v][k][2] - A[ij][1]] for ij in keys(A) if split(ij, " => ")[2] == B_v[v][k][1] && B_v[v][k][2] - A[ij][1] >= 0) 
        >= 
        beta_vk[v, k]
    )

    #----- c3 -----#
    @constraint(model, c3[i in keys(N), d in keys(D), t in keys(T_dict)],
        sum(y_dijt[ji, T_dict[t] - A[ji][1]] for ji in keys(A) if split(ji, " => ")[2] == i && T_dict[t] - A[ji][1] >= 0)
        -
        sum(y_dijt[ij, T_dict[t]] for ij in keys(A) if split(ij, " => ")[1] == i)
        ==
        if i == D["d1"]["s_d"] && T_dict[t] == first(T)
            -1
        elseif i == "E" && T_dict[t] == last(T)
            1
        else
            0
        end
    )

    #----- c4 -----#
    @constraint(model, c4[t in T[2:end], d in keys(D)],
        f_dt[d, t]
        ==
        f_dt[d, t-1]
        -
        (
        sum(
            sum(
                y_dijt[ij, time] * A[ij][3]
                for time in max(t - A[ij][1], 0):t-1
            )
            for ij in keys(A)
        )
        -
        sum(
            y_dijt[ij, t - A[ij][1]] * f_dij[d][ij] for ij in A_Rt[t-1] if t - A[ij][1] >= 0
        )
        )
    )

    #----- c5 -----#
    @constraint(model, c5[d in keys(D)], f_dt[d, T[1]] == D[d]["F_d"])

    #-------------- objective function --------------#
    @objective(model, Max, sum(B[v] * sum(beta_vk[v, k] for k in keys(B_v[v])) for v in keys(B)))

    set_optimizer_attribute(model, "CPX_PARAM_TILIM", 43200.0)

    optimize!(model)
    println(solution_summary(model))

    return model, value.(beta_vk), value.(f_dt), value.(y_dijt)     #, value.(x_PM), value.(x_CM), value.(f)

    end

model, beta_vk_values, f_dt_values, y_dijt_values = create_and_solve_model(B, B_v, D, A, N, T, T_dict, A_Rt, f_dij)     #, x_PM_values, x_CM_values, f_values