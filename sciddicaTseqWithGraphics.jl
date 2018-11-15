using Gtk, Gtk.ShortNames, Graphics
using Distributed
using DelimitedFiles

#addprocs(2)

function displays(matrice::Matrix{Float64}, canv)
    #println("qui1")
    #dimWin = size(matrice)[2]*2

    @guarded draw(canv) do widget
        #println("qui2")
        ctx = getgc(canv)
        w, h = width(canv), height(canv)
        #println("qui3")
        offsetW = w
        offsetH = h
        rectangle(ctx, 0, 0, w, h)
        set_source_rgb(ctx, 0, 0, 0)
        #set_source_rgb(ctx, rand(1)[1], rand(1)[1], rand(1)[1])
        #set_source_rgb(ctx, 1, 1, 1)
        fill(ctx)
        #=for i in 0:2:dimWin

            rectangle(ctx, i, 0, 1, dimWin)
            set_source_rgb(ctx, 0, 0, 0)
            #set_source_rgb(ctx, 0, 0, 0)
            fill(ctx)

            rectangle(ctx, 0, i, dimWin, 1)
            set_source_rgb(ctx, 0, 0, 0)
            #set_source_rgb(ctx, 0, 0, 0)
            fill(ctx)

        end=#
        for i in 1:size(matrice)[1], j in 1:size(matrice)[2]

                 rectangle(ctx, ((j*w)/size(matrice)[2]), ((i*h)/size(matrice)[1]), 2, 2)
                 #println("i : $i, j: $j")
                 if (matrice[i,j]>0)
                     set_source_rgb(ctx, 1, 0, 0)
                 else
                      set_source_rgb(ctx, 0, 0, 0)
                  end
                 #=tmp=matrice[i,j]/10
                 =##println("$i, $j, $(matrice[i,j])")
                 #set_source_rgb(ctx, 0, 0, 0)
                 fill(ctx)

         end

    end
    sleep(1/60)
end

function neighbors(matrix::Array{Float64}, i, j)

    array = Tuple{Int64,Int64}[]
    if (i+1 <= size(matrix)[1]) push!(array, (i+1,j)) end
    if (i-1 > 0) push!(array, (i-1,j)) end
    if (j+1 <= size(matrix)[2]) push!(array, (i,j+1)) end
    if (j-1 > 0) push!(array, (i,j-1)) end

    return array

end

function sciddicaT_step(matrixHS::Array{Float64}, matrixD::Array{Float64}, pr)

    matrixDtmp = similar(matrixD)
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

function sciddicaT(matrixHS, matrixD, gen, canv, win)

    @async begin
        for u in 1:300
            displays(matrixD, canv)
            sciddicaT_step(matrixHS, matrixD, pr)
            #tmp = matrixD + matrixHS
            #println(u)


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

matrixHS = readdlm("C:/Users/Daniele/Desktop/dem.txt")
matrixD = readdlm("C:/Users/Daniele/Desktop/source.txt")
matrixHS[1:end, 1:end] -= matrixD[1:end, 1:end]

#matrixHS = Array{Float64}(undef, dim, dim)
#matrixD = Array{Float64}(undef, dim, dim)
#matrixHS[1:end, 1:end] -= matrixD[1:end, 1:end]
#=
fill!(matrixHS, 1)
fill!(matrixD, 0)
matrixD[10,10]=100
#println(matrixHS)=#
pr = 1 #fattore rallentamento

sciddicaT(matrixHS, matrixD, 100, canv, win)

#println(t)
