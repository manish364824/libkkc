/*
 * Copyright (C) 2012-2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2012-2013 Red Hat, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gee;

namespace Kkc {
    public class SegmentList : Object {
        Gee.List<Segment> segments = new ArrayList<Segment> ();

        int _cursor_pos = -1;
        public int cursor_pos {
            get {
                return _cursor_pos;
            }
            set {
                _cursor_pos = value.clamp (0, size - 1);
            }
        }

        public int size {
            get {
                return segments.size;
            }
        }

        public void clear () {
            segments.clear ();
            cursor_pos = -1;
        }

        public new Segment @get (int index) {
            return segments.get (index);
        }

        public void set_segments (Segment segment) {
            segments.clear ();
            while (segment != null) {
                segments.add (segment);
                segment = segment.next;
            }
            cursor_pos = 0;
        }

        public void next_segment () {
            if (cursor_pos == -1)
                return;
            _cursor_pos += 1;
            _cursor_pos = _cursor_pos.clamp (0, size - 1);
        }

        public void previous_segment () {
            if (cursor_pos == -1)
                return;
            _cursor_pos += -1;
            _cursor_pos = _cursor_pos.clamp (0, size - 1);
        }

        public string to_string () {
            var builder = new StringBuilder ();
            foreach (var segment in segments) {
                builder.append (segment.output);
            }
            return builder.str;
        }

        public string get_input () {
            var builder = new StringBuilder ();
            foreach (var segment in segments) {
                builder.append (segment.input);
            }
            return builder.str;
        }
    }
}
