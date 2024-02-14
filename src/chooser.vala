/**
 * Copyright (c) 2021-2022 Lains
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Co-Authored by: Arvianto Dwi Wicaksono <arvianto.dwi@gmail.com>
 */

public class Colorway.Chooser : Gtk.DrawingArea {
    //  Properties
    private const uint16 WIDTH = 140;
    private const uint16 HEIGHT = 140;
    private static double r;
    private static double g;
    private static double b;
    public static double xpos = 140;
    public static double ypos = 0;
    public static unowned Chooser instance;
    private static Cairo.Surface surface;
    private static Gtk.GestureClick gesture;
    private static Gtk.GestureDrag drag;
    public Gdk.RGBA active_color;
    public double h;
    public double s;
    public double v;

    //  Signals
    public signal void on_sv_move (double s, double v);

    public Chooser (Gdk.RGBA active_color) {
        double h, s, v;
        r = active_color.red;
        g = active_color.green;
        b = active_color.blue;
        this.active_color = active_color;
        this.add_css_class ("clr-da");

        Gtk.rgb_to_hsv ((float)r, (float)g, (float)b, out h, out s, out v);
        this.h = h;
        this.s = s;
        this.v = v;
        
        sv_to_xy (s, v, out xpos, out ypos);
        create_surface ();
    }

    construct {
        instance = this;
        instance.set_size_request (WIDTH, HEIGHT);

        gesture = new Gtk.GestureClick ();
        this.add_controller (gesture);
        GLib.Signal.connect (gesture, "released", (GLib.Callback) gesture_press_release, null);

        drag = new Gtk.GestureDrag ();
        GLib.Signal.connect (drag, "drag-begin", (GLib.Callback) gesture_drag_begin, null);
        GLib.Signal.connect (drag, "drag-update", (GLib.Callback) gesture_drag_update, null);
        GLib.Signal.connect (drag, "drag-end", (GLib.Callback) gesture_drag_end, null);
        this.add_controller (drag);

        surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, WIDTH, HEIGHT);
        
        this.set_draw_func (draw_func);
    }

    public void draw_func (Gtk.DrawingArea da, Cairo.Context context, int width, int height) {
        double xc = 7;
        double yc = 7;
        double stroke_width = 5;
        double radius = xc - stroke_width / 2;
        double angle1 = 0;
        double angle2 = 2 * GLib.Math.PI;
        
        context.set_source_surface (surface, 0, 0);
        context.paint ();
        context.translate (xpos - 7, ypos - 7);
        context.arc (xc, yc, radius, angle1, angle2);
        context.set_line_width (stroke_width);
        context.set_source_rgb (1, 1, 1);
        context.stroke_preserve ();
        context.set_line_width (2);
        context.set_source_rgb (0, 0, 0);
        context.stroke ();
        
        da.queue_draw ();
    }

    public void update_surface_color (double r_arg, double g_arg, double b_arg) {
        r = r_arg;
        g = g_arg;
        b = b_arg;
        create_surface ();
        this.queue_draw ();
    }

    public void pos_to_sv (out double s, out double v) {
        xy_to_sv (xpos, ypos, out s, out v);
    }
    
    public void sv_to_pos (float s, float v) {
        sv_to_xy (s, v, out xpos, out ypos);
        
        double new_s, new_v;
        xy_to_sv (xpos, ypos, out new_s, out new_v);
        instance.on_sv_move (new_s, new_v);
        instance.queue_draw ();
    }

    private static void xy_to_sv (double x, double y, out double s, out double v) {
        s = x / WIDTH;
        v = 1 - (y / HEIGHT);
    }

    public void sv_to_xy (double s, double v, out double x, out double y) {
        x = s * WIDTH;
        y = HEIGHT - (v * HEIGHT);
    }

    private static void create_surface () {
        double x             = 0,
               y             = 0,
               width         = WIDTH,
               height        = HEIGHT,
               aspect        = 1.0,
               corner_radius = 0.0,
               radius        = corner_radius / aspect,
               degrees       = Math.PI / 180.0;

        Cairo.Context context = new Cairo.Context (surface);
        context.arc (x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
        context.arc (x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
        context.arc (x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
        context.arc (x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
        context.set_source_rgb (r, g, b);
        context.fill_preserve ();

        Cairo.Pattern p1 = new Cairo.Pattern.linear (0, 0, WIDTH, 0);
        p1.add_color_stop_rgba (0, 1, 1, 1, 1);
        p1.add_color_stop_rgba (1, 1, 1, 1, 0);
        context.arc (x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
        context.arc (x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
        context.arc (x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
        context.arc (x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
        context.set_source (p1);
        context.fill_preserve ();

        Cairo.Pattern p2 = new Cairo.Pattern.linear (0, 0, 0, HEIGHT);
        p2.add_color_stop_rgba (0, 0, 0, 0, 0);
        p2.add_color_stop_rgba (1, 0, 0, 0, 1);
        context.arc (x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
        context.arc (x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
        context.arc (x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
        context.arc (x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
        context.set_source (p2);
        context.fill_preserve ();
    }

    private static void gesture_press_release (double offset_x, double offset_y) {
        double _xpos, _ypos;
        gesture.get_point (null, out _xpos, out _ypos);

        move_inbound(_xpos, _ypos, out xpos, out ypos);

        double new_s, new_v;
        xy_to_sv (xpos, ypos, out new_s, out new_v);
        instance.on_sv_move (new_s, new_v);
        instance.queue_draw ();
    }

    private static void gesture_drag_begin (double start_x, double start_y) {
        xpos = start_x;
        ypos = start_y;

        drag.set_state (Gtk.EventSequenceState.CLAIMED);

        double new_s, new_v;
        xy_to_sv (xpos, ypos, out new_s, out new_v);
        instance.on_sv_move (new_s, new_v);
        instance.queue_draw ();
    }

    private static void gesture_drag_update (double offset_x, double offset_y) {
        double _xpos, _ypos;
        drag.get_start_point (out _xpos, out _ypos);

        move_inbound(_xpos + offset_x, _ypos + offset_y, out xpos, out ypos);

        double new_s, new_v;
        xy_to_sv (xpos, ypos, out new_s, out new_v);
        instance.on_sv_move (new_s, new_v);
        instance.queue_draw ();
    }

    private static void gesture_drag_end (double offset_x, double offset_y) {
        drag.set_state (Gtk.EventSequenceState.DENIED);
    }

    private static void move_inbound(double xpos, double ypos, out double new_x, out double new_y) {
        if (xpos > WIDTH) {
            new_x = WIDTH;
        } else if (xpos < 0) {
            new_x = 0;
        } else {
            new_x = xpos;
        }

        if (ypos > HEIGHT) {
            new_y = HEIGHT;
        } else if (ypos < 0) {
            new_y = 0;
        } else {
            new_y = ypos;
        }
    }
}
