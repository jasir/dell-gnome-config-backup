import St from 'gi://St';
import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import Clutter from 'gi://Clutter';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import * as Fs from './fs.js';
import { ext } from '../extension.js';
import { FocusTracker } from './focus.js';
import { scroll_to_widget } from './scroll.js';

export function unreachable(_) {
    throw new Error('Unreachable.');
}

export function get_icon(str) {
    return Gio.Icon.new_for_string(ext.path + '/data/icons/' + str + '.svg');
}

export function get_transformed_allocation(actor) {
    const extents = actor.get_transformed_extents();
    const top_left = extents.get_top_left();
    const bottom_right = extents.get_bottom_right();
    return { x1: top_left.x, y1: top_left.y, x2: bottom_right.x, y2: bottom_right.y };
}

export function get_monitor_work_area(for_actor) {
    const monitor = Main.layoutManager.findIndexForActor(for_actor);
    return Main.layoutManager.getWorkAreaForMonitor(monitor);
}

// Returns the bounding box of the line that contains the idx.
//
// The box coordinates are relative to the same thing that the
// allocation box of the containing Clutter.Text are.
//
// The box extends horizontally to the edges of the Clutter.Text.
export function get_line_box_at_idx(text, idx) {
    if (!text.is_mapped())
        return { x1: 0, x2: 0, y1: 0, y2: 0 };
    
    const a = text.get_allocation_box();
    const [, , y, line_height] = text.position_to_coords(idx);
    
    return {
        x1: a.x1,
        x2: a.x2,
        y1: a.y1 + y,
        y2: a.y1 + y + line_height,
    };
}

export function later_add(fn) {
    const laters = global.compositor.get_laters();
    laters.add(Meta.LaterType.BEFORE_REDRAW, fn);
}

export function run_before_redraw(fn) {
    later_add(() => { fn(); return false; });
}

export function run_when_mapped(actor, fn, once = true) {
    let id1 = 0;
    let id2 = 0;
    let destroyed = false;
    
    const run = () => {
        if (destroyed || !actor.is_mapped())
            return;
        if (once) {
            actor.disconnect(id1);
            actor.disconnect(id2);
        }
        fn();
    };
    
    id1 = actor.connect('destroy', () => destroyed = true);
    id2 = actor.connect('notify::mapped', run);
    
    if (actor.is_mapped())
        run();
}

export function focus_when_mapped(actor) {
    run_when_mapped(actor, () => actor.grab_key_focus());
}

// TODO(GNOME_BUG): The functions adjust_width and adjust_height
// are used to fix layout issues in the Clutter toolkit. No idea
// how/why/when they work; they're discovered by trial and error.
//
// In particular, they are applied to Clutter.GridLayout and
// popups so that St.Label's render properly inside tables
// and so that tables don't get clipped off.
//
// These are also used to implement the multiline entry widget.
//
// Also, sometimes this will not work if the container of the
// actor on which these functions are applied has a 'min-width'
// css property.
export function adjust_width(widget, child = widget) {
    let destroyed = false;
    widget.connect('destroy', () => destroyed = true);
    
    run_before_redraw(() => {
        if (destroyed || !widget.is_mapped())
            return;
        
        const theme_node = widget.get_theme_node();
        const a = widget.get_allocation_box();
        let [, nat_width] = child.get_preferred_width(-1);
        nat_width = nat_width + theme_node.get_horizontal_padding();
        const width = theme_node.adjust_for_width(a.x2 - a.x1);
        
        if (width < nat_width)
            widget.width = nat_width;
    });
}

export function adjust_height(widget, child = widget) {
    let destroyed = false;
    widget.connect('destroy', () => destroyed = true);
    
    run_before_redraw(() => {
        if (destroyed || !widget.is_mapped())
            return;
        
        const theme_node = widget.get_theme_node();
        const a = widget.get_allocation_box();
        let [, nat_height] = child.get_preferred_height(a.x2 - a.x1);
        nat_height = nat_height + theme_node.get_vertical_padding();
        const height = theme_node.adjust_for_height(a.y2 - a.y1);
        
        if (height < nat_height)
            widget.height = nat_height;
    });
}

export function get_cell_box(widget) {
    const layout = new Clutter.GridLayout();
    const table = new St.Widget({ x_expand: true, layout_manager: layout });
    const cell = new St.BoxLayout({ x_expand: true, vertical: true });
    layout.attach(cell, 0, 0, 1, 1);
    cell.add_child(widget);
    return table;
}

export function play_sound(sound_file) {
    if (!sound_file)
        return null;
    const cancel = new Gio.Cancellable();
    const player = global.display.get_sound_player();
    const file = Fs.file_new_for_path(sound_file);
    player.play_from_file(file, '', cancel);
    return cancel;
}

export function light_or_dark(r, g, b) {
    const hsp = Math.sqrt(0.299 * (r ** 2) + 0.587 * (g ** 2) + 0.114 * (b ** 2));
    return hsp > 127.5 ? 'light' : 'dark';
}

