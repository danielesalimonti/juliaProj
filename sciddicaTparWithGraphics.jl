using Distributed
using DelimitedFiles
using Gtk, Gtk.ShortNames, Graphics

if nworkers() != 4
    addprocs(4)
end

@everywhere using SharedArrays

function displays(matrice::SharedArray, canv)

    dimWin = size(matrice)[1]*2
    @guarded draw(canv) do widget
        ctx = getgc(canv)
        w, h = width(canv), height(canv)

        offsetW = w
        offsetH = h
        rectangle(ctx, 0, 0, dimWin, dimWin)
        set_source_rgb(ctx, 0, 0, 0)
        #set_source_rgb(ctx, rand(1)[1], rand(1)[1], rand(1)[1])
        #set_source_rgb(ctx, 1, 1, 1)
        fill(ctx)
        #=
        for i in 0:30:dimWin

            rectangle(ctx, i, 0, 1, dimWin)
            set_source_rgb(ctx, 1, 1, 1)
            #set_source_rgb(ctx, 0, 0, 0)
            fill(ctx)

            rectangle(ctx, 0, i, dimWin, 1)
            set_source_rgb(ctx, 1, 1, 1)
            #set_source_rgb(ctx, 0, 0, 0)
            fill(ctx)

        end=#
        for i in 1:size(matrice)[1], j in 1:size(matrice)[2]
             if matrice[i,j]>0
                 rectangle(ctx, ((j*dimWin)/size(matrice)[2])-2+1, ((i*dimWin)/size(matrice)[1])-2+1, 2, 2)
                 #println("i : $i, j: $j")
                 set_source_rgba(ctx, 1, 0, 0, 1#=matrice[i,j]=#)
                 #set_source_rgb(ctx, 0, 0, 0)
                 fill(ctx)

             end
         end

    end
    sleep(1/30)
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
    from = left==1 ? 1 : 2
    to = right==size(matrixDtmp)[2] ? size(matrixDlocal)[2] : size(matrixDlocal)[2]-1
    #println("from $from, to $to")
    for h in 1:size(matrixDlocal)[1], j in from:to

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

    matrixDtmp[1:end, left:right] += matrixDtmplocal[1:end, 1:end]
    matrixDlocal = 0
    matrixDlocal = 0

end

function sciddicaT_step(matrixHS::SharedArray{Float64}, matrixD::SharedArray{Float64}, pr)
    #println("qui")
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
            right = ranges[i]==size(matrixD)[2] ? ranges[i] : ranges[i]+1

            matrixDlocal[1:end, 1:end] = matrixD[top:bot, left:right]
            matrixHSlocal[1:end, 1:end] = matrixHS[top:bot, left:right]

            sciddicaT_rule(matrixDlocal, matrixHSlocal, matrixDtmp, pr, left, right)

        end
    end


    matrixD[1:end, 1:end] = matrixDtmp[1:end, 1:end]
    matrixDtmp = 0
    #println(matrixD)
end

@everywhere function stampaMatrice(matrice)

    for i in 1:size(matrice)[1], j in 1:size(matrice)[2]


        if (j == size(matrice)[2])
            print("\n")
        end

    end
    print("\n")
end

function sciddicaT(matrixHS, matrixD, gen, canv, win)

    @async begin
        for u in 1:3000

            displays(matrixD, canv)
            #println(u)
            sciddicaT_step(matrixHS, matrixD, pr)
            #tmp = matrixD + matrixHS
            stampaMatrice(matrixD)
        end
    end
    showall(win)

end


h = 610*2
w = 496*2

win = GtkWindow("sciddicaT", h, w)
hbox = Box(:h)
set_gtk_property!(hbox, :homogeneous, true)
push!(win, hbox)
canv = Canvas()
push!(hbox, canv)

#dim = 5000
matrixHSread = readdlm("C:/Users/Daniele/Desktop/dem.txt")
matrixDread = readdlm("C:/Users/Daniele/Desktop/source.txt")
matrixHSread[1:end, 1:end] -= matrixDread[1:end, 1:end]

matrixHS = SharedArray{Float64}(size(matrixHSread)[1], size(matrixHSread)[2])
matrixD = SharedArray{Float64}(size(matrixHSread)[1], size(matrixHSread)[2])

matrixHS[1:end, 1:end] = matrixHSread[1:end, 1:end]
matrixD[1:end, 1:end] = matrixDread[1:end, 1:end]

matrixHSread=0
matrixDread=0

#=
matrixHS = SharedArray{Float64}(20,20)
matrixD = SharedArray{Float64}(20,20)
#println(ranges)
fill!(matrixHS, 0)
fill!(matrixD, 0)
matrixD[10,1]=50=#
ranges = assignRange(size(matrixD)[2])
#println(ranges)
pr = 1 #fattore rallentamento

sciddicaT(matrixHS, matrixD, 100, canv, win)

#=
t = @elapsed for u in 1:2000
    sciddicaT_step(matrixHS, matrixD, pr)
    tmp = matrixD + matrixHS
    #println(varinfo())
    println(u)
    #GC.gc()
end=#
matrixHS = 0
matrixD = 0
#println(t)
#println(varinfo())
