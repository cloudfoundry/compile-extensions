# compile extensions

A library which provides extra functions and overrides for Cloud
Foundry Buildpack compile scripts.

This is included a git submodule in all the official Cloud Foundry buildpacks.

## check\_stack\_support

Print out a lovely error message when the current `stack` is not supported by the buildpack.

### Usage

```bash
./compile-extensions/bin/check_stack_support
```

## download\_dependency

Translates the URL given in `ARGV[0]` by matching the URL to a corresponding entry in `manifest.yml` and downloads the translated file with `curl`.

### Usage

```bash
./compile-extensions/bin/download_dependency [URI] [INSTALL_DIR]
```

## is\_cached

Returns an exit status of `0` if the current buildpack is a cached buildpack.

### Usage

```bash
./compile-extensions/bin/is_cached
```

## default\_version\_for

Returns the default version in the manifest (if specified) for a given dependency

### Usage

```bash
./compile-extensions/bin/default_version_for [MANIFEST_FILE] [DEPENDENCY_NAME]
```

## check\_buildpack\_version

Print out a warning message when the current buildpack used for staging is a different version
than the version of the buildpack used for the last successful staging.

- The buildpacks need to be the same buildpack (i.e. have the same `language`
  value in their `manifest.yml` files.) for the version check to apply.

```bash
./compile-extensions/bin/check_buildpack_version [STAGING_BUILDPACK_DIR] [CACHE_DIR]
```

## store\_buildpack\_metadata

Write the version of the current buildpack used for staging and the language (`language`
value in its `manifest.yml` file) to a metadata file (`BUILDPACK_METADATA`)
in the buildpack app cache directory.

```bash
./compile-extensions/bin/store_buildpack_metadata [STAGING_BUILDPACK_DIR] [CACHE_DIR]
```
