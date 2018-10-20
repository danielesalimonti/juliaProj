using Gtk, Gtk.ShortNames, Graphics
using Distributed
using Random


function displays(dim, matrice::Matrix{Bool}, canv)

    dimWin = dim*30
    @guarded draw(canv) do widget
        ctx = getgc(canv)
        w, h = width(canv), height(canv)

        offsetW = w
        offsetH = h
        rectangle(ctx, 0, 0, dimWin, dimWin)
        set_source_rgb(ctx, 0, 0, 0)
        fill(ctx)
        for i in 0:30:dimWin

            rectangle(ctx, i, 0, 1, dimWin)
            set_source_rgb(ctx, 1, 1, 1)
            fill(ctx)

            rectangle(ctx, 0, i, dimWin, 1)
            set_source_rgb(ctx, 1, 1, 1)
            fill(ctx)

        end
        for i in 1:dim, j in 1:dim
             if matrice[i,j]
                 rectangle(ctx, ((j*dimWin)/dim)-30+1, ((i*dimWin)/dim)-30+1, 29, 29)
                 #println("i : $i, j: $j")
                 set_source_rgb(ctx, rand(1)[1], rand(1)[1], rand(1)[1])
                 fill(ctx)

             end
         end

    end
    sleep(1/30)
end

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


function gameOfLife(matrix::Array, gen::Int, canv, win)
    @async begin
        for _ in 1:gen

            life_step(matrix)
            #matrix[1:dim, 1:dim] = tmp[1:dim, 1:dim]
            #println(d)
            #stampaMatrice(matrix)
            displays(size(matrix)[1], matrix, canv)
        end
    end
    showall(win)
end


function stampaMatrice(matrice::Matrix{Bool}, dim)

    for i in 1:dim, j in 1:dim
            if matrice[i,j]
                print("@")
            else
                print("  ")
            end
            if (j == dim)
                print("\n")
            end
    end
    print("\n")
end



#inizio programma
dim = 30
dimWin = dim*30

win = GtkWindow("GameOfLife", dimWin, dimWin)
hbox = Box(:h)
set_gtk_property!(hbox, :homogeneous, true)
push!(win, hbox)
canv = Canvas()
push!(hbox, canv)
cont = 0

matrix = Matrix{Bool}(undef, dim, dim)
tmp = Matrix{Bool}(undef, dim, dim)

fill!(matrix, false)

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

t = @elapsed gameOfLife(matrix, 1000, canv, win)
println(t)

matrix = 0
GC.gc()

println(t)
#showall(win)
