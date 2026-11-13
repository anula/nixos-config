"""Redact transaction details from a Viseca statement before sending it
along with the tax return.

usage: viseca-tax-redact in.pdf             # dry run: show what would go
       viseca-tax-redact in.pdf out.pdf     # write the redacted copy

Only transactions are touched: lines of the "Details" column that have a date
to their left, plus the lines directly below them (wrapped descriptions).
Their text is blacked out (removed, not just covered), except bold text such
as "Card carried forward" -- dates and amounts inside the column go too.
Everything else, including the date and amount columns and the page footer,
is left alone. Each redacted line becomes one black bar across the full
column width, so word lengths don't show.
"""
import argparse
import re
import sys
from pathlib import Path
from typing import NamedTuple

import pymupdf

HEADER = "Details"
DATE = re.compile(r"^\d{1,2}\.\d{1,2}\.(\d{2}|\d{4})$")
BOLD_FONT = re.compile(r"bold|black|heavy|semibold|demi", re.IGNORECASE)
BOLD_FLAG = 16
LINE_TOLERANCE = 3.0  # points; header words this close vertically share a line
COLUMN_MARGIN = 2.0


class Word(NamedTuple):
    """One entry of `page.get_text("words")`."""

    x0: float
    y0: float
    x1: float
    y1: float
    text: str
    block: int
    line: int
    word_no: int

    @property
    def rect(self) -> pymupdf.Rect:
        return pymupdf.Rect(self.x0, self.y0, self.x1, self.y1)

    @property
    def centre(self) -> pymupdf.Point:
        return pymupdf.Point((self.x0 + self.x1) / 2, (self.y0 + self.y1) / 2)


class Column(NamedTuple):
    x_left: float
    x_right: float
    y_top: float

    def contains(self, word: Word) -> bool:
        return word.y0 >= self.y_top and self.x_left <= word.x0 < self.x_right


class PagePlan(NamedTuple):
    redact: list[Word]
    keep: list[Word]
    boxes: list[pymupdf.Rect]


def page_words(page: pymupdf.Page) -> list[Word]:
    return [Word(*w) for w in page.get_text("words")]


def find_column(words: list[Word]) -> Column | None:
    """Locate the column under HEADER, bounded by the next header to its right."""
    headers = [w for w in words if w.text == HEADER]
    for header in headers:
        to_the_right = [
            w.x0 for w in words
            if abs(w.y0 - header.y0) < LINE_TOLERANCE and w.x0 > header.x1
        ]
        if to_the_right:
            return Column(header.x0 - COLUMN_MARGIN,
                          min(to_the_right) - COLUMN_MARGIN, header.y1)
    if headers:
        return Column(headers[0].x0 - COLUMN_MARGIN, float("inf"),
                      headers[0].y1)
    return None


def bold_rects(page: pymupdf.Page) -> list[pymupdf.Rect]:
    rects: list[pymupdf.Rect] = []
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            for span in line["spans"]:
                if span["flags"] & BOLD_FLAG or BOLD_FONT.search(span["font"]):
                    rects.append(pymupdf.Rect(span["bbox"]))
    return rects


def is_kept(word: Word, bold: list[pymupdf.Rect]) -> bool:
    return any(word.centre in rect for rect in bold)


def row_boxes(redact: list[Word], x_left: float,
              x_right: float) -> list[pymupdf.Rect]:
    """One box per line spanning the whole column, so neither the number of
    words nor the length of the text shows through."""
    rows: dict[tuple[int, int], pymupdf.Rect] = {}
    for word in redact:
        key = (word.block, word.line)
        rows[key] = rows[key] | word.rect if key in rows else word.rect
    return [pymupdf.Rect(x_left, r.y0, x_right, r.y1) for r in rows.values()]


def column_lines(words: list[Word], column: Column) -> list[list[Word]]:
    """Words of the column grouped into text lines, top to bottom."""
    lines: dict[tuple[int, int], list[Word]] = {}
    for word in filter(column.contains, words):
        lines.setdefault((word.block, word.line), []).append(word)
    return sorted(lines.values(), key=lambda line: min(w.y0 for w in line))


def line_rect(line: list[Word]) -> pymupdf.Rect:
    rect = line[0].rect
    for word in line[1:]:
        rect |= word.rect
    return rect


