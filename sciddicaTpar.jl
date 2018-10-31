using Distributed

if nworkers() != 7
    addprocs(7)
end

@everywhere using SharedArrays

function assignRange(dim)

    ranges = Array{Int64}(undef, nprocs())
    let
        index = dim/nworkers()
        index = floor(Int, index)
        mrange = index
        ranges[1] = 0
        for i in 2:nprocs()-1
            ranges[i] = index
            index = index + mrange
        end
        ranges[nprocs()] = dim
    end
    return ranges

end

@everywhere function neighbors(matrix::Array{Float64}, i, j)

    array = Tuple{Int64,Int64}[]
    if (i+1 <= size(matrix)[1]) push!(array, (i+1,j)) end
    if (i-1 > 0) push!(array, (i-1,j)) end
    if (j+1 <= size(matrix)[2]) push!(array, (i,j+1)) end
    if (j-1 > 0) push!(array, (i,j-1)) end

    return array

end

@everywhere function sciddicaT_rule(matrixDlocal::Array{Float64}, matrixHSlocal::Array{Float64}, matrixDtmp::SharedArray, pr, left, right)

    matrixDtmplocal = similar(matrixDlocal)
    fill!(matrixDtmplocal, 0)
    from = left==1 ? 1 : left+1
    to = right==size(matrixDtmp)[1] ? right : right-1
    for h in from:to, j in 1:size(matrixDlocal)[2]

        neighbor = neighbors(matrixHSlocal, h, j)
        #println(neighbor)
        let
            again = true
            me = true
            avg = 0
            while again

                sum = 0
                for k in 1:size(neighbor)[1]
                    sum = sum + (matrixHSlocal[neighbor[k][1],neighbor[k][2]]+matrixDlocal[neighbor[k][1],neighbor[k][2]])

                end
                sum += matrixDlocal[h,j]
                if me sum += matrixHSlocal[h,j] end

                avg = me ? sum/(size(neighbor)[1]+1) : sum/size(neighbor)[1]

                delete = Int64[]

                for k in 1:size(neighbor)[1]
                    if (matrixHSlocal[neighbor[k][1],neighbor[k][2]]+matrixDlocal[neighbor[k][1],neighbor[k][2]]) > avg
                        pushfirst!(delete, k)
                    end
                end
                anotherCycle = size(delete)[1]

                if me && matrixHSlocal[h,j] > avg
                    me = false
                    anotherCycle+=1
                end

                if anotherCycle == 0
                    again = false
                end

                for k in 1:size(delete)[1]
                    splice!(neighbor, delete[k])
                end

            end #end while
            delete = 0
            r = size(matrixDlocal)[2]
            for k in 1:size(neighbor)[1]

                mod = (avg - (matrixHSlocal[neighbor[k][1],neighbor[k][2]]+matrixDlocal[neighbor[k][1],neighbor[k][2]]))*pr

                matrixDtmplocal[h,j] -= mod
                matrixDtmplocal[neighbor[k][1],neighbor[k][2]] += mod

            end
        end #end let
    end #end for
    #println(matrixDtmplocal)
    matrixDtmp[1:end, left:right] += matrixDtmplocal[1:end, 1:end]
    matrixDlocal = 0
    matrixDlocal = 0

end

function sciddicaT_step(matrixHS::SharedArray{Float64}, matrixD::SharedArray{Float64}, pr)

    matrixDtmp = SharedArray{Float64}(size(matrixD)[1], size(matrixD)[2])
    matrixDtmp[1:end, 1:end] = matrixD[1:end, 1:end]
    @sync for i in 2:nworkers()+1
        @spawnat i begin
            row = size(matrixHS)[1]
            col = ranges[i-1]==0 || ranges[i]==size(matrixD)[2] ? (ranges[i]-ranges[i-1])+1 : (ranges[i]-ranges[i-1])+2
            matrixDlocal = Array{Float64}(undef, row, col)
            matrixHSlocal = Array{Float64}(undef, row, col)

            top = 1
            bot = size(matrixD)[1]
            left = ranges[i-1]==0 ? 1 : ranges[i-1]
            right = ranges[i]==size(matrixD)[1] ? ranges[i] : ranges[i]+1

            matrixDlocal[1:end, 1:end] = matrixD[top:bot, left:right]
            matrixHSlocal[1:end, 1:end] = matrixHS[top:bot, left:right]

            sciddicaT_rule(matrixDlocal, matrixHSlocal, matrixDtmp, pr, left, right)

        end
    end


    matrixD[1:end, 1:end] = matrixDtmp[1:end, 1:end]
    matrixDtmp = 0
    #println(matrixD)
end

dim = 5000
matrixHS = SharedArray{Float64}(dim, dim)
matrixD = SharedArray{Float64}(dim, dim)

ranges = assignRange(dim)
#println(ranges)
fill!(matrixHS, 1)
fill!(matrixD, 1)
matrixHS[1,1]=4

pr = 1 #fattore rallentamento
t = @elapsed for _ in 1:10
    sciddicaT_step(matrixHS, matrixD, pr)
    tmp = matrixD + matrixHS
    #println(varinfo())
    #println(tmp)
    #GC.gc()
end
matrixHS = 0
matrixD = 0
println(t)
