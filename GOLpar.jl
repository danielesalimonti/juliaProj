using Distributed, Random
@everywhere using DistributedArrays

if (nworkers() != 4)
    addprocs(4)

end

function life_step(d::DArray)
    DArray(size(d),procs(d)) do I

        top   = mod(first(I[1])-2,size(d,1))+1
        bot   = mod( last(I[1])  ,size(d,1))+1
        left  = mod(first(I[2])-2,size(d,2))+1
        right = mod( last(I[2])  ,size(d,2))+1

        old = Array{Bool}(undef, length(I[1])+2, length(I[2])+2)
        old[1      , 1      ] = d[top , left]   # left side
        old[2:end-1, 1      ] = d[I[1], left]
        old[end    , 1      ] = d[bot , left]
        old[1      , 2:end-1] = d[top , I[2]]
        old[2:end-1, 2:end-1] = d[I[1], I[2]]   # middle
        old[end    , 2:end-1] = d[bot , I[2]]
        old[1      , end    ] = d[top , right]  # right side
        old[2:end-1, end    ] = d[I[1], right]
        old[end    , end    ] = d[bot , right]

        #println(size(old))
        d[:L] = life_rule(old)
    end
end

function stampaMatrice(matrice, dim)
    println("start")
    for i in 1:dim, j in 1:dim
            #print("riga $i ")
            if matrice[i,j]
                print("@")
            else
                print("-")
            end
            if (j == dim)
                print("\n")
            end
    end
    println("end")
end

@everywhere function life_rule(old)
    m, n = size(old)
    new = similar(old, m-2, n-2)
    for j = 2:n-1
        for i = 2:m-1
            nc = +(old[i-1,j-1], old[i-1,j], old[i-1,j+1],
                   old[i  ,j-1],             old[i  ,j+1],
                   old[i+1,j-1], old[i+1,j], old[i+1,j+1])
            new[i-1,j-1] = (nc == 3 || nc == 2 && old[i,j])
        end
    end
    return new
end

dim = 10000

matrice = Matrix{Bool}(undef, dim, dim)

fill!(matrice, false)

Random.seed!(1234)
x = rand(dim*dim)
cont1 = 0

for i in 1:dim, j in 1:dim
    global cont1 = cont1 + 1
    if x[cont1] > 0.5
        matrice[i,j] = true
    end
end

dmatrix = distribute(matrice)


for _ in 1:10000

    @async life_step(dmatrix)
    #stampaMatrice(dmatrix, dim)
end
#println(procs(dmatrix))
#println(procs(dmatrix)[1])


#printLocalMatrix(dmatrix)
