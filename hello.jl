using Distributed

x = rand(1000000)
#println(x)

dim = size(x)[1]
println(dim)

t = @elapsed begin
    let
        cont = 0
        dim = size(x)[1]
        println(dim)
        for i in 1:dim

            cont = cont + x[i]

        end
        println(cont)
    end
end
println(t)

if (nworkers() != 4)
    addprocs(4)
end

t1 = @elapsed begin


    cont1 = @distributed (+) for i in 1:size(x)[1]
        x[i]
    end
    println(cont1)

end
println(t1)
