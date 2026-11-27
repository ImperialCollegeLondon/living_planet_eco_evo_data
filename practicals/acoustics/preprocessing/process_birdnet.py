"""This script use the Python birdnet_analyzer function to quickly process a site folder
of WAV files. This is more efficient than the single file processing in the birdnetR
package in R. The directory structure needs to be structured as:

       ── root
       │   ├── sites
       │   │   ├── site_name
       │   │   │   ├── Data
       │   │   │   │   ├── 20240802_054502.wav
       │   │   │   │   ├── 20240802_055002.wav
       │   ...
       ── outputs # created as needed
       ── script_files etc

Each `site_name` directory is basically the contents of the data downloaded from the
song meters. The script is then expecting to be run in an array job and will use the
array index to pick up one of the site folders and process all the files in the
folder.
"""

import os
import tempfile
from pathlib import Path

import pandas as pd
from birdnet_analyzer import analyze

ROOT_DIRECTORY = Path("/rds/general/users/dorme/acoustics_2026")


def analyse_directory():
    """Run birdnet_analyzer.analyze on an array subjob directory.

    This function runs analyze on a site directory selected by the PBS_ARRAY_INDEX value
    and then compiles the file by file identifications into a single site CSV file. It
    is structured as a function rather than a script to be compatible with the spawn
    process for using multiple threads.
    """
    # Path handling
    output_directory = ROOT_DIRECTORY / "outputs"
    output_directory.mkdir(exist_ok=True)

    # Get the path to the WAV file directory for this site
    array_index = int(os.getenv("PBS_ARRAY_INDEX"))
    sites = sorted((ROOT_DIRECTORY / "sites").glob("[!.]*"))
    site_directory = sites[array_index]

    # Write outputs to a temporary directory
    with tempfile.TemporaryDirectory() as tmp:
        # Run the analysis. This is equivalent to using the command line:
        #
        # python -m birdnet_analyzer.analyze \
        #     site_directory \
        #     --output output_directory --batch_size 32 --min_conf 0.1
        #
        # It is being run from within a python script mostly so that pandas can then be used
        # to compile the file by file outputs into a single site output file.

        analyze(
            audio_input=str(site_directory),
            output=tmp,
            batch_size=32,
            min_conf=0.1,
        )

        # Compile the per-WAV outputs into a single dataframe
        outputs = list(Path(tmp).glob("*.BirdNET.selection.table.txt"))
        data_frames = [pd.read_csv(f, delimiter=r"\t") for f in outputs]
        site_data = pd.concat(data_frames, ignore_index=True)

    # Process the columns to reduce to key data and use cleaner names
    site_data["file"] = [Path(x).name for x in site_data["Begin Path"]]
    site_data["start_time"] = pd.to_datetime(
        site_data["file"], format="%Y%m%d_%H%M%S.wav"
    ) + pd.to_timedelta(site_data["File Offset (s)"], "s")
    site_data["length"] = site_data["End Time (s)"] - site_data["Begin Time (s)"]
    site_data["site"] = site_directory.name

    # Reduce the data frame to only the required fields
    site_data = site_data[
        [
            "site",
            "file",
            "Common Name",
            "Species Code",
            "Confidence",
            "start_time",
            "length",
            "File Offset (s)",
        ]
    ]

    # Rename fields to remove spaces
    site_data.rename(
        columns={
            "Common Name": "common_name",
            "Species Code": "species_code",
            "Confidence": "confidence",
            "File Offset (s)": "file_offset",
        },
        inplace=True,
    )

    # Export compiled data to a site file
    site_data.to_csv(output_directory / f"{site_directory.name}_birdnet.csv")


if __name__ == "__main__":
    """Python syntax to define what happens when the script is run."""
    analyse_directory()
