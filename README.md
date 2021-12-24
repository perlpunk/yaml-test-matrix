# YAML Test Matrix

This matrix makes use of the [YAML Test Suite](https://github.com/yaml/yaml-test-suite)
and the [YAML Runtimes](https://github.com/yaml/yaml-runtimes).

Its output is currently saved in the
[gh-pages branch](https://github.com/yaml/yaml-test-suite/tree/gh-pages)
of yaml-test-suite.

You can find the current version on: [matrix.yaml.info](https://matrix.yaml.info/).
During development I'm using
[perlpunk.github.io/yaml-test-matrix](https://perlpunk.github.io/yaml-test-matrix/).

It shows which processors pass which test cases:

| Test ID | Lib1 Events | Lib2 Events | Lib3 JSON | ...  |
| ------- | ----------- | ----------- | --------  | ---- |
| 229Q    | ok          | error       | ok        | diff |
| 236B    | diff        | ok          | error     | ok   |
| 26DV    | diff        | ok          | n/a       | n/a  |

It only shows results of valid YAML files currently.

## YAML Test Suite

The [Test Suite](https://github.com/yaml/yaml-test-suite) is a collection of
over 320 YAML test cases.

Every test case contains some of the following files:
- in.yaml: The input YAML
- test.event: Parser events in a specific format
- in.json: The corresponding JSON that matches the loaded data structure
- out.yaml, emit.yaml
- error: Marks YAML files that are invalid

## YAML Runtimes

[yaml-runtimes](https://github.com/yaml/yaml-runtimes)  consists of code to
create docker images that currently have 21 different YAML libraries installed.

For each library there exist scripts to output the yaml-test-suite parsing
event format, the loaded data structure in native format and in JSON.

You can also try out these library runtimes with the [YAML
Editor](https://github.com/yaml/yaml-editor).  It contains a script that will
open Vim in the Docker container with some fancy mappings, so you can test YAML
input for many processors at the same time.

## Matrix

Now the matrix takes all test cases from yaml-test-suite and runs them
through the various processors in the yaml-runtimes Docker container.

It checks if the program died, or if the result matches the expected
output.
It does some transformations as not all libraries support all features.

## Adding a library

If you want to see a new library in the matrix, it has to be added to YAML
Runtimes.
Please create an [issue](https://github.com/yaml/yaml-runtimes/issues) or [pull
request](https://github.com/yaml/yaml-runtimes/pulls) there.

