using Gtk, Gtk.ShortNames, Graphics
using Distributed
using Random


function contaCelleVive(matrice::Matrix{Bool},i,j, dim)

    dim = dim+1
    cont = 0
    a = 0
    b = 0

    println("controllando cella $i, $j")
    if (i-1)%dim < 0
        a = (i-1)%dim + dim
        if (a == 0) a = dim-1 end
    else
        a = (i-1)%dim
        if (a == 0) a = dim-1 end
    end
    if (j-1)%dim < 0
        b = (j-1)%dim + dim
        if (b == 0) b = dim-1 end
    else

        b = (j-1)%dim
        if (b == 0) b = dim-1 end
    end
    println("intorno $a, $b $(matrice[a,b]) ")
    if matrice[a,b]
        cont = cont+1

    end

    for w in 1:2
        b = (b+1)%dim
        if (b == 0) b = 1 end
        println("intorno $a, $b $(matrice[a,b]) ")
        if matrice[a,b]
            cont = cont+1
        end
    end

    for w in 1:2
        a = (a+1)%dim

        if (a == 0) a = 1 end
        println("intorno $a, $b $(matrice[a,b]) ")
        if matrice[a,b]
            cont = cont+1
        end
    end

    for w in 1:2
        if (b-1)%dim < 0
            b = (b-1)%dim + dim
            if (b == 0) b = dim-1 end
        else
            b = (b-1)%dim
            if (b == 0) b = dim-1 end
        end
        if matrice[a,b]
            cont = cont+1
        end
        println("intorno $a, $b $(matrice[a,b]) ")
    end

    if (a-1)%dim < 0
        a = (a-1)%dim + dim
        if (a == 0) b = dim-1 end
    else
        a = (a-1)%dim
        if (a == 0) a = dim-1 end
    end
    println("intorno $a, $b $(matrice[a,b]) ")
    if matrice[a,b]
        cont = cont+1
    end

    return cont

end

function displays(dim, matrice::Matrix{Bool}, canv)

    dimWin = dim*30
    @guarded draw(canv) do widget
        ctx = getgc(canv)
        w, h = width(canv), height(canv)

        offsetW = w
        offsetH = h
        rectangle(ctx, 0, 0, dimWin, dimWin)
        set_source_rgb(ctx, 1, 1, 1)
        fill(ctx)
        for i in 0:30:dimWin

            rectangle(ctx, i, 0, 1, dimWin)
            set_source_rgb(ctx, 0, 0, 0)
            fill(ctx)

            rectangle(ctx, 0, i, dimWin, 1)
            set_source_rgb(ctx, 0, 0, 0)
            fill(ctx)

        end
        for i in 1:dim, j in 1:dim
             if matrice[i,j]
                 rectangle(ctx, ((j*dimWin)/dim)-30, ((i*dimWin)/dim)-30, 30, 30)
                 #println("i : $i, j: $j")
                 set_source_rgb(ctx, 0, 0, 0)
                 fill(ctx)

             end
         end

    end
    sleep(1/60)
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

function scambia(matrice::Matrix{Bool}, tmp::Matrix{Bool}, dim)

    for i in 1:dim, j in 1:dim

        matrice[i, j] = tmp[i, j]
    end

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
gen = 100
matrice = Matrix{Bool}(undef, dim, dim)
tmp = Matrix{Bool}(undef, dim, dim)

fill!(matrice, false)

#println(matrice)
#println(matrice[1,1])

Random.seed!(1234)
x = rand(dim*dim)
cont1 = 0

for i in 1:dim, j in 1:dim
    global cont1 = cont1 + 1
    if x[cont1] > 0.5
        matrice[i,j] = true
    else
        matrice[i,j] = false
    end

end


@async begin
    for _ in 1:gen
        #println("qui")
        for i in 1:dim, j in 1:dim

            celleVive = contaCelleVive(matrice, i, j, dim)
            println("cella $i, $j ha celle vive $celleVive")

            if celleVive < 2 || celleVive > 3
                tmp[i,j] = false
                println("morte")
            elseif celleVive == 3
                tmp[i,j] = true
                println("Vive")
            else
                tmp[i,j] = matrice[i,j]
                println("$(matrice[i,j]) come prima")
            end

        end

        scambia(matrice, tmp, dim)

        displays(dim, matrice, canv)
    end
end
showall(win)
