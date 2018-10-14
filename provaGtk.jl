using Gtk, Gtk.ShortNames, Graphics
using Distributed

win = Window("Test")
hbox = Box(:h)
set_gtk_property!(hbox, :homogeneous, true)
push!(win, hbox)
canv = Canvas()
push!(hbox, canv)
@async begin

    while true
      #println("qui")
      @guarded draw(canv) do widget
        ctx = getgc(canv)
        w, h = width(canv), height(canv)

        offsetW = 32
        offsetH = 32
        @inbounds for x = 1:32
          @inbounds for y = 1:32
            set_source_rgb(ctx, rand(), rand(), rand())
            rectangle(ctx, x*offsetW, y*offsetH, offsetW, offsetH)
            fill(ctx)
          end
        end
      end
      sleep(1/10)
    end
end
showall(win)

cond = Condition()
signal_connect(win, :destroy) do widget
  notify(cond)
end
wait(cond)
