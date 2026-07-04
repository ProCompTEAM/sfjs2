# Versioned Builds

This directory contains production-ready versioned builds of **Satisfaction.JS**.

Each version is stored in a separate folder. The folder name must match the value of `SF_PUBLIC_VERSION` from the root development file:

```js
const SF_PUBLIC_VERSION = "2.1.2.1229";
```

## Directory format

```text
versions/
  <version>/
    satisfaction.min.js
```

Example:

```text
versions/
  2.1.2.1229/
    satisfaction.min.js
```

## File rules

* Each version folder must contain the minified production file named `satisfaction.min.js`.
* Version folders should not be renamed after release.
* Released files should be treated as immutable.
* Do not edit files inside `versions/` manually.
* Production files are generated from the root `satisfaction.dev.js` file.

## Creating a new version

To create a new version:

1. Update `SF_PUBLIC_VERSION` inside `satisfaction.dev.js`.
2. Run the build script.
3. Commit the generated version folder.

The build script will automatically:

* read the version from `satisfaction.dev.js`;
* create the matching folder inside `versions/`;
* generate `satisfaction.min.js`;
* place the final production-ready file into the correct version folder.

## Public usage format

A released file can be referenced by version:

```html
<script src="/versions/2.1.2.1229/satisfaction.min.js"></script>
```

Replace `2.1.2.1229` with the required version.