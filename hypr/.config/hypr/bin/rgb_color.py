#!/usr/bin/env python3
import gi
import sys
import re

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gdk, GLib

class ColorConverterWindow(Adw.ApplicationWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.set_title("Color Converter")
        self.set_default_size(650, 550)
        self.set_decorated(False)
        
        self.color_history = []
        self.history_index = -1
        self.active_popover = None
        self.input_format = "hex"  # Track what format user is inputting

        # Exit with Escape key
        esc_binding = Gtk.EventControllerKey()
        esc_binding.connect("key-pressed", self.on_escape_pressed)
        self.add_controller(esc_binding)
        
        # Main box
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.set_content(main_box)
        
        # Custom header bar
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        header_box.set_margin_top(6)
        header_box.set_margin_bottom(6)
        header_box.set_margin_start(6)
        header_box.set_margin_end(6)
        main_box.append(header_box)
         
        # Spacer
        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        header_box.append(spacer) 
         
        # Scrolled window for content
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        main_box.append(scrolled)
        
        # Content box with margin
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        content_box.set_margin_top(12)
        content_box.set_margin_bottom(12)
        content_box.set_margin_start(12)
        content_box.set_margin_end(12)
        scrolled.set_child(content_box)
        
        # Input section
        input_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        content_box.append(input_box)
        
        # Back button
        self.back_button = Gtk.Button()
        self.back_button.set_icon_name("go-previous-symbolic")
        self.back_button.connect("clicked", self.on_back_clicked)
        self.back_button.set_sensitive(False)
        input_box.append(self.back_button)
        
        # Forward button
        self.forward_button = Gtk.Button()
        self.forward_button.set_icon_name("go-next-symbolic")
        self.forward_button.connect("clicked", self.on_forward_clicked)
        self.forward_button.set_sensitive(False)
        input_box.append(self.forward_button)
         
        self.color_entry = Gtk.Entry()
        self.color_entry.set_placeholder_text("#000000 or rgb(0,0,0)")
        self.color_entry.set_hexpand(True)
        self.color_entry.connect("changed", self.on_color_changed)
        input_box.append(self.color_entry)
        
        # Color preview with click gesture
        self.color_preview = Gtk.DrawingArea()
        self.color_preview.set_content_height(80)
        self.color_preview.set_draw_func(self.draw_color_preview)
        content_box.append(self.color_preview)
        
        # Add click gesture to preview
        preview_gesture = Gtk.GestureClick()
        preview_gesture.connect("pressed", self.on_preview_clicked)
        self.color_preview.add_controller(preview_gesture)
        
        # Shades section
        shades_label = Gtk.Label()
        shades_label.set_markup("<b>Shades</b>")
        shades_label.set_xalign(0)
        shades_label.set_margin_top(8)
        content_box.append(shades_label)
        
        self.shades_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        self.shades_box.set_homogeneous(True)
        content_box.append(self.shades_box)
        
        # Tints section
        tints_label = Gtk.Label()
        tints_label.set_markup("<b>Tints</b>")
        tints_label.set_xalign(0)
        tints_label.set_margin_top(8)
        content_box.append(tints_label)
        
        self.tints_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        self.tints_box.set_homogeneous(True)
        content_box.append(self.tints_box)
        
        # Create shade and tint tiles (10 each)
        self.shade_data = []
        self.tint_data = []
        
        for i in range(10):
            shade_tile = self.create_color_tile()
            self.shades_box.append(shade_tile)
            self.shade_data.append(shade_tile)
            
            tint_tile = self.create_color_tile()
            self.tints_box.append(tint_tile)
            self.tint_data.append(tint_tile)
    
    def create_color_tile(self):
        overlay = Gtk.Overlay()
        
        # Main container
        container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        overlay.set_child(container)
        
        # Drawing area for color
        area = Gtk.DrawingArea()
        area.set_content_height(50)
        area.set_vexpand(True)
        container.append(area)
        
        # Hex label
        hex_label = Gtk.Label()
        hex_label.add_css_class("monospace")
        hex_label.add_css_class("caption")
        hex_label.set_ellipsize(3)  # PANGO_ELLIPSIZE_END
        container.append(hex_label)
        
        # Create gesture click
        gesture = Gtk.GestureClick()
        gesture.connect("pressed", self.on_tile_clicked, overlay)
        area.add_controller(gesture)
        
        # Store references
        overlay.area = area
        overlay.hex_label = hex_label
        overlay.rgba_value = None
        overlay.container = container
        
        return overlay
    
    def on_preview_clicked(self, gesture, n_press, x, y):
        if not hasattr(self, 'current_rgba') or self.current_rgba is None:
            return
        
        # Close any existing popover
        if self.active_popover:
            self.active_popover.popdown()
        
        # Create popover
        popover = Gtk.Popover()
        popover.set_parent(self.color_preview)
        
        # Button box
        button_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        button_box.set_margin_top(6)
        button_box.set_margin_bottom(6)
        button_box.set_margin_start(6)
        button_box.set_margin_end(6)
        popover.set_child(button_box)
        
        r, g, b, a = self.current_rgba
        
        # HEX button
        hex_val = self.rgba_to_hex(r, g, b, a)
        hex_btn = Gtk.Button(label=f"Copy HEX: {hex_val}")
        hex_btn.connect("clicked", lambda btn: self.copy_and_close(hex_val, popover))
        button_box.append(hex_btn)
        
        # RGB button
        rgb_val = f"rgb({r}, {g}, {b})"
        rgb_btn = Gtk.Button(label=f"Copy RGB: {rgb_val}")
        rgb_btn.connect("clicked", lambda btn: self.copy_and_close(rgb_val, popover))
        button_box.append(rgb_btn)
        
        # RGBA button
        rgba_val = f"rgba({r}, {g}, {b}, {a/255:.2f})"
        rgba_btn = Gtk.Button(label=f"Copy RGBA: {rgba_val}")
        rgba_btn.connect("clicked", lambda btn: self.copy_and_close(rgba_val, popover))
        button_box.append(rgba_btn)
        
        popover.popup()
        self.active_popover = popover
    
    def on_tile_clicked(self, gesture, n_press, x, y, overlay):
        # Close any existing popover
        if self.active_popover:
            self.active_popover.popdown()
        
        rgba_value = overlay.rgba_value
        if not rgba_value:
            return
        
        r, g, b, a = rgba_value
        
        # Create popover
        popover = Gtk.Popover()
        popover.set_parent(overlay)
        
        # Button box
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        button_box.set_margin_top(6)
        button_box.set_margin_bottom(6)
        button_box.set_margin_start(6)
        button_box.set_margin_end(6)
        popover.set_child(button_box)
        
        # View button
        view_btn = Gtk.Button(label="View")
        view_btn.add_css_class("suggested-action")
        hex_val = self.rgba_to_hex(r, g, b, a)
        view_btn.connect("clicked", lambda b: self.on_view_color(hex_val, popover))
        button_box.append(view_btn)
        
        # Copy button
        copy_btn = Gtk.Button(label="Copy")
        copy_btn.connect("clicked", lambda b: self.copy_and_close(hex_val, popover))
        button_box.append(copy_btn)
        
        popover.popup()
        self.active_popover = popover

    def on_escape_pressed(self, controller, keyval, keycode, state):
        if keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False
    
    def copy_and_close(self, text, popover):
        clipboard = Gdk.Display.get_default().get_clipboard()
        clipboard.set(text)
        popover.popdown()
        self.active_popover = None
    
    def parse_color(self, color_str):
        """Parse color string and return (r, g, b, a) tuple and format"""
        color_str = color_str.strip()
        
        # Try HEX format
        hex_match = re.match(r'^#?([0-9a-fA-F]{3,8})$', color_str)
        if hex_match:
            hex_color = hex_match.group(1)
            if len(hex_color) == 3:
                hex_color = ''.join([c*2 for c in hex_color])
                a = 255
            elif len(hex_color) == 4:
                hex_color = ''.join([c*2 for c in hex_color])
                a = int(hex_color[6:8], 16)
                hex_color = hex_color[:6]
            elif len(hex_color) == 6:
                a = 255
            elif len(hex_color) == 8:
                a = int(hex_color[6:8], 16)
                hex_color = hex_color[:6]
            else:
                return None, None
            
            try:
                r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
                return (r, g, b, a), "hex"
            except ValueError:
                return None, None
        
        # Try RGB format
        rgb_match = re.match(r'^rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$', color_str, re.IGNORECASE)
        if rgb_match:
            r, g, b = map(int, rgb_match.groups())
            if all(0 <= v <= 255 for v in [r, g, b]):
                return (r, g, b, 255), "rgb"
            return None, None
        
        # Try RGBA format
        rgba_match = re.match(r'^rgba\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*\)$', color_str, re.IGNORECASE)
        if rgba_match:
            r, g, b = map(int, rgba_match.groups()[:3])
            alpha_float = float(rgba_match.group(4))
            if all(0 <= v <= 255 for v in [r, g, b]) and 0 <= alpha_float <= 1:
                a = int(alpha_float * 255)
                return (r, g, b, a), "rgba"
            return None, None
        
        return None, None
    
    def rgba_to_hex(self, r, g, b, a=255):
        if a == 255:
            return f"#{r:02x}{g:02x}{b:02x}"
        else:
            return f"#{r:02x}{g:02x}{b:02x}{a:02x}"
    
    def generate_shade(self, r, g, b, factor):
        return (int(r * factor), int(g * factor), int(b * factor))
    
    def generate_tint(self, r, g, b, factor):
        return (
            int(r + (255 - r) * factor),
            int(g + (255 - g) * factor),
            int(b + (255 - b) * factor)
        )
    
    def draw_color_preview(self, area, cr, width, height):
        if not hasattr(self, 'current_rgba') or self.current_rgba is None:
            return
        
        r, g, b, a = self.current_rgba
        
        # Draw checkerboard pattern for transparency
        if a < 255:
            square_size = 10
            for y in range(0, height, square_size):
                for x in range(0, width, square_size):
                    if (x // square_size + y // square_size) % 2 == 0:
                        cr.set_source_rgb(0.8, 0.8, 0.8)
                    else:
                        cr.set_source_rgb(0.6, 0.6, 0.6)
                    cr.rectangle(x, y, square_size, square_size)
                    cr.fill()
        
        cr.set_source_rgba(r/255.0, g/255.0, b/255.0, a/255.0)
        cr.rectangle(0, 0, width, height)
        cr.fill()
    
    def draw_tile_color(self, area, cr, width, height, rgba):
        r, g, b, a = rgba
        
        # Draw checkerboard pattern for transparency
        if a < 255:
            square_size = 5
            for y in range(0, height, square_size):
                for x in range(0, width, square_size):
                    if (x // square_size + y // square_size) % 2 == 0:
                        cr.set_source_rgb(0.8, 0.8, 0.8)
                    else:
                        cr.set_source_rgb(0.6, 0.6, 0.6)
                    cr.rectangle(x, y, square_size, square_size)
                    cr.fill()
        
        cr.set_source_rgba(r/255.0, g/255.0, b/255.0, a/255.0)
        cr.rectangle(0, 0, width, height)
        cr.fill()
    
    def add_to_history(self, color_str):
        # Remove any forward history
        self.color_history = self.color_history[:self.history_index + 1]
        
        # Add new color
        if not self.color_history or self.color_history[-1] != color_str:
            self.color_history.append(color_str)
            self.history_index = len(self.color_history) - 1
        
        self.update_navigation_buttons()
    
    def update_navigation_buttons(self):
        self.back_button.set_sensitive(self.history_index > 0)
        self.forward_button.set_sensitive(self.history_index < len(self.color_history) - 1)
    
    def on_back_clicked(self, button):
        if self.history_index > 0:
            self.history_index -= 1
            color_str = self.color_history[self.history_index]
            self.color_entry.set_text(color_str)
            self.update_navigation_buttons()
    
    def on_forward_clicked(self, button):
        if self.history_index < len(self.color_history) - 1:
            self.history_index += 1
            color_str = self.color_history[self.history_index]
            self.color_entry.set_text(color_str)
            self.update_navigation_buttons()
    
    def on_color_changed(self, entry):
        color_str = entry.get_text().strip()
        rgba, fmt = self.parse_color(color_str)
        
        if rgba is None:
            self.current_rgba = None
            self.color_preview.queue_draw()
            return
        
        self.current_rgba = rgba
        self.input_format = fmt
        r, g, b, a = rgba
        
        # Add to history
        self.add_to_history(color_str)
        
        # Update preview
        self.color_preview.queue_draw()
        
        # Update shades (10 variations, from 90% to 0%)
        for i, overlay in enumerate(self.shade_data):
            factor = 0.9 - (i * 0.1)
            shade_rgb = self.generate_shade(r, g, b, factor)
            hex_val = self.rgba_to_hex(*shade_rgb, a)
            
            overlay.rgba_value = shade_rgb + (a,)
            overlay.hex_label.set_text(hex_val)
            overlay.area.set_draw_func(lambda ar, cr, w, h, rgb=shade_rgb+(a,): 
                                        self.draw_tile_color(ar, cr, w, h, rgb))
            overlay.area.queue_draw()
        
        # Update tints (10 variations, from 10% to 100%)
        for i, overlay in enumerate(self.tint_data):
            factor = 0.1 + (i * 0.1)
            tint_rgb = self.generate_tint(r, g, b, factor)
            hex_val = self.rgba_to_hex(*tint_rgb, a)
            
            overlay.rgba_value = tint_rgb + (a,)
            overlay.hex_label.set_text(hex_val)
            overlay.area.set_draw_func(lambda ar, cr, w, h, rgb=tint_rgb+(a,): 
                                        self.draw_tile_color(ar, cr, w, h, rgb))
            overlay.area.queue_draw()
    
    def on_view_color(self, hex_color, popover):
        self.color_entry.set_text(hex_color)
        popover.popdown()
        self.active_popover = None

class ColorConverterApp(Adw.Application):
    def __init__(self, initial_color=None):
        super().__init__(application_id="com.example.ColorConverter")
        self.initial_color = initial_color
    
    def do_activate(self):
        win = ColorConverterWindow(application=self)
        if self.initial_color:
            win.color_entry.set_text(self.initial_color)
        win.present()

if __name__ == "__main__":
    # Check if color is piped in
    initial_color = None
    if not sys.stdin.isatty():
        piped_input = sys.stdin.read().strip()
        if piped_input:
            initial_color = piped_input
    elif len(sys.argv) > 1:
        initial_color = sys.argv[1]
    
    app = ColorConverterApp(initial_color=initial_color)
    app.run(None)
