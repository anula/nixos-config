# Viseca statement for taxes

`viseca-tax-redact` blacks out transaction descriptions in the **Details**
column (the text is removed, not just covered). A transaction is a line with a
date to its left, plus the lines directly below it. Bold lines ("Card carried
forward" etc.), the footer, and the date and amount columns are untouched.
Each redacted line is one full-width bar, so word lengths don't leak. Source: `users/anula/scripts/viseca_tax_redact.py`.

## Steps

```bash
# 1. Optional: keep only the pages you need
pdftk statement.pdf cat 2-3 output pages.pdf

# 2. Dry run: prints the transaction lines, ████ = will be redacted
viseca-tax-redact pages.pdf

# 3. Write the redacted copy (must be a different file than the input)
viseca-tax-redact pages.pdf redacted.pdf
```

Step 3 re-reads the output and confirms the redacted words are gone and the
kept ones are intact. Still open it and eyeball it before sending.

## If something looks off

- **Column not found**: Viseca renamed the header. Change `HEADER` in the script.
- **A bold line got redacted**: the PDF doesn't mark it as bold; check the
  `BOLD_FONT` pattern against the font name.
- **Footer redacted / second line of a description not redacted**: the gap
  rule in `transaction_lines` (half a line height) needs tuning.
- **A whole transaction not redacted**: its date isn't `dd.mm.yy(yy)`; fix `DATE`.
- **End of a long description still visible**: it started past the column's
  right edge.

Keep statements out of `~/.nixos-config` (jj records every file there).
