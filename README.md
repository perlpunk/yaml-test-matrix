# YAML Test Framework Matrix

This matrix makes use of the [YAML Test Suite](https://github.com/yaml/yaml-test-suite)
and the [YAML Runtimes](https://github.com/yaml/yaml-runtimes).

Its output is currently saved in the
[gh-pages branch](https://github.com/yaml/yaml-test-suite/tree/gh-pages)
of yaml-test-suite.

It shows which frameworks pass which test cases:

| Test ID | Framework 1 Events | FW2 Events | FW1 JSON | ...  |
| ------- | ------------------ | ---------- | -------- | ---- |
| 229Q    | ok                 | error      | ok       | diff |
| 236B    | diff               | ok         | error    | ok   |
| 26DV    | diff               | ok         | n/a      | n/a  |

It only shows results of valid YAML files currently.

## YAML Test Suite

The Test Suite is a collection of over 250 YAML test cases.

Every test case contains some of the following files:
- in.yaml: The input YAML
- test.event: Parser events in a specific format
- in.json: The corresponding JSON that matches the loaded data structure
- out.yaml, emit.yaml
- error: Marks YAML files that are invalid

## YAML Editor

The editor consists of code to create a Docker image that has currently
16 different YAML frameworks installed.

For each framework there exist scripts to output the yaml-test-suite parsing
event format, the loaded data structure in native format and in JSON.

It also contains a script that will open Vim in the Docker container with
some fancy mappings, so you can test YAML input for as manu frameworks
at the same time.

## Matrix

Now the matrix takes all test cases from yaml-test-suite and runs them
through the various frameworks in the yaml-runtimes Docker container.

It checks if the program died, or if the result matches the expected
output.
It does some transformations as not all frameworks support all features.

## Adding frameworks

If you want to see a new framework in the matrix, it has to be added to
the YAML Editor. Please create an [issue](https://github.com/yaml/yaml-runtimes/issues)
or [pull request](https://github.com/yaml/yaml-runtimes/pulls) there.
