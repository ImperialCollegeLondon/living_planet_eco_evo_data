# Building and deploying the practicals

## Local builds

When writing or editing the practicals, it is useful to run `jupyter book` alongside: it
can provide live updates to the HTML update as you save changes to the documentation.

```sh
cd practicals
jupyter book start --execute
```

## Deploying practicals

The code below builds the site, using the `BASE_URL` variable to configure the build for
a deployment to the GitHub pages for the repository.

```sh
cd practicals

# Build the practicals site
export BASE_URL=https://imperialcollegelondon.github.io/living_planet_eco_evo_data
jupyter book build --html --execute

# Deploy it to GitHub pages
ghp-import -n -p -f _build/html -m "Informative message on updated practicals."
```