export function copy_to_clipboard(text) {
    St.Clipboard.get_default().set_text(St.ClipboardType.CLIPBOARD, text);
}

export function array_swap(array, a, b) {
    const tmp = array[a];
    array[a] = array[b];
    array[b] = tmp;
}

export function array_remove_idx(array, element_idx) {
    if (element_idx !== -1)
        array.splice(element_idx, 1);
}

export function array_remove(array, element) {
    array_remove_idx(array, array.indexOf(element));
}

export function* iter_set(set) {
    let idx = 0;
    
    for (const element of set) {
        yield [element, idx];
        idx++;
    }
}

// A simple O(n) search algorithm. First we look ahead in @haystack to see if
// all chars in @needle appear in the exact order, then we loop back to
// see if there is a shorter version. If a single @needle letter is
// missing from the text, we return null.
//
//     a  b  c d e  abcdef
//     ----------------->|
//                  |<----
//
// This algorithm does not try to find the optimal match:
//
//     a b  c d  e ab c def    abcdef
//     ------------------>|
//                 |<------
//
// The score is computed based on how many consecutive letters in the text
// were found, whether letters appear at word beginnings, number of gaps, ...
export function fuzzy_search(needle, haystack) {
    const txt_len = haystack.length;
    const pat_len = needle.length;
    
    if (txt_len < pat_len)
        return null;
    
    let matches = 0;
    let patt_pos = 0;
    let start_pos = -1;
    let cursor = 0;
    
    for (; cursor < txt_len; cursor++) {
        if (haystack[cursor] === needle[patt_pos]) {
            if (start_pos < 0)
                start_pos = cursor;
            if (++matches === pat_len) {
                cursor++;
                break;
            }
            patt_pos++;
        }
    }
    
    if (matches !== pat_len)
        return null;
    
    let gaps = 0;
    let consecutives = 0;
    let word_beginnings = 0;
    let last_match_idx = 0;
    
    if (needle[0] === haystack[0])
        word_beginnings++;
    
    while (cursor-- > start_pos) {
        if (haystack[cursor] === needle[patt_pos]) {
            if ((cursor + 1) === last_match_idx)
                consecutives++;
            if ((cursor > 1) && /\W/.test(haystack[cursor - 1]))
                word_beginnings++;
            last_match_idx = cursor;
            patt_pos--;
        }
        else {
            gaps++;
        }
    }
    
    return (consecutives * 4) + (word_beginnings * 3) - gaps - start_pos;
}

export class Row {
    actor;
    label;
    widget;
    
    constructor(title, widget, parent) {
        this.actor = new St.BoxLayout({ style_class: 'cronomix-row' });
        parent?.add_child(this.actor);
        
        this.label = new St.Label({ y_align: Clutter.ActorAlign.CENTER });
        this.actor.add_child(this.label);
        
        this.widget = widget;
        this.actor.add_child(widget);
        
        if (title !== null) {
            this.label.text = title;
            this.widget.style ??= '';
            this.widget.x_expand = true;
            this.widget.style += 'margin-left: 20px;';
            this.widget.x_align = Clutter.ActorAlign.END;
        }
        else {
            this.label.hide();
        }
    }
}

export class Card {
    actor;
    header;
    left_header_box;
    autohide_box;
    
    constructor() {
        this.actor = new St.BoxLayout({ reactive: true, vertical: true, x_expand: true, style_class: 'cronomix-card cronomix-box' });
        
        this.header = new St.BoxLayout({ style_class: 'header' });
        this.actor.add_child(this.header);
        
        this.left_header_box = new St.BoxLayout({ y_align: Clutter.ActorAlign.CENTER, reactive: true, x_expand: true });
        this.header.add_child(this.left_header_box);
        
        this.autohide_box = new St.BoxLayout({ opacity: 0 });
        this.header.add_child(this.autohide_box);
        
        const focus_tracker = new FocusTracker(this.actor);
        focus_tracker.subscribe('focus_enter', () => { scroll_to_widget(this.actor); this.autohide_box.opacity = 255; });
        focus_tracker.subscribe('focus_leave', (has_pointer) => this.autohide_box.opacity = has_pointer ? 255 : 0);
        focus_tracker.subscribe('pointer_enter', () => this.autohide_box.opacity = 255);
        focus_tracker.subscribe('pointer_leave', (has_focus) => this.autohide_box.opacity = has_focus ? 255 : 0);
    }
}

// TODO(GNOME_BUG): Wrap content in this grid cell to work
// around a bug wherein a certain amount of padding appears
// at the bottom. The bug seems related to the layout of text.
export class CellBox {
    table;
    cell;
    
    constructor(parent, child) {
        const layout = new Clutter.GridLayout();
        this.table = new St.Widget({ x_expand: true, layout_manager: layout });
        this.cell = new St.BoxLayout({ x_expand: true, vertical: true });
        
        layout.attach(this.cell, 0, 0, 1, 1);
        
        if (parent)
            parent.add_child(this.table);
        if (child)
            this.cell.add_child(child);
    }
}
