## OwnMyLvar
OwnMyLvar (OML) provides users with a syntax (owner values), that guarantees the segregation of regions. If this condition is not met, a compile error will occur.
The introduced syntax enables variables (value bindings) to own the region in which the value is placed. As a result, as long as the variable stays in the scope, there can be no new allocation other than through the variable.
Presently, inter-module level code and reference mutating are not supported in OML, thus, no allocations can take place within the variable region as long as it remains within the scope

For example in the following code:
```sml
let 
  val a = (*some list which will last forever*)
  val b = (*some list will be popped soon*)
in
  if sum(a) > sum(b) then a else b
end
```

Lists a and b have to be on the same region because of the if statement, but if we change the code to the following:

```sml
let 
  val a = (*some list which will last forever*)
  val b = (*some list will be popped soon*)
in
  if sum(a) > sum(b) then a else (cp b)
end
```

Then a, and b will be placed in two regions. Now if the programmer uses OML, and marks a as owner:

```sml
let 
  oval a = (*some list which will last forever*)
  val b = (*some list will be popped soon*)
in
  if sum(a) > sum(b) then a else b
end
```

This code will result in a compile error telling that b is going to allocate some memory in the owned region of a and the following code will not have any compile error:

```sml
let 
  oval a = (*some list which will last forever*)
  val b = (*some list will be popped soon*)
in
  if sum(a) > sum(b) then a else (cp b)
end
```

In summary, OML helps the programmer separate variable regions.


## Build

For installation in details please look at the main MLKit [installation guide](https://github.com/melsman/mlkit?tab=readme-ov-file#installation). Here is a short approach for building the project:

### Linux
```bash
$ sudo apt-get update
$ sudo apt-get install -y gcc autoconf make
$ wget https://github.com/melsman/mlkit/releases/latest/download/mlkit-bin-dist-linux.tgz
$ tar xzf mlkit-bin-dist-linux.tgz
$ cd mlkit-bin-dist-linux
$ sudo make install
$ sudo mkdir /usr/local/etc/mlkit
$ sudo -s
$ echo "SML_LIB /usr/local/lib/mlkit" > /usr/local/etc/mlkit/mlb-path-map
$ Ctrl + d
$ cd ..
$ git clone https://github.com/amsen20/OwnML.git
$ cd OwnML
$ ./autobuild
$ ./configure --with-compiler=mlkit
$ make mlkit # might take couple of minutes
```

## Tests and samples
The tests and samples are in [ownershipdemo](/ownershipdemo).

You can compile any of them using following command (use these command from root of the project):
```bash
$ sudo bin/mlkit -no_gc ownershipdemo/any_test.sml
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

This algorithm first is implemented staightforward in [eval.sml](/ownershipdemo/eval.sml), and then in [own_eval.sml](/ownershipdemo/own_eval.sml) I tried to separate samples regions from the argument region so that they can be freed in each iteration.
You can run the codes using following commands:
```bash
$ sudo bin/mlkit -no_gc -Pole ownershipdemo/eval.sml && /usr/bin/time -v ./run
$ sudo bin/mlkit -no_gc -Pole ownershipdemo/own_eval.sml && /usr/bin/time -v ./run
```
The result shows that the memory usage in the separated version of the code is 3 times less than the basic version, despite of having more copying happening.
