## OwnMyLvar

TODO

## Installation

For installation in details please look at the main MLKit [installation guide](https://github.com/melsman/mlkit?tab=readme-ov-file#installation). Here is a short approach for building the project:

### Linux
```bash
$ wget https://github.com/melsman/mlkit/releases/latest/download/mlkit-bin-dist-linux.tgz
$ tar xzf mlkit-bin-dist-linux.tgz
$ cd mlkit-bin-dist-linux
$ make install
$ sudo mkdir /usr/local/etc/mlkit
$ sudo echo "SML_LIB /usr/local/lib/mlkit" > /usr/local/etc/mlkit/mlb-path-map
```

### MacOS
```bash
```

## Tests and samples
The tests and samples are in [ownershipdemo](/ownershipdemo).

You can compile any of them using following command (use these command from root of the project):
```bash
$ SML_LIB=$PWD bin/mlkit -no_gc ownershipdemo/any_test.sml
```
and then run the compiled program using `./run`.
### Basic tests:
There are three sample codes that should fail the effect check for owner values:
- [basic_error1.sml](/ownershipdemo/basic_error1.sml): An implementation of append function which tries to allocate memory in its arguments regions.
- [basic_error2.sml](/ownershipdemo/basic_error2.sml): Using the ML defualt append function which has a side effect of allocating the result in its second argument's region.
- [basic_error3.sml](/ownershipdemo/basic_error3.sml): A curried function which applying it forces their arguments to be in the same region which causes vaiolating ownership of one of it's arguments to its region.
### Performance test:
For performance checking, a simple evalotionary algorithm is implemented that tries to solve following problem:

Given an expression of form following:

$$ F(X) = \sum_{i, j}^{n}{ A_{i, j} \times x_{i}x_{j} } + \sum_{i}^{n}{ B_{i} \times x_{i} } $$

Find some $X$ where $l_i \leq x_i \leq r_i$ and $F(X)$ is maximum. For solving this problem a simple evalotionary algorithm is used:
1. Set $X$ to some random values and repeate following couple of times:
2. Generate $100$ samples from mutating $X$.
3. Choose the maximum sample and store it in $X$.

This algorithm first is implemented staightforward in [basic_error3.sml](/ownershipdemo/eval.sml), and then in [basic_error3.sml](/ownershipdemo/own_eval.sml) I tried to separate samples regions from the argument region so that they can be freed in each iteration.
You can run the codes using following commands:
```bash
$ SML_LIB=$PWD bin/mlkit -no_gc -Pole ownershipdemo/eval.sml && /usr/bin/time -v ./run
$ SML_LIB=$PWD bin/mlkit -no_gc -Pole ownershipdemo/own_eval.sml && /usr/bin/time -v ./run
```
The result show that the memory usage in the separated version of the code is divided by $1/3$ despite of having more copying happening.
