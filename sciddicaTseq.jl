

function neighbors(matrix::Array{Float64}, i, j)

    array = Tuple{Int64,Int64}[]
    if (i+1 <= size(matrix)[1]) push!(array, (i+1,j)) end
    if (i-1 > 0) push!(array, (i-1,j)) end
    if (j+1 <= size(matrix)[2]) push!(array, (i,j+1)) end
    if (j-1 > 0) push!(array, (i,j-1)) end

    return array

end

function sciddicaT_step(matrixHS::Array{Float64}, matrixD::Array{Float64}, pr)

    matrixDtmp = Array{Float64}(undef, dim, dim)
    #println(matrixHS)
    matrixDtmp[1:end, 1:end] = matrixD[1:end, 1:end]
    for i in 1:size(matrixHS)[1], j in 1:size(matrixHS)[2]

        neighbor = neighbors(matrixHS, i, j)

        let
            again = true
            me = true
            avg = 0
            while again

                sum = 0
                for k in 1:size(neighbor)[1]
                    sum = sum + (matrixHS[neighbor[k][1],neighbor[k][2]]+matrixD[neighbor[k][1],neighbor[k][2]])
                end
                sum += matrixD[i,j]
                if me sum += matrixHS[i,j] end

                avg = me ? sum/(size(neighbor)[1]+1) : sum/size(neighbor)[1]

                delete = Int64[]

                for k in 1:size(neighbor)[1]
                    if (matrixHS[neighbor[k][1],neighbor[k][2]]+matrixD[neighbor[k][1],neighbor[k][2]]) > avg
                        pushfirst!(delete, k)
                    end
                end
                anotherCycle = size(delete)[1]

                if me && matrixHS[i,j] > avg
                    me = false
                    anotherCycle+=1
                end

                if anotherCycle == 0
                    again = false
                end

                for k in 1:size(delete)[1]
                    splice!(neighbor, delete[k])
                end

            end

            for k in 1:size(neighbor)[1]

                mod = (avg - (matrixHS[neighbor[k][1],neighbor[k][2]]+matrixD[neighbor[k][1],neighbor[k][2]]))*pr
                #println(mod)
                matrixDtmp[i,j] -= mod
                matrixDtmp[neighbor[k][1],neighbor[k][2]] += mod

            end
        end #end let
    end #end for

    matrixD[1:end, 1:end] = matrixDtmp[1:end, 1:end]

end

dim = 5000
matrixHS = Array{Float64}(undef, dim, dim)
matrixD = Array{Float64}(undef, dim, dim)


fill!(matrixHS, 1)
fill!(matrixD, 1)
matrixHS[1,1]=4

pr = 1 #fattore rallentamento

t = @elapsed for _ in 1:10
    sciddicaT_step(matrixHS, matrixD, pr)
    tmp = matrixD + matrixHS
    #println(matrixD)
end

println(t)
