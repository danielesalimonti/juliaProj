using Distributed, SharedArrays, Random
@everywhere using SharedArrays
if (nworkers() != 7)
    addprocs(7)
end


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

@everywhere function life_rule(old, range1, range2, array::SharedArray)
    m, n = size(old)
    newA = similar(old, m-2, n-2)
    #println(old)
    for j = 2:n-1
        for i = 2:m-1
            nc = (old[i-1,j-1] + old[i-1,j] + old[i-1,j+1]+
                   old[i  ,j-1] + old[i  ,j+1] +
                   old[i+1,j-1] + old[i+1,j] + old[i+1,j+1])
            #println(nc)
            newA[i-1,j-1] = (nc == 3 || nc == 2 && old[i,j])
        end
    end
    #println("$(size(newA))")
    array[1:size(array)[1], range1:range2] = newA[1:end, 1:end]

end

function life_step(matrix::SharedArray, ranges::Array)

    @sync for i in 2:nworkers()+1
        @spawnat i begin
            row::Int = size(matrix)[1]+2
            col::Int = (ranges[i]-ranges[i-1])+2
            old = Array{Bool}(undef, row, col)
            #println(old)
            left = (ranges[i-1])%(size(matrix)[2]+1) > 0 ? (ranges[i-1])%(size(matrix)[2]+1) : size(matrix)[2]
            right = (ranges[i]+1)%(size(matrix)[2]+1) > 0 ? (ranges[i]+1)%(size(matrix)[2]+1) : 1
            #println("left $i $left")
            #println("right $i $right")
            top = size(matrix)[1]
            bot = 1
            old[1      , 1      ] = matrix[top , left]   # left side
            old[2:end-1, 1      ] = matrix[1:size(matrix)[1], left]
            old[end    , 1      ] = matrix[bot , left]
            old[1      , 2:end-1] = matrix[top , ranges[i-1]+1:ranges[i]]
            old[2:end-1, 2:end-1] = matrix[1:size(matrix)[1], ranges[i-1]+1:ranges[i]]   # middle
            old[end    , 2:end-1] = matrix[bot , ranges[i-1]+1:ranges[i]]
            old[1      , end    ] = matrix[top , right]  # right side
            old[2:end-1, end    ] = matrix[1:size(matrix)[1], right]
            old[end    , end    ] = matrix[bot , right]
            #println("qui")
            #println(i)
            #stampaMatrice(old)
            life_rule(old, ranges[i-1]+1, ranges[i], matrix)
            old = 0
        end
    end
end


function stampaMatrice(matrice)
    println("start")
    for i in 1:size(matrice)[1], j in 1:size(matrice)[2]
            #print("riga $i ")
            if matrice[i,j]
                print("@")
            else
                print("-")
            end
            if (j == size(matrice)[2])
                print("\n")
            end
    end
    println("end")
end

function gameOfLife(matrix::SharedArray, ranges::Array, gen::Int)


    for _ in 1:gen

        life_step(matrix, ranges)
        #println(d)
        #matrix[1:dim, 1:dim] = tmp[1:dim, 1:dim]
        #stampaMatrice(matrix)

    end

end

#inizio programma
dim = 20000
matrix = SharedArray{Bool}(dim, dim)
#tmp = SharedArray{Bool}(dim, dim)

Random.seed!(1234)
x = rand(dim*dim)
fill!(matrix, false)
let
    cont1 = 0
    for i in 1:dim, j in 1:dim
        cont1 = cont1 + 1
        if x[cont1] > 0.5
            matrix[i,j] = true
        end
    end
end
x = 0
#=
matrix[1,20] = true
matrix[2,20] = true
matrix[3,20] = true
=#
#stampaMatrice(matrix)

#stabilire range


ranges = Array{Int64}(undef, nprocs()+1)
ranges = assignRange(dim)
#tmp[1:dim, 1:dim] = matrix[1:dim, 1:dim]
#println(ranges)


t = @elapsed gameOfLife(matrix, ranges, 10)
println(t)

matrix = 0
GC.gc()

#println(varinfo())