def transaction_lines(lines: list[list[Word]], dates: list[Word],
                      bold: list[pymupdf.Rect]) -> list[list[Word]]:
    """Lines level with a date left of the column, plus the lines directly
    below them. A gap of half a line or more, or an all-bold line, ends the
    transaction, so the footer and summary lines are never included."""
    result: list[list[Word]] = []
    previous: pymupdf.Rect | None = None
    for line in lines:
        rect = line_rect(line)
        dated = any(rect.y0 <= d.centre.y <= rect.y1 for d in dates)
        wrapped = (previous is not None
                   and rect.y0 - previous.y1 < rect.height / 2)
        all_bold = all(is_kept(w, bold) for w in line)
        if (dated or wrapped) and not all_bold:
            result.append(line)
            previous = rect
        else:
            previous = None
    return result


def plan_page(page: pymupdf.Page) -> PagePlan | None:
    words = page_words(page)
    column = find_column(words)
    if column is None:
        return None
    bold = bold_rects(page)
    dates = [w for w in words
             if DATE.match(w.text) and w.y0 >= column.y_top
             and w.x1 <= column.x_left + COLUMN_MARGIN]
    redact: list[Word] = []
    keep: list[Word] = []
    for line in transaction_lines(column_lines(words, column), dates, bold):
        for word in line:
            (keep if is_kept(word, bold) else redact).append(word)

    x_right = min(column.x_right, page.rect.x1 - COLUMN_MARGIN)
    boxes = row_boxes(redact, column.x_left, x_right)
    # A bold word on a redacted line goes with it; bold only marks metadata
    # lines, which never share a line with transaction details.
    swallowed = [w for w in keep if any(w.centre in box for box in boxes)]
    keep = [w for w in keep if w not in swallowed]
    return PagePlan(redact=redact + swallowed, keep=keep, boxes=boxes)


def print_plan(page_number: int, plan: PagePlan) -> None:
    """Print the column row by row, redacted words shown as blocks."""
    print(f"--- page {page_number} ---")
    rows: dict[tuple[int, int], list[tuple[float, str]]] = {}
    for word in plan.redact:
        rows.setdefault((word.block, word.line), []).append(
            (word.x0, "█" * len(word.text)))
    for word in plan.keep:
        rows.setdefault((word.block, word.line), []).append(
            (word.x0, word.text))
    for key in sorted(rows):
        print("   ", " ".join(text for _, text in sorted(rows[key])))


def verify(path: Path, redacted: list[str], kept: list[str]) -> bool:
    """Check the saved file: redacted words gone, kept words still present."""
    with pymupdf.open(path) as doc:
        text = " ".join(page.get_text() for page in doc)
    leaked = sorted({w for w in redacted if len(w) > 2 and w in text})
    lost = sorted({w for w in kept if w not in text})
    if leaked:
        print("WARNING, still in the text (maybe they also appear outside "
              "the column, check):", leaked)
    if lost:
        print("WARNING, kept words that went missing:", lost)
    return not leaked and not lost


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path)
    parser.add_argument(
        "output", type=Path, nargs="?",
        help="where to write the redacted copy; omit for a dry run")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    src: Path = args.input
    dst: Path | None = args.output
    if dst is not None and src.resolve() == dst.resolve():
        sys.exit("Output must be a different file than the input.")

    redacted: list[str] = []
    kept: list[str] = []
    with pymupdf.open(src) as doc:
        for page in doc:
            plan = plan_page(page)
            if plan is None:
                print(f"--- page {page.number + 1}: no '{HEADER}' column, "
                      "left untouched ---")
                continue
            print_plan(page.number + 1, plan)
            redacted += [w.text for w in plan.redact]
            kept += [w.text for w in plan.keep]
            if dst is None:
                continue
            for box in plan.boxes:
                page.add_redact_annot(box, fill=(0, 0, 0))
            page.apply_redactions(images=pymupdf.PDF_REDACT_IMAGE_PIXELS,
                                  graphics=pymupdf.PDF_REDACT_LINE_ART_NONE)

        if dst is None:
            print("\nDry run, nothing written. Pass an output file to redact.")
            return

        doc.scrub()
        doc.save(dst, garbage=4, deflate=True, clean=True)

    print(f"\nWrote {dst}: {len(redacted)} words redacted.")
    if verify(dst, redacted, kept):
        print("Verified: redacted words are gone, kept words are intact.")


if __name__ == "__main__":
    main()
