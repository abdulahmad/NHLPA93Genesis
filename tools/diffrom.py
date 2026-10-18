#!/usr/bin/env python3
"""diffrom.py: where two builds of the ROM really differ, when code and data have moved.

  python3 tools/diffrom.py built.bin reference.bin [built.sym] [--all]

A plain byte compare is useless once something is a few bytes longer: everything after it is shifted. This aligns the
two files on runs of identical bytes (16 or more) and lists the gaps between the runs. A gap that is the same size in
both is usually just an address or branch that moved with the shift; a gap whose size differs is a real edit (or a
changed asset). Gaps are named after the nearest label of built.sym (the SNASM symbol file next to the build) so they can
be found in the source. By default only the gaps that differ in size, or that are larger than 200 bytes, are listed.
"""
import struct, sys, bisect

W = 16

def segments(a, b):
    idx = {}
    for j in range(len(b) - W):
        idx.setdefault(b[j:j + W], []).append(j)
    segs, i, prev = [], 0, 0
    while i < len(a) - W:
        c = idx.get(a[i:i + W])
        if not c:
            i += 1
            continue
        j = min(c, key=lambda x: abs((x - i) - prev))
        k = 0
        while i + k < len(a) and j + k < len(b) and a[i + k] == b[j + k]:
            k += 1
        # a match far from where the last run ended is only believed when it is long (so a table of addresses that
        # happens to repeat elsewhere does not pull the alignment away)
        if abs((j - i) - prev) > 1024 and k < 64:
            i += 1
            continue
        if k >= W:
            segs.append([i, j, k])
            prev = j - i
        i += max(k, 1)
    merged = []
    for s in segs:
        if merged and merged[-1][1] - merged[-1][0] == s[1] - s[0] and s[0] <= merged[-1][0] + merged[-1][2]:
            merged[-1][2] = s[0] + s[2] - merged[-1][0]
        else:
            merged.append(s)
    return merged

def symbols(path):
    d = open(path, 'rb').read()
    pos, out = 8, []
    while pos + 6 < len(d):
        addr = struct.unpack_from('<I', d, pos)[0]
        kind, n = d[pos + 4], d[pos + 5]
        name = d[pos + 6:pos + 6 + n]
        if kind != 2 or not name.isascii():
            break
        out.append((addr, name.decode()))
        pos += 6 + n
    return sorted(out)

def main():
    args = [x for x in sys.argv[1:] if not x.startswith('--')]
    show_all = '--all' in sys.argv
    built, ref = open(args[0], 'rb').read(), open(args[1], 'rb').read()
    syms = symbols(args[2]) if len(args) > 2 else []
    keys = [s[0] for s in syms]
    def label(p):
        k = bisect.bisect_right(keys, p) - 1
        return '%s+%X' % (syms[k][1], p - keys[k]) if k >= 0 else '?'
    segs = segments(built, ref)
    covered = sum(s[2] for s in segs)
    print('%d runs, %d of %d built bytes found in the reference' % (len(segs), covered, len(built)))
    for x, y in zip(segs, segs[1:]):
        ga, gb = (x[0] + x[2], y[0]), (x[1] + x[2], y[1])
        sa, sb = ga[1] - ga[0], gb[1] - gb[0]
        if show_all or sa != sb or sa > 200:
            print('built %06X..%06X (%d)  ref %06X..%06X (%d)  %s' % (ga[0], ga[1], sa, gb[0], gb[1], sb, label(ga[0])))

if __name__ == '__main__':
    main()
