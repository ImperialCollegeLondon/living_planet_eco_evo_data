r"""Format R code cells in MyST notebook using air

This is a very basic script that scans a MyST notebook and looks for R code chunks
bracketed by "```{code-cell} R\n" and "```\n". It saves the code chunks out to temporary
files and runs air over the files and then exports a file replacing the code cell
contents with the air formatted outputs.
"""

import subprocess
import sys
import tempfile
from pathlib import Path


def run_air(file: Path):
    with open(file) as md_file:
        markdown_source = md_file.readlines()

    code_cell_start = [
        line_no
        for line_no, line in enumerate(markdown_source)
        if line.startswith("```{code-cell} r")
    ]

    formatted = []
    non_code_start = 0

    for cell in code_cell_start:
        chunk = []
        non_code_end = cell
        while True:
            cell += 1
            line = markdown_source[cell]

            if line == "```\n":
                break

            chunk.append(line)

        tmp = tempfile.NamedTemporaryFile(suffix=".R")  # noqa: SIM115

        with open(tmp.name, "w") as chunk_file:
            chunk_file.writelines(chunk)

        # Run air:
        subprocess.run(["air", "format", tmp.name], check=False)

        with open(tmp.name, "r") as chunk_file:
            formatted_chunk = chunk_file.readlines()

        formatted.extend(markdown_source[non_code_start : (non_code_end + 1)])
        formatted.extend(formatted_chunk)
        non_code_start = cell

    formatted.extend(markdown_source[non_code_start:])

    outfile = file.parent / (file.name.removesuffix(".md") + "_air" + ".md")
    with open(outfile, "w") as formatted_outfile:
        formatted_outfile.writelines(formatted)


if __name__ == "__main__":
    run_air(Path(sys.argv[1]))
