


using Gtk, Graphics
dimWin = 540
change = true
c = @GtkCanvas(dimWin, dimWin)
#win = GtkWindow("My First Gtk.jl Program", 400, 200)
win = GtkWindow(c, "Canvas")
@guarded draw(c) do widget
    ctx = getgc(c)
    h = height(c)
    w = width(c)
    rectangle(ctx, 0, 0, w, h)
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

    if (change)
        rectangle(ctx, 1, 1, 29, 29)
        set_source_rgb(ctx, 0, 0, 0)
        fill(ctx)

        rectangle(ctx, 1, 31, 29, 29)
        set_source_rgb(ctx, 1, 1, 1)
        fill(ctx)

    #rectangle(ctx, )
    #g.fillRect(tmp.getPoint().x*32, tmp.getPoint().y*32, 32, 32);
    else
        rectangle(ctx, 1, 31, 29, 29)
        set_source_rgb(ctx, 0, 0, 0)
        fill(ctx)

        rectangle(ctx, 1, 1, 29, 29)
        set_source_rgb(ctx, 1, 1, 1)
        fill(ctx)
    end
end

show(c)
