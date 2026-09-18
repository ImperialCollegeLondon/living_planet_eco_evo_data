# Teaching Materials for the Ecological and Evolutionary Data Science module

This repository provides teaching materials used in the Ecological and Evolutionary Data
Science module used by the following courses at Imperial College London and the Natural
History Museum:

* the Living Planet program at the Silwood Park campus,
* the Taxonomy, Biodiversity and Evolution MSc at the NHM, and
* the Biosystematics MRes at the NHM.

## Content and deployment

The main part of the repository are practical notes for the course. Practicals are

* written as executable notebooks using the [Myst Markdown](https://mystmd.org/) format,
* executed using [Jupyter Book](https://jupyterbook.org/) to build the HTML site,
* deployed using the [`ghp-import`](https://pypi.org/project/ghp-import/) tool to GitHub
  Pages at
  [https://imperialcollegelondon.github.io/living_planet_eco_evo_data/](https://imperialcollegelondon.github.io/living_planet_eco_evo_data/)

## Tools

The repository uses the following tools for reproducible running and quality assurance:

* The [`uv`](https://docs.astral.sh/uv) package is used to maintain the Python
  environment used to build the site in Jupyter Book.

* The ['uvr`](https://nbafrank.github.io/uvr) package is used to install and maintain
  the R environment needed to run the code provided in the practicals.

* The [`pre-commit`](https://pre-commit.com/) package is used for running and
  maintaining code quality checks within the repository. This package hooks into `git`
  and runs a configured set of code checks when `git commit` is used to commit new
  content to the repository.

## Setup

The following steps are needed to setup and build the course website.

1. Clone the repository to your computer:

```sh
git clone https://github.com/ImperialCollegeLondon/living_planet_eco_evo_data.git
```

1. Now [install `uv`](https://docs.astral.sh/uv/getting-started/installation/) then run
   `uv sync` in the repository root. This will download all of the Python packages
   needed to run Jupyter Book and the `pre-commit` tool. The `uv` tool creates directory
   `.venv` that contains a Python virtual environment that can then be used to run all
   of the Python tool commands.

1. Now [install `uvr`](https://nbafrank.github.io/uvr/#install) and run `uvr sync` in
   the repository root. This will create a director `.uvr` and install the specific
   version of R and packages needed to execute the practical code in the notebooks.

1. Next install `pre-commit` into the local repository clone:
   `uv run pre-commit install`. You should see the message
   `pre-commit installed at .git/hooks/pre-commit`.

   Note the use of `uv run`: this ensures that the following command
   `pre-commit install` is run using the virtual environment installed by `uv`.

1. Next, we need to make sure that the R code in the notebooks is run using the R
   environment installed using `uvr`. To do this, we need to install a new Jupyter
   kernel that links to the R environment. This is slightly complex because we need to
   make sure that we are running the right environments for both Python and R!

```sh
# Activate the Python environment - this will change your command prompt to add
# the text `(living-planet-eco-evo-data)`.
source .venv/bin/activate
# Activate the R environment - this will further change the command prompt to add
# the text `(living_planet_eco_evo_data_uvr)`.
source .uvr/activate
# Run the R code needed to install the kernel
R -e "IRkernel::installspec(name = 'uvr-ecoevodata', displayname = 'R (ecoevodata)')"
```

   The metadata for all of the practical notebooks in the repository should specify that
   they use the `uvr-ecoevodata` kernel. This ensures that all of the practical code is
   run using the same R environment.

## Adding content and deployment

**IMPORTANT**: The build process requires the underlying datasets used to demonstrate
the code and generate figures and graphics. These are large datafiles and are not
included in the repository. At the moment, we do not have a shared location containing
the build data but the plan is to provide a downloadable `data` directory that can be
dropped into the repository.

### Developing the notebooks

The notebooks in this repository are written using [Myst Markdown](https://mystmd.org/).
This format allows the notebooks to be stored as simple plain text files but Myst format
provides an extended set of options for running code blocks and text formatting that
works very well for providing high quality HTML outputs.

The downside of using Myst notebooks rather than the standard `ipynb` format notebooks
is that they do not store the outputs of running cells. These are only generated when
you run the notebook in Jupyter Lab or when the content is built using Jupyter Book to
generate the final HTML. These two approaches for developing notebook content are
explained below:

1. You can use `jupyter-lab` to open the notebooks and edit the content and run the code
   cells. You will need to activate the `uvr` environment first so that Jupyter can
   connect to the `uvr-ecoevodata` kernel.

    ```sh
    source .uvr/activate
    uv run jupyter-lab
    ```

   When Jupyter Lab starts, you can then open and run notebooks. This option can be
   particularly useful when developing the bulk of a notebook content because you can
   edit and add content and outputs are shown immediately in the same window. There are
   two main drawbacks:

    * Jupyter Lab is not integrated with the tools used by `pre-commit` and so is quite
      happy to save notebooks with minor formatting problems like over-long lines. This
      is not a big deal - you will just need to leave Jupyter Lab and then tidy up any
      issues in a code editor before you can commit the changes.

    * Jupyter Lab runs Myst notebooks without any issue, but is not aware of some of the
      formatting extensions available in Myst. It also only shows the immediate content
      of the notebook and not the content of that notebook page in the eventual HTML
      page. You can only see the final result of the notebook content once it has been
      run using Jupyter Book.

2. Jupyter Book provides a "live" mode that updates the built HTML when the input
   notebooks are edited and saved. This option allows you to work in VSCode directly and
   Jupyter Book will update the HTML when you save files. This does mean you have to
   watch a separate browser as you edit the files, but you do then see the final
   rendered output as it will appear online. To start the live rendering, run the code
   below:

    ```sh
    source .uvr/activate
    cd practicals
    uv run jupyter book start --execute
    ```

   The command should start a process and give you a URL to the locally hosted HTML
   (usually `http://localhost:3000`). If you open that URL then you should see the
   website and pages will update automatically when you save the underlying notebook
   code.

### Building the site

:::{note}
Ideally we would build and deploy changes to the site automatically using one of the
existing GitHub Actions workflows for `jupyter book`. The problem here is that the
practicals execute code cells that require practical data in order to generate expected
code outputs and images. At some point, we may be able to fix those inputs into an asset
that GitHub Actions can use, but at the moment we need to build locally and then deploy.
:::

In order to build the site locally, we use `jupyter book` to re-run all of the notebooks
and save the resulting HTML to a build directory. The first step is to clean up any
previous build, including cached outputs, so that all of the code is executed from
scratch to give a complete rebuild. You will get a prompt to confirm that you want to do
this.

```sh
# Activate the R environment
source .uvr/activate
cd practicals

uv run jupyter book clean
```

The next step is to rebuild the site. In order to make sure that the links are correct
when it is deployed to GitHub, we need to set the `BASE_URL` environment variable,
otherwise all the links will point to the local file locations.

```sh
# Build the practicals site
export BASE_URL=https://imperialcollegelondon.github.io/living_planet_eco_evo_data
uv run jupyter book build --html --execute
```

Ths can take a while to run - all of the R code in the notebooks needs to execute.

### Deploying the site

We use the `ghp-import` tool to deploy the built HTML to the `gh-pages` branch of the
repository, which is then automatically deployed to [https://imperialcollegelondon.github.io/living_planet_eco_evo_data/](https://imperialcollegelondon.github.io/living_planet_eco_evo_data/)

```sh
uv run ghp-import -n -p -f _build/html -m "Informative message on updated practicals."
```
