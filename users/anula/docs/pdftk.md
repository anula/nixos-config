# pdftk

Basic shape: `pdftk <in.pdf> <operation> <args> output <out.pdf>`

> **`cat` drops every page you don't list.**
> **`output` can't be the input file** — write to a new file, then `mv`.

## Page ranges

| Syntax         | Meaning                          |
|----------------|----------------------------------|
| `3`            | page 3                           |
| `3-7`          | pages 3 to 7                     |
| `1 4-6 10-end` | several ranges, in listed order  |
| `end`          | last page                        |
| `r1`, `r3-r1`  | last page, last 3 pages          |
| `7-3`          | pages 7 down to 3 (reversed)     |
| `1-endodd`     | odd pages (`even` for even ones) |

Page count: `pdftk in.pdf dump_data | grep NumberOfPages`

## Keep / remove pages

```bash
pdftk in.pdf cat 3-7 output out.pdf          # keep 3–7
pdftk in.pdf cat 1-4 6-end output out.pdf    # drop page 5
pdftk in.pdf cat end-1 output out.pdf        # reverse page order
```

## Rotate

Absolute: `north` (0°), `east` (90° cw), `south` (180°), `west` (90° ccw).
Relative to current orientation: `right`, `left`, `down`.

```bash
pdftk in.pdf rotate 2west 5-7west output out.pdf   # only these; rest untouched
pdftk in.pdf cat 1-endeast output out.pdf          # every page
pdftk in.pdf cat 3-7east output out.pdf            # keep 3–7 and rotate them
```

## Merge

```bash
pdftk a.pdf b.pdf cat output merged.pdf

# Pick pages from several files via handles
pdftk A=a.pdf B=b.pdf cat A1-3 B2 A4-end output merged.pdf
```

## Split

```bash
pdftk in.pdf burst                            # pg_0001.pdf, pg_0002.pdf, ...
pdftk in.pdf burst output page_%02d.pdf       # custom naming
```

## Interleave double-sided scans

Fronts scanned in order, backs scanned as a separate stack (so in reverse):

```bash
pdftk A=fronts.pdf B=backs.pdf shuffle A Bend-1 output combined.pdf
```

If the backs came out in normal order, use `shuffle A B`.

## Passwords

```bash
pdftk in.pdf input_pw SECRET output unlocked.pdf               # remove
pdftk in.pdf output locked.pdf user_pw SECRET                  # require to open
pdftk in.pdf output locked.pdf owner_pw SECRET allow printing  # restrict editing
```
