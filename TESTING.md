# Testing is performed using BATS

The BATS software is consumed via git submodules. After you have cloned this repository,
you will need to initialise and update the git submodules

```
git submodule update --init --recursive
```

Then from within the container (or dev-container), you should be able to run

```
cd /                          # if inside the production container
cd /workspaces/json-to-mmdb   # if inside the dev-container in VS Code

[user@1164dff93b6a json-to-mmdb]$ ./test/libs/bats/bin/bats -r ./test/spec/
 ✓ Help must be given
 ✓ Must not only provide input
 ✓ Must not only provide output
 ✓ Basic conversion (demo.json to demo.mmdb) must work
 ✓ Non-MMDB should fail to be recognised as a MMDB file
 ✓ Output must be recognised as a MMDB file
 ✓ Correct subnet should be found for 172.16.0.1

7 tests, 0 failures
```

When building the Docker image, the tests are performed as part of the image build.


To do this initially, I had done:

```
mkdir -p test/lib
git submodule add https://github.com/bats-core/bats-core test/libs/bats
git submodule add https://github.com/bats-core/bats-support test/libs/bats-support
git submodule add https://github.com/ztombol/bats-assert test/libs/bats-assert
```

Alternatively you would need to download these into the container image. I'm not
in love with either idea myself.
