using Random


function life_rule(old, matrix::Array)
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
    matrix[1:size(matrix)[1], 1:size(matrix)[2]] = newA[1:end, 1:end]
    newA = 0
end

function life_step(matrix::Array)

    old = Array{Bool}(undef, size(matrix)[1]+2, size(matrix)[2]+2)
    left = size(matrix)[2]
    right = 1
    top = size(matrix)[1]
    bot = 1
    old[1      , 1      ] = matrix[top , left]   # left side
    old[2:end-1, 1      ] = matrix[1:size(matrix)[1], left]
    old[end    , 1      ] = matrix[bot , left]
    old[1      , 2:end-1] = matrix[top , 1:size(matrix)[2]]
    old[2:end-1, 2:end-1] = matrix[1:size(matrix)[1], 1:size(matrix)[2]]   # middle
    old[end    , 2:end-1] = matrix[bot , 1:size(matrix)[2]]
    old[1      , end    ] = matrix[top , right]  # right side
    old[2:end-1, end    ] = matrix[1:size(matrix)[1], right]
    old[end    , end    ] = matrix[bot , right]
    #println("qui")
    #println(i)
    #stampaMatrice(old)
    life_rule(old, matrix)
    old = 0
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

function gameOfLife(matrix::Array, gen::Int)


    for _ in 1:gen

        life_step(matrix)
        #matrix[1:dim, 1:dim] = tmp[1:dim, 1:dim]
        #println(d)
        #stampaMatrice(matrix)

    end

end

#inizio programma
dim = 20000
matrix = Array{Bool}(undef, dim, dim)

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

#println(ranges)


t = @elapsed gameOfLife(matrix, 10)
println(t)

matrix = 0
GC.gc()
#println(varinfo())
